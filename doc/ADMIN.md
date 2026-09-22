## What this package installs

- The `tsbridge` binary at `__INSTALL_DIR__/tsbridge`, matching this
  server's CPU architecture (amd64 or arm64).
- `__INSTALL_DIR__/config.yaml`, `tsbridge`'s own YAML config.
- `__INSTALL_DIR__/tsbridge.env`, holding `TS_AUTHKEY` (if you set one),
  read by the systemd unit's `EnvironmentFile=`.
- A `__APP__.service` systemd unit, running as the dedicated `__APP__`
  system user, with `Restart=on-failure`.
- The app's persistent data directory, holding tsnet's node identity --
  this is **not** removed on a plain app removal, only with `--purge`.

There is no domain, no nginx configuration, and no SSO/LDAP integration:
`tsbridge` has no web interface of its own, so this app doesn't ask for
or use a domain/path.

## Adding, removing and changing bridges

`config.yaml`'s `bridges:` list has no hot-reload: add, remove, or
change a bridge by editing it, then restart the service. Edit it from
the app's own shell rather than over plain SSH, so it's opened as the
`__APP__` user with `__INSTALL_DIR__` already the working directory:

```sh
yunohost app shell __APP__
$ nano config.yaml   # or your editor of choice
$ exit
yunohost service restart __APP__
```

Each entry needs `name`, `listen` (an absolute Unix socket path -- see
the commented example already in `config.yaml`) and `target`
(`host:port` reachable over the tailnet). See upstream's own README
(linked from this app's admin doc URL) for the full field reference,
including `mode: http` for terminating HTTP and reverse-proxying instead
of a raw byte copy.

**A hand-edited `bridges:` list does not survive an app upgrade** -- see
`doc/POST_UPGRADE.md` / the message shown after upgrading.

## Reaching a bridge socket from a reverse proxy

Bridge sockets are created group-owned `www-data` by default
(`socket_group: www-data` in `config.yaml`, with `SupplementaryGroups=
www-data` on the systemd unit so `__APP__` can set that group), so
nginx -- or any other local service running as `www-data` -- can
`connect()` to them directly, e.g. as a `proxy_pass
http://unix:/run/__APP__/my-service.sock:;` target in a hand-written
nginx snippet. There is no YunoHost-managed nginx config for this app;
wiring a bridge socket up to a domain is left entirely to you.

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
- **Set a new auth key** (`TS_AUTHKEY` in `tsbridge.env`) -- write-only,
  the current key is never displayed or readable back; only affects
  registration, and changing it does **not** re-register an
  already-known node

Any change restarts the `__APP__` service automatically. The `bridges:`
list itself is intentionally not exposed here -- see the previous
sections.

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

## Troubleshooting

**Service keeps restarting, `journalctl -u __APP__` just shows "Main
process exited, code=killed, status=31/SYS" / "Failed with result
'signal'"**: signal 31 is `SIGSYS` -- the kernel's seccomp filter,
installed by the unit's `SystemCallFilter=`, killed the process for
calling a syscall outside `@system-service` (systemd's own curated
allow-list for long-running network daemons). This should not happen
with the shipped unit, but if it does after a manual edit or a future
tsbridge upgrade that changes its syscall usage:

- `SystemCallErrorNumber=EPERM` on the unit means a *future* mismatch
  fails the syscall with an error tsbridge can log, instead of a silent
  kill -- check `journalctl -u __APP__` first for a Go-level error
  before assuming it's still this.
- To find exactly which syscall was denied, check kernel/audit messages
  around the same timestamp (`journalctl -k` or `dmesg`) for a `syscall=`
  number, or temporarily comment out `SystemCallFilter=`/
  `SystemCallErrorNumber=` in the unit, `systemctl daemon-reload &&
  systemctl restart __APP__`, and confirm the service now stays up --
  that isolates the cause to the filter before you go syscall-hunting.
- [Report an issue](https://github.com/mkettn/tsbridge_ynh/issues) with
  the syscall number/name if you track one down; it very likely needs
  adding back for everyone, not just worked around locally.
