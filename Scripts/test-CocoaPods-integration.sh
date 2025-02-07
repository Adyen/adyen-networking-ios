#!/bin/bash

set -e # Any subsequent(*) commands which fail will cause the shell script to exit immediately

PROJECT_NAME=TempProject

function clean_up {
  cd ../
  rm -rf $PROJECT_NAME
  echo "exited"
}

# Delete the temp folder if the script exited with error.
trap "clean_up" 0 1 2 3 6

rm -rf $PROJECT_NAME

mkdir -p $PROJECT_NAME && cd $PROJECT_NAME

echo "
name: $PROJECT_NAME
targets:
  $PROJECT_NAME:
    type: application
    platform: iOS
    sources: Source
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.adyen.$PROJECT_NAME
  Tests:
    type: bundle.ui-testing
    platform: iOS
    sources: Tests
schemes:
  TempProject-Package:
    build:
      targets:
        $PROJECT_NAME: all
        Tests: [tests]
    test:
      targets:
        - Tests
" > project.yml

mkdir -p Source

echo "
import Foundation
import AdyenNetworking
@main
class EmptyClass {static func main() {}}
"  > Source/EmptyClass.swift

mkdir -p Tests

xcodegen generate

# Create a Podfile with our pod as dependency.

echo "platform :ios, '12.0'

target '$PROJECT_NAME' do
  use_frameworks!

  pod 'AdyenNetworking', :path => '../'
end
" >> Podfile

# Install the pods.
pod install

# Archive for generic iOS device
echo '############# Archive for generic iOS device ###############'
xcodebuild archive -scheme TempProject-Package -workspace TempProject.xcworkspace -destination 'generic/platform=iOS'

# Build for generic iOS device
echo '############# Build for generic iOS device ###############'
xcodebuild clean build -scheme TempProject-Package -workspace TempProject.xcworkspace -destination 'generic/platform=iOS'

# Archive for x86_64 simulator
echo '############# Archive for simulator ###############'
xcodebuild archive -scheme TempProject-Package -workspace TempProject.xcworkspace -destination 'generic/platform=iOS Simulator'

# Build for x86_64 simulator
echo '############# Build for simulator ###############'
xcodebuild clean build -scheme TempProject-Package -workspace TempProject.xcworkspace -destination 'generic/platform=iOS Simulator'

# Clean up.
cd ../
rm -rf $PROJECT_NAME
