
import os
import json
import shutil
from pathlib import Path

# Config
SOURCE_DIR = Path("./images_lecture_syllabique")
DEST_IMAGES = Path("assets/images")
DEST_DATA = Path("assets/data")

def migrate():
    count = 0
    if not SOURCE_DIR.exists():
        print(f"Source {SOURCE_DIR} not found!")
        return

    # Ensure dest dirs exist
    DEST_IMAGES.mkdir(parents=True, exist_ok=True)
    DEST_DATA.mkdir(parents=True, exist_ok=True)

    for root, dirs, files in os.walk(SOURCE_DIR):
        for file in files:
            src_path = Path(root) / file
            
            # Determine relative path (theme)
            rel_path = src_path.relative_to(SOURCE_DIR)
            theme = rel_path.parent.name if rel_path.parent.name else "default"
            
            # Create theme subdirs
            (DEST_IMAGES / theme).mkdir(exist_ok=True)
            (DEST_DATA / theme).mkdir(exist_ok=True)

            if file.endswith(".jpg"):
                dest_path = DEST_IMAGES / theme / file
                shutil.copy2(src_path, dest_path)
            
            elif file.endswith(".json"):
                # Read JSON
                with open(src_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                # Add image path
                image_filename = file.replace('.json', '.jpg')
                # Flutter path uses forward slashes
                flutter_image_path = f"assets/images/{theme}/{image_filename}"
                data['image_path'] = flutter_image_path
                
                # SRS Defaults (Level 1, etc. as discussed)
                if 'level' not in data:
                    data['level'] = 1
                if 'success_count' not in data:
                    data['success_count'] = 0

                # Save to new location
                dest_path = DEST_DATA / theme / file
                with open(dest_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=4)
                
                count += 1

    print(f"Migration complete! Processed {count} items.")

if __name__ == "__main__":
    migrate()
