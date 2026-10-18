{
  all = {
    targets = [
      "wasm32-wasi"
      "x86_64-linux-musl"
      "aarch64-linux-musl"
      "aarch64-linux-gnu"
      "x86_64-windows-gnu"
      "aarch64-apple-ios"
      "aarch64-apple-ios-simulator"
      "aarch64-linux-android"
    ];

    artifacts = {
      zig = {
        keepLibc = null;
        keepIncludes = null;
      };

      scriptc = { };
    };
  };

  linux = {
    targets = [
      "x86_64-linux-musl"
      "aarch64-linux-musl"
      "aarch64-linux-gnu"
    ];

    artifacts = {
      scriptc = { };

      zig = {
        keepLibc = [
          "glibc"
          "musl"
        ];

        keepIncludes = [
          "aarch64-linux-musl"
          "x86_64-linux-musl"
          "generic-musl"
          "any-linux-any"
        ];
      };
    };
  };

  mobile = {
    targets = [
      "aarch64-apple-ios"
      "aarch64-apple-ios-simulator"
      "aarch64-linux-android"
    ];

    artifacts = {
      scriptc = { };

      zig = {
        keepLibc = [
          "darwin"
        ];

        keepIncludes = [
          "aarch64-linux-android"
        ];
      };
    };
  };

  wasm = {
    targets = [
      "wasm32-wasi"
    ];

    artifacts = {
      scriptc = { };

      zig = {
        keepLibc = [
          "wasi"
          "musl"
        ];

        keepIncludes = [
          "wasm-wasi-musl"
          "generic-musl"
        ];
      };
    };
  };

  windows = {
    targets = [
      "x86_64-windows-gnu"
    ];

    artifacts = {
      scriptc = { };

      zig = {
        keepLibc = [
          "mingw"
        ];

        keepIncludes = [
          "x86_64-windows-gnu"
        ];
      };
    };
  };
}
