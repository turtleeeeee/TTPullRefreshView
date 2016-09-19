#
#  Be sure to run `pod spec lint TTPullRefreshView.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name = "TTPullRefreshView"
  s.version = "1.0.0"
  s.license = "MIT"
  s.summary = "TTPullRefreshView is a simple pull refresh view with diverse layout types and some custom settings to let you be easy to make your own pull refresh view. "
  s.homepage = "https://github.com/dark19940411/TTPullRefreshView"
  s.author = {"dark19940411" => "279714010@qq.com" }
  s.source = { :git => "https://github.com/dark19940411/TTPullRefreshView.git", :tag => "1.0.0" }
  s.requires_arc = true
  s.description = <<-DESC
                   This is a Simple pull refresh view you can play with.
                  DESC
  s.source_files = "TTPullRefreshViewDemo/Views/*"
  s.platform = :ios, '9.0'
  s.framework = 'UIKit'

end
