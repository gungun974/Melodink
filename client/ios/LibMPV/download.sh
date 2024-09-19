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
  curl -L "https://github.com/gungun974/melodink-libmpv-darwin-build/releases/download/v0.38.1/$archive_framework_name" -o "Frameworks/$archive_framework_name" 

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

check_and_install "libmpv-xcframeworks_v0.38.1_ios-universal-video-default.tar.gz" "27b7b62ef299749f7e7ab60bc1de7e1c141e042b81163795bc5afe72696fd324"

exit 0
