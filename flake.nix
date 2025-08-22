{
  description = "Melodink, A self hosted Streaming Music Streaming App";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs";

    air-nixpkgs.url = "github:nixos/nixpkgs?rev=c1ce56e9c606b4cd31f0950768911b1171b8db51";

    flake-utils.url = "github:numtide/flake-utils";

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs?rev=5a052c62cdb51b210bc0717177d5bd014cba3df1";
    };

    zig-overlay.url = "github:mitchellh/zig-overlay";
    # Keep in sync with zigVersion below.
    zls-overlay.url = "github:gungun974/zls/fix-0.14.0-nix";
  };

  outputs = {
    nixpkgs,
    air-nixpkgs,
    gitignore,
    flake-utils,
    android-nixpkgs,
    zig-overlay,
    zls-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
        overlays = [
          (final: prev: {
            zigpkgs = zig-overlay.packages.${prev.system};
          })
        ];
      };

      zig = pkgs.zigpkgs."0.14.1";
      zls = zls-overlay.packages.${system}.zls.overrideAttrs (old: {
        nativeBuildInputs = [zig];
      });

      air-pkgs = import air-nixpkgs {
        inherit system;
      };

      ffmpeg = pkgs.ffmpeg.overrideAttrs (oldAttrs: {
        patches =
          (oldAttrs.patches or [])
          ++ [
            ./nix/ffmpeg/0001-hls-seek-patch-1.patch
            ./nix/ffmpeg/0002-hls-seek-patch-2.patch
            ./nix/ffmpeg/0003-return-eio-for-prematurely-broken-connection.patch
          ];
      });

      flutter-sdk = pkgs.flutter;
      sdk = android-nixpkgs.sdk.${system} (sdkPkgs:
        with sdkPkgs; [
          build-tools-33-0-1
          build-tools-34-0-0
          cmdline-tools-latest
          emulator
          platform-tools
          platforms-android-34
          platforms-android-33
          platforms-android-32
          platforms-android-31
          platforms-android-28
          system-images-android-34-google-apis-playstore-x86-64
          ndk-23-1-7779620
        ]);
      pinnedJDK = pkgs.jdk17;

      mkMinShell = (import ./nix/minshell) pkgs;
    in {
      packages = rec {
        melodink-server = pkgs.buildGo125Module rec {
          name = "melodink-server";
          src = gitignore.lib.gitignoreSource ./.;
          subPackages = ["cmd/api"];
          vendorHash = "sha256-YPVOIgBswQRnLJ1PfgtnQR8S3veWZ0IHX48v00c6gi4=";
          env.CGO_ENABLED = 1;

          buildInputs = with pkgs; [
            pkg-config
            gcc

            chromaprint
            fftw

            vips
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
            ln -s ../vendor ./
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
            mkdir -m 0777 tmp
          '';
        };

        melodink-client = pkgs.flutter.buildFlutterApplication rec {
          pname = "melodink-client";
          version = "1.0.0";

          buildInputs = [
            pkgs.copyDesktopItems
            pkgs.which
            pkgs.wrapGAppsHook
            ffmpeg.dev
            pkgs.pulseaudio.dev
            pkgs.zenity
            zig
          ];

          nativeBuildInputs = buildInputs;

          src = gitignore.lib.gitignoreSource ./client;

          patchPhase = ''
            mkdir -p /build/source/build/linux/x64/release/
            cp ${pkgs.fetchurl {
              url = "https://github.com/microsoft/mimalloc/archive/refs/tags/v2.1.2.tar.gz";
              hash = "sha256-Kxv/b3F/lyXHC/jXnkeG2hPeiicAWeS6C90mKue+Rus=";
            }} /build/source/build/linux/x64/release/mimalloc-2.1.2.tar.gz

            ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
            export ZIG_GLOBAL_CACHE_DIR

            ln -s ${pkgs.callPackage ./client/melodink_player/deps.nix {}} $ZIG_GLOBAL_CACHE_DIR/p
          '';

          NIX = "true";

          preBuild = ''
            packageRun slang
            make prebuild
          '';

          postFixup = ''
            rm $out/bin/melodink_client

            # Move Melodink App data to sub directory to prevent issue with Home manager
            # https://github.com/nix-community/home-manager/issues/5173
            mkdir -p $out/melodink
            mv $out/app/* $out/melodink/
            mv $out/melodink $out/app/melodink

            install -Dm644 $src/assets/melodink_icon.png -t $out/share/pixmaps

            makeWrapper $out/app/melodink/melodink-client/melodink_client $out/bin/melodink_client \
                "''${gappsWrapperArgs[@]}" \
                --prefix LD_LIBRARY_PATH : $out/app/lib:${pkgs.lib.makeLibraryPath [pkgs.sqlite pkgs.ffmpeg pkgs.pulseaudio]}
          '';

          desktopItems = [
            (pkgs.makeDesktopItem {
              desktopName = "Melodink";
              name = "Melodink";
              exec = "melodink_client";
              icon = "melodink_icon";
              comment = "Melodink";
              categories = ["Audio" "Player"];
            })
          ];

          autoPubspecLock = ./client/pubspec.lock;

          gitHashes = {
            adwaita_icons = "sha256-M2QMkxDc1qEnm344H2mdrUNqxO/sVHCY8ETc2rBtrXo=";
            color_thief_flutter = "sha256-1I9OufoE03J7CNfJpE0A6GnwNtLtIwaAVxrKpfl77f0=";
            quantize_dart = "sha256-BQeankAcKuCr77+8Dwhg+iVjEMt9cnmHOuPROFiIIGc=";
            flutter_rating_bar = "sha256-BejegYGpBtAkpL9cPxg1+iLoPO1VuFVzIto+HMZRymg=";
          };
        };
      };

      devShell =
        if !pkgs.stdenv.isDarwin
        then
          (pkgs.mkShell {
            ANDROID_SDK_ROOT = "${sdk}/share/android-sdk";
            ANDROID_HOME = "${sdk}/share/android-sdk";
            CHROME_EXECUTABLE = "chromium";
            FLUTTER_SDK = "${flutter-sdk}";
            GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/share/android-sdk/build-tools/34.0.0/aapt2";

            GOROOT = "${pkgs.go_1_25}/share/go";

            shellHook = ''
              export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [pkgs.sqlite pkgs.chromaprint]}
            '';

            buildInputs = [
              (pkgs.golangci-lint.override {buildGoModule = pkgs.buildGo125Module;})
              pkgs.go_1_25
              air-pkgs.air
              flutter-sdk
              pinnedJDK
              sdk
              (pkgs.go-migrate.overrideAttrs (finalAttrs: previousAttrs: {
                tags = ["sqlite3" "sqlite"];
              }))
              pkgs.sqlite

              pkgs.pkg-config
              pkgs.gtk3
              ffmpeg.dev
              pkgs.pulseaudio.dev

              pkgs.chromaprint
              pkgs.fftw
              pkgs.vips

              pkgs.zenity
              pkgs.cmake

              zig
              zls
              pkgs.zon2nix
            ];
          })
        else
          (mkMinShell {
            name = "app-ios-macos";

            env = {
              PKG_CONFIG_PATH = "${pkgs.chromaprint}/lib/pkgconfig:${pkgs.fftw.dev}/lib/pkgconfig:${pkgs.vips.dev}/lib/pkgconfig:${pkgs.glib.dev}/lib/pkgconfig";
              CGO_CFLAGS = "-I${pkgs.chromaprint}/include";
              CGO_LDFLAGS = "-L${pkgs.chromaprint}/lib";
            };

            shellHook = ''
              export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [pkgs.sqlite pkgs.chromaprint]}
            '';

            packages = [
              (pkgs.golangci-lint.override {buildGoModule = pkgs.buildGo125Module;})
              pkgs.go_1_25
              air-pkgs.air
              pkgs.cocoapods
              (pkgs.go-migrate.overrideAttrs (finalAttrs: previousAttrs: {
                tags = ["sqlite3" "sqlite"];
              }))
              pkgs.sqlite

              ffmpeg.dev
              ffmpeg

              pkgs.chromaprint
              pkgs.fftw
              pkgs.vips

              zig
              zls
              pkgs.zon2nix
            ];
          });
    });
}
