@echo off
set PATH=C:\Windows\system32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
set B=D:\fritzing-build
set QT=%B%\Qt\6.8.3\msvc2022_64
set PATH=%QT%\bin;%PATH%
set D=%B%\dist\Fritzing-1.0.7-unofficial-win64
if exist %D% rmdir /S /Q %D%
mkdir %D%

echo ===== exe + windeployqt
copy /Y %B%\obj\release64\Fritzing.exe %D%\ >nul || exit /b 2
windeployqt --release --no-compiler-runtime --no-opengl-sw %D%\Fritzing.exe >%B%\windeployqt.log 2>&1 || exit /b 3

echo ===== third-party dlls
copy /Y %B%\libgit2-1.7.1\bin\git2.dll %D%\ >nul || exit /b 4
copy /Y %B%\quazip-6.8.3-1.4intuisphere\bin\quazip1-qt6.dll %D%\ >nul || exit /b 4
copy /Y %QT%\bin\Qt6Core5Compat.dll %D%\ >nul || exit /b 4
copy /Y %B%\ngspice-42\dll-vs\ngspice.dll %D%\ >nul || exit /b 4
copy /Y %B%\ngspice-42\dll-vs\libomp140.x86_64.dll %D%\ >nul || exit /b 4
xcopy /E /I /Y /Q %B%\ngspice-42\lib\ngspice %D%\ngspice >nul || exit /b 4
set CRT=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Redist\MSVC\14.44.35112\x64\Microsoft.VC143.CRT
for %%f in (msvcp140.dll msvcp140_1.dll msvcp140_2.dll vcruntime140.dll vcruntime140_1.dll concrt140.dll) do copy /Y "%CRT%\%%f" %D%\ >nul

echo ===== app data
xcopy /E /I /Y /Q %B%\fritzing-app\sketches %D%\sketches >nul
xcopy /E /I /Y /Q %B%\fritzing-app\help %D%\help >nul
if not exist %D%\translations mkdir %D%\translations
for %%f in (%B%\fritzing-app\translations\*.ts) do lrelease -silent %%f -qm %D%\translations\%%~nf.qm
rem Code editor syntax highlighting (Arduino, PICAXE) is read from translations\syntax.
xcopy /E /I /Y /Q %B%\fritzing-app\translations\syntax %D%\translations\syntax >nul || exit /b 5
robocopy %B%\dist-parts %D%\fritzing-parts /E /XD .git /NFL /NDL /NJH /NJS >nul

echo ===== licences
mkdir %D%\licenses
copy /Y %B%\fritzing-app\LICENSE.* %D%\licenses\ >nul
copy /Y %B%\fritzing-app\LICENSE_1_0.txt.BOOST %D%\licenses\ >nul
copy /Y %B%\fritzing-app\README.md %D%\licenses\fritzing-README.md >nul
copy /Y %B%\src\libgit2-1.7.1\COPYING %D%\licenses\libgit2-COPYING.txt >nul
copy /Y %B%\src\quazip-1.4\COPYING %D%\licenses\quazip-COPYING.txt >nul
copy /Y %B%\src\zlib-1.3.1\LICENSE %D%\licenses\zlib-LICENSE.txt >nul
copy /Y %B%\src\clipper\License.txt %D%\licenses\clipper-License.txt >nul
copy /Y %B%\src\ngspice\Spice64_dll\License.txt %D%\licenses\ngspice-License.txt >nul
copy /Y %QT%\..\..\Licenses\* %D%\licenses\ >nul 2>&1

echo ===== parts database
%D%\Fritzing.exe -db %D%\fritzing-parts\parts.db >%B%\partsdb.log 2>&1
echo PKG OK
