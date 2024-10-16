{
  description = "Melodink, A self hosted Streaming Music Streaming App";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?rev=c1ce56e9c606b4cd31f0950768911b1171b8db51";

    flake-utils.url = "github:numtide/flake-utils";

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    gitignore,
    flake-utils,
    android-nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };
      flutter-sdk = (import ./nix/flutter) pkgs;
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
      packages = rec {
        melodink-server = pkgs.buildGo122Module rec {
          name = "melodink-server";
          src = gitignore.lib.gitignoreSource ./.;
          subPackages = ["cmd/api"];
          vendorHash = "sha256-ys0VDicdna4h0y4f6pYfIP1mYKxjkHsvIpiWroOJCI0=";
          CGO_ENABLED = 1;

          buildInputs = with pkgs; [
            pkg-config
            gcc

            chromaprint
            fftw
          ];

          nativeBuildInputs = buildInputs;

          flags = [
            "-trimpath"
          ];
          ldflags = [
            "-s"
            "-w"
          ];
          preBuild = ''
            cd server
            make prebuild
            cp -r ../vendor ./
          '';

          postInstall = ''
            mkdir -p public
            cp -r ./public/ $out/bin/
            mv $out/bin/api $out/bin/melodink_server
          '';
        };

        melodink-server-docker = pkgs.dockerTools.buildLayeredImage {
          name = "melodink-server";
          contents = [
            melodink-server
            pkgs.cacert

            pkgs.ffmpeg-full
          ];
          config.Cmd = ["${melodink-server}/bin/melodink_server"];

          fakeRootCommands = ''
            mkdir -p data
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

          NIX = "true";

          preBuild = ''
            packageRun pigeon --input ./pigeon/native_communication.dart
            packageRun build_runner build --delete-conflicting-outputs
            make prebuild
          '';

          postFixup = ''
            rm $out/bin/melodink_client

            # Move Melodink App data to sub directory to prevent issue with Home manager
            # https://github.com/nix-community/home-manager/issues/5173
            mkdir -p $out/melodink
            mv $out/app/* $out/melodink/
            mv $out/melodink $out/app/melodink

            makeWrapper $out/app/melodink/melodink_client $out/bin/melodink_client \
                "''${gappsWrapperArgs[@]}" \
                --prefix LD_LIBRARY_PATH : $out/app/lib:${pkgs.lib.makeLibraryPath [pkgs.mpv-unwrapped pkgs.sqlite]}
          '';

          autoPubspecLock = ./client/pubspec.lock;

          gitHashes = {
            adwaita_icons = "sha256-M2QMkxDc1qEnm344H2mdrUNqxO/sVHCY8ETc2rBtrXo=";
            color_thief_flutter = "sha256-1I9OufoE03J7CNfJpE0A6GnwNtLtIwaAVxrKpfl77f0=";
            quantize_dart = "sha256-BQeankAcKuCr77+8Dwhg+iVjEMt9cnmHOuPROFiIIGc=";
          };
        };
      };

      devShell = pkgs.mkShell {
        ANDROID_SDK_ROOT = "${sdk}/share/android-sdk";
        ANDROID_HOME = "${sdk}/share/android-sdk";
        CHROME_EXECUTABLE = "chromium";
        FLUTTER_SDK = "${flutter-sdk}";
        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/share/android-sdk/build-tools/34.0.0/aapt2";

        GOROOT = "${pkgs.go_1_22}/share/go";

        shellHook = ''
          export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [pkgs.mpv-unwrapped pkgs.sqlite pkgs.chromaprint]}
        '';

        buildInputs = [
          (pkgs.golangci-lint.override {buildGoModule = pkgs.buildGo122Module;})
          pkgs.go_1_22
          pkgs.air
          flutter-sdk
          pinnedJDK
          sdk
          (pkgs.go-migrate.overrideAttrs (finalAttrs: previousAttrs: {
            tags = ["sqlite3" "sqlite"];
          }))
          pkgs.sqlite

          pkgs.pkg-config
          pkgs.gtk3
          pkgs.mpv

          pkgs.chromaprint
          pkgs.fftw
        ];
      };
    });
}
