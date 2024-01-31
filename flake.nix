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
        melodink-server = pkgs.buildGo121Module {
          name = "melodink-server";
          src = gitignore.lib.gitignoreSource ./server;
          subPackages = ["cmd/api"];
          vendorHash = "sha256-0HDZ3llIgLMxRLNei93XrcYliBzjajU6ZPllo3/IZVY=";
          CGO_ENABLED = 0;
          flags = [
            "-trimpath"
          ];
          ldflags = [
            "-s"
            "-w"
            "-extldflags -static"
          ];
          preBuild = ''
            make prebuild
          '';
        };

        melodink-client = pkgs.flutter.buildFlutterApplication {
          pname = "melodink-client";
          version = "1.0.0";

          src = gitignore.lib.gitignoreSource ./client;

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
        ];
      };
    });
}
