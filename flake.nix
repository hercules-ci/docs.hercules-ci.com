{
  description = "A flake with pre-commit hooks";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    hercules-ci-effects.url = "hercules-ci-effects/netlifyDeploy-extraDeployArgs";
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
            ];

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
                  src = lib.cleanSourceWith {
                    src = ./.;
                    filter = path: type:
                      # netlify will fetch any node packages it finds, but
                      # we don't want it to do that.
                      baseNameOf path != "node_modules" &&
                      baseNameOf path != "package.json";
                  };
                  nativeBuildInputs = [
                    config.packages.antora
                    pkgs.tree
                  ];
                  preEffect = lib.optionalString (!isProd) ''
                    mkdir -p public
                    { echo 'User-agent: *'
                      echo 'Disallow: /'
                    } >public/robots.txt
                  '';
                  extraDeployArgs = [
                    "--debug"
                    "--build"
                  ] ++ lib.optionals (!isProd) [
                    # Try without branch name
                    # "--alias"
                    # branch
                  ];
                  postEffect = ''
                    find
                  '';
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
              onSchedule.timed-deploy = {
                outputs.effects.netlifyDeploy = deploy;
                when.hour = [ 0 6 12 18 ];
              };
            };
        };
      });
}
