{
  fetchzip,
  lib,
  metadata,
  version,
  runCommand,
}:

lib.mapAttrs (
  _: cfg:
  let
    src = fetchzip {
      url = "https://registry.npmjs.org/@scriptc/runtime-${cfg.npmName}/-/runtime-${cfg.npmName}-${version}.tgz";

      hash = cfg.hash;
      stripRoot = false;
    };
  in

  runCommand "scriptc-runtime-${cfg.npmName}" { } ''
    cp -R ${src}/package $TMPDIR/package

    mkdir -p $out
    cp -R $TMPDIR/package/* $out/
  ''
) metadata
