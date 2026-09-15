If you had hand-edited `__INSTALL_DIR__/config.yaml`'s `bridges:` list
(rather than managing bridges through the runtime management API), check
for a `__INSTALL_DIR__/config.yaml.bkp` file: the upgrade detected the
change and backed up your version before replacing it with a freshly
rendered one. Re-apply your `bridges:` entries from the `.bkp` file if
needed.

Bridges added through the management API (persisted in
`managed-bridges.yaml` under the app's data directory) are unaffected by
this and don't need anything re-applied.
