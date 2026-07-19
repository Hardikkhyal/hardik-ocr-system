import os

def patch_project():
    print("Starting Android project patching...")
    
    # 1. Modify android/app/build.gradle to set minSdkVersion to 21 and register proguard rules
    gradle_path = os.path.join('android', 'app', 'build.gradle')
    if os.path.exists(gradle_path):
        with open(gradle_path, 'r') as f:
            content = f.read()
        
        # Replace minSdkVersion flutter.minSdkVersion with minSdkVersion 21
        if 'minSdkVersion flutter.minSdkVersion' in content:
            content = content.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 21')
            print("Successfully updated minSdkVersion to 21 in build.gradle.")
            
        # Register proguard files inside release buildType
        if 'signingConfig signingConfigs.debug' in content and 'proguardFiles' not in content:
            proguard_lines = "signingConfig signingConfigs.debug\n            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'"
            content = content.replace('signingConfig signingConfigs.debug', proguard_lines)
            print("Successfully added Proguard rules path to build.gradle.")
            
        with open(gradle_path, 'w') as f:
            f.write(content)
    else:
        print("ERROR: build.gradle not found at " + gradle_path)

    # 2. Modify android/app/src/main/AndroidManifest.xml
    manifest_path = os.path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')
    if os.path.exists(manifest_path):
        with open(manifest_path, 'r') as f:
            content = f.read()
        
        permissions = (
            '    <uses-permission android:name="android.permission.CAMERA" />\n'
            '    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />\n'
            '    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />'
        )
        
        if 'android.permission.CAMERA' not in content:
            content = content.replace('<application', permissions + '\n    <application')
            print("Successfully injected camera and storage permissions into Manifest.")

        ucrop_activity = (
            '        <activity\n'
            '            android:name="com.yalantis.ucrop.UCropActivity"\n'
            '            android:screenOrientation="portrait"\n'
            '            android:theme="@style/Theme.App.UCrop"/>'
        )
        
        if 'com.yalantis.ucrop.UCropActivity' not in content:
            idx = content.find('<application')
            if idx != -1:
                end_idx = content.find('>', idx)
                if end_idx != -1:
                    content = content[:end_idx+1] + '\n' + ucrop_activity + content[end_idx+1:]
                    print("Successfully registered UCropActivity in Manifest.")
            else:
                print("ERROR: Could not locate <application tag in Manifest.")
        elif '@style/Theme.AppCompat.Light.NoActionBar' in content:
            content = content.replace('@style/Theme.AppCompat.Light.NoActionBar', '@style/Theme.App.UCrop')
            print("Successfully updated UCropActivity theme to @style/Theme.App.UCrop in Manifest.")
                
        with open(manifest_path, 'w') as f:
            f.write(content)
    else:
        print("ERROR: AndroidManifest.xml not found at " + manifest_path)

    # 3. Modify styles.xml to add custom UCrop theme with fitsSystemWindows
    styles_paths = [
        os.path.join('android', 'app', 'src', 'main', 'res', 'values', 'styles.xml'),
        os.path.join('android', 'app', 'src', 'main', 'res', 'values-night', 'styles.xml')
    ]
    ucrop_style = (
        '    <style name="Theme.App.UCrop" parent="Theme.AppCompat.Light.NoActionBar">\n'
        '        <item name="android:fitsSystemWindows">true</item>\n'
        '    </style>\n'
    )
    for styles_path in styles_paths:
        if os.path.exists(styles_path):
            with open(styles_path, 'r') as f:
                content = f.read()
            if 'Theme.App.UCrop' not in content:
                content = content.replace('</resources>', ucrop_style + '</resources>')
                with open(styles_path, 'w') as f:
                    f.write(content)
                print(f"Successfully added Theme.App.UCrop to {styles_path}")

    # 4. Create android/app/proguard-rules.pro to ignore missing ML Kit classes and prevent R8 stripping
    proguard_path = os.path.join('android', 'app', 'proguard-rules.pro')
    proguard_rules = (
        "-keep class com.google.mlkit.** { *; }\n"
        "-keep interface com.google.mlkit.** { *; }\n"
        "-dontwarn com.google.mlkit.**\n"
        "-dontwarn com.google.mlkit.vision.text.**\n"
    )
    with open(proguard_path, 'w') as f:
        f.write(proguard_rules)
    print("Successfully generated proguard-rules.pro with ML Kit keep rules.")

if __name__ == '__main__':
    patch_project()
