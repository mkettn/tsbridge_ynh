The service is briefly stopped during the upgrade, so every bridge's
Unix socket is unavailable for its duration. Clients connecting to a
bridge socket during this window will simply fail to connect and should
retry once the upgrade finishes and the service restarts.
