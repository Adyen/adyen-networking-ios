#!/bin/bash

set -e # Any subsequent(*) commands which fail will cause the shell script to exit immediately

function echo_header {
  echo " "
  echo "===   $1"
}

function print_help {
  echo "Test Carthage Integration"
  echo " "
  echo "test-carthage-integration [project name] [arguments]"
  echo " "
  echo "options:"
  echo "-h, --help                show brief help"
  echo "-c, --no-clean            ignore cleanup"
}

PROJECT_NAME=TempProject
NEED_CLEANUP=true

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -c|--no-clean)
      NEED_CLEANUP=false
      shift
      ;;
    -p|--project)
      PROJECT_NAME="$1"
      shift
      ;;
  esac
done

if [ "$NEED_CLEANUP" == true ]
then
  echo_header "Clean up $PROJECT_NAME"
  rm -rf $PROJECT_NAME
  mkdir -p $PROJECT_NAME && cd $PROJECT_NAME

  echo_header "Setup Carthage"
  CWD=$(pwd)
  CURRENT_COMMIT=$(git rev-parse HEAD)

  echo "git \"file://$CWD/../\" \"$CURRENT_COMMIT\"" > Cartfile
  ../Scripts/carthage.sh update --use-xcframeworks
else
  cd $PROJECT_NAME
fi

echo_header "Generate Project"
echo "
name: $PROJECT_NAME
targets:
  $PROJECT_NAME:
    type: application
    platform: iOS
    sources: Source
    settings:
      base:
        INFOPLIST_FILE: Source/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.adyen.$PROJECT_NAME
    dependencies:
      - framework: Carthage/Build/AdyenNetworking.xcframework
        embed: true
        codeSign: true
schemes:
  App:
    build:
      targets:
        $PROJECT_NAME: all
" > project.yml

mkdir -p Source
touch Source/Dummy.swift

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>\$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleExecutable</key>
	<string>\$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleLocalizations</key>
	<array>
		<string>da-DK</string>
		<string>de-DE</string>
		<string>en-US</string>
		<string>es-ES</string>
		<string>ja-JP</string>
		<string>fr-FR</string>
		<string>it-IT</string>
		<string>nl-NL</string>
		<string>pl-PL</string>
		<string>pt-BR</string>
		<string>ru-RU</string>
		<string>sv-SE</string>
		<string>zh-CN</string>
		<string>zh-TW</string>
		<string>ko</string>
		<string>nb-NO</string>
		<string>fi</string>
		<string>cs-CZ</string>
		<string>el-GR</string>
		<string>hr-HR</string>
		<string>hu-HU</string>
		<string>ro-RO</string>
		<string>sk-SK</string>
		<string>sl-SL</string>
		<string>ar</string>
	</array>
	<key>CFBundleName</key>
	<string>\$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>\$(MARKETING_VERSION)</string>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>com.adyen.AdyenUIHost</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>ui-host</string>
			</array>
		</dict>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>weixin</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>wx33ed7fe146f6a50a</string>
			</array>
		</dict>
	</array>
	<key>CFBundleVersion</key>
	<string>\$(CURRENT_PROJECT_VERSION)</string>
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>weixin</string>
	</array>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsLocalNetworking</key>
		<true/>
	</dict>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>Save vouchers to your photos library</string>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIRequiredDeviceCapabilities</key>
	<array>
		<string>armv7</string>
	</array>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
</dict>
</plist>
"  > Source/Info.plist

xcodegen generate

echo_header "Build"
xcodebuild build -project $PROJECT_NAME.xcodeproj -scheme App -destination "name=iPhone 11" | xcpretty && exit ${PIPESTATUS[0]}

if [ "$NEED_CLEANUP" == true ]
then
  echo_header "Clean up"
  cd ../
  rm -rf $PROJECT_NAME
fi
