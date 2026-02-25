import os
import shutil

base_src = "images_lecture_syllabique"
base_dest_img = os.path.join("app_lecture", "assets", "images")
base_dest_data = os.path.join("app_lecture", "assets", "data")

os.makedirs(base_dest_img, exist_ok=True)
os.makedirs(base_dest_data, exist_ok=True)

themes_added = set()

for root, dirs, files in os.walk(base_src):
    for f in files:
        src_path = os.path.join(root, f)
        rel_dir = os.path.relpath(root, base_src)
        
        if rel_dir == ".": continue
            
        themes_added.add(rel_dir)
            
        if f.endswith('.jpg'):
            dest_dir = os.path.join(base_dest_img, rel_dir)
            os.makedirs(dest_dir, exist_ok=True)
            shutil.copy2(src_path, os.path.join(dest_dir, f))
            
        elif f.endswith('.json'):
            dest_dir = os.path.join(base_dest_data, rel_dir)
            os.makedirs(dest_dir, exist_ok=True)
            shutil.copy2(src_path, os.path.join(dest_dir, f))

print(f"Migrated assets for themes: {themes_added}")

# Update pubspec
pubspec_path = os.path.join("app_lecture", "pubspec.yaml")
with open(pubspec_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
in_assets = False
existing_assets = set()

for line in lines:
    if line.strip().startswith("- assets/images/") or line.strip().startswith("- assets/data/"):
        existing_assets.add(line.strip())

for line in lines:
    new_lines.append(line)
    if line.strip() == "assets:":
        in_assets = True
        
    if in_assets and line.strip() == "- assets/images/vetements/":
        for theme in themes_added:
            line_to_add = f"- assets/images/{theme}/"
            if line_to_add not in existing_assets:
                new_lines.append(f"    {line_to_add}\n")

    if in_assets and line.strip() == "- assets/data/vetements/":
        for theme in themes_added:
            line_to_add = f"- assets/data/{theme}/"
            if line_to_add not in existing_assets:
                new_lines.append(f"    {line_to_add}\n")
        in_assets = False

with open(pubspec_path, "w", encoding="utf-8") as f:
    f.writelines(new_lines)
print("Updated pubspec.yaml")
