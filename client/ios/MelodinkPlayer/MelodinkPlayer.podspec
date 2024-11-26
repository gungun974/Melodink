Pod::Spec.new do |s|
  system("make")

  s.name         = 'MelodinkPlayer'
  s.version      = '1.0.0'
  s.summary      = 'LibMPV binaries & custom wrapper used for IOS and MacOS Melodink'
  s.homepage     = 'https://github.com/gungun974/Melodink'
  s.license      = { :type => 'LGPL-3.0' }
  s.authors      = { 'Gungun974' => 'xfelix974@gmail.com' }
  s.source       = { :path => '.' }

  s.platform     = :ios, '12.0'
  s.source_files = 'Src/**/*.{mm}'

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

  #s.header_dirs = 'Frameworks/Avcodec.xcframework/Headers'
  #s.public_header_files = 'Frameworks/Avcodec.xcframework/**/*.h'
  #s.xcconfig = {
  #'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/Frameworks/Avcodec.xcframework/ios-arm64/Avcodec.framework/Headers $(PODS_ROOT)/Frameworks/Avcodec.xcframework/ios-arm64_x86_64-simulator/Avcodec.framework/Headers'
  #}


  #s.xcconfig = { 'OTHER_LDFLAGS' => '-framework Avcodec' }

  
  s.compiler_flags = '-lavcodec -lavformat -lavutil -lswscale -I/Users/gungun974/lab/perso/Melodink/client/ios/MelodinkPlayer/Frameworks/Avcodec.xcframework/ios-arm64/Avcodec.framework/Headers -I/Users/gungun974/lab/perso/Melodink/client/ios/MelodinkPlayer/Frameworks/Avutil.xcframework/ios-arm64/Avutil.framework/Headers -I/Users/gungun974/lab/perso/Melodink/client/ios/MelodinkPlayer/Frameworks/Avformat.xcframework/ios-arm64/Avformat.framework/Headers -I/Users/gungun974/lab/perso/Melodink/client/ios/MelodinkPlayer/Frameworks/Swresample.xcframework/ios-arm64/Swresample.framework/Headers'
  


  s.libraries = ['bz2', 'xml2', 'iconv', 'z', 'c++']

  s.frameworks = [
    'AVFoundation',
    'AudioToolbox',
    'CoreVideo',
    'CoreAudio',
    'CoreText',
    'CoreFoundation',
    'CoreMedia',
    'Metal',
    'VideoToolbox'
  ]

  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-framework Avcodec -framework Avfilter -framework Avformat -framework Avutil -framework Dav1d -framework Mbedcrypto -framework Mbedtls -framework Mbedx509 -framework Swresample -framework Swscale -framework Xml2',
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
  }

  s.static_framework = false

  s.swift_version = '5.0'
end
