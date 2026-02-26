import os
import json

base_dir = r"c:\Users\phili\AndroidStudioProjects\projet_perso\app_lecture"
v4_file = os.path.join(base_dir, "mots_decoupesV4.txt")
data_dir = os.path.join(base_dir, "assets", "data")

# Load V4 words
v4_words = set()
with open(v4_file, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("=") or line.startswith("Liste") or line.startswith("Total"):
            continue
        parts = line.split('\t')
        if len(parts) > 0:
            word = parts[0].strip().lower()
            v4_words.add(word)

missing_entries = []

for root, dirs, files in os.walk(data_dir):
    for file in files:
        if file.endswith(".json"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as jf:
                try:
                    data = json.load(jf)
                    mot = data.get("mot", "").strip().lower()
                    if mot and mot not in v4_words:
                        syllabes_texte = data.get("syllabes_texte", "")
                        if not syllabes_texte and "syllabes" in data:
                            syllabes_texte = "-".join(data["syllabes"])
                        missing_entries.append(f"{mot}\t{syllabes_texte}")
                except Exception as e:
                    pass

print(f"Total V4 words: {len(v4_words)}")
print(f"Found {len(missing_entries)} missing JSON words not in V4:")
for entry in missing_entries:
    print(f" - {entry}")

# Append to V4 file
if missing_entries:
    with open(v4_file, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Remove the total line at the bottom if it exists
    lines = content.split('\n')
    while lines and (lines[-1].startswith("Total:") or lines[-1].strip() == ""):
        lines.pop()
    
    lines.append("")
    for entry in missing_entries:
        lines.append(entry)
    
    new_total = len(v4_words) + len(missing_entries)
    lines.append("")
    lines.append(f"Total: {new_total} mots")
    lines.append("")
    
    with open(v4_file, "w", encoding="utf-8") as f:
        f.write('\n'.join(lines))
        
    print(f"\n=> Successfully appended {len(missing_entries)} words to {v4_file}.")
    print(f"=> New File Total: {new_total} mots")
