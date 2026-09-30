Before installing, you should have (or be ready to create) a Tailscale
account, or a self-hosted Headscale instance if you intend to use one
instead (via the "control server URL" question below).

Generating a tagged, ACL-scoped auth key ahead of time is recommended for
unattended registration, but not required -- leaving the auth key empty
is fine, and you will instead approve this node once via a one-time URL
logged on first start. See the app's admin documentation for details on
both paths, and a suggested tailnet ACL snippet to scope this node down
to only the hosts/ports it actually needs to reach.

You'll also be asked for a domain/path, same as any webapp -- `tsbridge`
itself doesn't serve anything there, it's reserved for an optional,
off-by-default admin dashboard you can enable now or later.
