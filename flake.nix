{
  description = "Melodink, A self hosted Streaming Music Streaming App";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs = {
    nixpkgs,
    gitignore,
    flake-utils,
    zig-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            zigpkgs = zig-overlay.packages.${prev.stdenv.hostPlatform.system};
          })
        ];
      };

      zig = pkgs.zigpkgs."0.17.0";
    in {
      devShell = pkgs.mkShell {
        buildInputs =
          [
            pkgs.gleam
            pkgs.beamPackages.erlang
            pkgs.beamPackages.rebar3
            pkgs.tailwindcss_4
            pkgs.bun
            pkgs.nodejs
            pkgs.pnpm

            zig
            pkgs.zon2nix

            pkgs.pkg-config

            pkgs.just
          ]
          ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux [
            pkgs.gtk3
            pkgs.gtk3.dev
            pkgs.webkitgtk_4_1
            pkgs.webkitgtk_4_1.dev
          ];

        # expose real xcode
        shellHook = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          real_developer_dir="$(env -u DEVELOPER_DIR -u SDKROOT /usr/bin/xcode-select -p 2>/dev/null)"
          if [ -n "$real_developer_dir" ]; then
            export DEVELOPER_DIR="$real_developer_dir"
          fi
          export PATH="/usr/bin:$PATH"
        '';
      };
    });
}
