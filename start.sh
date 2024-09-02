#!/bin/bash

set -euo pipefail

[ -f .env ] && source .env

declare -A deps
deps["gum"]="github.com/charmbracelet/gum@latest"
deps["get-authkey"]="tailscale.com/cmd/get-authkey@latest"

for dep in "${!deps[@]}"; do
	if ! command -v "${dep}" &>/dev/null; then
		echo "Installing ${dep}"
		go install "${deps[${dep}]}"
	fi
done

[ ! -v NAME ] && NAME=$(gum input --placeholder="Enter the nameserver to manage (e.g. ns1)")
if [ -z "$NAME" ]; then
	echo "Enter a valid name"
	exit 1
fi
export NAME

if tailscale ip "${NAME}" >/dev/null 2>&1; then
	echo "${NAME} seems to already exist. You should remove it before continuing"
	echo "https://login.tailscale.com/admin/machines"
	exit 1
fi

[ ! -v DOMAIN ] && DOMAIN=$(gum input --placeholder="Enter the domain to manage (e.g. example.com)")
if [ -z "$DOMAIN" ]; then
	echo "Enter a valid domain"
	exit 1
fi
export DOMAIN

[ ! -v DOMAIN_PREFIX ] && DOMAIN_PREFIX=$(gum input --placeholder="Enter the domain prefix (e.g. internal)")
if [ -z "$DOMAIN_PREFIX" ]; then
	echo "Enter a valid prefix"
	exit 1
fi
export DOMAIN_PREFIX

echo "Managing ${NAME}.${DOMAIN_PREFIX}.${DOMAIN}"

echo "Enter your tailscale API client ID"
echo "https://login.tailscale.com/admin/settings/oauth"
TS_API_CLIENT_ID=$(gum input --password)
export TS_API_CLIENT_ID

echo "Enter your tailscale API client secret"
echo "https://login.tailscale.com/admin/settings/oauth"
TS_API_CLIENT_SECRET=$(gum input --password)
export TS_API_CLIENT_SECRET

echo "Generating tailscale auth keys"
NS_AUTHKEY=$(get-authkey -ephemeral -preauth -tags tag:nameserver,tag:authoritative)
export NS_AUTHKEY
# COREDNS_AUTHKEY is used as a line in the config file verbatim. That's why it has authkey as a prefix.
COREDNS_AUTHKEY="authkey $(get-authkey -ephemeral -preauth -tags tag:coredns)"
export COREDNS_AUTHKEY

gum spin --title "Starting up" --show-output -- docker compose up -d --build

if gum confirm "Would you like to write settings to .env?"; then
	{
		echo "NAME=${NAME}"
		echo "DOMAIN=${DOMAIN}"
		echo "DOMAIN_PREFIX=${DOMAIN_PREFIX}"
	} >.env
fi

echo "Remember to update DNS records with OpenTofu"
echo "Done!"
