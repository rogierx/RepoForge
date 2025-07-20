#!/bin/bash

echo "Building and launching RepoForge..."

# Build RepoForge
echo "Building RepoForge..."
swift build -c release

# Create app bundle
echo "Creating app bundle..."
mkdir -p RepoForge.app/Contents/MacOS
mkdir -p RepoForge.app/Contents/Resources

# Copy executable
cp .build/release/RepoForge RepoForge.app/Contents/MacOS/

# Copy icon and info
cp Sources/RepoForge/Resources/AppIcon.icns RepoForge.app/Contents/Resources/
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>RepoForge</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.rogierx.repoforge</string>
    <key>CFBundleName</key>
    <string>RepoForge</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
</dict>
</plist>' > RepoForge.app/Contents/Info.plist

echo "Build complete!"
echo "App bundle created: RepoForge.app"

# Launch the app
open RepoForge.app

echo "You can now double-click RepoForge.app to launch RepoForge!"
echo "RepoForge is now running as a proper macOS app!"
echo "You should see it in your dock with the RepoForge logo." 