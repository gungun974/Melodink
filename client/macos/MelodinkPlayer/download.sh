#!/bin/bash

mkdir -p Frameworks

function check_and_install () {
  archive_framework_name="$1"

  expected_hash="$2"

  current_hash=$(shasum -a 256 "Frameworks/$archive_framework_name" | awk '{ print $1 }')

  if [ "$current_hash" == "$expected_hash" ]; then
    return 0
  fi

  # Thanks to media-kit for the base of the building process. https://github.com/gungun974/melodink-libmpv-darwin-build
  #curl -L "https://github.com/gungun974/melodink-libmpv-darwin-build/releases/download/v0.39.0/$archive_framework_name" -o "Frameworks/$archive_framework_name" 
  cp "/Users/gungun974/Downloads/melodink-libmpv-darwin-build/build/output/$archive_framework_name" "Frameworks/$archive_framework_name" 

  downloaded_hash=$(shasum -a 256 "Frameworks/$archive_framework_name" | awk '{ print $1 }')

  if [ "$downloaded_hash" != "$expected_hash" ]; then
      echo "The expected hash for the file $archive_framework_name does not match the received hash."
      echo "Expected hash $expected_hash"
      echo "Recieved hash $downloaded_hash"

      rm "Frameworks/$archive_framework_name"

      exit 1
  fi

  rm -rf Frameworks/*.xcframework

  tar -xvf Frameworks/$archive_framework_name --strip-components=1 -C Frameworks/

  return 2
}

check_and_install "libmpv-xcframeworks_develop_macos-universal-video-default.tar.gz" "6f7537f68fa083e387302da5658e9c19f6deaf97da241ebf59661634147194ad"

exit 0
