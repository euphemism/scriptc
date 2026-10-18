{
  wasm32-wasi = {
    runtimeId = "wasm32-wasi";
    runtimePackage = "wasm32-wasi";

    runtimeInstallPath = "lib/runtime-wasm32-wasi";

    npmName = "wasm32-wasi";

    hash = "sha256-r/blz+oCM2n8oiXpTnkQddX37wZwzEu2ztnzFtG4CV0=";
  };

  x86_64-linux-musl = {
    runtimeId = "linux-x64-musl";
    runtimePackage = "linux-x64-musl";

    runtimeInstallPath = "lib/runtime-linux-x64-musl";

    npmName = "linux-x64-musl";

    hash = "sha256-0H4DiO+7M++z48MOoep6Xvi8VJxHz9lw6SGS6aa0S5E=";
  };

  aarch64-linux-musl = {
    runtimeId = "linux-arm64-musl";
    runtimePackage = "linux-arm64-musl";

    runtimeInstallPath = "lib/runtime-linux-arm64-musl";

    npmName = "linux-arm64-musl";

    hash = "sha256-BoWirOmienUTTcr2fgsYwAJjV3GGrHLXygw6Lp+hXRA=";
  };

  aarch64-linux-gnu = {
    runtimeId = "linux-arm64-gnu";
    runtimePackage = "linux-arm64-gnu";

    runtimeInstallPath = "lib/runtime-linux-arm64-gnu";

    npmName = "linux-arm64-gnu";

    hash = "sha256-QLsrsQC8m/R9BTmWM9sjucvCqMCQ82LSmV2z3oK8Xz4=";
  };

  x86_64-windows-gnu = {
    runtimeId = "windows-x64-gnu";
    runtimePackage = "windows-x64-gnu";

    runtimeInstallPath = "lib/runtime-windows-x64-gnu";

    #
    # ScriptC's runtime package currently uses
    # win32-x64-msvc despite the target being
    # named windows-x64-gnu.
    #
    npmName = "win32-x64-msvc";

    hash = "sha256-XO0D6iIjMkRY/M6yWV6gZ1sNeG/Oc7yi+Oh7pZHEmd4=";
  };

  aarch64-apple-ios = {
    runtimeId = "apple-ios-arm64";
    runtimePackage = "apple-ios-arm64";

    runtimeInstallPath = "lib/runtime-apple-ios-arm64";

    npmName = "ios-arm64";

    hash = "sha256-XvmAQf0huMP8+NF/20VwkU+BI4LSJNjEXegOq2KNs/U=";
  };

  aarch64-apple-ios-simulator = {
    runtimeId = "apple-ios-arm64-simulator";
    runtimePackage = "apple-ios-arm64-simulator";

    runtimeInstallPath = "lib/runtime-apple-ios-arm64-simulator";

    npmName = "ios-simulator-arm64";

    hash = "sha256-/2rN6Kbf2e2TfgS2bOcSQu2025zZotHa9vFzF3fw6Uk=";
  };

  aarch64-linux-android = {
    runtimeId = "linux-arm64-android";
    runtimePackage = "linux-arm64-android";

    runtimeInstallPath = "lib/runtime-linux-arm64-android";

    npmName = "android-arm64";

    hash = "sha256-n062aEeVWd91Q1K2luLMZH8LhDHeXpncMJfigcQWsWk=";
  };
}
