Pod::Spec.new do |s|
  s.name = 'AdyenNetworking'
  s.version = '1.0.0'
  s.summary = "Adyen Networking for iOS"
  s.description = <<-DESC
    Adyen Networking for iOS provides Http/Https networking API's.
  DESC

  s.homepage = 'https://adyen.com'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Adyen' => 'support@adyen.com' }
  s.source = { :git => 'https://github.com/Adyen/adyen-networking-ios.git', :tag => "#{s.version}" }
  s.platform = :ios
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1'
  s.frameworks = 'Foundation'
  s.source_files = 'AdyenNetworking/**/*.swift'

end
