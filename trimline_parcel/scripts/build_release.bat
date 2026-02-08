@echo off
REM Build Release Script for Trimline Parcel
REM Automatically increments version, builds APK, and uploads to server
REM Keeps last 5 versions on server

setlocal enabledelayedexpansion

cd /d %~dp0..

REM Read current version from pubspec.yaml
for /f "tokens=2 delims=: " %%a in ('findstr /r "^version:" pubspec.yaml') do set FULL_VERSION=%%a

REM Parse version and build number
for /f "tokens=1,2 delims=+" %%a in ("%FULL_VERSION%") do (
    set VERSION=%%a
    set BUILD_NUM=%%b
)

REM Increment build number
set /a NEW_BUILD_NUM=%BUILD_NUM%+1

REM Parse version parts
for /f "tokens=1,2,3 delims=." %%a in ("%VERSION%") do (
    set MAJOR=%%a
    set MINOR=%%b
    set PATCH=%%c
)

REM Increment patch version
set /a NEW_PATCH=%PATCH%+1
set NEW_VERSION=%MAJOR%.%MINOR%.%NEW_PATCH%+%NEW_BUILD_NUM%
set VERSION_NAME=%MAJOR%.%MINOR%.%NEW_PATCH%

echo.
echo ========================================
echo   Trimline Parcel - Release Builder
echo ========================================
echo.
echo Current version: %FULL_VERSION%
echo New version:     %NEW_VERSION%
echo.

REM Update pubspec.yaml with new version using PowerShell (UTF-8 safe)
powershell -Command "$content = Get-Content -Path 'pubspec.yaml' -Raw; $content = $content -replace 'version: %FULL_VERSION%', 'version: %NEW_VERSION%'; Set-Content -Path 'pubspec.yaml' -Value $content -NoNewline"

echo [1/4] Version updated in pubspec.yaml
echo.

REM Build release APK
echo [2/4] Building release APK...
call flutter build apk --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Build failed!
    REM Revert version on failure
    powershell -Command "$content = Get-Content -Path 'pubspec.yaml' -Raw; $content = $content -replace 'version: %NEW_VERSION%', 'version: %FULL_VERSION%'; Set-Content -Path 'pubspec.yaml' -Value $content -NoNewline"
    exit /b 1
)

echo.
echo [3/4] Build complete! Uploading to server...
echo.

REM Create update.json
echo {"version": "%VERSION_NAME%", "apk_url": "https://trimline.co.ke/apps/Parcel/trimline_parcel.apk", "release_notes": "Version %VERSION_NAME% release"} > build\update.json

REM Upload versioned APK (keep history)
echo Uploading versioned APK: trimline_parcel_%VERSION_NAME%.apk
scp "build\app\outputs\flutter-apk\app-release.apk" Administrator@trimline.co.ke:"D:/apps/Parcel/trimline_parcel_%VERSION_NAME%.apk"

REM Upload current APK (overwrites latest)
echo Uploading latest APK: trimline_parcel.apk
scp "build\app\outputs\flutter-apk\app-release.apk" Administrator@trimline.co.ke:"D:/apps/Parcel/trimline_parcel.apk"

REM Upload update.json
echo Uploading update.json
scp "build\update.json" Administrator@trimline.co.ke:"D:/apps/Parcel/update.json"

REM Clean up old versions (keep last 5)
echo.
echo [4/4] Cleaning old versions (keeping last 5)...
ssh Administrator@trimline.co.ke powershell.exe -NoProfile -ExecutionPolicy Bypass -File D:/apps/Parcel/cleanup_old_apks.ps1

echo.
echo ========================================
echo   Build Summary
echo ========================================
echo Version:  %NEW_VERSION%
echo APK Path: build\app\outputs\flutter-apk\app-release.apk
echo APK Size: 
for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do echo          %%~zA bytes
echo.
echo Server files:
echo   - trimline_parcel.apk (latest)
echo   - trimline_parcel_%VERSION_NAME%.apk (versioned)
echo   - update.json
echo.
echo ========================================

endlocal
