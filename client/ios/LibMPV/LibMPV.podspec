Pod::Spec.new do |s|
  system("make")

  s.name         = 'LibMPV'
  s.version      = '1.0.0'
  s.summary      = 'LibMPV binaries used for IOS and MacOS Melodink'
  s.homepage     = 'https://github.com/karelrooted/libmpv'
  s.license      = { :type => 'LGPL-3.0' }
  s.authors      = { 'Gungun974' => 'xfelix974@gmail.com' }
  s.source       = { :path => '.' }

  s.platform     = :ios, '12.0'
  s.source_files = 'Src/**/*.{c,h}'

  s.vendored_frameworks = [
    'Frameworks/Ass.xcframework',
    'Frameworks/Avcodec.xcframework',
    'Frameworks/Avfilter.xcframework',
    'Frameworks/Avformat.xcframework',
    'Frameworks/Avutil.xcframework',
    'Frameworks/Dav1d.xcframework',
    'Frameworks/Freetype.xcframework',
    'Frameworks/Fribidi.xcframework',
    'Frameworks/Harfbuzz.xcframework',
    'Frameworks/Mbedcrypto.xcframework',
    'Frameworks/Mbedtls.xcframework',
    'Frameworks/Mbedx509.xcframework',
    'Frameworks/Mpv.xcframework',
    'Frameworks/Placebo.xcframework',
    'Frameworks/Png16.xcframework',
    'Frameworks/Swresample.xcframework',
    'Frameworks/Swscale.xcframework',
    'Frameworks/Uchardet.xcframework',
    'Frameworks/Xml2.xcframework'
  ]

  s.static_framework = true

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
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }

  s.swift_version = '5.0'
end
