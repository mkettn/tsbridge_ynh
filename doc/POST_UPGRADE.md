If you had hand-edited `__INSTALL_DIR__/config.yaml`'s `bridges:` list,
check for a `__INSTALL_DIR__/config.yaml.bkp` file: the upgrade detected
the change and backed up your version before replacing it with a freshly
rendered one. Re-apply your `bridges:` entries from the `.bkp` file.
