{
  description = "better-control - A system control panel utility";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      version = "5.7"; # Define the version here
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages.default = packages.better-control;
        packages.better-control = pkgs.stdenv.mkDerivation {
          pname = "better-control";
          inherit version;
          src = pkgs.fetchzip {
            url = "https://github.com/quantumvoid0/better-control/archive/refs/tags/${version}.zip";
            sha256 = "1mdy4382jrla9wsii7xlgy7wvvqs062q8p67ks1a6y7d63awx9b0";
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
            libpulseaudio
            pulseaudio
          ];
          nativeBuildInputs = with pkgs; [
            pkg-config
            wrapGAppsHook
            python3Packages.wrapPython
            makeWrapper
          ];
          dontBuild = true;
          sourceRoot = "source/";
          postPatch = ''
            # Properly update the desktop file to use the correct binary path
            substituteInPlace src/control.desktop \
              --replace 'Exec=/usr/bin/better-control' 'Exec=better-control'
          '';
          installPhase = ''
            mkdir -p $out/bin $out/share/better-control $out/share/applications

            # Copy application files
            cp -r src/* $out/share/better-control/

            # Create better-control executable
            cat > $out/bin/better-control << EOF
            #!/bin/sh
            exec python3 $out/share/better-control/better_control.py "\$@"
            EOF
            chmod +x $out/bin/better-control

            # Create control executable (symlink to better-control)
            ln -s better-control $out/bin/control

            # Install desktop file
            cp src/control.desktop $out/share/applications/better-control.desktop
            # Ensure desktop file uses the correct path
            substituteInPlace $out/share/applications/better-control.desktop \
              --replace 'Exec=better-control' "Exec=$out/bin/better-control"
          '';
          postFixup = ''
            wrapPythonPrograms
            wrapProgram $out/bin/better-control \
              --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [
                python3
                brightnessctl
                networkmanager
                bluez
                pipewire
                power-profiles-daemon
                gammastep
                libpulseaudio
                pulseaudio
              ])} \
              --prefix GI_TYPELIB_PATH : "${pkgs.lib.makeSearchPath "lib/girepository-1.0" [
                pkgs.gtk3
                pkgs.gobject-introspection
                pkgs.pango
              ]}" \
              --set PYTHONPATH "$PYTHONPATH:${pkgs.python3Packages.pygobject3}/${pkgs.python3.sitePackages}" \
              --set DBUS_SYSTEM_BUS_ADDRESS "unix:path=/run/dbus/system_bus_socket"
          '';
          meta = with pkgs.lib; {
            description = "A system control panel utility";
            homepage = "https://github.com/quantumvoid0/better-control";
            license = licenses.gpl3Only;
            platforms = platforms.linux;
            mainProgram = "better-control";
            maintainers = [ maintainers.quantumvoid maintainers.nekrooo ];
          };
        };
        # Add NixOS module to enable power-profiles-daemon service
        nixosModules.default = { config, lib, ... }: {
          config = lib.mkIf (config.services.power-profiles-daemon.enable or false) {
            services.power-profiles-daemon.enable = true;
            services.dbus.packages = [ self.packages.${system}.better-control ];
            environment.systemPackages = [ self.packages.${system}.better-control ];
          };
        };
        devShells.default = pkgs.mkShell {
          buildInputs = self.packages.${system}.better-control.buildInputs ++ [ pkgs.gnumake ];
        };
      }
    );
}
