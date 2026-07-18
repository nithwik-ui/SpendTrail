$ErrorActionPreference = "Stop"

# Get version from pubspec.yaml
$pubspec = Get-Content .\pubspec.yaml
$versionLine = $pubspec | Select-String -Pattern "^version:\s*(.+)$"
$version = $versionLine.Matches.Groups[1].Value
$versionName = "v$version"

Write-Host "Building release for version $versionName..." -ForegroundColor Cyan

# Use Java 17 for the build
$env:JAVA_HOME = "d:\jdk17\jdk-17.0.2"
d:\flutter\bin\flutter.bat build apk --release

# Rename APK
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
$newApkPath = "build\app\outputs\flutter-apk\SpendTrail-$versionName.apk"

if (Test-Path $apkPath) {
    Rename-Item -Path $apkPath -NewName "SpendTrail-$versionName.apk" -Force
    Write-Host "Build successful! APK saved as $newApkPath" -ForegroundColor Green
} else {
    Write-Host "Build failed. Could not find $apkPath" -ForegroundColor Red
    exit 1
}

Write-Host "`nTo publish this release to GitHub, run the following commands:" -ForegroundColor Yellow
Write-Host "git add ."
Write-Host "git commit -m `"Release $versionName`""
Write-Host "git tag $versionName"
Write-Host "git push origin main --tags"
Write-Host "`nAfter pushing, create a GitHub Release for tag $versionName and attach $newApkPath as an asset!" -ForegroundColor Yellow
