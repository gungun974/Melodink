Pod::Spec.new do |s|
  system("make")

  s.name         = 'MelodinkPlayer'
  s.version      = '1.0.0'
  s.summary      = 'FFmpeg binaries & custom player used for IOS and MacOS Melodink'
  s.homepage     = 'https://github.com/gungun974/Melodink'
  s.license      = { :type => 'LGPL-3.0' }
  s.authors      = { 'Gungun974' => 'xfelix974@gmail.com' }
  s.source       = { :path => '.' }

  s.platform     = :osx, '10.9'
  s.public_header_files = 'Src/**/*.h}'
  s.source_files = 'Src/**/*'

  s.vendored_frameworks = [
    'Frameworks/Avcodec.xcframework',
    'Frameworks/Avfilter.xcframework',
    'Frameworks/Avformat.xcframework',
    'Frameworks/Avutil.xcframework',
    'Frameworks/Dav1d.xcframework',
    'Frameworks/Mbedcrypto.xcframework',
    'Frameworks/Mbedtls.xcframework',
    'Frameworks/Mbedx509.xcframework',
    'Frameworks/Swresample.xcframework',
    'Frameworks/Swscale.xcframework',
    'Frameworks/Xml2.xcframework',
    'Frameworks/MelodinkPlayer.xcframework'
  ]

  s.libraries = ['bz2', 'xml2', 'iconv', 'z', 'c++']

  s.frameworks = [
    'AVFoundation',
    'AudioToolbox',
    'CoreAudio',
    'CoreFoundation',
  ]

  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => [
      '-framework Avcodec',
      '-framework Avfilter',
      '-framework Avformat',
      '-framework Avutil',
      '-framework Dav1d',
      '-framework Mbedcrypto',
      '-framework Mbedtls',
      '-framework Mbedx509',
      '-framework Swresample',
      '-framework Swscale',
      '-framework Xml2',
      '-framework CoreFoundation',
      '-framework CoreAudio',
      '-framework AudioToolbox',
    ],
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
  }

  s.static_framework = false

  s.swift_version = '5.0'
end
