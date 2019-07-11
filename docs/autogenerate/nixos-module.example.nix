let
  hercules-ci-agent =
      builtins.fetchTarball "https://github.com/hercules-ci/hercules-ci-agent/archive/stable.tar.gz";
in
{
  imports = [
    (hercules-ci-agent + "/module.nix")
  ];

  services.hercules-ci-agent.enable = true;
  services.hercules-ci-agent.concurrentTasks = 4; # Number of jobs to run
}
