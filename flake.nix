{
  description = "Flutter dev environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        buildToolVersion = "34.0.0";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [
            buildToolVersion
            "33.0.1"
            "30.0.3"
          ];
          platformVersions = [
            "34"
            "33"
            "32"
            "31"
          ];
          abiVersions = [ "x86_64" ];
        };
        androidSdk = androidComposition.androidsdk;
        flutter_pkg = pkgs.flutter;
      in
      {
        devShell =
          with pkgs;
          mkShell rec {
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/${buildToolVersion}/aapt2";
            ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
            JAVA_HOME = "${pkgs.jdk17}";
            buildInputs = [
              flutter_pkg
              androidSdk
              jdk17
              # extra deps https://github.com/NixOS/nixpkgs/issues/341147#issuecomment-2359171650
              libsysprof-capture
              pkg-config
              gtk3
              pcre2.dev
              util-linux.dev
              libselinux
              libsepol
              libthai
              libdatrie
              xorg.libXdmcp
              xorg.libXtst
              lerc.dev
              libxkbcommon
              libepoxy
            ];

            shellHook = ''
              export PATH=$PATH:${androidSdk}/libexec/android-sdk/platform-tools
              export PATH=$PATH:${androidSdk}/libexec/android-sdk/cmdline-tools/latest/bin
              export PATH=$PATH:${androidSdk}/libexec/android-sdk/emulator
              export PATH="$PATH:$HOME/.pub-cache/bin"

              echo "Flutter SDK: ${flutter_pkg.version}"
              echo "Android SDK: ${androidSdk.version}"
              if [ -n "$BASH" ]; then
                ${pkgs.flutter}/bin/flutter bash-completion > .flutter-completions
                source .flutter-completions
              fi
            '';
          };
      }
    );
}
