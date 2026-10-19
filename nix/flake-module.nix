{
  inputs,
  ...
}:

{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:

    let
      scriptcVersion = "0.3.6";

      compilerMetadata = import ./data/compilers.nix;

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
      };

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
        };

      mkScriptcCrossImage =
        targetSystem:
        let
          targetPackages = mkTargetPackages targetSystem;

          containerHostPkgs = import inputs.nixpkgs {
            system = targetSystem;
          };
        in
        mkImage {
          inherit containerHostPkgs;

          name = "scriptc-cross";

          toolchain = targetPackages.crossToolchain;
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

        scriptc-image = pkgs.dockerTools.buildLayeredImage {
          name = "scriptc";
          tag = scriptcVersion;

          contents = [
            nativeToolchain
          ];

          config = {
            Entrypoint = [
              "${nativeToolchain}/bin/scriptc"
            ];
          };
        };

        scriptc-cross-image-arm64 = mkScriptcCrossImage "aarch64-linux";

        scriptc-cross-image-amd64 = mkScriptcCrossImage "x86_64-linux";

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
