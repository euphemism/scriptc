{
  all = {
    runtimes = [
      "apple-ios-arm64-simulator"
      "apple-ios-arm64"
      "linux-arm64-android"
      "linux-arm64-gnu"
      "linux-arm64-musl"
      "linux-x64-musl"
      "wasm32-wasi"
      "windows-x64-gnu"
    ];

    zig = {
      keepLibc = null;
      keepIncludes = null;
    };
  };

  linux = {
    runtimes = [
      "linux-arm64-gnu"
      "linux-arm64-musl"
      "linux-x64-musl"
    ];

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

  mobile = {
    runtimes = [
      "apple-ios-arm64"
      "apple-ios-arm64-simulator"
      "linux-arm64-android"
    ];

    zig = {
      keepLibc = [
        "darwin"
      ];

      keepIncludes = [
        "aarch64-linux-android"
      ];
    };
  };

  wasm = {
    runtimes = [
      "wasm32-wasi"
    ];

    scriptcTrimPolicy = {
      removePaths = [
        "lib/runtime-linux-arm64-gnu"
      ];
    };

    zig = {
      keepLibc = [
        "musl"
        "wasi"
      ];

      keepIncludes = [
        "wasm-wasi-musl"
        "generic-musl"
      ];
    };
  };

  windows = {
    runtimes = [
      "windows-x64-gnu"
    ];

    zig = {
      keepLibc = [
        "mingw"
      ];

      keepIncludes = [
        "x86_64-windows-gnu"
      ];
    };
  };
}
