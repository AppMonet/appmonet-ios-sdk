# redirect stdout & stderr to a logfile
exec > /tmp/${PROJECT_NAME}_archive.log 2>&1

UNIVERSAL_OUTPUTFOLDER="${BUILD_DIR}/${CONFIGURATION}-universal"

if [ "true" == ${ALREADYINVOKED:-false} ]; then
  echo "RECURSION: Detected, stopping"
  exit 0;
fi

export ALREADYINVOKED="true"

# make sure that the output directory exists
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"

echo "Building for iPhoneSimulator"
xcodebuild -workspace "${WORKSPACE_PATH}" \
  -scheme "${TARGET_NAME}" \
  -configuration ${CONFIGURATION} \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone XS' \
  ONLY_ACTIVE_ARCH=NO ARCHS='i386 x86_64' \
  BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" \
  ENABLE_BITCODE=YES OTHER_CFLAGS="-fembed-bitcode" \
  BITCODE_GENERATION_MODE=bitcode clean build 2>&1 | perl -sne '$|=1;print "\t[xcode] $_";'

# Step 1. Copy the framework structure (from iphoneos build) to the universal folder
echo "Copying to output folder"
cp -R "${ARCHIVE_PRODUCTS_PATH}${INSTALL_PATH}/" "${UNIVERSAL_OUTPUTFOLDER}"

# Step 2. Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
FRAMEWORK_ROOT="${UNIVERSAL_OUTPUTFOLDER}/${TARGET_NAME}.framework"
SIMULATOR_SWIFT_MODULES_DIR="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${TARGET_NAME}.framework/Modules/${TARGET_NAME}.swiftmodule/."
if [ -d "${SIMULATOR_SWIFT_MODULES_DIR}" ]; then
  cp -R "${SIMULATOR_SWIFT_MODULES_DIR}" "${FRAMEWORK_ROOT}/Modules/${TARGET_NAME}.swiftmodule"
fi

# step 3a - copy the modulemap into the framework

echo "making module directory @ $FRAMEWORK_ROOT"
mkdir "$FRAMEWORK_ROOT/Modules"

MODULEMAP_TEMPLATE="$SRCROOT/module.modulemap.template"
if [[ ! -f "$MODULEMAP_TEMPLATE" ]]; then
  echo "missing modulemap @ $MODULEMAP_TEMPLATE !"
  exit 1
fi

echo "templating the modulemap with $TARGET_NAME into the framework"
sed -e "s,@product@,$TARGET_NAME,g" "$MODULEMAP_TEMPLATE" > "$FRAMEWORK_ROOT/Modules/module.modulemap"

# Step 3. Create universal binary file using lipo and place the combined executable in the copied framework directory
echo "Combining executables"
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${EXECUTABLE_PATH}" \
  "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${EXECUTABLE_PATH}" \
  "${ARCHIVE_PRODUCTS_PATH}${INSTALL_PATH}/${EXECUTABLE_PATH}"

echo "Combining executables end"

# Step 5. Convenience step to copy the framework to the project's directory
echo "Copying to project dir"
yes | cp -Rf "${UNIVERSAL_OUTPUTFOLDER}/${FULL_PRODUCT_NAME}" "${PROJECT_DIR}"

buildNumber="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$SRCROOT/AppMonet/Info.plist")"

echo $buildNumber -> "${PROJECT_DIR}/framework_info_dfp"

open "${PROJECT_DIR}"
