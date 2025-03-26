{
  description = "better-control - A system control panel utility";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages.default = packages.better-control;

        packages.better-control = pkgs.stdenv.mkDerivation {
          pname = "better-control";
          version = "5.3";

          src = pkgs.fetchzip {
            url = "https://github.com/quantumvoid0/better-control/archive/refs/tags/5.3.zip";
            sha256 = "sha256-h8rUpeoBHTa4sP7xwwI3vx9gyxiq2muPx1wZhly3JUA=";
          };

          buildInputs = with pkgs; [
            gtk3
            networkmanager
            bluez
            pipewire
            brightnessctl
            python3
            python3Packages.pygobject3
            python3Packages.dbus-python
            python3Packages.pydbus
            python3Packages.psutil
            power-profiles-daemon
            gammastep
          ];

          nativeBuildInputs = with pkgs; [
            pkg-config
            wrapGAppsHook
            python3Packages.wrapPython
            makeWrapper
          ];

          dontBuild = true;

          setSourceRoot = "sourceRoot=$(find $PWD -type d -mindepth 1 -maxdepth 1 | head -1)";

          postPatch = ''
            substituteInPlace src/control.desktop \
              --replace-fail '/usr/bin/control' 'control'
          '';

          installPhase = ''
            mkdir -p $out/bin $out/share/better-control $out/share/applications

            # Install both binaries initially
            make install PREFIX=$out

            # Remove the better-control binary after installation
            rm -f $out/bin/better-control
            rm -f $out/bin/.better-control-wrapped
          '';

          postFixup = ''
            wrapPythonPrograms
            wrapProgram $out/bin/control --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [
              python3 brightnessctl networkmanager bluez pipewire
              power-profiles-daemon gammastep libpulseaudio pulseaudio
            ])} \
            --set PYTHONPATH "$PYTHONPATH:${pkgs.python3Packages.pygobject3}/${pkgs.python3.sitePackages}" 
          '';

          meta = with pkgs.lib; {
            description = "A system control panel utility";
            homepage = "https://github.com/quantumvoid0/better-control";
            license = pkgs.lib.licenses.gpl3Only;
            platforms = platforms.linux ++ platforms.darwin;
            maintainers = [ ];
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = self.packages.${system}.better-control.buildInputs ++ [ pkgs.gnumake ];
        };
      }
    );
}
