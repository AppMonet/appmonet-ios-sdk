#!/bin/bash
set -e
set -u
set -o pipefail

function usage()
{
  cat <<-USAGE
$(basename $0) <env> <flavor> <action>
- env: dev | prod
- flavor: mopub | dfp | bidder
- action: build | clean | deploy
USAGE
  exit 1;
}

COLS="$(tput cols)"
LINE_SEP="$(printf '=%.s' $(seq 1 $COLS))"
TPUT_END="$(tput sgr0)"
BANNER_START="$(tput setaf 7)$(tput setab 2)"
ERROR_START="$(tput setaf 7)$(tput setab 1)"
FLAVORS=("Release-universal" "Release-iphoneos" "Release-iphonesimulator")

function banner()
{
  echo -e "$BANNER_START$LINE_SEP\n$@\n$LINE_SEP$TPUT_END"
}

function die()
{
  echo -e "$ERROR_START$LINE_SEP\n[FATAL ERROR]    $@  \n$LINE_SEP$TPUT_END"
  exit 1;
}


if [[ $# < 3 ]]; then
  usage;
fi

ENV="$1"
FLAVOR="$2"
ACTION="$3"

echo "working with $ENV in $FLAVOR - $ACTION";

if [[ ! -f "$PWD/build-config.$FLAVOR.sh" ]]; then
  die "cannot find build config for $FLAVOR";
fi

echo "sourcing configuration..." >&2
source "$PWD/build-config.$FLAVOR.sh";

echo "starting work.." >&2

##### Constants
OUTPUT_PODSPEC_FILE_NAME="appmonet.podspec"
DEV_BINTRAY_REPO="monet_android_dev"
PROD_BINTRAY_REPO="MonetBidder"
WORKSPACE_NAME="AppMonet.xcworkspace"


# get the repo
BINTRAY_REPO="$DEV_BINTRAY_REPO"
BINTRAY_CREDS="${BINTRAY_CREDS}"
if [[ "$ENV" == "prod" ]]; then
  BINTRAY_REPO="$PROD_BINTRAY_REPO"
fi

##
# Utility Functions
##

function log_output()
{
  perl -sne '$|=1;print "[$prefix]\t$_";' -- -prefix="$1"
}

##
# Build steps
##

function get_framework_version() {
  if [[ ! -f "./$1/$(basename $FRAMEWORK_NAME)/Info.plist" ]]; then
    die "cannot find plist for ./$1/$(basename $FRAMEWORK_NAME)"
  fi

  # use xargs to trim the whitespace
  /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "./$1/$(basename $FRAMEWORK_NAME)/Info.plist" | xargs

}

function build_all_versions() {
    build_framework;
}

function build_framework()
{
  local scheme="$BUILD_SCHEME"
  local file_name="$    "
  local sdk="$FLAVOR"

  banner "1. building framework for - $sdk. Output to $file_name"
  rm -rf  "${FLAVORS[0]}"
  rm -rf  "${FLAVORS[1]}"
  rm -rf  "${FLAVORS[2]}"

  local error_log_fmt="$(tput setaf 1)$sdk/error$(tput sgr0)"

  xcodebuild -workspace $WORKSPACE_NAME -scheme $scheme clean 2> >(log_output $error_log_fmt) | log_output "$(tput setaf 2)($sdk)xcode/clean$(tput sgr0)"
  xcodebuild -workspace $WORKSPACE_NAME -scheme $scheme build 2> >(log_output $error_log_fmt) | log_output "$(tput setaf 2)($sdk)xcode/build$(tput sgr0)"
  xcodebuild -workspace $WORKSPACE_NAME -scheme $scheme archive 2> >(log_output $error_log_fmt) | log_output "$(tput setaf 2)($sdk)xcode/archive$(tput sgr0)"

  if [[ ! -d "${FLAVORS[0]}" ]]; then
    die "failed to find ${FLAVORS[0]} after build!"
  fi

  if [[ ! -d "${FLAVORS[1]}" ]]; then
    die "failed to find ${FLAVORS[0]} after build!"
  fi

  if [[ ! -d "${FLAVORS[2]}" ]]; then
    die "failed to find ${FLAVORS[0]} after build!"
  fi
}

function create_zip()
{
  banner "2. creating zip files"

  for i in "${FLAVORS[@]}"
  do
      FLAVOR_FRAMEWORK_NAME="$i/$(basename $FRAMEWORK_NAME)"

      if [[ ! -d "$FLAVOR_FRAMEWORK_NAME" ]]; then
        die "missing $FLAVOR_FRAMEWORK_NAME. Build failed"
      fi

      FRAMEWORK_BASE="$(basename $FLAVOR_FRAMEWORK_NAME)"
      FRAMEWORK_DIR="$(dirname $FLAVOR_FRAMEWORK_NAME)"
      IFS='-' read -ra TYPE <<< "$i"
      suffix=$(get_zip_suffix "${TYPE[1]}")

      echo "zipping into $FRAMEWORK_DIR"
#      zip -j "$FRAMEWORK_DIR/$ZIP_FILENAME-${TYPE[1]}.zip" "$FLAVOR_FRAMEWORK_NAME" "$FRAMEWORK_DIR/$OUTPUT_PODSPEC_FILE_NAME" "./LICENSE"
       cp ./LICENSE ${FRAMEWORK_DIR}
      (cd "$FRAMEWORK_DIR" && zip -r "$ZIP_FILENAME-$suffix.zip" "$FRAMEWORK_BASE" "$OUTPUT_PODSPEC_FILE_NAME" "./LICENSE")
  done
}

function create_podspec()
{
  banner "3. creating podspec"

  for i in "${FLAVORS[@]}"
  do
      FRAMEWORK_VERSION=$(get_framework_version "$i")

      if [[ -z "$FRAMEWORK_VERSION" ]]; then
        die "failed to get framework version!";
        exit 1;
      fi

      IFS='-' read -ra TYPE <<< "$i"
      suffix=$(get_zip_suffix "${TYPE[1]}")

      cat "$PODSPEC_FILE" | \
      perl -psne 's/{version}/$version/; s/{repo}/$repo/; s/{type}/$type/; s/{bintray_creds}/$bintraycreds/' -- \
        -version="$FRAMEWORK_VERSION" -repo="$BINTRAY_REPO" -type="$suffix" -bintraycreds="$BINTRAY_CREDS" > "$i/$OUTPUT_PODSPEC_FILE_NAME"
  done

}

function upload_to_bintray()
{
  banner "4. uploading to bintray"
  for i in "${FLAVORS[@]}"
  do
      IFS='-' read -ra TYPE <<< "$i"
      suffix=$(get_zip_suffix "${TYPE[1]}")

      local zip_file="$i/$ZIP_FILENAME-$suffix.zip"
      local repo_target="$REPO_TARGET"

      local version=$(get_framework_version $i)
      if [[ ! -f "$zip_file" ]]; then
        die "missing $zip_file - cannot upload!"
      fi

      banner "($repo_target) uploading to bintray with $BINTRAY_REPO @ $version"

      curl -T $zip_file -u$BINTRAY_USER:$BINTRAY_API_KEY https://api.bintray.com/content/appmonet/$BINTRAY_REPO/monetbidder-ios/$version/com/monet/ios/$repo_target/$version/
      local affected=$(curl -X POST -u$BINTRAY_USER:$BINTRAY_API_KEY https://api.bintray.com/content/appmonet/$BINTRAY_REPO/monetbidder-ios/$version/publish | jq '.files')
#
      echo "$affected files were changed during upload"
      if [[ $affected -eq 0 ]]; then
        die "did not affect any files. Error!"
      fi
  done
}

function upload_to_github()
{
    banner "5. uploading to github"
    git clone https://github.com/AppMonet/CocoaPods.git
    for i in "${FLAVORS[@]}"
    do
        IFS='-' read -ra TYPE <<< "$i"
        suffix=$(get_zip_suffix "${TYPE[1]}")
        flavor=$(upperCaseFlavor "$FLAVOR")
        local version=$(get_framework_version $i)
        mkdir -p "CocoaPods/AppMonet_${flavor}-${suffix}/${version}"
        cp "$i/appmonet.podspec" "CocoaPods/AppMonet_${flavor}-${suffix}/${version}/AppMonet_${flavor}-${suffix}.podspec"
        (cd "CocoaPods" && git add * && git commit -m "Release ${flavor} version: ${version}" && git push)
    done
    rm -rf ./CocoaPods
}


function remove()
{
  local file="$1"
  echo -e "removing\t$file"
  rm -rf "$file"
}

function clean_up()
{
  banner "cleaning..."
  remove "$ZIP_FILENAME"
  remove $OUTPUT_PODSPEC_FILE_NAME
  remove "$FRAMEWORK_NAME"
  rm -rf "CocoaPods"
}

function get_zip_suffix()
{
    if [ "$1" = "iphoneos" ]
    then
        echo "device"
    elif [ "$1" = "iphonesimulator" ]
    then
        echo "simulator"
    else
        echo $1
    fi

}

function upperCaseFlavor(){

    if [ "$1" = "mopub" ]
    then
        echo "Mopub"
    elif [ "$1" = "dfp" ]
    then
        echo "Dfp"
    else
        echo "Bidder"
    fi
}

echo "action is $ACTION"

case "$ACTION" in
  build-only)
    build_framework;;
  build)
    build_framework && create_podspec && create_zip;;
  version)
    get_framework_version;;
  podspec)
    create_podspec;;
  zip)
    create_zip;;
  clean)
    clean_up;;
  deploy)
    upload_to_bintray;;
  github)
    upload_to_github;;
  *)
    usage;;
esac
