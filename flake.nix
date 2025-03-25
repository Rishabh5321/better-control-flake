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
          version = "5.0";

          src = pkgs.fetchFromGitHub {
            owner = "quantumvoid0";
            repo = "better-control";
            rev = "8a0fcc5015edfa0b8fd7011d4148034b8b83848c";
            sha256 = "sha256-CinfUN0HpP3ymREHZvCbt2vHz6Fsm+ZaXLpdQ2DpZyg=";
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

          postPatch = ''
            substituteInPlace src/control.desktop \
              --replace-fail '/usr/bin/control' 'control'
          '';

          installPhase = ''
            mkdir -p $out/bin $out/share/better-control $out/share/applications

            make install PREFIX=$out

            install -Dm644 src/control.desktop $out/share/applications/control.desktop
          '';

          postFixup = ''
            wrapPythonPrograms
            wrapProgram $out/bin/control --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [
              brightnessctl networkmanager bluez pipewire
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
