#!/bin/bash

# Build the Swift executable
echo "Building RepoForge..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Create app bundle directory structure
echo "Creating app bundle..."
APP_NAME="RepoForge"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Clean up any existing app bundle
rm -rf "${APP_BUNDLE}"

# Create directories
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy the executable
cp ".build/release/RepoForge" "${MACOS_DIR}/${APP_NAME}"

# Copy the Info.plist
cp "Info.plist" "${CONTENTS_DIR}/"

# Copy the app icon
cp "Sources/RepoForge/Resources/AppIcon.icns" "${RESOURCES_DIR}/"

# Make the executable... executable
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "App bundle created: ${APP_BUNDLE}"
echo "You can now double-click ${APP_BUNDLE} to launch RepoForge!"

# Optionally launch the app
if [ "$1" = "--launch" ]; then
    echo "Launching RepoForge..."
    open "${APP_BUNDLE}"
fi 