import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/2394284537b89471c87065b040d3dedd8b5907fe.tar.gz";
  sha256 = "sha256:1j7vp735is5d32mbrgavpxi3fbnsm6d99a01ap8gn30n5ysd14sl";
}) {
  config.allowUnfree = true;
  overlays = [
    (prev: final: {
      antora = prev.callPackage ./antora/package.nix {};
    })
  ];
}