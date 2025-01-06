{
  description = "RosettaLinux packaging for use on Linux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:usertam/nix-systems";
  };

  # RosettaUpdateAuto.pkg found at AppleDB by littlebyteorg:
  # https://github.com/littlebyteorg/appledb/blob/main/osFiles/Software/Rosetta/24x%20-%2015.x/24C101.json

  # Hack found at CathyKMeow/rosetta-linux-asahi, updated by rawenger:
  # https://github.com/CathyKMeow/rosetta-linux-asahi
  # https://github.com/rawenger/rosetta-linux-asahi

  outputs = { self, nixpkgs, systems }: let
    forAllSystems = with nixpkgs.lib; genAttrs systems.systems;
    forAllPkgs = pkgsWith: forAllSystems (system: pkgsWith nixpkgs.legacyPackages.${system});
  in {
    packages = forAllPkgs (pkgs: rec {
      default = pkgs.stdenvNoCC.mkDerivation {
        pname = "rosetta";
        version = "14.7-23H124";
        nativeBuildInputs = [ pkgs.p7zip ];
        src = pkgs.fetchurl {
          url = "https://swcdn.apple.com/content/downloads/23/52/062-78837-A_F5Z09RRWFT/2hl1q0336rcw825lejz4e9uwayu11kir87/RosettaUpdateAuto.pkg";
          hash = "sha256-RGzYPOaOm1vDXtxYvVLeqoUHKxho/MmLdmG6m7FhaRE=";
        };
        buildCommand = ''
          7z x $src
          7z x Payload~
          install -Dm755 -t $out/bin Library/Apple/usr/libexec/oah/RosettaLinux/*
          dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=180376 conv=notrunc
          dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=180404 conv=notrunc
        '';
      };
    });
  };
}
