#!/bin/bash

# Download Flutter SDK
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter dependencies
flutter pub get

# Build Flutter for web
flutter build web --release --web-renderer canvaskit

# Ensure proper permissions for web files
chmod -R 755 build/web/

# Ensure manifest.json and other critical files exist and are accessible
if [ -f "build/web/manifest.json" ]; then
    echo "manifest.json exists and is accessible"
    cat build/web/manifest.json
else
    echo "Error: manifest.json not found in build/web/"
    exit 1
fi 