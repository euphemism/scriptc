{
  lib,
  pkgs,
}:

{
  profile,
  runtimePacks,
  scriptcPackage,
  targets,
  zigPackage,
}:

let
  selectedTargets = lib.getAttrs profile.targets targets;

  runtimeNames = lib.unique (map (target: target.runtimeId) (builtins.attrValues selectedTargets));

  runtimeTree = pkgs.linkFarm "scriptc-runtime-packs" (
    map (runtime: {
      name = runtime;
      path = runtimePacks.${runtime};
    }) runtimeNames
  );

  trimmedScriptc = pkgs.callPackage ../pkgs/trim-scriptc.nix {
    inherit scriptcPackage;

    selectedTargets = selectedTargets;

    allTargets = targets;
  };

  trimmedZig =
    (import ./trim.nix {
      inherit pkgs;
    })
      {
        inherit profile;
        inherit zigPackage;
      };

  generatedCases = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (target: meta: ''
      ${target})
        runtime="${meta.runtimeId}"
        ;;
    '') selectedTargets
  );

  wrapper = pkgs.callPackage ../pkgs/wrapper.nix {
    scriptcPackage = trimmedScriptc;

    zigPackage = trimmedZig.zig;

    inherit
      runtimeTree
      generatedCases
      ;

    enableCross = true;
  };

in
{
  inherit
    wrapper
    runtimeTree
    selectedTargets
    ;
}
