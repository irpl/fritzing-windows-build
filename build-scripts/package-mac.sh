#!/bin/bash
# Package the Fritzing.app from build-mac.sh into a dmg.
# Data (sketches, help, translations, parts) goes in Contents/Resources, which FolderUtils::applicationDirPath
# checks on macOS. The official script puts it in Contents/MacOS, but codesign rejects fritzing-parts/.git there.
set -euo pipefail

B=${B:-$HOME/fritzing-build}
Q=$B/Qt/6.8.3/macos
NAME=Fritzing-1.0.7-unofficial-macos-arm64
D=$B/dist/$NAME
APP=$D/Fritzing.app
M=$APP/Contents/MacOS
R=$APP/Contents/Resources

rm -rf "$D" && mkdir -p "$D"
cp -R "$B/release64/Fritzing.app" "$D/"

echo "===== app data"
cp -R "$B/fritzing-app/sketches" "$B/fritzing-app/help" "$R/"
mkdir -p "$R/translations"
for f in "$B"/fritzing-app/translations/*.ts; do
  "$Q/bin/lrelease" -silent "$f" -qm "$R/translations/$(basename "${f%.ts}").qm"
done
find "$R/translations" -name '*.qm' -size -128c -delete
# Code editor syntax highlighting (Arduino, PICAXE) is read from translations/syntax.
cp -R "$B/fritzing-app/translations/syntax" "$R/translations/"
# Keep .git: Fritzing reads the parts commit from it and won't build parts.db without it.
rsync -a "$B/fritzing-parts/" "$R/fritzing-parts/"

echo "===== ngspice (QCoreApplication::libraryPaths includes Contents/MacOS)"
cp "$B/src/ngspice-42-install/lib/libngspice.0.dylib" "$M/"
install_name_tool -id @rpath/libngspice.0.dylib "$M/libngspice.0.dylib"
mkdir -p "$M/ngspice"
cp "$B"/src/ngspice-42-install/lib/ngspice/*.cm "$M/ngspice/"

echo "===== Qt frameworks + quazip"
# QuaZip links Qt via @rpath but has no rpath of its own, so macdeployqt can't find QtCore5Compat.
# Give the installed copy one for deployment, then strip it from the bundled copy.
QZ=$B/quazip-6.8.3-1.4intuisphere/lib/libquazip1-qt6.1.4.0.dylib
otool -l "$QZ" | grep -q "path $Q/lib " || install_name_tool -add_rpath "$Q/lib" "$QZ"
"$Q/bin/macdeployqt" "$APP" -libpath="$B/quazip-6.8.3-1.4intuisphere/lib" > "$B/macdeployqt.log" 2>&1
install_name_tool -delete_rpath "$Q/lib" "$APP/Contents/Frameworks/libquazip1-qt6.1.4.0.dylib" 2>/dev/null || true
# Fritzing only uses SQLite; the other SQL drivers need client libraries that aren't bundled.
rm -f "$APP"/Contents/PlugIns/sqldrivers/libqsql{odbc,psql,mimer}.dylib
test -f "$APP/Contents/Frameworks/QtCore5Compat.framework/Versions/A/QtCore5Compat"
# Drop build-machine rpaths left by qmake.
for r in $(otool -l "$M/Fritzing" | awk '/LC_RPATH/{getline; getline; print $2}' | grep "^$B" || true); do
  install_name_tool -delete_rpath "$r" "$M/Fritzing"
done

echo "===== thin universal Qt binaries to arm64"
find "$APP/Contents" -type f \( -path '*/Frameworks/*' -o -path '*/PlugIns/*' \) | while read -r f; do
  if lipo -archs "$f" 2>/dev/null | grep -q x86_64; then lipo -thin arm64 "$f" -output "$f"; fi
done

echo "===== licences"
L=$D/licenses
mkdir -p "$L"
cp "$B"/fritzing-app/LICENSE.* "$B/fritzing-app/LICENSE_1_0.txt.BOOST" "$L/"
cp "$B/fritzing-app/README.md" "$L/fritzing-README.md"
cp "$B/src/libgit2/COPYING" "$L/libgit2-COPYING.txt"
cp "$B/src/quazip/COPYING" "$L/quazip-COPYING.txt"
cp "$B/src/clipper/License.txt" "$L/clipper-License.txt"
cp "$B/src/ngspice-42/COPYING" "$L/ngspice-COPYING.txt"
cp "$Q"/../../Licenses/* "$L/" 2>/dev/null || true

echo "===== parts database"
codesign --force --deep --sign - "$APP"
QT_FORCE_STDERR_LOGGING=1 "$M/Fritzing" -db "$R/fritzing-parts/parts.db" > "$B/partsdb.log" 2>&1
ls -la "$R/fritzing-parts/parts.db"

echo "===== sign (ad hoc; required for arm64, not a Developer ID)"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

echo "===== dmg"
ln -s /Applications "$D/Applications"
rm -f "$B/dist/$NAME.dmg"
hdiutil create -volname "Fritzing 1.0.7" -srcfolder "$D" -ov -format UDZO "$B/dist/$NAME.dmg"
ls -la "$B/dist/$NAME.dmg"
shasum -a 256 "$B/dist/$NAME.dmg"
echo "PKG OK"
