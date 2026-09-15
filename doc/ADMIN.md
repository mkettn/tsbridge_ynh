## What this package installs

- The `tsbridge` binary at `__INSTALL_DIR__/tsbridge`, matching this
  server's CPU architecture (amd64 or arm64).
- `__INSTALL_DIR__/config.yaml`, `tsbridge`'s own YAML config.
- `__INSTALL_DIR__/tsbridge.env`, holding `TS_AUTHKEY` (if you set one),
  read by the systemd unit's `EnvironmentFile=`.
- A `__APP__.service` systemd unit, running as the dedicated `__APP__`
  system user, with `Restart=on-failure`.
- The app's persistent data directory (tsnet's node identity, and
  `managed-bridges.yaml` if you use the management API below) -- this is
  **not** removed on a plain app removal, only with `--purge`.

There is no domain, no nginx configuration, and no SSO/LDAP integration:
`tsbridge` has no web interface of its own, so this app doesn't ask for
or use a domain/path.

## Adding, removing and changing bridges

`config.yaml`'s `bridges:` list has no hot-reload -- editing it by hand
requires `yunohost service restart __APP__` to take effect. To change
bridges without a restart, the runtime management API is enabled by
default on `/run/__APP__/control.sock` (only reachable locally, e.g. over
SSH, since there's no domain to expose it through):

```sh
# Add a bridge.
sudo curl --unix-socket /run/__APP__/control.sock \
  -X POST http://unix/bridges \
  -H 'content-type: application/json' \
  -d '{"name":"svc","listen":"/run/__APP__/svc.sock","target":"remote-machine:1234"}'

# List every bridge tsbridge currently knows about.
sudo curl --unix-socket /run/__APP__/control.sock http://unix/bridges

# Take one offline without forgetting it, then bring it back.
sudo curl --unix-socket /run/__APP__/control.sock -X POST http://unix/bridges/svc/disable
sudo curl --unix-socket /run/__APP__/control.sock -X POST http://unix/bridges/svc/enable

# Remove it entirely.
sudo curl --unix-socket /run/__APP__/control.sock -X DELETE http://unix/bridges/svc

# Check the tailnet connection itself (not any one bridge).
sudo curl --unix-socket /run/__APP__/control.sock http://unix/status
```

A bridge added this way is persisted to `managed-bridges.yaml` in the
app's data directory and survives restarts; `DELETE`/`disable` update
that file too, so the change sticks. A bridge defined directly in
`config.yaml` instead comes back on every restart unless you also edit
`config.yaml` -- `disable`/`DELETE` through the API only affect it until
the next restart. `GET /bridges` reports each bridge's `source`
(`"config"` or `"managed"`) so you can tell which is which. See
upstream's own README (linked from this app's admin doc URL) for the
full API reference and JSON field meanings.

**A hand-edited `bridges:` list in `config.yaml` does not survive an app
upgrade** -- see `doc/POST_UPGRADE.md` / the message shown after
upgrading. Bridges added through the management API are unaffected.

## Registering the node with the tailnet

If you left the auth key empty at install (or want to check the
approval flow), watch the log for a one-time registration URL right
after the service starts:

```sh
yunohost service log __APP__
# or
journalctl -u __APP__ -f
```

Open that URL once to approve the node in the Tailscale admin console
(or your Headscale server). This only needs to happen once -- the node's
identity persists in the app's data directory across restarts.

## Config panel

The webadmin's app config panel (Apps > __APP__ > Config panel) exposes:

- **Node name on the tailnet** (`hostname:` in `config.yaml`)
- **Control server URL** (`control_url:` in `config.yaml`) -- empty uses
  Tailscale's own; set it to switch to a self-hosted Headscale instance
- **Auth key** (`TS_AUTHKEY` in `tsbridge.env`) -- only affects
  registration; changing it does **not** re-register an already-known
  node

Any change restarts the `__APP__` service automatically. The `bridges:`
list itself is intentionally not exposed here -- see the previous
section.

## Logs

```sh
journalctl -u __APP__ -f          # follow live
journalctl -u __APP__ -e          # jump to the end
journalctl -u __APP__ --since -10m
```

Startup logs list every bridge tsbridge resolved (name, listen path,
target) -- check there first if a bridge you expect isn't running.

## Suggested tailnet ACL snippet

Restrict this node (tag it, e.g. `tag:tsbridge`, when generating its auth
key) to only the hosts/ports it actually bridges to:

```jsonc
{
  "tagOwners": {
    "tag:tsbridge": ["autogroup:admin"],
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:tsbridge"],
      "dst": [
        "remote-machine:1234",
      ],
    },
  ],
}
```

Adjust `dst` to match every `target:` this instance bridges to, and
nothing more.
