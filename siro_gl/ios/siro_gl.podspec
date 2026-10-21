#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'siro_gl'
  s.version          = '0.27.0'
  s.summary          = 'Siro GL Flutter plugin'
  s.description      = <<-DESC
Siro GL Flutter plugin, built on the MapLibre iOS SDK.
                       DESC
  s.homepage         = 'https://maplibre.org'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Siro Maps' => '' }
  s.source           = { :path => '.' }
  s.source_files = 'siro_gl/Sources/siro_gl/**/*'
  s.dependency 'Flutter'
  # When updating the dependency version,
  # make sure to also update the version in Package.swift.
  s.dependency 'MapLibre', '6.28.0'
  s.swift_version = '5.0'
  s.ios.deployment_target = '13.0'
end

