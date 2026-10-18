{
  inputs,
  ...
}:

{
  perSystem =
    {
      system,
      pkgs,
      ...
    }:

    let
      scriptcVersion = "0.3.6";

      compilerMetadata = import ./data/compilers.nix;

      runtimeMetadata = import ./data/runtimes.nix;

      targetMetadata = import ./data/targets.nix;

      scriptcPackage = pkgs.callPackage ./pkgs/scriptc.nix {
        version = scriptcVersion;
        compilerAssets = compilerMetadata;
      };

      runtimePacks = import ./pkgs/runtime-packs.nix {
        inherit (pkgs)
          fetchzip
          lib
          stdenvNoCC
          ;

        version = scriptcVersion;
        metadata = runtimeMetadata;
      };

      runtimePackTree = pkgs.linkFarm "scriptc-runtime-packs" (
        pkgs.lib.mapAttrsToList (name: drv: {
          inherit name;
          path = drv;
        }) runtimePacks
      );

      mkWrapper = pkgs.callPackage ./pkgs/wrapper.nix {
        inherit
          scriptcPackage
          runtimePackTree
          targetMetadata
          ;
      };

      nativeToolchain = mkWrapper {
        name = "scriptc";
      };

      crossToolchain = mkWrapper {
        name = "scriptc-cross";
        enableCross = true;
      };

    in
    {
      packages = {
        inherit scriptcPackage;

        inherit (runtimePacks)
          wasm32-wasi
          linux-x64-musl
          linux-arm64-musl
          linux-arm64-gnu
          windows-x64-gnu
          apple-ios-arm64
          apple-ios-arm64-simulator
          linux-arm64-android
          ;

        scriptc-native = nativeToolchain;
        scriptc-cross = crossToolchain;

        default = nativeToolchain;
      };

      apps = rec {
        default = scriptc;

        scriptc = {
          type = "app";
          program = "${nativeToolchain}/bin/scriptc";
        };

        scriptc-cross = {
          type = "app";
          program = "${crossToolchain}/bin/scriptc-cross";
        };
      };

      devShells = {
        default = pkgs.mkShell {
          packages = [
            nativeToolchain
          ];
        };

        cross = pkgs.mkShell {
          packages = [
            crossToolchain
          ];
        };
      };
    };
}
