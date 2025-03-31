{
  description = "Packaging of patched RosettaLinux";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: let
    forAllSystems = with nixpkgs.lib; genAttrs platforms.all;
    forAllPkgs = pkgsWith: forAllSystems (system: pkgsWith nixpkgs.legacyPackages.${system});
  in {
    packages = forAllPkgs (pkgs: with pkgs; {
      default = stdenvNoCC.mkDerivation {
        pname = "rosetta";
        version = "15.4-beta-4-24E5238a";
        src = fetchurl {
          url = "https://swcdn.apple.com/content/downloads/54/11/082-08305-A_VN60L27NBN/f2f9wkhllglu1zhe6y47n0wsjemdi46b8g/RosettaUpdateAuto.pkg";
          hash = "sha256-oMeLOFtH/AMjHKClvwgfce78vVrsMA5eyaWIUFIbf0g=";
        };
        nativeBuildInputs = [ p7zip ];
        unpackPhase = ''
          7z x $src
          7z x Payload~
        '';
        installPhase = ''
          install -Dm755 -t $out/bin Library/Apple/usr/libexec/oah/RosettaLinux/*
        '';
        fixupPhase = ''
          dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=196748 conv=notrunc
          dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=196776 conv=notrunc
          dd if=<(printf '\x1f\x20\x03\xd5') of=$out/bin/rosetta bs=1 seek=201340 conv=notrunc
        '';
        meta = with lib; {
          description = "A dynamic binary translator to run x86_64 binaries under ARM Linux";
          homepage = "https://developer.apple.com/documentation/virtualization/running-intel-binaries-in-linux-vms-with-rosetta";
          platforms = platforms.all;
        };
      };
    });
  };
}
