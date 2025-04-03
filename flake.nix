{
  description = "Better Control - A system control panel utility";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        better-control = pkgs.callPackage ./package.nix {};
      in
      {
        packages = {
          default = better-control;
          better-control = better-control;
        };

        apps.default = {
          type = "app";
          program = "${better-control}/bin/better-control";
          meta = better-control.meta; 
        };

        devShells.default = pkgs.mkShell {
          buildInputs = better-control.buildInputs;
          nativeBuildInputs = better-control.nativeBuildInputs;
        };
      });
}