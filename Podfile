source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'

target 'AppMonet_Mopub' do
  use_frameworks!
  pod 'mopub-ios-sdk', '5.13.0'
end

target 'App_Mopub' do
    use_frameworks!
    pod 'mopub-ios-sdk', '5.13.0'
end

target 'AppMonet_Dfp' do
  use_frameworks!
  pod 'Google-Mobile-Ads-SDK'
end

target 'App_DFP' do
  use_frameworks!
  pod 'Google-Mobile-Ads-SDK'
  target 'AppMonet_DfpTests' do
    inherit! :search_paths
    pod 'OCMockito', '~> 5.0'
  end
end

target 'App_AdMob' do
  use_frameworks!
  pod 'Google-Mobile-Ads-SDK'
  
end

target 'App_Bidder' do
  use_frameworks!
end


#post_install do |installer|
#  installer.pods_project.targets.each do |target|
#    puts target.name
#  end
#end

