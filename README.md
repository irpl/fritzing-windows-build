# Fritzing 1.0.7 for Windows: unofficial build

A free Windows (64-bit) build of [Fritzing](https://fritzing.org), compiled from its
public source code for students in ECSE3038 at UWI Mona.

**This is not the official release.** The official build is sold at
[fritzing.org](https://fritzing.org/download/), and buying it supports the people who make
Fritzing. Fritzing is free software (GPL v3), which is what allows this build to be shared.

## Download and install

1. Download `Fritzing-1.0.7-unofficial-win64.zip` from the
   [latest release](../../releases/latest) (114 MB).
2. Unzip the whole folder somewhere you keep programs, for example
   `C:\Users\<your name>\Fritzing`. Keep every file together in that folder.
3. Open the folder and double-click `Fritzing.exe`.
4. If Windows shows "Windows protected your PC", click **More info**, then **Run anyway**.
   The build is not signed, so Windows shows this warning for it.

The first start takes about 10–20 seconds while Fritzing loads its parts.

SHA-256 of the zip:
`5cdaf08a74c20dc6d557fc3f8674b7accda1e4adb32f2be60fbc67fa9d4d0934`

## macOS (Apple Silicon: M1 and later)

Needs macOS 12 Monterey or later on an Apple Silicon Mac. It does not run on Intel Macs.

1. Download `Fritzing-1.0.7-unofficial-macos-arm64.dmg` from the
   [latest release](../../releases/latest) (187 MB).
2. Open the dmg and drag **Fritzing** onto **Applications**.
3. Open Fritzing from Applications. macOS blocks it the first time, because the build is
   not notarised by Apple. Click **Done** (or **OK**).
4. Open **System Settings → Privacy & Security**, scroll down to the message about Fritzing,
   click **Open Anyway**, and confirm with your password or Touch ID.

You only need to do this once. The first start takes a little while as Fritzing loads its parts.

SHA-256 of the dmg:
`c83b4dea0df0af2e8ad7f8d410183074d314ba21b9675c4260c49e9754d73298`

The macOS build uses the same Fritzing, parts and library versions as the Windows build below,
built with Apple clang 17 (Xcode 26.2) against Qt 6.8.3 `clang_64`. ngspice 42 was built from
its source release for macOS 12+. Scripts: `build-scripts/build-mac.sh` and `package-mac.sh`.

## Source

No changes were made to the Fritzing source code. This build was made from:

| Component | Source | Version |
|---|---|---|
| Fritzing app | [fritzing/fritzing-app](https://github.com/fritzing/fritzing-app) | branch `1.0.7`, commit `394a8bb4791424ffd99f99ebc330264d4becea63` |
| Fritzing parts | [fritzing/fritzing-parts](https://github.com/fritzing/fritzing-parts) | tag `1.0.7`, commit `70a1773402e8c76a77795637de482a83db3ca6d7` |
| Qt | aqtinstall, `win64_msvc2022_64` + qtserialport, qtimageformats, qt5compat | 6.8.3 |
| libgit2 | [libgit2/libgit2](https://github.com/libgit2/libgit2) | v1.7.1 |
| QuaZip | [stachenov/quazip](https://github.com/stachenov/quazip) | v1.4 |
| zlib | [madler/zlib](https://github.com/madler/zlib) | 1.3.1 |
| Clipper | [polyclipping](https://sourceforge.net/projects/polyclipping/) | 6.4.2 |
| Boost (headers) | [boost.org](https://www.boost.org) | 1.85.0 |
| svgpp | [svgpp/svgpp](https://github.com/svgpp/svgpp) | v1.3.1 |
| ngspice | [ngspice](https://ngspice.sourceforge.io) `ngspice-42_dll_64.7z` | 42 |

Compiler: MSVC 14.44 (Visual Studio Build Tools 2022).

## Building it yourself

The scripts in [`build-scripts/`](build-scripts) are the ones used for this release. They
expect everything under `D:\fritzing-build`, with the sources unpacked as their names show.

1. `build-deps.bat` builds libgit2, zlib, QuaZip and Clipper, and copies the ngspice headers.
2. `build-app.bat` runs qmake and nmake on `fritzing-app\phoenix.pro`.
3. `package.bat` gathers the exe, Qt (via windeployqt), the libraries, parts, translations
   and licences into one folder.
4. Copy `fritzing-parts\.git` into the package as well. Fritzing reads the parts commit
   from it and refuses to build its parts database without it.
5. Run `Fritzing.exe -db <package>\fritzing-parts\parts.db` once to create the parts database.

## Licence

Fritzing and these build scripts are under the GNU GPL v3 ([LICENSE](LICENSE)). Part graphics
are CC BY-SA 3.0. Each bundled library's licence is in the zip's `licenses` folder.
