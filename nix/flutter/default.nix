{pkgs, ...}: let
  patched-flutter-android =
    (pkgs.flutter324.unwrapped.override {
      patches = [
        ./patches/copy-without-perms.patch
        ./patches/git-dir.patch
        ./patches/custom-gradle-plugin-build-dir.patch
        ./patches/dont-validate-executable-location.patch
        ./patches/override-host-platform.patch
        ./patches/deregister-pub-dependencies-artifact.patch
        ./patches/flutter-pub-dart-override.patch
        ./patches/set-flutter-gradle-cache.patch
        ./patches/disable-auto-update.patch
      ];
    })
    .overrideAttrs (oldAttrs: {
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r . $out
        rm -rf $out/bin/cache/dart-sdk
        ln -sf ${pkgs.flutter324.unwrapped.dart} $out/bin/cache/dart-sdk

        # The regular launchers are designed to download/build/update SDK
        # components, and are not very useful in Nix.
        # Replace them with simple links and wrappers.
        rm "$out/bin"/{dart,flutter}
        ln -s "$out/bin/cache/dart-sdk/bin/dart" "$out/bin/dart"
        makeShellWrapper "$out/bin/dart" "$out/bin/flutter" \
          --set-default FLUTTER_PLUGIN_BUILD_DIR "/tmp/flutter/gradle/plugin" \
          --set-default FLUTTER_ROOT "$out" \
          --set FLUTTER_ALREADY_LOCKED true \
          --add-flags "--disable-dart-dev \$NIX_FLUTTER_TOOLS_VM_OPTIONS $out/bin/cache/flutter_tools.snapshot"

        runHook postInstall
      '';
    });
in (
  pkgs.flutter324.override {
    flutter = patched-flutter-android;
  }
)
