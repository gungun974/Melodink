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
  };

  outputs = {
    self,
    nixpkgs,
    gitignore,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };
      buildToolsVersion = "34.0.0";
      androidComposition = pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = [buildToolsVersion "28.0.3"];
        platformVersions = ["34" "28"];
        abiVersions = ["armeabi-v7a" "arm64-v8a"];
      };
      androidSdk = androidComposition.androidsdk;
    in {
      packages = {
        melodink-server = pkgs.buildGo121Module rec {
          name = "melodink-server";
          src = gitignore.lib.gitignoreSource ./.;
          subPackages = ["cmd/api"];
          vendorHash = "sha256-3GLl34qxOOTeL841F/VzO0NvrLP+uUhMZnyGofw3goY=";
          CGO_ENABLED = 1;

          buildInputs = with pkgs; [
            pkg-config
            gcc
            glibc.static
            protobuf
            protoc-gen-go
            protoc-gen-go-grpc
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
          '';
        };

        melodink-client = pkgs.flutter.buildFlutterApplication rec {
          pname = "melodink-client";
          version = "1.0.0";

          buildInputs = with pkgs; [
            protobuf
            protoc-gen-dart
            which
          ];

          nativeBuildInputs = buildInputs;

          src = gitignore.lib.gitignoreSource ./client;

          patchPhase = ''
            cp -r ${./proto} ../proto
          '';

          preBuild = ''
            make prebuild
          '';

          autoPubspecLock = ./client/pubspec.lock;
        };
      };

      devShell = pkgs.mkShell {
        ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
        GOROOT = "${pkgs.go_1_21}/share/go";
        buildInputs = with pkgs; [
          (golangci-lint.override {buildGoModule = buildGo121Module;})
          go_1_21
          air
          flutter
          androidSdk
          jdk17
          (go-migrate.overrideAttrs (finalAttrs: previousAttrs: {
            tags = ["sqlite3" "sqlite"];
          }))
          sqlite
          protobuf
          protoc-gen-go
          protoc-gen-go-grpc
          protoc-gen-dart
        ];
      };
    });
}
