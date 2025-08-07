pkgs: ({
  name,
  packages ? [],
  env ? {},
  shellHook ? "",
}: let
  # Need to filter out attrNames used above so we don't accidentally clobber
  envClean = builtins.removeAttrs env [
    "args"
    "builder"
    "name"
    "outputs"
    "packages"
    "shellHook"
    "stdenv"
    "system"
  ];
in
  builtins.derivation ({
      name = name;
      system = pkgs.hostPlatform.system;
      builder = "${pkgs.bash}/bin/bash";
      outputs = ["out"];
      # The args are ignored in `nix develop`, but we need to create an output
      # to pass CI, which just builds the derivation.
      args = ["-c" "echo -n '' > $out"];

      # Explanation:
      #
      # `nix develop` builds a modified version of this derivation that changes
      # the derivation args to `get-env.sh`, a script packaged with `nix` itself.
      # It then builds the modified derivation, which runs `get-env.sh` with our
      # envs/packages/shellHook.
      #
      # 1. `get-env.sh` looks for a `$stdenv` env and runs `source $stdenv/setup`.
      #    -> we make this just dump all envs to $out
      # 2. `get-env.sh` looks for an `$outputs` env and for each output reads all
      #    the serialized envs from each line, returning them in a form that
      #    `nix develop` understands.
      #
      # So we add a `$stdenv` env which points to a directory containing a `setup`
      # bash script. This script then prints out the final envs to `$out`.
      stdenv = "${./min-stdenv}";

      packages = packages;
      shellHook = shellHook;
    }
    // envClean))
