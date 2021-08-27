#
# Be sure to run `pod lib lint TWMultiUploadFileManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TWMultiUploadFileManager'
  s.version          = '0.1.0'
  s.summary          = 'TWMultiUploadFileManager 为解决 aws3 分片上传的组件管理库'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
现状：主要是解决端执行执行 AWS3 SDK API，客户端通过后端预签名后的 URL 直接进行文件分段上传
TODO: 后续支出自己服务端上传
                       DESC

  s.homepage         = 'https://github.com/zeqinjie/TWMultiUploadFileManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhengzeqin' => '1875193628@qq.com' }
  s.source           = { :git => 'https://github.com/zeqinjie/TWMultiUploadFileManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'TWMultiUploadFileManager/Classes/**/*'
  
  s.subspec 'TWMultiUpload' do |ss|
      ss.source_files = 'TWMultiUploadFileManager/Classes/TWMultiUpload/*.{swift,h,m}'
      ss.dependency 'TWMultiUploadFileManager/TWQueueManager'
  end
  
  s.subspec 'TWQueueManager' do |ss|
      ss.source_files = 'TWMultiUploadFileManager/Classes/TWQueueManager/*.{swift,h,m}'
  end
  
  s.dependency 'Queuer', '~> 2.1.1'
end
