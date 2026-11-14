# Building Fritzing 1.0.7 for macOS (Apple Silicon)

Handoff notes for a Claude Code session on a Mac. The Windows build in this repo was done on
14 Nov 2026. This file records what that build needed, translated to macOS. It is a plan,
not a tested recipe: check each step's output before moving on.

Goal: `Fritzing-1.0.7-unofficial-macos-arm64.dmg`, attached to the existing GitHub Release
`1.0.7-unofficial` in `irpl/fritzing-windows-build`, plus macOS install steps in README.md.
Ask Phillip before uploading to the Release or pushing to the repo.

## Work folder

Use `~/fritzing-build`. The qmake detect scripts find every library **by folder name, next to
`fritzing-app`**:

```
~/fritzing-build/
  fritzing-app/                     git clone -b 1.0.7 --depth 1 https://github.com/fritzing/fritzing-app
  boost_1_85_0/                     headers only (archives.boost.io)
  libgit2-1.7.1/                    INSTALL prefix: include/ + lib/libgit2.a   (macOS links it STATIC)
  quazip-6.8.3-1.4intuisphere/      INSTALL prefix (yes, "intuisphere" is part of the name: pri/quazipdetect.pri)
  Clipper1-6.4.2/                   INSTALL prefix: include/polyclipping/clipper.hpp + lib/libpolyclipping.*
  svgpp-1.3.1/                      headers only (github svgpp/svgpp v1.3.1)
  ngspice-42/                       needs include/ngspice/sharedspice.h only at build time
  src/                              unpacked library sources
  Qt/6.8.3/macos/                   from aqtinstall
```

Read `fritzing-app/pri/*detect.pri` once before building; they are the source of truth.

## Steps

1. **Tools.** `xcode-select --install` (Command Line Tools). If qmake later complains that Xcode
   isn't set up, full Xcode from the App Store is needed instead. Homebrew: `brew install cmake ninja`.
   Do **not** `brew install qt`: a second Qt on the path gets picked up by CMake.
   (Windows lesson: MSYS2 headers leaking into the build cost a run. Keep the environment clean.)
2. **Qt 6.8.3** (Fritzing needs 6.5.3–6.10.10) with aqtinstall, no Qt account needed:
   ```
   python3 -m venv aqtenv && aqtenv/bin/pip install aqtinstall
   aqtenv/bin/aqt install-qt mac desktop 6.8.3 clang_64 -m qtserialport qtimageformats qt5compat -O ~/fritzing-build/Qt
   ```
   `qt5compat` is required: QuaZip links Qt6Core5Compat.
3. **libgit2 1.7.1, static:** `-DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DBUILD_CLI=OFF -DUSE_SSH=OFF
   -DUSE_BUNDLED_ZLIB=ON -DREGEX_BACKEND=builtin -DUSE_HTTPS=SecureTransport`, install to `libgit2-1.7.1`.
   `pri/libgit2detect.pri` links `libgit2.a -framework Security` on macOS.
4. **QuaZip 1.4:** `-DQUAZIP_QT_MAJOR_VERSION=6 -DCMAKE_PREFIX_PATH=<Qt>/6.8.3/macos -DQUAZIP_BZIP2=OFF`,
   install to `quazip-6.8.3-1.4intuisphere`. On macOS the system zlib should be found (the pri adds `-lz`).
5. **Clipper 6.4.2:** cmake on `clipper_ver6.4.2.zip`'s `cpp/` folder (sourceforge polyclipping), install to `Clipper1-6.4.2`.
   Prefer static (`-DBUILD_SHARED_LIBS=OFF`) so nothing needs bundling.
6. **ngspice:** at runtime Fritzing loads `libngspice.0.dylib` from its library paths and the code model
   `<that dir>/ngspice/analog.cm`. `brew install libngspice` gives the dylib and the header; copy
   `sharedspice.h` into `ngspice-42/include/ngspice/`. Bundle the dylib (and analog.cm) in the app;
   check `src/simulation/ngspice_simulator.cpp` for the exact macOS search paths.
7. **Build:** `qmake ../fritzing-app/phoenix.pro CONFIG-=debug_and_release CONFIG+=release
   boost_root=$HOME/fritzing-build/boost_1_85_0` in an out-of-source folder, then `make -j$(sysctl -n hw.ncpu)`.
   On Windows this took about 10 minutes.
8. **Package:** read `fritzing-app/tools/deploy_fritzing_mac.sh` first: it shows where parts, sketches,
   translations and help go inside `Fritzing.app`. Then:
   - `macdeployqt Fritzing.app` (adds Qt frameworks), and copy in quazip/ngspice dylibs if they are shared.
   - `fritzing-parts`: `git clone -b 1.0.7 --depth 1 https://github.com/fritzing/fritzing-parts` and
     **keep its `.git` folder**. Without it Fritzing logs "1.6 SHA empty" and can't build its parts database.
   - Build the parts database once: `Fritzing.app/Contents/MacOS/Fritzing -db <parts folder>/parts.db`.
     Set `QT_FORCE_STDERR_LOGGING=1` to see its log. Expect a ~16 MB parts.db.
   - Translations: `lrelease` each `translations/*.ts` to `.qm`.
   - Licences: copy as in `build-scripts/package.bat` (Fritzing LICENSE.*, libgit2, quazip, zlib, clipper, ngspice).
9. **Sign ad hoc** (required for arm64 binaries to run at all; it is not a Developer ID):
   `codesign --force --deep --sign - Fritzing.app`, then `codesign --verify --deep --strict Fritzing.app`.
10. **Test:** open `~/Documents/...` any sketch, or drag a resistor onto the breadboard. Then make the dmg:
    `hdiutil create -volname "Fritzing 1.0.7" -srcfolder <folder with Fritzing.app + README + licenses> -ov -format UDZO Fritzing-1.0.7-unofficial-macos-arm64.dmg`
11. **Test as a student would:** download the dmg from somewhere (so it gets the quarantine flag),
    install, and note exactly what Gatekeeper shows on this macOS version.

## What students will see (for the README)

The app is not notarised (no Apple Developer ID), so the first open is blocked. On macOS 15+
right-click → Open no longer bypasses it. The steps are: try to open it once, then
**System Settings → Privacy & Security → scroll down → Open Anyway**, and confirm.
Write the README steps from what step 11 actually showed.

## Recording

Time the build (`date` at the start and end). Report to Phillip: total time, every error hit and
its fix, and the dmg size and SHA-256. Add the macOS scripts to `build-scripts/` (e.g. `build-mac.sh`).
