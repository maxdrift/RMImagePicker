Pod::Spec.new do |s|
  s.name             = "RMImagePicker"
  s.version          = "0.1.3"
  s.summary          = "iOS image picker with single and multiple selection written in Swift using Apple PhotoKit."
  s.description      = <<-DESC
                       iOS image picker with single and multiple selection
                       written in Swift using Apple PhotoKit.
                       DESC
  s.homepage         = "https://github.com/maxdrift/RMImagePicker"
  s.license          = 'MIT'
  s.author           = { "Riccardo Massari" => "maxdrift85@gmail.com" }
  s.source           = { :git => "https://github.com/maxdrift/RMImagePicker.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/maxdrift'

  s.platform = :ios, '8.1'
  s.ios.deployment_target = "8.1"

  s.source_files = 'Source/*.swift'
  s.resources = [
                 'Source/RMImages.xcassets/tick_selected.imageset/*.png',
                 'Source/RMImages.xcassets/tick_deselected.imageset/*.png',
                 'Source/*.xib'
                ]
  s.requires_arc = true

  s.frameworks = 'Photos'
end
