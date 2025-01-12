cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)
project(melodink_player VERSION 1.0.0 LANGUAGES CXX)
project(miniaudio VERSION 1.0.0 LANGUAGES C)

function(download_and_verify url md5 locationForArchive)
  # Check if the archive exists.
  if(EXISTS "${locationForArchive}")
    file(MD5 "${locationForArchive}" ARCHIVE_MD5)

    # If MD5 doesn't match, delete the archive to download again.
    if(NOT md5 STREQUAL ARCHIVE_MD5)
      file(REMOVE "${locationForArchive}")
      message(STATUS "MD5 mismatch. File deleted.")
    endif()
  endif()

  # Download the archive if it doesn't exist.
  if(NOT EXISTS "${locationForArchive}")
    message(STATUS "Downloading archive from ${url}...")
    file(DOWNLOAD "${url}" "${locationForArchive}")
    message(STATUS "Downloaded archive to ${locationForArchive}.")

    # Verify MD5 of the newly downloaded file.
    file(MD5 "${locationForArchive}" ARCHIVE_MD5)

    if(md5 STREQUAL ARCHIVE_MD5)
      message(STATUS "${locationForArchive} Verification successful.")
    else()
      message(FATAL_ERROR "${locationForArchive} Integrity check failed, please try to re-build project again.")
    endif()
  endif()
endfunction()

function(check_directory_exists_and_not_empty dir result_var)
  # Check if the directory exists
  if(EXISTS "${dir}")
    # Check if the directory is not empty
    file(GLOB dir_contents "${dir}/*")

    if(dir_contents)
      set(${result_var} TRUE PARENT_SCOPE)
    else()
      set(${result_var} FALSE PARENT_SCOPE)
      message(STATUS "Directory ${dir} exists but is empty!")
    endif()
  else()
    set(${result_var} FALSE PARENT_SCOPE)
    message(STATUS "Directory ${dir} does not exist!")
  endif()
endfunction()

# libmpv archive containing the pre-built shared libraries & headers.
set(FFMPEG "ffmpeg-n7.1-152-gd72536008a-win64-lgpl-shared-7.1.zip")

# Download URL & MD5 hash of the libmpv archive.
set(FFMPEG_URL "https://github.com/gungun974/melodink-ffmpeg-win32-build/releases/download/autobuild-2025-01-12-12-13/${FFMPEG}")
set(FFMPEG_MD5 "3da17e79ef202cbfa00f181bc8e83ae8")

# Download location of the libmpv archive.
set(FFMPEG_ARCHIVE "${CMAKE_BINARY_DIR}/${FFMPEG}")
set(FFMPEG_SRC "${CMAKE_BINARY_DIR}/ffmpeg")

download_and_verify(
  ${FFMPEG_URL}
  ${FFMPEG_MD5}
  ${FFMPEG_ARCHIVE}
)

check_directory_exists_and_not_empty(${FFMPEG_SRC} FFMPEG_SRC_VALID)

# Extract the libmpv archive.
if(NOT FFMPEG_SRC_VALID)
  get_filename_component(FFMPEG_NAME "${FFMPEG_ARCHIVE}" NAME_WLE)

  message(STATUS "Extracting ${FFMPEG}...")
  make_directory("${FFMPEG_SRC}")
  add_custom_target("${PROJECT_NAME}_FFMPEG_EXTRACT" ALL)
  add_custom_command(
    TARGET "${PROJECT_NAME}_FFMPEG_EXTRACT"
    COMMAND powershell -Command "Expand-Archive -Path \"${FFMPEG_ARCHIVE}\" -DestinationPath \"${FFMPEG_SRC}\" -Force"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "\"${FFMPEG_SRC}/${FFMPEG_NAME}\"" "\"${FFMPEG_SRC}\""
    COMMAND ${CMAKE_COMMAND} -E remove_directory "\"${FFMPEG_SRC}/${FFMPEG_NAME}\""
    WORKING_DIRECTORY "${FFMPEG_SRC}"
  )
endif()

# sqlite3.dll

set(SQLITE_DLL "${CMAKE_BINARY_DIR}/sqlite3.dll")

download_and_verify(
  "https://raw.githubusercontent.com/tekartik/sqflite/master/sqflite_common_ffi/lib/src/windows/sqlite3.dll"
  "41cdb8f49cbb65bc9b3e41e4d8abd9c9"
  ${SQLITE_DLL}
)

# ------------------------------------------------------------------------------

add_library(miniaudio STATIC
    ../../melodink_player/miniaudio.c
)

target_compile_definitions(miniaudio
  PRIVATE MA_NO_DECODING MA_NO_ENCODING
)

target_compile_options(miniaudio PRIVATE /W0)

add_library(melodink_player SHARED
  "../../melodink_player/melodink_player.cpp"
  "../../melodink_player/sendevent.cc"
  "../../melodink_player/melodink_player.def"
)

include_directories(
 "${FFMPEG_SRC}/include"
)

target_link_libraries(melodink_player PRIVATE miniaudio)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

target_link_libraries(
  melodink_player PRIVATE
  "${FFMPEG_SRC}/lib/libswscale.dll.a"
  "${FFMPEG_SRC}/lib/libswresample.dll.a"
  "${FFMPEG_SRC}/lib/libavutil.dll.a"
  "${FFMPEG_SRC}/lib/libavformat.dll.a"
  "${FFMPEG_SRC}/lib/libavfilter.dll.a"
  "${FFMPEG_SRC}/lib/libavcodec.dll.a"
)

set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")
