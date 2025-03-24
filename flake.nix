{
  description = "better-control - A system control panel utility";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "better-control";
          version = "4.9"; # Update with the actual version

          src = pkgs.fetchFromGitHub {
            owner = "quantumvoid0";
            repo = "better-control";
            rev = "main"; 
            sha256 = "sha256-jnLOU4CovoKok8WwjH+ywhRTO74Bm4EM9841QvzHNOU="; 
          };
          
          buildInputs = with pkgs; [
            # GUI dependencies
            gtk3
            
            # Network dependencies
            networkmanager
            
            # Bluetooth dependencies
            bluez
            
            # Audio dependencies
            pipewire
            
            # Hardware control
            brightnessctl
            
            # Python and dependencies
            python3
            python3Packages.pygobject3
            python3Packages.dbus-python
            python3Packages.pydbus
            python3Packages.psutil
            
            # Other utilities
            power-profiles-daemon
            gammastep
          ];
          
          nativeBuildInputs = with pkgs; [
            pkg-config
            wrapGAppsHook
            python3Packages.wrapPython
            makeWrapper
          ];

          pythonPath = with pkgs.python3Packages; [
            pygobject3
            dbus-python
            pydbus
            psutil
          ];
          
          dontBuild = true;
          
          prePatch = ''
            if [ -f Makefile ]; then
              substituteInPlace Makefile \
                --replace '/usr/bin' '$(PREFIX)/bin' \
                --replace '/usr/share' '$(PREFIX)/share'
            fi
            
            # If the desktop file exists, patch it to use the correct paths
            if [ -f src/control.desktop ]; then
              substituteInPlace src/control.desktop \
                --replace '/usr/bin/control' 'control'
            fi
          '';
          
          installPhase = ''
            # Create target directories
            mkdir -p $out/bin
            mkdir -p $out/share/better-control
            mkdir -p $out/share/applications
            
            # If Makefile exists and has an install target, use it
            if [ -f Makefile ] && grep -q install Makefile; then
              make install PREFIX=$out
            else
              # Manual installation for Python files
              cp -r src $out/share/better-control/
              
              # Create a main executable script
              cat > $out/bin/control << EOF
#!/bin/sh
exec ${pkgs.python3}/bin/python3 $out/share/better-control/src/control.py "\$@"
EOF
              chmod +x $out/bin/control
            fi
            
            # Install the desktop file from src directory
            if [ -f src/control.desktop ]; then
              install -Dm644 src/control.desktop $out/share/applications/control.desktop
            fi
          '';

          postFixup = ''
            wrapPythonPrograms
            if [ -f $out/bin/control ]; then
              wrapProgram $out/bin/control \
                --prefix PATH : ${pkgs.lib.makeBinPath [
                  pkgs.brightnessctl
                  pkgs.networkmanager
                  pkgs.bluez
                  pkgs.pipewire
                  pkgs.power-profiles-daemon
                  pkgs.gammastep
                ]}
            fi
          '';
          
          meta = with pkgs.lib; {
            description = "A system control panel utility";
            homepage = "https://github.com/quantumvoid0/better-control";
            license = licenses.mit; # Adjust based on the actual license
            platforms = platforms.linux;
            maintainers = with maintainers; [ /* your name here */ ];
          };
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = self.packages.${system}.default.buildInputs ++ (with pkgs; [
            # Additional development tools
            gnumake
          ]);
        };
      }
    );
}