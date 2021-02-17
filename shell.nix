{ pkgs ? import ./packages.nix }:
pkgs.mkShell {
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
            antora antora-playbook-local.yml && \
              antora antora-playbook-local.yml --generator=@antora/xref-validator
            echo 1>&2 "antora finished ($(last_status)) at $(date +%T)";
          done
    }
  '';

  LANG = "en_US.utf8";
}
