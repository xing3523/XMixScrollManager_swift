#
# Be sure to run `pod lib lint XMixScrollManager_swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XMixScrollManager_swift'
  s.version          = '0.1.0'
  s.summary          = 'A manager class for scroll together.'
  s.description      = <<-DESC
    管理UIScrollView嵌套滑动的一个小组件。 通过KVO实现，无UI布局，低耦合
                       DESC
  s.homepage         = 'https://github.com/xing3523/XMixScrollManager_swift.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xing' => 'xinxof@foxmail.com' }
  s.source           = { :git => 'https://github.com/xing3523/XMixScrollManager_swift.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'XMixScrollManager_swift/Classes/**/*'
  
end
