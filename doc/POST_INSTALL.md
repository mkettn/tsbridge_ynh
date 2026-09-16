tsbridge is now running with an empty `bridges:` list -- it joined the
tailnet, but isn't proxying anything yet.

To add your first bridge, SSH in and edit `__INSTALL_DIR__/config.yaml`'s
`bridges:` list (a commented example is already there), then:

```sh
yunohost service restart __APP__
```

If no auth key was provided during install, check
`yunohost service log __APP__` (or `journalctl -u __APP__`) for a
one-time registration URL to approve this node with the tailnet's control
server -- until that's done, `tsbridge` won't be able to reach anything.

See the app's admin documentation for the config panel and how a
hand-edited `bridges:` list is affected by future upgrades.
