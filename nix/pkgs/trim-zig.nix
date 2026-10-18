{
  lib,
  runCommand,
  zigPackage,
  profile,
}:

runCommand "zig-trimmed" { } ''
  cp -a ${zigPackage} $out

  chmod -R u+w $out

  rm -rf "$out/doc"

  rm -rf "$out/lib/libcxx"
  rm -rf "$out/lib/libcxxabi"

  ${
    if profile.keepLibc == null then
      ""
    else
      ''
        #
        # Intentionally operate on a known list of libc
        # implementations instead of enumerating everything
        # under lib/libc.
        #
        # Blindly deleting directories under lib/libc can break WASI.
        #
        for d in darwin freebsd glibc mingw musl netbsd openbsd wasi
        do

          keep=0

          ${lib.concatStringsSep "\n" (
            map (name: ''
              [ "$d" = "${name}" ] && keep=1
            '') profile.keepLibc
          )}

          [ "$keep" = 1 ] || rm -rf "$out/lib/libc/$d"

        done
      ''
  }

  ${
    if profile.keepIncludes == null then
      ""
    else
      ''
        cd "$out/lib/libc/include"

        for d in */
        do

          keep=0

          ${lib.concatStringsSep "\n" (
            map (name: ''
              [ "''${d%/}" = "${name}" ] && keep=1
            '') profile.keepIncludes
          )}

          [ "$keep" = 1 ] || rm -rf "$d"

        done
      ''
  }
''
