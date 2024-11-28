cmake_minimum_required(VERSION 3.29.6)

project(melodink_player VERSION 1.0.0 LANGUAGES CXX)
project(miniaudio VERSION 1.0.0 LANGUAGES C)

add_library(miniaudio STATIC
    ../../../melodink_player/miniaudio.c
)

target_compile_options(miniaudio PRIVATE -w)

add_library(
  melodink_player SHARED
 ../../../melodink_player/melodink_player.cpp ../../../melodink_player/sendevent.cc
)

target_compile_definitions(miniaudio
  PRIVATE MA_NO_RUNTIME_LINKING MA_NO_DECODING MA_NO_ENCODING
)

target_compile_features(melodink_player PUBLIC cxx_std_17)

include_directories(
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/include
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/include
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/include
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/include
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/include
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/include
)

target_link_libraries(
  melodink_player PRIVATE
  android
  miniaudio
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/usr/local/lib/libswscale.so
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/usr/local/lib/libswresample.so
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/usr/local/lib/libavutil.so
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/usr/local/lib/libavformat.so
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/usr/local/lib/libavfilter.so
  ${PROJECT_SOURCE_DIR}/../../../build/app/ffmpeg/prefix/${ANDROID_ABI}/usr/local/lib/libavcodec.so
  log
  OpenSLES
)
