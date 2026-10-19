{
  lib,
  pkgs,
  runtimePacks,
  targetMetadata,
  imageProfile,
}:

let
  runtimePacksFiltered = lib.filterAttrs (
    name: _: builtins.elem name imageProfile.runtimes
  ) runtimePacks;

  runtimePackTree = pkgs.linkFarm "scriptc-runtime-packs" (
    lib.mapAttrsToList (name: drv: {
      inherit name;
      path = drv;
    }) runtimePacksFiltered
  );

  targetMetadataFiltered = lib.filterAttrs (
    _: runtime: builtins.elem runtime imageProfile.runtimes
  ) targetMetadata;

in
{
  inherit
    runtimePackTree
    targetMetadataFiltered
    ;
}
