{
  inputs,
  lib,
  pkgs,
  system,
}:
let
  version = "0.3.6";

  compilers = import ./data/compilers.nix;

  targets = import ./data/targets.nix;

  profiles = import ./data/profiles.nix;

  imagePlatforms = {
    x86_64-linux = {
      dockerArchitecture = "amd64";
      dockerOs = "linux";
    };

    aarch64-linux = {
      dockerArchitecture = "arm64";
      dockerOs = "linux";
    };
  };

  runtimePackages = lib.foldl' (
    acc: target:
    acc
    // {
      ${target.runtimePackage} = {

        inherit (target)
          hash
          npmName
          runtimeInstallPath
          runtimePackage
          ;

        runtime = target.runtime or target.runtimePackage;
      };
    }
  ) { } (builtins.attrValues targets);

  zig = inputs.zig-overlay.packages.${system}."0.16.0";

  scriptc = pkgs.callPackage ./pkgs/scriptc.nix {
    inherit
      system
      version
      ;

    compilerAssets = compilers;
  };

  runtimePacks = pkgs.callPackage ./pkgs/runtime-packs.nix {
    inherit version;

    runtimes = runtimePackages;
  };

  mkNativeToolchain = pkgs.callPackage ./pkgs/wrapper.nix {
    enableCross = false;
    scriptcPackage = scriptc;
  };

  mkToolchain =
    profile:
    import ./lib/toolchain.nix
      {
        inherit
          lib
          pkgs
          ;
      }
      {
        inherit
          profile
          runtimePacks
          targets
          ;

        scriptcPackage = scriptc;

        zigPackage = zig;
      };

  mkImage =
    {
      profile,
      hostSystem,
    }:
    let
      hostPkgs = import inputs.nixpkgs {
        system = hostSystem;
      };

      hostZig = inputs.zig-overlay.packages.${hostSystem}."0.16.0";

      hostScriptc = hostPkgs.callPackage ./pkgs/scriptc.nix {
        inherit version;

        system = hostSystem;

        compilerAssets = compilers;
      };

      hostRuntimePacks = hostPkgs.callPackage ./pkgs/runtime-packs.nix {
        inherit version;

        runtimes = runtimePackages;
      };

    in
    import ./lib/image.nix
      {
        inherit lib;
      }
      {
        inherit
          hostPkgs
          profile
          targets
          ;

        runtimePacks = hostRuntimePacks;

        scriptcPackage = hostScriptc;

        version = version;

        zigPackage = hostZig;
      };

in
{
  inherit
    imagePlatforms
    mkImage
    mkNativeToolchain
    mkToolchain
    pkgs
    profiles
    runtimePackages
    runtimePacks
    scriptc
    targets
    version
    zig
    ;
}
