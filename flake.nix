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
      };
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
      };

      devShell = pkgs.mkShell {
        GOROOT = "${pkgs.go_1_21}/share/go";
        buildInputs = with pkgs; [
          (golangci-lint.override {buildGoModule = buildGo121Module;})
          go_1_21
          air
        ];
      };
    });
}
