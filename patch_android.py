import os

def patch_project():
    print("Starting Android project patching...")
    
    # 1. Modify android/app/build.gradle to set minSdkVersion to 21
    gradle_path = os.path.join('android', 'app', 'build.gradle')
    if os.path.exists(gradle_path):
        with open(gradle_path, 'r') as f:
            content = f.read()
        
        # Replace minSdkVersion flutter.minSdkVersion with minSdkVersion 21
        if 'minSdkVersion flutter.minSdkVersion' in content:
            content = content.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 21')
            with open(gradle_path, 'w') as f:
                f.write(content)
            print("Successfully updated minSdkVersion to 21 in build.gradle.")
        else:
            print("minSdkVersion already modified or different structure in build.gradle.")
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
            '            android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>'
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
                
        with open(manifest_path, 'w') as f:
            f.write(content)
    else:
        print("ERROR: AndroidManifest.xml not found at " + manifest_path)

if __name__ == '__main__':
    patch_project()
