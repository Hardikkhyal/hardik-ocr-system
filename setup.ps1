# OmniOCR Offline Android App - Automated Setup Script
# Run this script in PowerShell after installing Flutter on your machine.

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   OmniOCR Offline App Setup Utility" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Step 1: Check for Flutter installation
Write-Host "[1/5] Checking if Flutter is installed..." -ForegroundColor Yellow
$flutterCheck = Get-Command flutter -ErrorAction SilentlyContinue

if (-not $flutterCheck) {
    Write-Host "[ERROR] Flutter SDK was not found in your system PATH." -ForegroundColor Red
    Write-Host "Please install Flutter first by following the instructions in SETUP.md." -ForegroundColor White
    Exit
}

$flutterVersion = flutter --version | Select-Object -First 1
Write-Host "Found Flutter: $flutterVersion" -ForegroundColor Green

# Step 2: Initialize Flutter native platform wrappers
Write-Host "[2/5] Initializing Flutter project template..." -ForegroundColor Yellow

# Backup custom main.dart and pubspec.yaml to prevent flutter create from overwriting them
$mainBackupExists = Test-Path "lib/main.dart"
$pubspecBackupExists = Test-Path "pubspec.yaml"

if ($mainBackupExists) { Copy-Item "lib/main.dart" "lib/main.dart.bak" -Force }
if ($pubspecBackupExists) { Copy-Item "pubspec.yaml" "pubspec.yaml.bak" -Force }

# Run flutter create which creates native wrappers
flutter create --org com.omniocr.offline --project-name offline_ocr_app .

# Restore custom files
if ($mainBackupExists) { 
    Copy-Item "lib/main.dart.bak" "lib/main.dart" -Force 
    Remove-Item "lib/main.dart.bak" -Force
}
if ($pubspecBackupExists) { 
    Copy-Item "pubspec.yaml.bak" "pubspec.yaml" -Force 
    Remove-Item "pubspec.yaml.bak" -Force
}

# Step 3: Configure Android Gradle & Proguard Rules
Write-Host "[3/5] Configuring Android build parameters..." -ForegroundColor Yellow
$gradlePath = "android/app/build.gradle"

if (Test-Path $gradlePath) {
    $gradleContent = Get-Content $gradlePath -Raw
    
    # 1. Update minSdkVersion to 21
    if ($gradleContent -like "*minSdkVersion flutter.minSdkVersion*") {
        $gradleContent = $gradleContent -replace 'minSdkVersion\s+flutter.minSdkVersion', 'minSdkVersion 21'
        Write-Host "Successfully updated minSdkVersion to 21 in build.gradle." -ForegroundColor Green
    }
    
    # 2. Register Proguard rules file
    if ($gradleContent -like "*signingConfig signingConfigs.debug*" -and $gradleContent -notlike "*proguardFiles*") {
        $gradleContent = $gradleContent -replace 'signingConfig signingConfigs.debug', 'signingConfig signingConfigs.debug`r`n            proguardFiles getDefaultProguardFile(`'proguard-android-optimize.txt`'), `'proguard-rules.pro`'''
        Write-Host "Successfully registered Proguard rules configuration in build.gradle." -ForegroundColor Green
    }
    
    Set-Content $gradlePath $gradleContent
    
    # 3. Create proguard-rules.pro file to ignore missing ML Kit classes during R8 minification
    $proguardPath = "android/app/proguard-rules.pro"
    $proguardRules = "-dontwarn com.google.mlkit.vision.text.**"
    Set-Content $proguardPath $proguardRules
    Write-Host "Successfully generated proguard-rules.pro." -ForegroundColor Green
} else {
    Write-Host "[ERROR] Could not find android/app/build.gradle. Ensure 'flutter create' ran successfully." -ForegroundColor Red
    Exit
}

# Step 4: Configure Android Manifest (Camera permissions and Image Cropper Activity)
Write-Host "[4/5] Updating Android Manifest configurations..." -ForegroundColor Yellow
$manifestPath = "android/app/src/main/AndroidManifest.xml"

if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath -Raw
    
    # 1. Inject Camera and Storage permissions (if not present)
    if ($manifestContent -notlike "*android.permission.CAMERA*") {
        $permissions = "    <uses-permission android:name=`"android.permission.CAMERA`" />`n    <uses-permission android:name=`"android.permission.READ_EXTERNAL_STORAGE`" />`n    <uses-permission android:name=`"android.permission.WRITE_EXTERNAL_STORAGE`" android:maxSdkVersion=`"29`" />"
        $manifestContent = $manifestContent -replace '<application', "$permissions`n    <application"
        Write-Host "Injected camera and storage permissions into Manifest." -ForegroundColor Green
    }

    # 2. Inject UCropActivity for image_cropper (if not present)
    if ($manifestContent -notlike "*com.yalantis.ucrop.UCropActivity*") {
        $activityXml = "        <activity`n            android:name=`"com.yalantis.ucrop.UCropActivity`"`n            android:screenOrientation=`"portrait`"`n            android:theme=`"@style/Theme.AppCompat.Light.NoActionBar`"/>"
        # Insert activity inside <application> right after the starting tag
        $manifestContent = $manifestContent -replace '(<application[^>]*>)', "`$1`n$activityXml"
        Write-Host "Registered UCropActivity in Manifest." -ForegroundColor Green
    }

    Set-Content $manifestPath $manifestContent
} else {
    Write-Host "[ERROR] Could not find AndroidManifest.xml. Ensure 'flutter create' ran successfully." -ForegroundColor Red
    Exit
}

# Step 5: Get package dependencies
Write-Host "[5/5] Fetching pub dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Setup Completed Successfully!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "You are now ready to run the app." -ForegroundColor White
Write-Host "Connect your Android device or start an emulator and run:" -ForegroundColor White
Write-Host "   flutter run" -ForegroundColor Yellow
