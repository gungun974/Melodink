{
  description = "Melodink, a self hosted Local Streaming Music App since I'm bored";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flutter-nix = {
      url = "github:maximoffua/flutter.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    gitignore,
    flake-utils,
    android-nixpkgs,
    flutter-nix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };
      flutter-sdk = flutter-nix.packages.${system};
      sdk = android-nixpkgs.sdk.${system} (sdkPkgs:
        with sdkPkgs; [
          build-tools-30-0-3
          build-tools-34-0-0
          cmdline-tools-latest
          emulator
          platform-tools
          platforms-android-34
          platforms-android-33
          platforms-android-31
          platforms-android-28
          system-images-android-34-google-apis-playstore-x86-64
        ]);
      pinnedJDK = pkgs.jdk17;
    in {
      packages = {
        melodink-server = pkgs.buildGo121Module rec {
          name = "melodink-server";
          src = gitignore.lib.gitignoreSource ./.;
          subPackages = ["cmd/api"];
          vendorHash = "sha256-QW0Y7TDmcc2bo0TPEvGV8r3vb3JaST3ewz/NcG2k8qE=";
          CGO_ENABLED = 1;

          buildInputs = with pkgs; [
            pkg-config
            gcc
            glibc.static
          ];

          nativeBuildInputs = buildInputs;

          flags = [
            "-trimpath"
          ];
          ldflags = [
            "-s"
            "-w"
            "-extldflags -static"
          ];
          preBuild = ''
            cd server
            make prebuild
            cp -r ../vendor ./
          '';
        };

        melodink-client = pkgs.flutter.buildFlutterApplication rec {
          pname = "melodink-client";
          version = "1.0.0";

          buildInputs = with pkgs; [
            which
            mpv
            wrapGAppsHook
          ];

          nativeBuildInputs = buildInputs;

          src = gitignore.lib.gitignoreSource ./client;

          patchPhase = ''
            mkdir -p /build/source/build/linux/x64/release/
            cp ${pkgs.fetchurl {
              url = "https://github.com/microsoft/mimalloc/archive/refs/tags/v2.1.2.tar.gz";
              hash = "sha256-Kxv/b3F/lyXHC/jXnkeG2hPeiicAWeS6C90mKue+Rus=";
            }} /build/source/build/linux/x64/release/mimalloc-2.1.2.tar.gz
          '';

          preBuild = ''
            make prebuild
          '';

          postFixup = ''
            rm $out/bin/melodink_client
            makeWrapper $out/app/melodink_client $out/bin/melodink_client \
                "''${gappsWrapperArgs[@]}" \
                --prefix LD_LIBRARY_PATH : $out/app/lib:${pkgs.lib.makeLibraryPath [pkgs.mpv-unwrapped pkgs.sqlite]}
          '';

          autoPubspecLock = ./client/pubspec.lock;

          gitHashes = {
            just_audio = "sha256-ATr743tguD2WVUAAX02lEG2UewmT9sdF6xhXjjhyocU=";
            mpris_service = "sha256-dA4aILtRKjAMPpCxjLAsBAkVvw5KM12dWukhbGBNy9A=";
          };
        };
      };

      devShell = pkgs.mkShell {
        ANDROID_SDK_ROOT = "${sdk}/share/android-sdk";
        ANDROID_HOME = "${sdk}/share/android-sdk";
        CHROME_EXECUTABLE = "chromium";
        FLUTTER_SDK = "${pkgs.flutter}";
        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/share/android-sdk/build-tools/34.0.0/aapt2";

        GOROOT = "${pkgs.go_1_21}/share/go";

        shellHook = ''
          export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [pkgs.mpv-unwrapped pkgs.sqlite]}
        '';

        buildInputs = with pkgs; [
          (golangci-lint.override {buildGoModule = buildGo121Module;})
          go_1_21
          air
          flutter-sdk.flutter
          flutter-sdk.dart
          pinnedJDK
          sdk
          (go-migrate.overrideAttrs (finalAttrs: previousAttrs: {
            tags = ["sqlite3" "sqlite"];
          }))
          sqlite

          mpv
          pkg-config
          gtk3
        ];
      };
    });
}
