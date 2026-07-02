#!/bin/bash

PODSPEC_PATH=AdyenNetworking.podspec
CURRENT_VERSION=`agvtool mvers -terse1`
CURRENT_BUILD=`agvtool vers -terse`

echo ""
echo "Current Version: ${CURRENT_VERSION} (${CURRENT_BUILD})"
echo ""

NEW_VERSION=$1

if [ -n "$NEW_VERSION" ]
then
  agvtool new-marketing-version $NEW_VERSION
  agvtool new-version -all $NEW_VERSION

  # Replace the podspec version regardless of its current value, so the bump
  # does not depend on the Xcode marketing version matching the podspec.
  sed -i '' -E "s/(s\.version[[:space:]]*=[[:space:]]*)'[^']*'/\1'$NEW_VERSION'/" $PODSPEC_PATH
fi

CURRENT_VERSION=`agvtool mvers -terse1`
CURRENT_BUILD=`agvtool vers -terse`

echo "New Version:     ${CURRENT_VERSION} (${CURRENT_BUILD})"
echo ""

echo "### New Version: ${CURRENT_VERSION} (${CURRENT_BUILD})" >> $GITHUB_STEP_SUMMARY
