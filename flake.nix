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
          version = "0-unstable-2025-03-24";

          src = pkgs.fetchFromGitHub {
            owner = "quantumvoid0";
            repo = "better-control";
            rev = "ff270596815a7da7d876dec7dac11ee2ce566e33";
            sha256 = "sha256-MJ+YfC+NfCPojb3HT2PmWgr0BWpQGkXLpVHkIP8plJY=";
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
              power-profiles-daemon gammastep
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
