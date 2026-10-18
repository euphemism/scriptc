{
  fetchzip,
  lib,
  runCommand,
  runtimes,
  version,
}:
lib.mapAttrs (
  runtimeName: runtime:
  let
    src = fetchzip {
      hash = runtime.hash;

      stripRoot = false;

      url = "https://registry.npmjs.org/@scriptc/runtime-${runtime.npmName}/-/runtime-${runtime.npmName}-${version}.tgz";
    };
  in
  runCommand "scriptc-runtime-${runtimeName}" { } ''
    mkdir -p "$out"

    cp -R \
      ${src}/package/* \
      "$out/"
  ''
) runtimes
