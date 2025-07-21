#!/bin/bash

echo "🔥 RepoForge Launcher Script"
echo "==========================="

# 1. Kill any existing RepoForge instances
echo "📱 Killing existing RepoForge instances..."
killall RepoForge 2>/dev/null || true
killall -9 RepoForge 2>/dev/null || true

# Wait a moment for processes to fully terminate
sleep 1

# 2. Clean old builds
echo "🧹 Cleaning old builds..."
rm -rf .build/
rm -rf RepoForge.app/ 2>/dev/null || true

# 3. Build the app
echo "🔨 Building RepoForge..."
swift build --configuration release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# 4. Copy the built executable to create a proper .app bundle
echo "📦 Creating app bundle..."
mkdir -p RepoForge.app/Contents/MacOS
mkdir -p RepoForge.app/Contents/Resources

# Copy the executable
cp .build/arm64-apple-macosx/release/RepoForge RepoForge.app/Contents/MacOS/

# Copy the icon
if [ -f "appicon.png" ]; then
    cp appicon.png RepoForge.app/Contents/Resources/
    echo "✅ App icon copied to bundle"
else
    echo "⚠️  appicon.png not found in current directory"
fi

# Create Info.plist
cat > RepoForge.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>RepoForge</string>
    <key>CFBundleIdentifier</key>
    <string>com.rogierx.RepoForge</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>appicon.png</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ Info.plist created"

# 5. Launch the app
echo "🚀 Launching RepoForge..."
open RepoForge.app

# Wait a moment and then force it to appear in dock
sleep 2
osascript -e 'tell application "RepoForge" to activate'

echo "✅ RepoForge launched successfully!"
echo "📍 App should now be visible in the dock with the correct icon" 