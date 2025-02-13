Pod::Spec.new do |s|
  system("make")

  s.name         = 'MelodinkPlayer'
  s.version      = '1.0.0'
  s.summary      = 'FFmpeg binaries & custom player used for IOS and MacOS Melodink'
  s.homepage     = 'https://github.com/gungun974/Melodink'
  s.license      = { :type => 'LGPL-3.0' }
  s.authors      = { 'Gungun974' => 'xfelix974@gmail.com' }
  s.source       = { :path => '.' }

  s.platform     = :ios, '12.0'
  s.source_files = 'Src/**/{melodink_player.cpp,miniaudio.mm,sendevent.cc}'

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
    'Frameworks/Xml2.xcframework'
  ]

  s.compiler_flags = [
    '-DMA_NO_RUNTIME_LINKING',
    '-DMA_NO_DECODING',
    '-DMA_NO_ENCODING',

    '-I$(PODS_ROOT)/../MelodinkPlayer/Frameworks/Avcodec.xcframework/ios-arm64/Avcodec.framework/Headers',
    '-I$(PODS_ROOT)/../MelodinkPlayer/Frameworks/Avutil.xcframework/ios-arm64/Avutil.framework/Headers',
    '-I$(PODS_ROOT)/../MelodinkPlayer/Frameworks/Avformat.xcframework/ios-arm64/Avformat.framework/Headers',
    '-I$(PODS_ROOT)/../MelodinkPlayer/Frameworks/Swresample.xcframework/ios-arm64/Swresample.framework/Headers',
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
