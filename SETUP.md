# Setup & Run Guide: OmniOCR Offline Android App

This guide walks you through setting up Flutter on your Windows machine and running the **OmniOCR Offline** application.

---

## Prerequisites (Step-by-Step Installation)

### 1. Install Git
If you don't have Git installed:
1. Download Git from [git-scm.com/download/win](https://git-scm.com/download/win).
2. Run the installer and accept default choices.

### 2. Install Java JDK 17
Flutter Android builds require Java JDK 17:
1. Download Microsoft Build of OpenJDK 17 from [learn.microsoft.com/en-us/java/openjdk/download](https://learn.microsoft.com/en-us/java/openjdk/download#openjdk-17). Select the **Windows x64 MSI** installer.
2. Run the installer to completion.

### 3. Install Flutter SDK
1. Download the Flutter SDK bundle from [docs.flutter.dev/get-started/install/windows/mobile](https://docs.flutter.dev/get-started/install/windows/mobile?tab=download).
2. Extract the zip file and place the `flutter` folder in a simple directory path (e.g., `C:\src\flutter` or `D:\flutter`).
   > [!WARNING]
   > Do **NOT** install Flutter in paths requiring administrator privileges like `C:\Program Files\`.
3. Add the `bin` directory of Flutter to your User Env Variables:
   - Search for **"Environment Variables"** in Windows Search.
   - Edit the **Path** variable in the user list.
   - Click **New** and paste the path to your extracted flutter bin (e.g., `C:\src\flutter\bin`).
   - Click OK to save and close all windows.
4. Open a **new** PowerShell window and verify installation by running:
   ```powershell
   flutter --version
   ```

### 4. Install Android Studio & Android SDK
1. Download Android Studio from [developer.android.com/studio](https://developer.android.com/studio).
2. Run the installer. During the setup wizard, ensure you check **Android SDK**, **Android SDK Platform**, and **Android Virtual Device**.
3. Open Android Studio. Go to **More Actions** -> **SDK Manager**:
   - Under **SDK Platforms**, verify **Android 14 (API 34)** or newer is installed.
   - Under **SDK Tools**, check **Android SDK Command-line Tools (latest)** and click **Apply** to install.
4. Accept Android licenses by running the following command in PowerShell:
   ```powershell
   flutter doctor --android-licenses
   ```
   (Press `y` to accept every license prompt).

---

## How to Build the Application

### Option 1: Build & Run Locally (Requires Local Flutter Setup)

Once your local prerequisites are installed, follow these steps to configure and run the OCR app:

#### Step 1: Run the Automated Setup Script
Open a PowerShell terminal in the project directory (`d:\ocr`) and run:
```powershell
./setup.ps1
```
*Note: If Windows blocks execution of scripts, run this command in PowerShell first, then retry the script:*
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

#### Step 2: Start an Emulator or Connect a Device
- **Physical Device:** Enable Developer Options and USB Debugging on your phone, then connect it via USB.
- **Emulator:** In Android Studio, go to **More Actions** -> **Virtual Device Manager** and launch a configured emulator.

Verify your device is visible to Flutter by running:
```powershell
flutter devices
```

#### Step 3: Launch the Application
Run the following command to compile and launch the app:
```powershell
flutter run
```

---

### Option 2: Build in the Cloud via GitHub Actions (Zero Local Setup Required)

If you don't want to install Android Studio, Java, or the Flutter SDK locally, you can use our built-in GitHub Actions pipeline to compile the release APK directly in the cloud.

#### Step 1: Initialize a Git Repository
Open a terminal or PowerShell in the `d:\ocr` directory and run:
```bash
git init
git add .
git commit -m "Initial commit of offline OCR app"
```

#### Step 2: Push to GitHub
1. Create a new repository on GitHub (Public or Private).
2. Link your local repository and push:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   git branch -M main
   git push -u origin main
   ```

#### Step 3: Download the Compiled APK
1. Go to your repository on the GitHub website.
2. Click on the **Actions** tab at the top.
3. You will see a workflow running titled **Build Android APK**.
4. Once it finishes (takes 3-4 minutes), click on the completed run.
5. Scroll down to the **Artifacts** section at the bottom.
6. Click **OmniOCR-Release-APK** to download the zip file containing your installable `app-release.apk`.

---

## Offline OCR Notes
*   **Google ML Kit Text Recognition** runs 100% offline.
*   On Android, the OCR engine is part of Google Play Services. When the app is launched for the first time, Play Services might download a small offline language model (~10MB) in the background. Once initialized, the app works entirely in airplane mode (you can test this by toggling airplane mode and scanning).
