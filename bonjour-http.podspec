Pod::Spec.new do |s|
  s.name             = 'bonjour-http'
  s.version          = '0.6.1'
  s.summary          = 'HTTP over Bonjour in Swift.'
 
  s.description      = <<-DESC
  HTTP over Bonjour in Swift for iOS and macOS.
                       DESC
 
  s.homepage         = 'https://github.com/snakajima/bonjour-http'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Satoshi Nakajima' => 'satoshi.nakajima@gmail.com' }
  s.source           = { :git => 'https://github.com/snakajima/bonjour-http.git', :tag => s.version.to_s }
 
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.source_files = 'core/*.swift'
  s.swift_versions = '5.0'
  s.dependency 'CocoaAsyncSocket'
end
