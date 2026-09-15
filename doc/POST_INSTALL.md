tsbridge is now running with an empty `bridges:` list -- it joined the
tailnet, but isn't proxying anything yet.

To add your first bridge, either:

- SSH in and edit `__INSTALL_DIR__/config.yaml`'s `bridges:` list, then
  `yunohost service restart __APP__`; or
- use the runtime management API, enabled by default on
  `/run/__APP__/control.sock`, to add one live with no restart:

  ```sh
  sudo curl --unix-socket /run/__APP__/control.sock \
    -X POST http://unix/bridges \
    -H 'content-type: application/json' \
    -d '{"name":"my-service","listen":"/run/__APP__/my-service.sock","target":"remote-machine:1234"}'
  ```

If no auth key was provided during install, check
`yunohost service log __APP__` (or `journalctl -u __APP__`) for a
one-time registration URL to approve this node with the tailnet's control
server -- until that's done, `tsbridge` won't be able to reach anything.

See the app's admin documentation for the full management API, the
config panel, and how bridges persist across restarts and upgrades.
