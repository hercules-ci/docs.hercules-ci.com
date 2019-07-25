let
  # to update: $ nix-prefetch-url --unpack url
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/6b89e87a234cb8471aff2562e5381ebbbe6df156.tar.gz";
    sha256 = "1q2awqwxsm80hw0j5wabxciihq0qmrzmma9rg59bkwbqz1zn3ii7";
  }) { config = {allowUnfree = true;}; overlays = []; };
in pkgs.stdenv.mkDerivation {
  name = "docs.hercules-ci.com";

  src = pkgs.lib.cleanSource ./.;

  buildInputs = [
    pkgs.antora
  ];

  LANG = "en_US.utf8";
}
