@echo off
echo ============================================
echo  AGCS Build Script
echo ============================================
echo.

REM 1. Setup MSVC environment
echo [1/6] Setting up MSVC environment...
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" amd64
if errorlevel 1 (
    echo ERRO: vcvarsall.bat falhou.
    pause
    exit /b 1
)

REM Add Qt tools and GStreamer to PATH
set PATH=C:\Qt\Tools\Ninja;C:\Qt\Tools\CMake_64\bin;%PATH%
set GSTREAMER_1_0_ROOT_MSVC_X86_64=C:\gstreamer\1.0\msvc_x86_64
set PATH=%GSTREAMER_1_0_ROOT_MSVC_X86_64%\bin;%PATH%
set PKG_CONFIG_PATH=%GSTREAMER_1_0_ROOT_MSVC_X86_64%\lib\pkgconfig

REM 2. Clean previous build
echo.
echo [2/6] Cleaning previous build...
if exist C:\CC\qgc\build rmdir /s /q C:\CC\qgc\build

REM 3. Configure
echo.
echo [3/6] Configuring CMake...
call C:\Qt\6.8.3\msvc2022_64\bin\qt-cmake.bat -B C:\CC\qgc\build -S C:\CC\qgc -G Ninja -DCMAKE_BUILD_TYPE=Release
if errorlevel 1 (
    echo ERRO: CMake configure falhou.
    pause
    exit /b 1
)

REM 4. Build
echo.
echo [4/6] Building AGCS...
cmake --build C:\CC\qgc\build
if errorlevel 1 (
    echo ERRO: Build falhou.
    pause
    exit /b 1
)

REM 5. Deploy Qt DLLs
echo.
echo [5/6] Deploying Qt DLLs...
C:\Qt\6.8.3\msvc2022_64\bin\windeployqt.exe C:\CC\qgc\build\Release\AGCS.exe --qmldir C:\CC\qgc\src
echo     windeployqt done.

REM 6. Deploy GStreamer DLLs
echo.
echo [6/6] Deploying GStreamer DLLs...
set GST_SRC=C:\gstreamer\1.0\msvc_x86_64
set DEPLOY_DIR=C:\CC\qgc\build\Release
echo     Copying bin DLLs...
xcopy /Y /Q "%GST_SRC%\bin\*.dll" "%DEPLOY_DIR%\"
REM GStreamer.cc looks for plugins at appDir/../lib/gstreamer-1.0
REM exe is in build/Release/, so plugins go to build/lib/gstreamer-1.0/
set GST_PLUGIN_DEPLOY=%DEPLOY_DIR%\..\lib\gstreamer-1.0
echo     Copying plugins to %GST_PLUGIN_DEPLOY%...
if not exist "%GST_PLUGIN_DEPLOY%" mkdir "%GST_PLUGIN_DEPLOY%"
xcopy /Y /Q "%GST_SRC%\lib\gstreamer-1.0\*.dll" "%GST_PLUGIN_DEPLOY%\"

echo.
echo ============================================
echo  Build completa!
echo  Executavel: %DEPLOY_DIR%\AGCS.exe
echo ============================================
pause
