{ lib, yarn2nix-moretea }:
let
  inherit (lib) cleanSourceWith;
in 
  yarn2nix-moretea.mkYarnPackage {
    src = cleanSourceWith { src = ./.; filter = p: t: baseNameOf p != "node_modules" && !lib.hasSuffix ".nix" p; };
    publishBinsFor = ["@antora/cli"];
  }
