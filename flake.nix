{
  description = "scriptc native and cross compilation toolchains";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          version = "0.3.6";

          assets = {
            x86_64-linux = {
              platform = "linux-x64-gnu";
              hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            };

            aarch64-linux = {
              platform = "linux-arm64-gnu";
              hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            };

            x86_64-darwin = {
              platform = "darwin-x64";
              hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            };

            aarch64-darwin = {
              platform = "darwin-arm64";
              hash = "sha256-2MM+dgGnEil0F8RYm2bs6QB/zjuG81p/0gzZkznK4XI=";
            };
          };

          asset =
            assets.${system}
              or (throw "unsupported system: ${system}");

          scriptc = pkgs.stdenvNoCC.mkDerivation rec {
            pname = "scriptc";
            inherit version;

            src = pkgs.fetchurl {
              url =
                "https://github.com/vercel-labs/scriptc/releases/download/v${version}/scriptc-${version}-${asset.platform}.tar.gz";

              hash = asset.hash;
            };

            dontBuild = true;
            dontConfigure = true;

            sourceRoot = ".";

            installPhase = ''
              runHook preInstall

              mkdir -p $out

              cp -r ./* $out/

              chmod -R u+w $out

              runHook postInstall
            '';

            meta = {
              mainProgram = "scriptc";
            };
          };

          nativeToolchain =
            pkgs.writeShellApplication {
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

          crossToolchain =
            pkgs.writeShellApplication {
              name = "scriptc-cross";

              runtimeInputs = [
                scriptc
                pkgs.zig
                pkgs.binutils
              ];

              text = ''
                export SCRIPTC_CC=zigcc
                exec ${scriptc}/bin/scriptc "$@"
              '';
            };

        in {
          packages = {
            inherit scriptc;

            scriptc-native = nativeToolchain;
            scriptc-cross = crossToolchain;

            default = crossToolchain;
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
              program = "${crossToolchain}/bin/scriptc-cross";
            };
          };

          devShells = {
            native = pkgs.mkShell {
              packages = [
                scriptc
                pkgs.clang
                pkgs.git
              ];
            };

            cross = pkgs.mkShell {
              packages = [
                scriptc
                pkgs.zig
                pkgs.binutils
              ];

              SCRIPTC_CC = "zigcc";
            };

            default = pkgs.mkShell {
              packages = [
                scriptc
                pkgs.zig
                pkgs.binutils
              ];

              SCRIPTC_CC = "zigcc";
            };
          };
        });
}