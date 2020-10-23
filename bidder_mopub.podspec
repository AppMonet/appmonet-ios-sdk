Pod::Spec.new do |s|
  s.name        = "AppMonet_Mopub-{type}"
  s.version     = "{version}"
  s.summary     = "Header bidding iOS sdk"
  s.homepage    = "http://appmonet.com"

  s.authors     = "AppMonet Awesome Developers"
  s.license     = { :file => './LICENSE' }

  s.platform    = :ios
  s.source      = { :http => '{bintray_creds}/{repo}/com/monet/ios/appmonet-mopub/{version}/appmonet-mopub-{type}.zip' }

  s.ios.deployment_target = '8.0'
  s.ios.vendored_frameworks = 'AppMonet_Mopub.framework'
end
