#!/bin/bash
# Build Fritzing 1.0.7 for macOS (Apple Silicon, arm64), macOS 12 or later.
# Tested on macOS 26.3 with Xcode 26.2. Run from anywhere; everything goes under $B.
# Steps: deps -> app. Then run package-mac.sh.
set -euo pipefail

B=${B:-$HOME/fritzing-build}
QTVER=6.8.3
Q=$B/Qt/$QTVER/macos
export MACOSX_DEPLOYMENT_TARGET=12.0
JOBS=$(sysctl -n hw.ncpu)
mkdir -p "$B/src"
cd "$B"

# ---------------------------------------------------------------- tools
# Requires Xcode (or Command Line Tools) and Homebrew. Do NOT brew install qt.
brew install cmake ninja

# ---------------------------------------------------------------- Qt
if [ ! -x "$Q/bin/qmake" ]; then
  python3 -m venv aqtenv
  aqtenv/bin/pip install -q aqtinstall
  aqtenv/bin/aqt install-qt mac desktop $QTVER clang_64 \
    -m qtserialport qtimageformats qt5compat -O "$B/Qt"
fi
# The macOS 26 SDK no longer ships AGL.framework, but Qt 6.8.3's qmake files still link it.
sed -i '' 's/ -framework AGL//; s/-framework AGL //' \
  "$Q/mkspecs/common/mac.conf" "$Q/mkspecs/modules/qt_lib_gui_private.pri"
grep -rl --include='*.prl' 'framework AGL' "$Q/lib" | while read -r f; do
  sed -i '' 's/-framework AGL //g; s/ -framework AGL//g' "$f"
done

# ---------------------------------------------------------------- sources
[ -d fritzing-app ]   || git clone -b 1.0.7 --depth 1 https://github.com/fritzing/fritzing-app
[ -d fritzing-parts ] || git clone -b 1.0.7 --depth 1 https://github.com/fritzing/fritzing-parts
[ -d src/libgit2 ]    || git clone -b v1.7.1 --depth 1 https://github.com/libgit2/libgit2 src/libgit2
[ -d src/quazip ]     || git clone -b v1.4   --depth 1 https://github.com/stachenov/quazip src/quazip
[ -d svgpp-1.3.1 ]    || git clone -b v1.3.1 --depth 1 https://github.com/svgpp/svgpp svgpp-1.3.1
if [ ! -d boost_1_85_0 ]; then
  curl -sSL -o src/boost.tar.gz https://archives.boost.io/release/1.85.0/source/boost_1_85_0.tar.gz
  tar xzf src/boost.tar.gz boost_1_85_0/boost
fi
if [ ! -d src/clipper ]; then
  curl -sSL -o src/clipper.zip "https://sourceforge.net/projects/polyclipping/files/clipper_ver6.4.2.zip/download"
  unzip -q src/clipper.zip -d src/clipper
fi
if [ ! -d src/ngspice-42 ]; then
  curl -sSL -o src/ngspice-42.tar.gz "https://sourceforge.net/projects/ngspice/files/ng-spice-rework/old-releases/42/ngspice-42.tar.gz/download"
  tar xzf src/ngspice-42.tar.gz -C src
fi

CM=(-G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 -DCMAKE_OSX_ARCHITECTURES=arm64)

# ---------------------------------------------------------------- libgit2 1.7.1 (static)
# Bundled zlib 1.2.x does not compile against the macOS 26 SDK (fdopen macro), so use the system zlib.
cmake -S src/libgit2 -B src/libgit2-build "${CM[@]}" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DBUILD_CLI=OFF \
  -DUSE_SSH=OFF -DUSE_BUNDLED_ZLIB=OFF -DREGEX_BACKEND=builtin -DUSE_HTTPS=SecureTransport \
  -DCMAKE_INSTALL_PREFIX="$B/libgit2-1.7.1"
cmake --build src/libgit2-build && cmake --install src/libgit2-build

# ---------------------------------------------------------------- Clipper 6.4.2 (static)
cmake -S src/clipper/cpp -B src/clipper-build "${CM[@]}" -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX="$B/Clipper1-6.4.2"
cmake --build src/clipper-build && cmake --install src/clipper-build

# ---------------------------------------------------------------- QuaZip 1.4 (shared, links Qt Core5Compat)
cmake -S src/quazip -B src/quazip-build "${CM[@]}" -DQUAZIP_QT_MAJOR_VERSION=6 -DCMAKE_PREFIX_PATH="$Q" \
  -DQUAZIP_BZIP2=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX="$B/quazip-$QTVER-1.4intuisphere"
cmake --build src/quazip-build && cmake --install src/quazip-build

# ---------------------------------------------------------------- ngspice 42 (shared, macOS 12+)
# Homebrew's libngspice is built for the newest macOS only, so build it here.
mkdir -p src/ngspice-42/build-shared
( cd src/ngspice-42/build-shared &&
  ../configure --prefix="$B/src/ngspice-42-install" --with-ngshared --enable-xspice --enable-cider \
    --disable-debug --disable-openmp --without-x \
    CFLAGS="-O2 -arch arm64 -mmacosx-version-min=12.0" LDFLAGS="-arch arm64 -mmacosx-version-min=12.0" &&
  make -j"$JOBS" && make install )
mkdir -p ngspice-42/include/ngspice
cp src/ngspice-42-install/include/ngspice/sharedspice.h ngspice-42/include/ngspice/

# ---------------------------------------------------------------- Fritzing
rm -rf build-release release64
mkdir build-release
cd build-release
"$Q/bin/qmake" ../fritzing-app/phoenix.pro CONFIG-=debug_and_release CONFIG+=release \
  CONFIG+=sdk_no_version_check boost_root="$B/boost_1_85_0"
# The aqt Qt is universal, so qmake defaults to x86_64+arm64; the libraries above are arm64 only.
make -j"$JOBS" ARCHS=arm64
echo "BUILD OK: $B/release64/Fritzing.app"
