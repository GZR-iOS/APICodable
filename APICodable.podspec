#
# Be sure to run `pod lib lint APICodable.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'APICodable'
  s.version          = '1.0'
  s.summary          = 'HTTP Request with NSURLSession and Swift Codable'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Use Swift Codable models to make request parameters.
Use URLSession to request HTTP.
                       DESC

  s.homepage         = 'https://github.com/GZR-iOS/APICodable'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DươngPQ' => 'duongpq@runsystem.net' }
  s.source           = { :git => 'https://github.com/GZR-iOS/APICodable.git', :branch => "version/" + s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.12'
  s.source_files     = 'APICodable/**/*'

  s.subspec 'RequestEncodable' do |sp|
    sp.source_files = 'APICodable/Encoder/**/*', 'APICodable/Models/**/*'
  end
end
