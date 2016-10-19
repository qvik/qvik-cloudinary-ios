platform :ios, '9.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/qvik/qvik-podspecs.git'

def all_pods
  #pod 'QvikSwift', '~> 3.0.0'
  pod 'QvikSwift', :path => '../qvik-swift-ios/'
  pod 'Cloudinary', '~> 1.0'
  pod 'XCGLogger', '~> 4.0'
end

target "QvikCloudinary" do
  all_pods
end

target "QvikCloudinaryTests" do
  all_pods
end
