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
# {
#   description = "scriptc native and cross compilation toolchains";

#   inputs = {
#     nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
#     flake-utils.url = "github:numtide/flake-utils";
#   };

#   outputs =
#     {
#       self,
#       nixpkgs,
#       flake-utils,
#     }:
#     flake-utils.lib.eachDefaultSystem (
#       system:
#       let
#         pkgs = import nixpkgs {
#           inherit system;
#         };

#         version = "0.3.6";

#         assets = {
#           x86_64-linux = {
#             platform = "linux-x64-gnu";
#             hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
#           };

#           aarch64-linux = {
#             platform = "linux-arm64-gnu";
#             hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
#           };

#           x86_64-darwin = {
#             platform = "darwin-x64";
#             hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
#           };

#           aarch64-darwin = {
#             platform = "darwin-arm64";
#             hash = "sha256-2MM+dgGnEil0F8RYm2bs6QB/zjuG81p/0gzZkznK4XI=";
#           };
#         };

#         asset = assets.${system} or (throw "unsupported system: ${system}");

#         scriptc = pkgs.stdenvNoCC.mkDerivation rec {
#           pname = "scriptc";
#           inherit version;

#           src = pkgs.fetchurl {
#             url = "https://github.com/vercel-labs/scriptc/releases/download/v${version}/scriptc-${version}-${asset.platform}.tar.gz";

#             hash = asset.hash;
#           };

#           dontBuild = true;
#           dontConfigure = true;

#           sourceRoot = ".";

#           installPhase = ''
#             runHook preInstall

#             mkdir -p $out

#             cp -r ./* $out/

#             chmod -R u+w $out

#             runHook postInstall
#           '';

#           meta = {
#             mainProgram = "scriptc";
#           };
#         };

#         nativeToolchain = pkgs.writeShellApplication {
#           name = "scriptc";

#           runtimeInputs = [
#             scriptc
#             pkgs.clang
#             pkgs.git
#           ];

#           text = ''
#             exec ${scriptc}/bin/scriptc "$@"
#           '';
#         };

#         # mkRuntimePack =
#         #   {
#         #     pname,
#         #     hash,
#         #   }:

#         #   pkgs.fetchzip {
#         #     url = "https://registry.npmjs.org/@scriptc/${pname}/-/${pname}-${version}.tgz";

#         #     inherit hash;

#         #     stripRoot = false;
#         #   };
#         mkRuntimePack =
#           {
#             target,
#             hash,
#           }:

#           pkgs.stdenvNoCC.mkDerivation {
#             pname = "scriptc-runtime-${target}";
#             version = version;

#             src = pkgs.fetchzip {
#               url = "https://registry.npmjs.org/@scriptc/runtime-${target}/-/runtime-${target}-${version}.tgz";

#               inherit hash;

#               stripRoot = false;
#             };

#             dontBuild = true;
#             dontConfigure = true;

#             installPhase = ''
#               mkdir -p $out
#               cp -R ./* $out/
#             '';
#           };

#         # runtimePacks = {
#         #   wasm32-wasi = mkRuntimePack {
#         #     pname = "runtime-wasm32-wasi";
#         #     hash = "sha256-...";
#         #   };

#         #   x86_64-linux-musl = mkRuntimePack {
#         #     pname = "runtime-linux-x64-musl";
#         #     hash = "sha256-...";
#         #   };

#         #   aarch64-linux-musl = mkRuntimePack {
#         #     pname = "runtime-linux-arm64-musl";
#         #     hash = "sha256-...";
#         #   };

#         #   aarch64-linux-gnu = mkRuntimePack {
#         #     pname = "runtime-linux-arm64-gnu";
#         #     hash = "sha256-...";
#         #   };
#         # };

#         runtimePacks = {
#           wasm32-wasi = mkRuntimePack {
#             target = "wasm32-wasi";
#             hash = "...";
#           };

#           x86_64-linux-musl = mkRuntimePack {
#             target = "linux-x64-musl";
#             hash = "...";
#           };

#           aarch64-linux-musl = mkRuntimePack {
#             target = "linux-arm64-musl";
#             hash = "...";
#           };

#           aarch64-linux-gnu = mkRuntimePack {
#             target = "linux-arm64-gnu";
#             hash = "...";
#           };
#         };

#         # crossToolchain = pkgs.writeShellApplication {
#         #   name = "scriptc-cross";

#         #   runtimeInputs = [
#         #     scriptc
#         #     pkgs.zig
#         #     pkgs.binutils
#         #   ];

#         #   text = ''
#         #     target="''${SCRIPTC_TARGET:-}"

#         #     case "$target" in
#         #       wasm32-wasi)
#         #         export SCRIPTC_RUNTIME_PACK="${runtimePacks.wasm32-wasi}"
#         #         ;;

#         #       x86_64-linux-musl)
#         #         export SCRIPTC_RUNTIME_PACK="${runtimePacks.x86_64-linux-musl}"
#         #         ;;

#         #       aarch64-linux-musl)
#         #         export SCRIPTC_RUNTIME_PACK="${runtimePacks.aarch64-linux-musl}"
#         #         ;;

#         #       aarch64-linux-gnu*)
#         #         export SCRIPTC_RUNTIME*PACK="${runtimePacks.aarch64-linux * gnu}"
#         #         ;;

#         #       "")
#         #         ;;

#         #       *)
#         #         echo "Unsupported SCRIPTC_TARGET: $target" >&2
#         #         echo "Known targets:" >&2
#         #         echo "  wasm32-wasi" >&2
#         #         echo "  x86_64-linux-musl" >&2
#         #         echo "  aarch64-linux-musl" >&2
#         #         echo "  aarch64-linux-gnu.*" >&2
#         #         exit 1
#         #         ;;
#         #     esac

#         #     export SCRIPTC_CC=zigcc

#         #     exec ${scriptc}/bin/scriptc "$@"
#         #   '';
#         # };
#         crossToolchain = pkgs.writeShellApplication {
#           name = "scriptc-cross";

#           runtimeInputs = [
#             scriptc
#             pkgs.zig
#             pkgs.binutils
#           ];

#           text = ''
#             target="''${SCRIPTC_TARGET:-}"

#             export SCRIPTC_CC=zigcc

#             case "$target" in
#               wasm32-wasi)
#                 export SCRIPTC_RUNTIME_PACK="${runtimePacks.wasm32-wasi}"
#                 ;;

#               x86_64-linux-musl)
#                 export SCRIPTC_RUNTIME_PACK="${runtimePacks.x86_64-linux-musl}"
#                 ;;

#               aarch64-linux-musl)
#                 export SCRIPTC_RUNTIME_PACK="${runtimePacks.aarch64-linux-musl}"
#                 ;;

#               aarch64-linux-gnu*)
#                 export SCRIPTC_RUNTIME_PACK="${runtimePacks.aarch64-linux-gnu}"
#                 ;;

#               "")
#                 ;;
#             esac

#             exec ${scriptc}/bin/scriptc "$@"
#           '';
#         };
#       in
#       {
#         packages = {
#           inherit scriptc;

#           runtime-wasm32-wasi = runtimePacks.wasm32-wasi;

#           runtime-linux-x64-musl = runtimePacks.x86_64-linux-musl;

#           runtime-linux-arm64-musl = runtimePacks.aarch64-linux-musl;

#           runtime-linux-arm64-gnu = runtimePacks.aarch64-linux-gnu;

#           scriptc-native = nativeToolchain;
#           scriptc-cross = crossToolchain;

#           default = crossToolchain;
#         };

#         apps = {
#           scriptc = {
#             type = "app";
#             program = "${nativeToolchain}/bin/scriptc";
#           };

#           scriptc-cross = {
#             type = "app";
#             program = "${crossToolchain}/bin/scriptc-cross";
#           };

#           default = {
#             type = "app";
#             program = "${crossToolchain}/bin/scriptc-cross";
#           };
#         };

#         devShells = {
#           native = pkgs.mkShell {
#             packages = [
#               scriptc
#               pkgs.clang
#               pkgs.git
#             ];
#           };

#           cross = pkgs.mkShell {
#             packages = [
#               scriptc
#               pkgs.zig
#               pkgs.binutils
#             ];

#             SCRIPTC_CC = "zigcc";
#           };

#           default = pkgs.mkShell {
#             packages = [
#               scriptc
#               pkgs.zig
#               pkgs.binutils
#             ];

#             SCRIPTC_CC = "zigcc";
#           };
#         };
#       }
#     );
# }
