
import os
import json
import pyphen
from pathlib import Path

# Config
DATA_DIR = Path("assets/data")
OUTPUT_FILE = Path("words_list_phonetic.txt")

# Pyphen for initial segmentation
dic = pyphen.Pyphen(lang='fr')

def get_oral_syllables(word):
    """
    Segmentation 'morceaux de voix' (Oral segments).
    Heuristic for PS/MS:
    - Initial split from pyphen.
    - Merge final silent 'e' syllable with previous one.
    """
    hyphenated = dic.inserted(word)
    if not hyphenated:
        return [word]
    
    parts = hyphenated.split('-')
    
    # Pedagogical refinement:
    # If the word ends with 'e' preceded by a consonant, 
    # it corresponds to a single oral chunk in many contexts, 
    # but the user said "ma / man", "so / leil".
    
    # Rule 1: Remove trailing empty or trivial segments
    parts = [p for p in parts if p.strip()]
    
    # Rule 2: Merge final silent 'e' chunk if it's very short (consonant + e)
    # Actually, for "banane", pyphen gives "ba-na-ne". 
    # Orally PS: "ba - nane"
    if len(parts) > 1:
        last = parts[-1]
        vowels = "aeiouyéèêëàâîïôöùûü"
        # If last part is just 'e' or consonant + 'e'
        if last.endswith('e'):
            # Check if there are other vowels in the last part
            has_other_vowels = any(v in last[:-1] for v in vowels)
            if not has_other_vowels:
                # Merge with previous
                parts[-2] = parts[-2] + parts[-1]
                parts.pop()
                
    return parts

def run():
    print(f"Scanning {DATA_DIR}...")
    results = []
    
    # walk recursively
    for root, dirs, files in os.walk(DATA_DIR):
        for file in files:
            if file.endswith(".json"):
                json_path = Path(root) / file
                try:
                    with open(json_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    
                    word = data.get('mot', '')
                    if word:
                        # Apply oral split
                        syllabes = get_oral_syllables(word)
                        segmentation = " / ".join(syllabes)
                        results.append(f"{word} : {segmentation}")
                except Exception as e:
                    print(f"Error processing {file}: {e}")

    # Sort results by word
    results.sort()
    
    # Write output
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write("\n".join(results) + "\n")
        
    print(f"✅ Generated {OUTPUT_FILE} with {len(results)} items.")

if __name__ == "__main__":
    run()
