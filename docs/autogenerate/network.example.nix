$ cat hercules-ci-agents.nix
let
  hercules-ci-agent =
      builtins.fetchTarball "https://github.com/hercules-ci/hercules-ci-agent/archive/stable.tar.gz";
in
{
  network.description = "Hercules CI agents";

  agent = {
    imports = [
      (hercules-ci-agent + "/nixops-profile.nix")
    ];

    deployment.keys."agent-token.key".keyFile = ./agent-token.key;
    services.hercules-ci-agent.concurrentTasks = 4; # Number of jobs to run
  };
}
