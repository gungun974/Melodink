#!/bin/bash

mkdir -p Frameworks

function check_and_install () {
  archive_framework_name="$1"

  expected_hash="$2"

  current_hash=$(shasum -a 256 "Frameworks/$archive_framework_name" | awk '{ print $1 }')

  if [ "$current_hash" == "$expected_hash" ]; then
    return 0
  fi

  # Thanks to media-kit for the base of the building process. https://github.com/gungun974/melodink-ffmpeg-darwin-build
  curl -L "https://github.com/gungun974/melodink-ffmpeg-darwin-build/releases/download/v7.0.2-1/$archive_framework_name" -o "Frameworks/$archive_framework_name" 

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

check_and_install "ffmpeg-xcframeworks_v7.0.2-1_ios-universal-video-default.tar.gz" "6a532daa3c9c5af70a09396ef948d6330179f62cabcbb34d5da9c225724f3e7d"

exit 0
