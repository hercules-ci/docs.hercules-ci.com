{ pkgs ? import ./nixpkgs.nix
}:
let
  inherit (pkgs) stdenv lib;
  ruby = pkgs.ruby_2_5;

  gems = pkgs.bundlerEnv {
    name = "your-package";
    inherit ruby;
    gemdir = ./.;
  };
  
in

stdenv.mkDerivation {
  name = "blog.hercules-ci.com";

  src = lib.cleanSource ./.;

  buildInputs = [
    pkgs.nodePackages.parcel-bundler
    # (pkgs.jekyll.override { withOptionalDependencies = true; })
    # ruby    # bundle
    gems      # deps
    pkgs.zlib    # transitive bundle runtime dependencies
    pkgs.libxml2 # transitive bundle runtime dependencies
    pkgs.bundix
    pkgs.glibcLocales
  ];

  LANG = "en_US.utf8";

  buildPhase = ''
    jekyll build
  '';

  installPhase = ''
    mkdir -p $out
    cp -R _site/* $out
  '';

  passthru.update = pkgs.mkShell {
    name = "update-shell";
    buildInputs = [ pkgs.bundler_HEAD pkgs.bundix ];
  };
}
