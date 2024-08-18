#!/bin/bash

export GOPATH="${PWD}/go"
echo "Installing dependencies to ${GOPATH}/bin"
go install tailscale.com/cmd/get-authkey@latest
go install github.com/cloudflare/cloudflare-go/cmd/flarectl@latest
go install github.com/charmbracelet/gum@latest
export PATH="${GOPATH}/bin:${PATH}"

if [ -f .env ]; then
	source .env
else
	echo "Choose which nameserver to bring up"
	NAME=$(gum input --placeholder "nsX")
	echo "Enter URL to manage"
	URL=$(gum input)
	echo "Enter URL prefix"
	URL_PREFIX=$(gum input)
	echo "NAME=${NAME}" >.env
	echo "URL=${URL}" >>.env
	echo "URL_PREFIX=${URL_PREFIX}" >>.env
	echo "Wrote variables to .env"
fi

echo "Managing ${NAME}.${URL_PREFIX}.${URL}"

echo "Enter your tailscale API client ID"
echo "https://login.tailscale.com/admin/settings/oauth"
TS_API_CLIENT_ID=$(gum input --password)
export TS_API_CLIENT_ID

echo "Enter your tailscale API client secret"
echo "https://login.tailscale.com/admin/settings/oauth"
TS_API_CLIENT_SECRET=$(gum input --password)
export TS_API_CLIENT_SECRET

echo "Enter your cloudflare API token"
echo "https://dash.cloudflare.com/profile/api-tokens"
CF_API_TOKEN=$(gum input --password)
export CF_API_TOKEN

if tailscale ip "${NAME}" >/dev/null 2>&1; then
	echo "${NAME} seems to already exist. You should remove it before continuing"
	echo "https://login.tailscale.com/admin/machines"
	exit 1
fi

echo "Generating tailscale auth keys"
NS_AUTHKEY=$(get-authkey -ephemeral -preauth -tags tag:nameserver)
export NS_AUTHKEY
# COREDNS_AUTHKEY is used as a line in the config file verbatim. That's why it has authkey as a prefix.
COREDNS_AUTHKEY="authkey $(get-authkey -ephemeral -preauth -tags tag:nameserver)"
export COREDNS_AUTHKEY

gum spin --title "Starting up" -- docker compose up -d --build
gum spin --title "Waiting for nodes to come up" -- sleep 10

NS_IPV4=$(tailscale ip -4 "${NAME}")
NS_IPV6=$(tailscale ip -6 "${NAME}")

echo "Checking for existing DNS records"
RECORD_COUNT=$(flarectl --json dns list --zone "${URL}" --type "NS" --name "${URL_PREFIX}.${URL}" --content "${NAME}.${URL_PREFIX}.${URL}" | jq length)
if ((RECORD_COUNT > 0)); then
	echo "Updating existing DNS records"
	# Need to get the record IDs to update them
	A_RECORD_ID=$(flarectl --json dns list --zone "${URL}" --type "A" --name "${NAME}.${URL_PREFIX}.${URL}" | jq -r '.[].ID')
	AAAA_RECORD_ID=$(flarectl --json dns list --zone "${URL}" --type "AAAA" --name "${NAME}.${URL_PREFIX}.${URL}" | jq -r '.[].ID')
	flarectl dns update --zone "${URL}" --id "${A_RECORD_ID}" --type "A" --name "${NAME}.${URL_PREFIX}.${URL}" --content "${NS_IPV4}" >/dev/null
	flarectl dns update --zone "${URL}" --id "${AAAA_RECORD_ID}" --type "AAAA" --name "${NAME}.${URL_PREFIX}.${URL}" --content "${NS_IPV6}" >/dev/null
else
	echo "Creating new DNS records"
	flarectl dns create --zone "${URL}" --type "NS" --name "${URL_PREFIX}.${URL}" --content "${NAME}.${URL_PREFIX}.${URL}" >/dev/null
	flarectl dns create --zone "${URL}" --type "A" --name "${NAME}.${URL_PREFIX}.${URL}" --content "${NS_IPV4}" >/dev/null
	flarectl dns create --zone "${URL}" --type "AAAA" --name "${NAME}.${URL_PREFIX}.${URL}" --content "${NS_IPV6}" >/dev/null
fi
echo "${URL_PREFIX}.${URL} NS --> ${NAME}.${URL_PREFIX}.${URL}"
echo "${NAME}.${URL_PREFIX}.${URL}    A --> ${NS_IPV4}"
echo "${NAME}.${URL_PREFIX}.${URL} AAAA --> ${NS_IPV6}"

echo "Done!"
