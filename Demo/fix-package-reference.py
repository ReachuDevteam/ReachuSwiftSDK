#!/usr/bin/env python3
"""
Script to fix local package reference in Xcode project.pbxproj
Removes the old reference and adds it correctly.
"""

import re
import sys
import os

def fix_project_pbxproj(project_path, sdk_relative_path="../../"):
    pbxproj_path = os.path.join(project_path, "project.pbxproj")
    
    if not os.path.exists(pbxproj_path):
        print(f"❌ project.pbxproj not found at {pbxproj_path}")
        return False
    
    print(f"📝 Reading {pbxproj_path}...")
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Backup
    backup_path = pbxproj_path + ".backup"
    with open(backup_path, 'w') as f:
        f.write(content)
    print(f"✅ Backup created: {backup_path}")
    
    # Fix the relative path if it exists
    content = re.sub(
        r'relativePath = [^;]+;',
        f'relativePath = {sdk_relative_path};',
        content
    )
    
    print(f"✅ Set relativePath to: {sdk_relative_path}")
    
    # Write back
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print("✅ project.pbxproj updated")
    return True

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 fix-package-reference.py <path-to-xcodeproj>")
        sys.exit(1)
    
    project_path = sys.argv[1]
    sdk_relative_path = sys.argv[2] if len(sys.argv) > 2 else "../.."
    
    print("🔧 Fixing Xcode package reference...")
    print(f"📁 Project: {project_path}")
    print(f"🔗 SDK Path: {sdk_relative_path}")
    print()
    
    if fix_project_pbxproj(project_path, sdk_relative_path):
        print()
        print("✅ Done! Now:")
        print("1. Open the project in Xcode")
        print("2. Go to Project → Package Dependencies")
        print("3. Remove the SDK package if it shows with errors")
        print("4. Add it again: + → Add Local → Select SDK root folder")
    else:
        print("❌ Failed to fix project")
        sys.exit(1)

if __name__ == "__main__":
    main()

