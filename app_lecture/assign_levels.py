import os
import json
import glob
import unicodedata

# Rules from Reference Document
# Level 1 (PS): 1 syllable, simple sounds.
# Level 2 (MS): 2 syllables, simple sounds.
# Level 3 (GS): 3 syllables OR sounds [ou, on, an, en, in, oi, ai, au].
# Level 4 (CP): 4+ syllables OR sounds [gn, ill, eau, eu, oeu]. (Override GS)

LEVEL_PS = 1
LEVEL_MS = 2
LEVEL_GS = 3
LEVEL_CP = 4

# Sound Complexity (normalized text)
SOUNDS_CP = ['gn', 'ill', 'eau', 'eu', 'oeu']
SOUNDS_GS = ['ou', 'on', 'an', 'en', 'in', 'oi', 'ai', 'au']

def remove_accents(input_str):
    if not input_str:
        return ""
    nfkd_form = unicodedata.normalize('NFKD', input_str)
    return "".join([c for c in nfkd_form if not unicodedata.combining(c)])

def determine_level(word_text, syllables):
    norm_text = remove_accents(word_text.lower())
    count = len(syllables)
    
    # 1. Check CP sounds (Highest priority)
    for sound in SOUNDS_CP:
        if sound in norm_text:
            return LEVEL_CP
            
    # 2. Check GS sounds
    for sound in SOUNDS_GS:
        if sound in norm_text:
            return LEVEL_GS
            
    # 3. Fallback to syllable count
    if count == 1:
        return LEVEL_PS
    elif count == 2:
        return LEVEL_MS
    elif count == 3:
        return LEVEL_GS
    else:
        return LEVEL_CP # 4+ syllables

# iterate and update
json_files = glob.glob('assets/data/**/*.json', recursive=True)
stats = {1: 0, 2: 0, 3: 0, 4: 0}

for file_path in json_files:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        mot = data.get('mot', '')
        syllabes = data.get('syllabes', [])
        
        level = determine_level(mot, syllabes)
        data['level'] = level
        
        stats[level] += 1
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4, ensure_ascii=False)

    except Exception as e:
        print(f"Error {file_path}: {e}")

print("Level assignment complete.")
print(f"PS (1): {stats[1]}")
print(f"MS (2): {stats[2]}")
print(f"GS (3): {stats[3]}")
print(f"CP (4): {stats[4]}")
