#!/bin/bash

# Download Flutter SDK
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter dependencies
flutter pub get

# Build Flutter for web
flutter build web --release --web-renderer canvaskit 