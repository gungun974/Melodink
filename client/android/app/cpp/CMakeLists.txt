cmake_minimum_required(VERSION 3.29.6)

project(melodink_player VERSION 1.0.0 LANGUAGES CXX)

add_library(
  ${CMAKE_PROJECT_NAME} SHARED
 ../../../melodink_player/melodink_player.cpp
)

add_library(MPVD_LIBRARY SHARED IMPORTED)

set_target_properties(MPVD_LIBRARY PROPERTIES IMPORTED_LOCATION
                      ${IMPORT_DIR}/dynamic/lib/${ANDROID_ABI}/libmpv.so)

target_link_libraries(
  ${CMAKE_PROJECT_NAME}
  android
  ${PROJECT_SOURCE_DIR}/../../../build/app/libmpv/prefix/${ANDROID_ABI}/usr/local/lib/libmpv.so
  log
)
