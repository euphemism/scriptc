{
  compilerAssets,
  fetchurl,
  runCommand,
  stdenv,
  system,
  version,
  patchelf,
}:

let
  asset = compilerAssets.${system} or (throw "Unsupported system");

  src = fetchurl {
    url = "https://github.com/vercel-labs/scriptc/releases/download/v${version}/scriptc-${version}-${asset.platform}.tar.gz";

    hash = asset.hash;
  };

  needsPatchelf =
    stdenv.hostPlatform.isLinux
    && builtins.elem system [
      "x86_64-linux"
      "aarch64-linux"
    ];
in
runCommand "scriptc-${version}-${asset.platform}"
  {
    nativeBuildInputs = if needsPatchelf then [ patchelf ] else [ ];
  }
  ''
    mkdir -p $out

    tar -xzf ${src} -C $out

    chmod -R u+w $out

    ${
      if needsPatchelf then
        ''
          patchelf \
            --set-interpreter \
            "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
            $out/bin/scriptc
        ''
      else
        ""
    }
  ''
