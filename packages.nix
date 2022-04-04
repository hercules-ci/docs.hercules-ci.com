import (builtins.fetchTarball {
  # nixos-unstable 2022-03-23
  url = "https://github.com/NixOS/nixpkgs/archive/1d08ea2bd83abef174fb43cbfb8a856b8ef2ce26.tar.gz";
  sha256 = "sha256:1q8p2bz7i620ilnmnnyj9hgx71rd2j6sjza0s0w1wibzr9bx0z05";
}) {
  config.allowUnfree = true;
  overlays = [
    (prev: final: {
      antora = prev.callPackage ./antora/package.nix {};
    })
  ];
}