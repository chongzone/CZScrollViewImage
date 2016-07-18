Pod::Spec.new do |s|

  s.name         = 'CZScrollViewImage'
  s.license      = 'MIT'
  s.requires_arc = true
  s.version      = '0.0.2'
  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.framework    = 'UIKit'
  s.summary      = 'A ScrollViewImageBanner For iOS'
  s.author       = { "chongzone" => "2209868966@qq.com" }
  s.source_files = 'CZScrollViewImage/**/*.{h,m}'
  s.homepage     = 'https://github.com/chongzone/CZScrollViewImage'
  s.source       = { :git => 'https://github.com/chongzone/CZScrollViewImage.git', :tag => s.version }
                      
end