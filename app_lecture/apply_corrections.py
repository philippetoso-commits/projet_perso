import os
import json
import glob
import unicodedata

def remove_accents(input_str):
    if not input_str:
        return ""
    nfkd_form = unicodedata.normalize('NFKD', input_str)
    return "".join([c for c in nfkd_form if not unicodedata.combining(c)])

# 1. Parse the correction file
corrections = {}
with open('liste_syllabique_corrigee_complete.txt', 'r', encoding='utf-8') as f:
    for line in f:
        if ':' in line:
            parts = line.strip().split(':')
            word_key = parts[0].strip()
            syllables_raw = parts[1].strip()
            syllables = [s.strip() for s in syllables_raw.replace('/', '-').split('-') if s.strip()]
            
            # Key = normalized (lowercase + no accents)
            norm_key = remove_accents(word_key.lower())
            
            corrections[norm_key] = {
                'mot': word_key, # Keep original accented version
                'syllabes': syllables
            }

print(f"Loaded {len(corrections)} corrections.")

# 2. Iterate over all JSON files
json_files = glob.glob('assets/data/**/*.json', recursive=True)
updated_count = 0

for file_path in json_files:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        current_mot = data.get('mot', '')
        norm_current = remove_accents(current_mot.lower())
        
        # Try to find correction
        if norm_current in corrections:
            correction = corrections[norm_current]
            
            # Update fields
            data['mot'] = correction['mot']
            data['syllabes'] = correction['syllabes']
            
            # Save back
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=4, ensure_ascii=False)
            
            updated_count += 1
            # print(f"Updated {file_path}: {current_mot} -> {correction['mot']}")
            
        else:
            # Check if filename helps?
            basename = os.path.basename(file_path).replace('.json', '')
            norm_base = remove_accents(basename.lower())
            
            if norm_base in corrections:
                 correction = corrections[norm_base]
                 data['mot'] = correction['mot']
                 data['syllabes'] = correction['syllabes']
                 with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=4, ensure_ascii=False)
                 updated_count += 1
                 # print(f"Updated by filename {file_path}: {correction['mot']}")

    except Exception as e:
        print(f"Error processing {file_path}: {e}")

print(f"Updated {updated_count} JSON files.")
