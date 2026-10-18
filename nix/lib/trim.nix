{
  pkgs,
}:

{
  profile,
  zigPackage,
}:

{
  zig = pkgs.callPackage ../pkgs/trim-zig.nix {
    inherit zigPackage;

    profile = profile.artifacts.zig or { };
  };
}
