#
#  Be sure to run `pod spec lint SYMessage.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|


  s.name         = "SYMessage"
  s.version      = "1.1.0"
  s.summary      = "communication: KVO , Notification"

  s.homepage     = "https://github.com/sunyong445"


  s.license      = "MIT"

  s.source       = { :git => "https://github.com/sunyong445/SYMessage.git", :tag => "v#{s.version}" }

  s.source_files = "SYMessageDemo/SYMessage/*.{h,m}"
  
  s.author             = { "sunyong445" => "512776506@qq.com" } # 作者信息
  
  s.requires_arc = true # 是否启用ARC
  s.platform     = :ios, "7.0" #平台及支持的最低版本
  s.social_media_url   = "http://blog.csdn.net/sunyong_shj" # 个人主页
  # s.public_header_files = "SYMessageDemo/SYMessage/SYMessage.h"


  s.framework  = "Foundation"
 
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"

  # s.dependency "JSONKit", "~> 1.4"

end
