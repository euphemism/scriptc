{
  stdenvNoCC,
  fetchurl,
  system,
  version,
  compilerAssets,
}:

let
  asset = compilerAssets.${system} or (throw "Unsupported system");

in

stdenvNoCC.mkDerivation {
  pname = "scriptc";

  inherit version;

  src = fetchurl {
    url = "https://github.com/vercel-labs/scriptc/releases/download/v${version}/scriptc-${version}-${asset.platform}.tar.gz";

    hash = asset.hash;
  };

  dontConfigure = true;
  dontBuild = true;

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out
    cp -R ./* $out/
    chmod -R u+w $out
  '';

  meta.mainProgram = "scriptc";
}
