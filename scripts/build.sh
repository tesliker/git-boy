#!/bin/zsh
set -eu
cd "${0:A:h:h}"
swift build -c release
app="$PWD/dist/Git Boy.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
mkdir -p dist/GitBoy.iconset
swift scripts/icon.swift dist/icon-1024.png
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" dist/icon-1024.png --out "dist/GitBoy.iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" dist/icon-1024.png --out "dist/GitBoy.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns dist/GitBoy.iconset -o "$app/Contents/Resources/AppIcon.icns"
cp assets/*.png "$app/Contents/Resources/"
cp .build/release/GitBoy "$app/Contents/MacOS/GitBoy"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Git Boy</string>
<key>CFBundleDisplayName</key><string>Git Boy</string>
<key>CFBundleIdentifier</key><string>com.sliker.gitboy</string>
<key>CFBundleExecutable</key><string>GitBoy</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.3.0</string>
<key>CFBundleVersion</key><string>3</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleURLTypes</key><array><dict><key>CFBundleURLName</key><string>Code Review</string><key>CFBundleURLSchemes</key><array><string>gitboy</string><string>githarbor</string></array></dict></array>
</dict></plist>
PLIST
codesign --force --deep --sign - "$app"
/usr/bin/ditto -c -k --keepParent "$app" dist/Git-Boy.zip
