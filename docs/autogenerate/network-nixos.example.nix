$ cat hercules-ci-agents-target.nix
{
  agent = {
    deployment.targetHost = "10.0.0.42"; # Your agent's IP address running NixOS
  };
}
