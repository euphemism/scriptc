{
  lib,
}:

{
  hostPkgs,
  profile,
  runtimePacks,
  scriptcPackage,
  targets,
  version,
  zigPackage,
}:

let
  toolchain =
    (import ./toolchain.nix {
      inherit lib;

      pkgs = hostPkgs;
    })
      {
        inherit
          profile
          scriptcPackage
          zigPackage
          runtimePacks
          targets
          ;
      };

in
hostPkgs.dockerTools.buildLayeredImage {
  name = "scriptc-cross";

  tag = version;

  contents = [
    toolchain.wrapper
  ];

  config = {
    Entrypoint = [
      "${toolchain.wrapper}/bin/scriptc-cross"
    ];

    Env = [
      "HOME=/tmp"
    ];

    WorkingDir = "/workspace";
  };
}
