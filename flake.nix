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
      {
        packages.better-control = pkgs.stdenv.mkDerivation {
          pname = "better-control";
          version = "5.0"; # Update if necessary

          src = pkgs.fetchFromGitHub {
            owner = "quantumvoid0";
            repo = "better-control";
            rev = "main";
            sha256 = "sha256-7jSYtNdfLQHv0vdAbxBULKTrF0C/rlnVywJEnWHn4GU=";
          };

          buildInputs = with pkgs; [
            # Dependencies
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

          prePatch = ''
            substituteInPlace Makefile --replace '/usr/bin' '$(PREFIX)/bin' --replace '/usr/share' '$(PREFIX)/share' || true
            substituteInPlace src/control.desktop --replace '/usr/bin/control' 'control' || true
          '';

          installPhase = ''
            mkdir -p $out/bin $out/share/better-control $out/share/applications
            
            if [ -f Makefile ] && grep -q install Makefile; then
              make install PREFIX=$out
            else
              cp -r src $out/share/better-control/
              echo "#!/bin/sh" > $out/bin/control
              echo "exec ${pkgs.python3}/bin/python3 $out/share/better-control/src/control.py \"$@\"" >> $out/bin/control
              chmod +x $out/bin/control
            fi
            
            install -Dm644 src/control.desktop $out/share/applications/control.desktop || true
          '';

          postFixup = ''
            wrapPythonPrograms
            wrapProgram $out/bin/control --prefix PATH : ${pkgs.lib.makeBinPath [
              pkgs.brightnessctl pkgs.networkmanager pkgs.bluez pkgs.pipewire
              pkgs.power-profiles-daemon pkgs.gammastep
            ]} \
            --set PYTHONPATH "$PYTHONPATH:${pkgs.python3Packages.pygobject3}/${pkgs.python3.sitePackages}"
          '';

          meta = with pkgs.lib; {
            description = "A system control panel utility";
            homepage = "https://github.com/quantumvoid0/better-control";
            license = licenses.mit; # Update if necessary
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
