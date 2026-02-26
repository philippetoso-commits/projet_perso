import os
import json

base_dir = r"c:\Users\phili\AndroidStudioProjects\projet_perso\app_lecture"
v4_file = os.path.join(base_dir, "mots_decoupesV4.txt")
data_dir = os.path.join(base_dir, "assets", "data")

# 1. Parse V4 words
# format: mot \t syllabe1-syllabe2
v4_dict = {}
with open(v4_file, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("=") or line.startswith("Liste") or line.startswith("Total"):
            continue
        parts = line.split('\t')
        if len(parts) >= 2:
            word = parts[0].strip().lower()
            syllabes_texte = parts[1].strip()
            v4_dict[word] = syllabes_texte

# 2. Iterate and update JSONs
modified_count = 0

for root, dirs, files in os.walk(data_dir):
    for file in files:
        if file.endswith(".json"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as jf:
                try:
                    data = json.load(jf)
                except Exception as e:
                    print(f"Error loading {path}: {e}")
                    continue
            
            mot = data.get("mot", "").strip().lower()
            if mot in v4_dict:
                v4_syllabes_texte = v4_dict[mot]
                v4_syllabes_array = [s for s in v4_syllabes_texte.split('-') if s.strip()]
                
                current_array = data.get("syllabes", [])
                current_texte = data.get("syllabes_texte", "")
                
                # Check if an update is needed
                if current_array != v4_syllabes_array or current_texte != v4_syllabes_texte:
                    data["syllabes"] = v4_syllabes_array
                    data["syllabes_texte"] = v4_syllabes_texte
                    
                    with open(path, "w", encoding="utf-8") as jf:
                        json.dump(data, jf, ensure_ascii=False, indent=2)
                    modified_count += 1
#                    print(f"Updated {mot}")

print(f"SYNC COMPLETE. Modified {modified_count} files.")
