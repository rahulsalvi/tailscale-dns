# tailscale-dns
My setup for resolving DNS names to tailscale addresses. The start script generates tailscale auth keys and brings up the system.

Based on work from [willnorris/ipn-dns](https://github.com/willnorris/ipn-dns) and uses the plugin [damomurf/coredns-tailscale](https://github.com/damomurf/coredns-tailscale)

## Running
```
make start
# follow the prompts
# you will need an oauth client ID and secret from tailscale
```

## Updating
```
make update
# follow the prompts
# you will need an oauth client ID and secret from tailscale
```

### Updating CoreDNS
```
cd coredns
go get -u
go mod tidy
```

## Stopping
```sh
# bring down containers
make down
# (optional) clean up all resources
# WARNING: this will prune docker volumes that aren't being used
make clean
```

## DNS Records
I now manage these externally using OpenTofu, but you can use flarectl to create the required records.
