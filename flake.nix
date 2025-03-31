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
            wrapProgram $out/bin/control \
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
            maintainers = [ ];
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
