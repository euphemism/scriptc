{
  inputs,
  ...
}:

{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:

    let
      scriptcVersion = "0.3.6";

      compilerMetadata = import ./data/compilers.nix;

      imageProfiles = import ./data/image-profiles.nix;

      runtimeMetadata = import ./data/runtimes.nix;

      targetMetadata = import ./data/targets.nix;

      hostPackages = import ./pkgs/mk-scriptc-packages.nix {
        inherit
          scriptcVersion
          compilerMetadata
          runtimeMetadata
          targetMetadata
          pkgs
          system
          ;

        zigPackage = inputs.zig-overlay.packages.${system}."0.16.0";
      };

      crossToolchains = lib.mapAttrs (_: runtimes: hostPackages.mkCrossToolchain runtimes) imageProfiles;

      inherit (hostPackages)
        scriptcPackage
        runtimePacks
        nativeToolchain
        crossToolchain
        ;

      mkImage =
        {
          name,
          tag ? scriptcVersion,
          toolchain,
          containerHostPkgs,
        }:

        containerHostPkgs.dockerTools.buildLayeredImage {
          inherit name tag;

          contents = [
            toolchain
          ];

          config = {
            Entrypoint = [
              "${toolchain}/bin/${name}"
            ];

            Env = [
              "HOME=/tmp"
            ];

            WorkingDir = "/workspace";
          };
        };

      mkTargetPackages =
        targetSystem:
        let
          targetPkgs = import inputs.nixpkgs {
            system = targetSystem;
          };
        in
        import ./pkgs/mk-scriptc-packages.nix {
          inherit
            scriptcVersion
            compilerMetadata
            runtimeMetadata
            targetMetadata
            ;

          pkgs = targetPkgs;

          system = targetSystem;

          zigPackage = inputs.zig-overlay.packages.${targetSystem}."0.16.0";
        };

      mkScriptcCrossImage =
        targetSystem: imageProfile:

        let
          targetPkgs = import inputs.nixpkgs {
            system = targetSystem;
          };

          targetPackages = mkTargetPackages targetSystem;

          profileData = targetPkgs.callPackage ./pkgs/mk-image-profile.nix {
            runtimePacks = targetPackages.runtimePacks;

            inherit
              targetMetadata
              imageProfile
              ;
          };

          trimmedScriptc = targetPkgs.callPackage ./pkgs/trim-scriptc.nix {
            scriptcPackage = targetPackages.scriptcPackage;

            trimPolicy = imageProfile.scriptcTrimPolicy or { };
          };

          trimmedZig = targetPkgs.callPackage ./pkgs/trim-zig.nix {
            zigPackage = inputs.zig-overlay.packages.${targetSystem}."0.16.0";

            profile = imageProfile;
          };

          imageToolchain =
            targetPkgs.callPackage ./pkgs/wrapper.nix
              {
                # scriptcPackage = targetPackages.scriptcPackage;

                scriptcPackage = trimmedScriptc;

                runtimePackTree = profileData.runtimePackTree;

                targetMetadata = profileData.targetMetadataFiltered;

                zigPackage = trimmedZig;
              }
              {
                name = "scriptc-cross";
                enableCross = true;
              };

        in
        mkImage {
          containerHostPkgs = targetPkgs;

          name = "scriptc-cross";

          toolchain = imageToolchain;
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

        scriptc-cross-all = crossToolchains.all;

        scriptc-cross-linux = crossToolchains.linux;

        scriptc-cross-mobile = crossToolchains.mobile;

        scriptc-cross-wasm = crossToolchains.wasm;

        scriptc-cross-windows = crossToolchains.windows;

        scriptc-native = nativeToolchain;

        scriptc-cross-all-image-arm64 = mkScriptcCrossImage "aarch64-linux" imageProfiles.all;

        scriptc-cross-linux-image-arm64 = mkScriptcCrossImage "aarch64-linux" imageProfiles.linux;

        scriptc-cross-mobile-image-arm64 = mkScriptcCrossImage "aarch64-linux" imageProfiles.mobile;

        scriptc-cross-wasm-image-arm64 = mkScriptcCrossImage "aarch64-linux" imageProfiles.wasm;

        scriptc-cross-windows-image-arm64 = mkScriptcCrossImage "aarch64-linux" imageProfiles.windows;

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
