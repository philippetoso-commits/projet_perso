
import re
import json
import os

import unicodedata

def normalize_filename(word):
    word = word.strip()
    # Normalize unicode characters to their base form (NFD splits accents)
    nfkd_form = unicodedata.normalize('NFD', word)
    # Filter out non-spacing mark characters (accents)
    only_ascii = "".join([c for c in nfkd_form if not unicodedata.combining(c)])
    # Remove any remaining non-alphanumeric (keep spaces as _)
    clean = re.sub(r'[^a-zA-Z0-9]', '_', only_ascii)
    return clean.lower()

def main():
    source_file = 'source_words.md'
    output_file = '../scenarios.json'
    
    scenarios = []
    
    with open(source_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    count = 0
    for line in lines:
        if not line.startswith('|'):
            continue
            
        parts = line.split('|')
        if len(parts) < 3:
            continue
            
        word = parts[1].strip()
        if not word or word.lower() == 'mot' or word.startswith('---'):
            continue
            
        filename = normalize_filename(word) + ".wav"
        
        # Determine strictness/level
        # Default to GS for balanced testing
        level = "gs" 
        
        scenario = {
            "id": f"audit_{count:03d}_{normalize_filename(word)}",
            "word": word,
            "level": level,
            "audio_file": f"assets/tests/audio/{filename}",
            "expected_result": "success",
            "notes": "Audit complet du catalogue."
        }
        
        scenarios.append(scenario)
        count += 1
        
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(scenarios, f, indent=4)
        
    print(f"✅ Generated {len(scenarios)} scenarios in {output_file}")

if __name__ == '__main__':
    main()
