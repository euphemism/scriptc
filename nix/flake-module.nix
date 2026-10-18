{
  inputs,
  ...
}:

{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      packageSet = import ./package-set.nix {
        inherit
          inputs
          lib
          pkgs
          system
          ;
      };

      toolchains = lib.mapAttrs (
        _: profile:

        packageSet.mkToolchain profile
      ) packageSet.profiles;

      images = lib.mapAttrs (
        hostSystem: _:

        lib.mapAttrs (
          _: profile:

          packageSet.mkImage {
            inherit
              profile
              hostSystem
              ;
          }
        ) packageSet.profiles
      ) packageSet.imagePlatforms;

      nativeToolchain = packageSet.mkNativeToolchain;

      crossToolchainPackages = lib.mapAttrs' (
        profileName: projection:

        lib.nameValuePair "scriptc-cross-${profileName}" projection.wrapper
      ) toolchains;

      imagePackages = lib.foldl' lib.recursiveUpdate { } (
        lib.mapAttrsToList (
          hostSystem: hostImages:

          lib.mapAttrs' (
            profileName: image:

            lib.nameValuePair "scriptc-image-${profileName}-${hostSystem}" image
          ) hostImages
        ) images
      );

      crossToolchainList = map (projection: projection.wrapper) (builtins.attrValues toolchains);
    in
    {
      packages = {
        default = nativeToolchain;

        scriptc = nativeToolchain;
      }
      // crossToolchainPackages
      // imagePackages;

      apps = {
        default = {
          program = "${nativeToolchain}/bin/scriptc";

          type = "app";
        };

        scriptc = {
          program = "${nativeToolchain}/bin/scriptc";

          type = "app";
        };
      };

      devShells = {
        default = pkgs.mkShell {
          packages = [
            nativeToolchain
          ];
        };

        cross = pkgs.mkShell {
          packages = crossToolchainList;
        };
      };
    };
}
