{
  enableCross ? false,
  generatedCases ? "",
  lib,
  pkgs,
  runtimeTree ? null,
  scriptcPackage,
  zigPackage ? null,
}:
pkgs.writeShellApplication {
  name = if enableCross then "scriptc-cross" else "scriptc";

  runtimeInputs = [
    scriptcPackage
  ]
  ++ lib.optionals enableCross [
    zigPackage
  ]
  ++ lib.optionals (!enableCross) [
    pkgs.clang
  ];

  text = ''
    ${lib.optionalString enableCross ''
      export SCRIPTC_CC=zigcc

      if [ -n "''${SCRIPTC_TARGET:-}" ]; then

        case "$SCRIPTC_TARGET" in

        ${generatedCases}

        *)
          echo \
            "Unsupported target: $SCRIPTC_TARGET" \
            >&2

          exit 1
          ;;
        esac

        export SCRIPTC_RUNTIME_PACK="${runtimeTree}/$runtime"
      fi

    ''}

    exec ${scriptcPackage}/bin/scriptc "$@"
  '';
}
