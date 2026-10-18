{
  allTargets,
  lib,
  runCommand,
  scriptcPackage,
  selectedTargets,
}:
let
  allRuntimePaths = map (target: target.runtimeInstallPath) (builtins.attrValues allTargets);

  selectedRuntimePaths = map (target: target.runtimeInstallPath) (
    builtins.attrValues selectedTargets
  );

  removedRuntimePaths = builtins.filter (
    path: !(builtins.elem path selectedRuntimePaths)
  ) allRuntimePaths;
in
runCommand "scriptc-trimmed" { } ''
  cp -a ${scriptcPackage} $out

  chmod -R u+w $out

  ${lib.concatStringsSep "\n" (
    map (path: ''
      rm -rf "$out/${path}"
    '') removedRuntimePaths
  )}
''
