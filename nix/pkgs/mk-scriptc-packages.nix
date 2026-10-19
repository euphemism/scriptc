{
  compilerMetadata,
  pkgs,
  runtimeMetadata,
  scriptcVersion,
  system,
  targetMetadata,
  zigPackage,
}:

let
  scriptcPackage = pkgs.callPackage ./scriptc.nix {
    version = scriptcVersion;
    compilerAssets = compilerMetadata;

    inherit system;

    inherit (pkgs)
      fetchurl
      runCommand
      stdenv
      patchelf
      ;
  };

  runtimePacks = import ./runtime-packs.nix {
    inherit (pkgs)
      fetchzip
      lib
      runCommand
      ;

    version = scriptcVersion;
    metadata = runtimeMetadata;
  };

  runtimePackTree = pkgs.linkFarm "scriptc-runtime-packs" (
    pkgs.lib.mapAttrsToList (name: drv: {
      inherit name;
      path = drv;
    }) runtimePacks
  );

  mkWrapper = pkgs.callPackage ./wrapper.nix {
    inherit
      runtimePackTree
      scriptcPackage
      targetMetadata
      zigPackage
      ;
  };

  nativeToolchain = mkWrapper {
    name = "scriptc";
  };

  crossToolchain = mkWrapper {
    name = "scriptc-cross";
    enableCross = true;
  };

in
{
  inherit
    crossToolchain
    nativeToolchain
    runtimePacks
    runtimePackTree
    scriptcPackage
    targetMetadata
    ;
}
