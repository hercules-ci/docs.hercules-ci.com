let
  # to update: $ nix-prefetch-url --unpack url
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/2394284537b89471c87065b040d3dedd8b5907fe.tar.gz";
    sha256 = "sha256:1j7vp735is5d32mbrgavpxi3fbnsm6d99a01ap8gn30n5ysd14sl";
  }) { config = {allowUnfree = true;}; overlays = []; };
in pkgs.stdenv.mkDerivation {
  name = "docs.hercules-ci.com";

  src = pkgs.lib.cleanSource ./.;

  nativeBuildInputs = [
    pkgs.antora
    pkgs.inotify-tools
  ];

  shellHook = ''
    echo 1>&2 "antora $(antora --version)"
    cat 1>&2 <<EOF
    
    Welcome to the docs.hercules-ci.com shell

    Commands:
      live-rebuild        Performs a local build whenever watched files change.

    EOF
    last_status() {
      local r=$?
      if [[ $r = 0 ]]; then
        echo ok
      elif [[ $r = 1 ]]; then
        echo FAILED
      else
        echo "FAILED ($r)"
      fi
    }
    live-rebuild() {
      (
        echo 1>&2 "Press ENTER to force a rebuild."
        inotifywait -mr . ../hercules-ci-effects ../arion -e MODIFY \
          | grep --line-buffered -E 'adoc|hbs' &
        cleanup() {
          kill %%
        }
        trap cleanup EXIT
        echo first build for good measure
        cat
        ) | while read ln; do
            echo 1>&2 "antora starting..."
            antora antora-playbook-local.yml
            echo 1>&2 "antora finished ($(last_status)) at $(date +%T)";
          done
    }
  '';

  LANG = "en_US.utf8";
}
