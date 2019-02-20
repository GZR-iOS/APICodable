#
# Be sure to run `pod lib lint APICodable.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'APICodableEncoder'
  s.version          = '1.0.1'
  s.summary          = 'Swift Encoder encodes Encodable models into HTTP Request Data'

  s.description      = <<-DESC
  Swift Encoder encodes Encodable models into HTTP Request Data
  DESC

  s.homepage         = 'https://github.com/GZR-iOS/APICodable'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DươngPQ' => 'duongpq@runsystem.net' }
  s.source           = { :git => 'https://github.com/GZR-iOS/APICodable.git', :branch => "version/" + s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.12'
  s.source_files = 'APICodable/Encoder/**/*', 'APICodable/Models/**/*'
end
