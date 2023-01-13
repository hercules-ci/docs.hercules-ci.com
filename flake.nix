{
  description = "A flake with pre-commit hooks";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, flake-parts, hercules-ci-effects, ... }:
    flake-parts.lib.mkFlake
      { inherit self; }
      ({ lib, withSystem, ... }: {
        imports = [
          inputs.hercules-ci-effects.flakeModule
          inputs.pre-commit-hooks-nix.flakeModule
        ];
        systems = [ "x86_64-linux" ];
        perSystem = { config, self', inputs', pkgs, ... }: {
          packages.antora = pkgs.callPackage ./antora/package.nix { };
          pre-commit.settings.hooks.nixpkgs-fmt.enable = true;
          pre-commit.settings.excludes = [
            # The snippets didn't improve. May try again later.
            "docs/modules/ROOT/partials/snippets"
          ];
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [
              config.packages.antora
              pkgs.inotify-tools
              pkgs.netlify-cli
              pkgs.nixpkgs-fmt
              pkgs.yarn
            ];
            NODE_PATH = config.packages.antora.node_modules;
            shellHook = ''
              ${config.pre-commit.installationScript}

              echo
              echo 1>&2 "antora $(antora --version)"
              cat 1>&2 <<EOF
              
              Welcome to the docs.hercules-ci.com shell

              Commands:
                live-rebuild        Performs a local build whenever watched files change.
                open-browser        Opens the homepage in a browser

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
                  inotifywait -mr . ../hercules-ci-effects ../arion ../hercules-ci-agent -e MODIFY \
                    | grep --line-buffered -E 'adoc|hbs|(lib/.*\.js)' &
                  cleanup() {
                    kill %%
                  }
                  trap cleanup EXIT
                  echo first build for good measure
                  cat
                  ) | while read ln; do
                      echo 1>&2 "antora starting..."
                      antora antora-playbook-local.yml --stacktrace
                      echo 1>&2 "antora finished ($(last_status)) at $(date +%T)";
                    done
              }

              open-browser() {
                xdg-open public/index.html
              }
            '';

            LANG = "en_US.utf8";
          };
        };
        flake = {
          herculesCI = { branch, ... }:
            let
              isProd = branch == "master";
              deploy = withSystem "x86_64-linux" ({ config, pkgs, effects, ... }:
                effects.netlifyDeploy {
                  siteId = "48f50b78-b03a-4f2b-bc57-8e043b0f569f";
                  secretName = "default-netlify";
                  productionDeployment = isProd;
                  content = "./public";
                  src = ./.;
                  nativeBuildInputs = [
                    config.packages.antora
                    pkgs.tree
                    pkgs.git
                    pkgs.nix
                  ];
                  # TODO package the extension properly
                  NODE_PATH = config.packages.antora.node_modules;
                  preEffect = ''
                    mkdir -p public
                    mkdir -p ~/.config/nix
                    echo >>~/.config/nix/nix.conf experimental-features = flakes nix-command
                    git config --global user.email "no-reply@hercules-ci.com"
                    git config --global user.name CI
                    git config --global init.defaultBranch master
                    git init .
                    git remote add origin https://github.com/hercules-ci/docs.hercules-ci.com
                    git add -N .
                    git commit -m init .
                    git checkout -B ${lib.escapeShellArg branch}

                    checklog() {
                      tee $TMPDIR/err
                      ! grep -E 'ERROR'
                    }
                    export CI=true;
                    export FORCE_SHOW_EDIT_PAGE_LINK=true;
                    antora --fetch ./antora-playbook.yml --stacktrace 2>&1 | checklog;
                    antora --url https://docs.hercules-ci.com --html-url-extension-style=indexify --redirect-facility=netlify ./antora-playbook.yml 2>&1 | checklog;
                    cat <./_redirects >>./public/_redirects
                  '' + lib.optionalString (!isProd) ''
                    { echo 'User-agent: *'
                      echo 'Disallow: /'
                    } >public/robots.txt
                  '';
                  extraDeployArgs = [
                    # "--debug"
                  ] ++ lib.optionals (!isProd) [
                    "--alias"
                    branch
                  ];
                }
              );
            in
            {
              onPush.default = {
                outputs = {
                  effects.netlifyDeploy = deploy;
                  inherit (self) checks packages;
                };
              };
              onSchedule.scheduled-deploy = {
                outputs.effects.netlifyDeploy = deploy;
                when.hour = [ 0 6 12 18 ];
              };
            };
        };
      });
}
