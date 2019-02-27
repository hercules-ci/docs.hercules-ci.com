# network.nix
let
  sources = {
    hercules-ci-agent =
      builtins.fetchTarball "https://github.com/hercules-ci/hercules-ci-agent/archive/master.tar.gz";
  };
in
{
  network.description = "Build farm";

  agent = {
    imports = [
      (sources.hercules-ci-agent + "/nixops-profile.nix")
    ];
    config = {
      deployment.keys."agent-token.key".keyFile = ./agent-token.key;
      services.hercules-ci-agent.concurrentTasks = 4; # Example
      nix.maxJobs = 4; # Example
    };
  };
}
