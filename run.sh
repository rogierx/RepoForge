#!/bin/bash

echo "Building and launching RepoForge..."

# Build and create app bundle
./build_app.sh

# Launch the app
open RepoForge.app

echo "RepoForge is now running as a proper macOS app!"
echo "You should see it in your dock with the RepoForge logo." 