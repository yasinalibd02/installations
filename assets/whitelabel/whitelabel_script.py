import sys
import os
import base64
import glob

def main():
    if len(sys.argv) < 5:
        print("Usage: python3 process.py <app_name> <package_name> <domain> <logo_base64>")
        sys.exit(1)

    app_name = sys.argv[1]
    package_name = sys.argv[2]
    domain = sys.argv[3]
    logo_base64 = sys.argv[4]

    print(f"Processing: {app_name}, {package_name}, {domain}")

    # 1. Handle Logo
    try:
        logo_data = base64.b64decode(logo_base64)
        # Assuming standard Flutter structure. Modify paths if needed.
        # Android
        os.makedirs("android/app/src/main/res/mipmap-xxxhdpi", exist_ok=True) 
        # Ideally we should generate multiple sizes, but for this MVP we'll just overwrite the main asset or 
        # put it in assets/res as requested.
        # The prompt said: "Overwrites the app_icon.png in the assets/res folder."
        os.makedirs("assets/res", exist_ok=True)
        with open("assets/res/app_icon.png", "wb") as f:
            f.write(logo_data)
        print("Logo saved to assets/res/app_icon.png")
    except Exception as e:
        print(f"Error saving logo: {e}")

    # 2. Update AndroidManifest.xml (Label)
    update_file("android/app/src/main/AndroidManifest.xml", 'android:label="', f'android:label="{app_name}"')
    
    # 3. Update Info.plist (CFBundleName)
    update_file("ios/Runner/Info.plist", "<key>CFBundleName</key>\n\t<string>", f"<key>CFBundleName</key>\n\t<string>{app_name}</string>", multiline=True)

    # 4. Update config.dart
    # Assuming lib/config.dart has a line like: static const String baseUrl = "...";
    # We will just append or replace.
    config_path = "lib/config.dart"
    if os.path.exists(config_path):
        with open(config_path, "r") as f:
            content = f.read()
        
        # Simple string replacement for now, or regex if we want to be robust
        # This is a basic implementation
        new_content = f"// Config updated by automation\nconst String domainName = '{domain}';\n" + content
        with open(config_path, "w") as f:
            f.write(new_content)
        print("Updated config.dart")
    else:
        print("lib/config.dart not found, creating it.")
        with open(config_path, "w") as f:
            f.write(f"const String domainName = '{domain}';\n")

    # 5. Change Package Name
    # This is complex. We will do basic string replacements in build.gradle and MainActivity
    # A full package rename involves moving directories which is risky in a simple script without `change_app_package_name` package.
    # We will try to replace where it matters most for the APK ID.
    
    print("Updating package name in build.gradle...")
    update_file("android/app/build.gradle", "applicationId ", f'applicationId "{package_name}"')
    
    # Update MainActivity.kt / java
    # Find the file first
    kt_files = glob.glob("android/app/src/main/kotlin/**/*.kt", recursive=True)
    java_files = glob.glob("android/app/src/main/java/**/*.java", recursive=True)
    
    for file_path in kt_files + java_files:
        update_file(file_path, "package ", f"package {package_name}")

    print("Automation script completed.")

def update_file(path, search_str, replace_line, multiline=False):
    if not os.path.exists(path):
        print(f"File not found: {path} - skipping")
        return

    try:
        with open(path, "r") as f:
            lines = f.readlines()
        
        with open(path, "w") as f:
            if multiline:
                # Basic handling for xml structure
                # This logic is very specific and simplified. 
                # Ideally use ElementTree or plistlib.
                # For this MVP, we will rely on sed-like behavior on the file content.
                content = "".join(lines)
                # This is tricky without regex. 
                # Let's assume we use sed in the shell for some parts if this is too weak.
                pass 
            else:
                for line in lines:
                    if search_str in line and not line.strip().startswith("//"):
                        if 'applicationId' in search_str:
                             f.write(f'        applicationId "{sys.argv[2]}"\n')
                        elif 'package ' in search_str: # kotlin/java package
                             f.write(f"package {sys.argv[2]}\n")
                        elif 'android:label' in search_str:
                             # preserving indentation is hard, but let's try
                             f.write(line.split('android:label')[0] + f'android:label="{sys.argv[1]}"\n')
                        else:
                             f.write(line)
                    else:
                        f.write(line)
    except Exception as e:
        print(f"Error updating {path}: {e}")

    # Re-reading for the tricky multiline replace for Info.plist if needed, 
    # but for now let's use the provided simple logic or enhance it.
    if multiline and 'Info.plist' in path:
        with open(path, "r") as f:
            content = f.read()
        import re
        # Regex to replace CFBundleName string
        content = re.sub(r'(<key>CFBundleName</key>[\s\n]*<string>)(.*?)(</string>)', fr'\1{sys.argv[1]}\3', content)
        with open(path, "w") as f:
            f.write(content)

if __name__ == "__main__":
    main()
