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
        better-control = pkgs.callPackage ./package.nix { };
      in
      {
        packages = {
          default = better-control;
          inherit better-control;
        };

        apps.default = {
          type = "app";
          program = "${better-control}/bin/better-control";
          inherit (better-control) meta;
        };

        devShells.default = pkgs.mkShell {
          inherit (better-control) buildInputs;
          inherit (better-control) nativeBuildInputs;
        };
      });
}
