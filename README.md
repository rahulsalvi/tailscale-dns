# tailscale-dns
My setup for resolving DNS names to tailscale addresses. The start script handles generating tailscale auth keys, bringing up the system, and creating/updating cloudflare DNS records.

Based on work from [willnorris/ipn-dns](https://github.com/willnorris/ipn-dns) and uses the plugin [damomurf/coredns-tailscale](https://github.com/damomurf/coredns-tailscale)

## Running
```
./start.sh
# follow the prompts
# you will need tokens from tailscale and cloudflare
```

## Stopping
```sh
# bring down containers
docker compose down
# (optional) remove .env file if starting over cleanly
rm .env
```
If you don't intend on restarting the server, you should clean up the DNS records using the cloudflare dashboard.
