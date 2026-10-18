{
  fetchzip,
  lib,
  metadata,
  stdenvNoCC,
  version,
}:

let
  mkRuntimePack =
    {
      hash,
      target,
      version,
    }:

    stdenvNoCC.mkDerivation {
      pname = "scriptc-runtime-${target}";
      inherit version;

      src = fetchzip {
        url = "https://registry.npmjs.org/@scriptc/runtime-${target}/-/runtime-${target}-${version}.tgz";

        inherit hash;

        stripRoot = false;
      };

      installPhase = ''
        mkdir -p $out

        if [ -d package ]; then
          cp -R package/* $out/
        else
          cp -R ./* $out/
        fi
      '';
    };
in

lib.mapAttrs (
  _: cfg:
  mkRuntimePack {
    inherit version;

    hash = cfg.hash;

    target = cfg.npmName;
  }
) metadata
