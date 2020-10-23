Pod::Spec.new do |s|
  s.name        = "AppMonet_Bidder-{type}"
  s.version     = "{version}"
  s.summary     = "Header bidding iOS sdk"
  s.homepage    = "http://appmonet.com"

  s.authors     = "AppMonet Awesome Developers"
  s.license     = { :file => './LICENSE' }

  s.platform    = :ios
  s.source      = { :http => '{bintray_creds}/{repo}/com/monet/ios/appmonet-bidder/{version}/appmonet-bidder-{type}.zip' }

  s.ios.deployment_target = '8.0'
  s.ios.vendored_frameworks = 'AppMonet_Bidder.framework'
end
