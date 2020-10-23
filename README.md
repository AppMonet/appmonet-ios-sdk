<br />
<p align="center">
  <a href="https://appmonet.com/">
    <img src="images/appmonet.png" alt="Logo" >
  </a>

  <h3 align="center">AppMonet iOS SDK</h3>

  <p align="center">
    Add header bidding and additional demand partners<br />in banner, interstitial, and native ads!
    <br />
    <a href="https://docs.appmonet.com/docs/get-started-with-appmonet"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/AppMonet/appmonet-ios-sdk/issues">Report Bug</a>
    ·
    <a href="https://github.com/AppMonet/appmonet-ios-sdk/issues">Request Feature</a>
  </p>
</p>

## Table of Contents

* [About the Project](#about-the-project)
* [Getting Started](#getting-started)
  * [Installation](#installation)
* [Contributing](#contributing)
* [License](#license)

## About The Project


![Architecture][architecture-screenshot]


This repository contains the code for the [AppMonet android SDK](http://appmonet.com/). This SDK lets app developers add header bidding and additional demand partners in banner, interstitial, and native ads. There are currently 3 variants of the SDK:

- MoPub: integration into the MoPub adserver & SDK. Allows AppMonet to bid into MoPub to provide header-bidding competition.
- GAM/AdMob: header bidding and mediation integrations with GAM and AdMob.
- Standalone/"Bidder": for use with custom adservers/mediation SDKs, or with AppMonet as the primary adserver. (**Not open-sourced at the moment**)

For more information on integrating the AppMonet SDK into your app, please see the [AppMonet Docs](https://docs.appmonet.com/docs)

## Getting Started

To get a local copy up and running follow these simple example steps.

### Installation

1. Clone the repo 
```sh
git clone https://github.com/AppMonet/appmonet-ios-sdk.git
```
2. Go into the project and run:
```sh
pod update
pod install
```
3. Choose a target
    - App_DFP -> builds with AppMonet_Dfp
      - Copy KEYS-Sample.plist as KEYS.plist.
      - Change bannerAdUnit value to a valid gam banner id
      - Change interstitialAdUnit value to a valid gam interstitial id
    - App_Admob -> builds with AppMonet_Dfp
    - App_Mopub -> builds with AppMonet_Mopub
4. Build


## Contributing

Contributions are welcomed! Feel free to offer suggestions and fixes to make our SDK better!

1. Fork the Project
2. Create your Feature or Fix Branch (`git checkout -b feature/branch_name` / `git checkout -b fix/branch_name`)
3. Commit your Changes (`git commit -m 'Add some awesome code'`)
4. Push to the Branch (`git push origin feature/branch_name`/ `git push origin fix/branch_name`)
5. Make sure all checks pass.
6. Open a Pull Request

## License
For full license, vist [https://appmonet.com/legal/sdk-license/](https://appmonet.com/legal/sdk-license/).


[architecture-screenshot]: images/architecture.png

