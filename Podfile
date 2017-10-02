platform :ios, '9.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/qvik/qvik-podspecs.git'

def all_pods
  pod 'QvikSwift', '~> 4'
 # pod 'QvikSwift', :path => '../qvik-swift-ios/'
  pod 'Cloudinary', '~> 1'
  pod 'XCGLogger', '~> 6'
end

target "QvikCloudinary" do
  all_pods
end

target "QvikCloudinaryTests" do
  all_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.0'
        end
    end
end
