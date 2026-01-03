import yaml
import subprocess
import os
import sys
import glob

def increment_version(version_str, new_v_name=None):
    # version format: 1.0.0+1
    base_version, build_number = version_str.split('+')
    new_build_number = int(build_number) + 1
    
    final_v_name = new_v_name if new_v_name else base_version
    return f"{final_v_name}+{new_build_number}", final_v_name, new_build_number

def run_command(command, cwd=None):
    print(f"Running: {command}")
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, cwd=cwd)
    for line in process.stdout:
        print(line, end='')
    process.wait()
    return process.returncode

def main():
    pubspec_path = 'pubspec.yaml'
    
    if not os.path.exists(pubspec_path):
        print(f"Error: {pubspec_path} not found. Run this from the flutter project root.")
        return

    # 1. Read optional version name from args
    new_v_name_arg = sys.argv[1] if len(sys.argv) > 1 else None

    # 2. Read pubspec
    with open(pubspec_path, 'r') as f:
        config = yaml.safe_load(f)
    
    old_version = config.get('version', '1.0.0+1')
    new_version, v_name, v_code = increment_version(old_version, new_v_name_arg)
    
    print(f"Old Version: {old_version}")
    print(f"New Version: {new_version}")

    # 3. Update pubspec
    with open(pubspec_path, 'r') as f:
        lines = f.readlines()
    
    with open(pubspec_path, 'w') as f:
        for line in lines:
            if line.strip().startswith('version:'):
                f.write(f"version: {new_version}\n")
            else:
                f.write(line)

    print("Pubspec updated.")

    # 3. Clean and Build
    run_command("flutter clean")
    run_command("flutter pub get")
    
    build_result = run_command("flutter build apk --release")
    
    if build_result != 0:
        print("Build failed!")
        return

    # 4. Find and Rename APK
    # Search recursively for app-release.apk or SkaagPay.apk in the build outputs
    apk_patterns = [
        'build/app/outputs/flutter-apk/app-release.apk',
        'build/app/outputs/apk/release/app-release.apk',
        'build/**/app-release.apk'
    ]
    
    found_apk = None
    for pattern in apk_patterns:
        matches = glob.glob(pattern, recursive=True)
        if matches:
            found_apk = matches[0]
            break
    
    target_path = 'build/app/outputs/flutter-apk/SkaagPay.apk'
    # Ensure target directory exists for renamed APK
    os.makedirs(os.path.dirname(target_path), exist_ok=True)

    if found_apk:
        if os.path.exists(target_path):
            os.remove(target_path)
        os.rename(found_apk, target_path)
        print(f"APK found at {found_apk} and renamed to: {target_path}")
    else:
        print("Error: Could not find build output APK (app-release.apk).")

    print("\n" + "="*40)
    print("RELEASE COMPLETE")
    print("="*40)
    print(f"Version Name: {v_name}")
    print(f"Version Code: {v_code}")
    print(f"File: SkaagPay.apk")
    print("\nACTION REQUIRED: Upload this APK to your backend with these version details.")
    print("="*40)

if __name__ == "__main__":
    main()
