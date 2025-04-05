# tailscale-dns
My setup for resolving DNS names to tailscale addresses.

Based on work from [willnorris/ipn-dns](https://github.com/willnorris/ipn-dns) and uses the plugin [damomurf/coredns-tailscale](https://github.com/damomurf/coredns-tailscale)

## Running
```
# put a unique ID into the .env file
echo ID=X >.env
# create two authkeys and put them in ts_authkey.txt and coredns_authkey.txt
# ephemeral, pre-approved, tags:nameserver,authoritative
echo $TS_AUTHKEY >ts_authkey.txt
# the format is slightly different here
# ephemeral, pre-approved, tags:nameserver,coredns
echo authkey $COREDNS_AUTHKEY >coredns_authkey.txt
# start
docker compose up
```

## Updating
```
docker compose pull && docker compose up
```

## Stopping
```sh
# bring down containers
docker compose down
# (optional) clean up all resources
# WARNING: this will prune docker volumes that aren't being used
docker system prune -a --volumes
```

## DNS Records
I now manage these externally using OpenTofu, but you can use flarectl to create the required records.
