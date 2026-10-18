{
  description = "ScriptC native and cross compilation toolchains";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs =
    inputs@{ flake-parts, ... }:

    flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      {
        imports = [
          ./nix/flake-module.nix
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
      };
}
