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

`tsbridge` itself has no web interface: it's a system service, configured
through a YAML file (edit + restart, no hot-reload). This app does add
an optional, off-by-default, admin-only read-only dashboard (tailnet
status and bridge list) for those who want one.
