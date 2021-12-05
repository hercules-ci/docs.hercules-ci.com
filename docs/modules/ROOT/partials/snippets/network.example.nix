{
  network.description = "Hercules CI agents";

  agent = {
    services.hercules-ci-agent.enable = true;

    deployment.keys."cluster-join-token.key" = {
      user = config.services.hercules-ci-agent.user;
      destDir = clusterJoinTokenDir;
      keyFile = ./cluster-join-token.key;
    };
    deployment.keys."binary-caches.json" = {
      user = config.services.hercules-ci-agent.user;
      destDir = binaryCachesDir;
      keyFile = ./binary-caches.json;
    };
  };
}
