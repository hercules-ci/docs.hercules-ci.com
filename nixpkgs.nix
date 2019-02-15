# to update: $ nix-prefetch-url --unpack url
import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/371a5656ad557363e7ef5e4738a3742d8e68b6e3.tar.gz";
  sha256 = "0g2h8sghwgqcbdqiq2hdkvkix0is2v34z0mdgc8fb04cqwykgxn4";
}) { config = {allowUnfree = true;}; overlays = []; }
