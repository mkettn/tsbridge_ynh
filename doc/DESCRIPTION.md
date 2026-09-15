tsbridge exposes TCP services that live on a [Tailscale](https://tailscale.com)
tailnet (or a self-hosted [Headscale](https://headscale.net) network) as
local Unix sockets, without joining this YunoHost server to the tailnet at
the OS level. It uses Tailscale's `tsnet` library to connect entirely
in-process (userspace WireGuard, no system-wide network interface, no
`tailscaled` daemon), then proxies TCP bytes -- or, for HTTP services,
reverse-proxies requests -- between each Unix socket and its tailnet
target.

Typical use: a reverse proxy or app server on this box connects to
`/run/tsbridge/my-service.sock` instead of directly to
`remote-machine:1234` on the tailnet, so only this one dedicated,
ACL-scoped node needs tailnet access at all.

This app has no web interface of its own: it is a system service,
configured through a YAML file and, optionally, a small local JSON API
for adding or removing bridges without a restart.
