# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

target 'SmartPantry' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SmartPantry
  pod 'GoogleMLKit/BarcodeScanning'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      # Suppress warnings about double-quoted includes in frameworks
      config.build_settings['OTHER_CFLAGS'] ||= ['$(inherited)']
      config.build_settings['OTHER_CFLAGS'] << '-Wno-quoted-include-in-framework-header'
    end
  end
end
