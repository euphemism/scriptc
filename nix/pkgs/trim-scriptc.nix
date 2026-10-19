{
  runCommand,
  scriptcPackage,
  trimPolicy ? { },
}:

runCommand "scriptc-trimmed" { } ''
  cp -a ${scriptcPackage} $out

  chmod -R u+w $out

  ${builtins.concatStringsSep "\n" (
    map (path: ''
      rm -rf "$out/${path}"
    '') (trimPolicy.removePaths or [ ])
  )}
''
