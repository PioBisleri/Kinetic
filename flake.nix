{
  description = "Kinetic — offline-first Flutter strength tracker dev shell";

  inputs = {
    # Flutter 3.47.5 (Dart 3.13.4) is required by pubspec `sdk: ^3.13.4`.
    # nixos-unstable currently ships 3.47.4 (Dart 3.13.3), so pin the
    # nixpkgs-update PR head (flutter: 3.47.4 -> 3.47.5) until it merges.
    # TODO: re-pin to github:NixOS/nixpkgs/nixos-unstable once PR #567033 lands.
    nixpkgs.url = "github:NixOS/nixpkgs/244664763dc742822c11a6c8bb69b08b6f461d99";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };

      jdk = pkgs.jdk17;

      androidSdk = (pkgs.androidenv.composeAndroidPackages {
        cmdLineToolsVersion = "latest";
        platformVersions = [ "36" ];
        buildToolsVersions = [ "latest" ];
        includeEmulator = false;
        includeNDK = true;
        ndkVersion = "28.2.13676358";
      }).androidsdk;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.flutter
          jdk
          androidSdk
          pkgs.sqlite
        ];

        shellHook = ''
          export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
          export ANDROID_SDK_ROOT="$ANDROID_HOME"
          export JAVA_HOME="${jdk}"
          export LD_LIBRARY_PATH="${pkgs.sqlite}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          export PATH="$ANDROID_HOME/platform-tools:$PATH"

          if [ ! -f android/local.properties ]; then
            cat > android/local.properties <<EOF
          flutter.sdk=${pkgs.flutter}
          sdk.dir=$ANDROID_HOME
          EOF
          fi
        '';
      };
    };
}
