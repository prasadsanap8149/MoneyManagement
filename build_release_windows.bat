@echo off
echo 🚀 SecureMoney Release APK Builder for Windows
echo =============================================

:: Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ Error: Please run this script from your Flutter project root directory
    echo    Make sure you can see pubspec.yaml in the current folder
    pause
    exit /b 1
)

echo.
echo 📋 Pre-build checklist:
echo ✅ Make sure you've created your keystore file
echo ✅ Make sure you've created key.properties file
echo ✅ Make sure you've updated build.gradle
echo.

set /p continue="Continue with build? (y/n): "
if /i not "%continue%"=="y" exit /b 0

echo.
echo 🧹 Cleaning previous builds...
flutter clean

echo.
echo 📦 Getting dependencies...
flutter pub get

echo.
echo 🎨 Generating app icons...
flutter pub run flutter_launcher_icons:main

echo.
echo 🏗️ Building release App Bundle...
flutter build appbundle --release

echo.
echo 🏗️ Building release APK...
flutter build apk --release --split-per-abi

echo.
echo ✅ Build complete!
echo.
echo 📱 Your files are ready:
echo    App Bundle: build\app\outputs\bundle\release\app-release.aab
echo    APK: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo.

:: Check if files exist
if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo ✅ App Bundle created successfully
) else (
    echo ❌ App Bundle not found - check for errors above
)

if exist "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" (
    echo ✅ APK created successfully
) else (
    echo ❌ APK not found - check for errors above
)

echo.
echo 🎯 Next steps:
echo    1. Test the APK on your device
echo    2. Upload the App Bundle (.aab) to Play Store
echo    3. Complete your Play Store listing
echo.

pause
