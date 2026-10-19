{
  pkgs,
  lib,
  scriptcPackage,
  runtimePackTree,
  targetMetadata,
  zigPackage,
}:

{
  name,
  enableCross ? false,
}:

let
  runtimeInputs = [
    scriptcPackage
  ]
  ++ lib.optionals enableCross [
    zigPackage
    # pkgs.zig
    # pkgs.binutils
  ]
  ++ lib.optionals (!enableCross) [
    pkgs.clang
  ];

  generatedCases = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (target: runtime: ''
      ${target})
        runtimePack="${runtime}"
        ;;
    '') targetMetadata
  );

in

pkgs.writeShellApplication {
  inherit name;

  inherit runtimeInputs;

  text =
    let
      crossSetup = ''
        export SCRIPTC_CC=zigcc

        if [ -n "''${SCRIPTC_TARGET:-}" ]; then

          case "$SCRIPTC_TARGET" in

          ${generatedCases}

          *)
            echo "Unsupported target: $SCRIPTC_TARGET" >&2
            exit 1
            ;;
          esac

          export SCRIPTC_RUNTIME_PACK="${runtimePackTree}/$runtimePack"
        fi
      '';
    in
    ''
      ${lib.optionalString enableCross crossSetup}

      exec ${scriptcPackage}/bin/scriptc "$@"
    '';
}
