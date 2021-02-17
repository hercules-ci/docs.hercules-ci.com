let
  pkgs = import ./packages.nix;
in
{
  inherit (pkgs) antora;
  shell = import ./shell.nix { inherit pkgs; };
}
