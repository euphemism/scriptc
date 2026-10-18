{
  description = "ScriptC native and cross-compilation toolchains";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        lib = pkgs.lib;

        scriptcVersion = "0.3.6";

        ######################################################################
        # Host ScriptC compiler
        ######################################################################

        compilerAssets = {
          x86_64-linux = {
            platform = "linux-x64-gnu";
            hash = lib.fakeHash;
          };

          aarch64-linux = {
            platform = "linux-arm64-gnu";
            hash = lib.fakeHash;
          };

          x86_64-darwin = {
            platform = "darwin-x64";
            hash = lib.fakeHash;
          };

          aarch64-darwin = {
            platform = "darwin-arm64";
            hash = "sha256-2MM+dgGnEil0F8RYm2bs6QB/zjuG81p/0gzZkznK4XI=";
          };
        };

        compilerAsset = compilerAssets.${system} or (throw "Unsupported system: ${system}");

        scriptc = pkgs.stdenvNoCC.mkDerivation {
          pname = "scriptc";
          version = scriptcVersion;

          src = pkgs.fetchurl {
            url = "https://github.com/vercel-labs/scriptc/releases/download/v${scriptcVersion}/scriptc-${scriptcVersion}-${compilerAsset.platform}.tar.gz";

            hash = compilerAsset.hash;
          };

          dontConfigure = true;
          dontBuild = true;

          sourceRoot = ".";

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp -R ./* $out/

            chmod -R u+w $out

            runHook postInstall
          '';

          meta.mainProgram = "scriptc";
        };

        ######################################################################
        # Runtime pack packaging
        #
        # Replace fakeHash values after first build.
        ######################################################################

        mkRuntimePack =
          target: hash:
          pkgs.stdenvNoCC.mkDerivation {
            pname = "scriptc-runtime-${target}";
            version = scriptcVersion;

            src = pkgs.fetchzip {
              url = "https://registry.npmjs.org/@scriptc/runtime-${target}/-/runtime-${target}-${scriptcVersion}.tgz";

              inherit hash;

              stripRoot = false;
            };

            dontConfigure = true;
            dontBuild = true;

            installPhase = ''
              mkdir -p $out

              # npm tgz expands to package/
              if [ -d package ]; then
                cp -R package/* $out/
              else
                cp -R ./* $out/
              fi
            '';
          };

        runtimePacks = {
          wasm32-wasi = mkRuntimePack "wasm32-wasi" "sha256-r/blz+oCM2n8oiXpTnkQddX37wZwzEu2ztnzFtG4CV0=";

          linux-x64-musl = mkRuntimePack "linux-x64-musl" "sha256-0H4DiO+7M++z48MOoep6Xvi8VJxHz9lw6SGS6aa0S5E=";

          linux-arm64-musl = mkRuntimePack "linux-arm64-musl" "sha256-BoWirOmienUTTcr2fgsYwAJjV3GGrHLXygw6Lp+hXRA=";

          linux-arm64-gnu = mkRuntimePack "linux-arm64-gnu" "sha256-QLsrsQC8m/R9BTmWM9sjucvCqMCQ82LSmV2z3oK8Xz4=";

          windows-x64-gnu = mkRuntimePack "win32-x64-msvc" "sha256-XO0D6iIjMkRY/M6yWV6gZ1sNeG/Oc7yi+Oh7pZHEmd4=";

          apple-ios-arm64 = mkRuntimePack "ios-arm64" "sha256-XvmAQf0huMP8+NF/20VwkU+BI4LSJNjEXegOq2KNs/U=";

          apple-ios-arm64-simulator = mkRuntimePack "ios-simulator-arm64" "sha256-/2rN6Kbf2e2TfgS2bOcSQu2025zZotHa9vFzF3fw6Uk=";

          linux-arm64-android = mkRuntimePack "android-arm64" "sha256-n062aEeVWd91Q1K2luLMZH8LhDHeXpncMJfigcQWsWk=";
        };

        ######################################################################
        # Runtime pack lookup tree
        ######################################################################

        runtimePackTree = pkgs.linkFarm "scriptc-runtime-packs" [
          {
            name = "wasm32-wasi";
            path = runtimePacks.wasm32-wasi;
          }

          {
            name = "linux-x64-musl";
            path = runtimePacks.linux-x64-musl;
          }

          {
            name = "linux-arm64-musl";
            path = runtimePacks.linux-arm64-musl;
          }

          {
            name = "linux-arm64-gnu";
            path = runtimePacks.linux-arm64-gnu;
          }

          {
            name = "windows-x64-gnu";
            path = runtimePacks.windows-x64-gnu;
          }
          {
            name = "apple-ios-arm64";
            path = runtimePacks.apple-ios-arm64;
          }
          {
            name = "apple-ios-arm64-simulator";
            path = runtimePacks.apple-ios-arm64-simulator;
          }
          {
            name = "linux-arm64-android";
            path = runtimePacks.linux-arm64-android;
          }
        ];

        ######################################################################
        # Native wrapper
        ######################################################################

        nativeToolchain = pkgs.writeShellApplication {
          name = "scriptc";

          runtimeInputs = [
            scriptc
            pkgs.clang
            pkgs.git
          ];

          text = ''
            exec ${scriptc}/bin/scriptc "$@"
          '';
        };

        ######################################################################
        # Cross wrapper
        ######################################################################

        crossToolchain = pkgs.writeShellApplication {
          name = "scriptc-cross";

          runtimeInputs = [
            scriptc
            pkgs.zig
            pkgs.binutils
          ];

          text = ''
            export SCRIPTC_CC=zigcc

            if [ -n "''${SCRIPTC_TARGET:-}" ]; then

              case "$SCRIPTC_TARGET" in

                wasm32-wasi)
                  runtimePack="wasm32-wasi"
                  ;;

                x86_64-linux-musl)
                  runtimePack="linux-x64-musl"
                  ;;

                aarch64-linux-musl)
                  runtimePack="linux-arm64-musl"
                  ;;

                aarch64-linux-gnu*)
                  runtimePack="linux-arm64-gnu"
                  ;;

                x86_64-windows-gnu)
                  runtimePack="windows-x64-gnu"
                  ;;

                aarch64-apple-ios)
                  runtimePack="apple-ios-arm64"
                  ;;

                aarch64-apple-ios-simulator)
                  runtimePack="apple-ios-arm64-simulator"
                  ;;

                aarch64-linux-android)
                  runtimePack="linux-arm64-android"
                  ;;

                *)
                  echo "Unsupported SCRIPTC_TARGET: $SCRIPTC_TARGET" >&2
                  exit 1
                  ;;
              esac

              export SCRIPTC_RUNTIME_PACK="${runtimePackTree}/$runtimePack"
            fi

            exec ${scriptc}/bin/scriptc "$@"
          '';
        };

      in
      {
        packages = {
          inherit scriptc;

          inherit (runtimePacks)
            wasm32-wasi
            linux-x64-musl
            linux-arm64-musl
            linux-arm64-gnu
            ;

          scriptc-native = nativeToolchain;
          scriptc-cross = crossToolchain;

          default = nativeToolchain;
        };

        apps = {
          scriptc = {
            type = "app";
            program = "${nativeToolchain}/bin/scriptc";
          };

          scriptc-cross = {
            type = "app";
            program = "${crossToolchain}/bin/scriptc-cross";
          };

          default = {
            type = "app";
            program = "${nativeToolchain}/bin/scriptc";
          };
        };

        devShells = {
          default = pkgs.mkShell {
            packages = [
              scriptc
              pkgs.clang
              pkgs.zig
              pkgs.binutils
              pkgs.git
            ];
          };
        };
      }
    );
}
