Pod::Spec.new do |s|

  s.name         = "SpaceDogSDK"
  s.version      = "0.0.1"
  s.summary      = "A short description of SpaceDogSDK."
  s.homepage     = "https://github.com/spacedog-io/spacedog-ios-sdk"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "spacedog" => "hello@spacedog.io" }
  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/lwinged/TestSDK.git", :tag => "#{s.version}" }

  s.requires_arc = 'true'
  s.source_files  = "SpaceDogSDK", "SpaceDogSDK/**/*.swift"

  s.dependency "Alamofire", "~> 3.4.1"
  s.dependency "ObjectMapper", "~> 1.3.0"
  s.dependency "AlamofireObjectMapper", "~> 3.0.0"
end
