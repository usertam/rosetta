{
  description = "Packaging of patched RosettaLinux";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: let
    forAllSystems = with nixpkgs.lib; genAttrs platforms.all;
    forAllPkgs = pkgsWith: forAllSystems (system: pkgsWith nixpkgs.legacyPackages.${system});
  in {
    packages = forAllPkgs (pkgs: rec {
      default = pkgs.stdenvNoCC.mkDerivation {
        pname = "rosetta";
        version = "15.3.2-24D81";
        nativeBuildInputs = [ pkgs.p7zip ];
        src = pkgs.fetchurl {
          url = "https://swcdn.apple.com/content/downloads/09/56/082-01503-A_0D9JVZVOF9/rzynizibmxzrlpumnvy3u27xzn9dapfu5m/RosettaUpdateAuto.pkg";
          hash = "sha256-PupVve9xep9Hy2peElrc32vzy6mZCmpVa9CHerK6aQ8=";
        };
        unpackPhase = ''
          7z x $src
          7z x Payload~
        '';
        installPhase = ''
          install -Dm755 -t $out/bin Library/Apple/usr/libexec/oah/RosettaLinux/*
        '';
        fixupPhase = ''
          dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=190960 conv=notrunc
          dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=190988 conv=notrunc
          dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=195472 conv=notrunc
        '';
      };
    });
  };
}
