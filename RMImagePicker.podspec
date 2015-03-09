#
# Be sure to run `pod lib lint RMImagePicker.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "RMImagePicker"
  s.version          = "0.1.0"
  s.summary          = "iOS image picker with single and multiple selection written in Swift using Apple PhotoKit."
  s.description      = <<-DESC
                       iOS image picker with single and multiple selection
                       written in Swift using Apple PhotoKit.
                       DESC
  s.homepage         = "https://github.com/maxdrift/RMImagePicker"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Riccardo Massari" => "maxdrift85@gmail.com" }
  s.source           = { :git => "https://github.com/maxdrift/RMImagePicker.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/maxdrift'

  s.platform     = :ios, '8.0'
  s.ios.deployment_target = "8.0"

  s.source_files = 'Source/*.swift'
  # s.resource_bundles = {
  #  'RMImagePicker' => ['Source/RMImages.xcassets/*.png']
  # }
  s.requires_arc = true

  s.frameworks = 'Photos'
end
