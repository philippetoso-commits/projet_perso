
import os
import json
import pyphen
from pathlib import Path

# Configuration
SCRIPT_DIR = Path(__file__).parent.resolve()
BASE_DIR = SCRIPT_DIR / "images_lecture_syllabique"
# Initialiser Pyphen pour le français
dic = pyphen.Pyphen(lang='fr')

def get_syllables(word):
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
    parts = [p for p in parts if p.strip()]
    
    if len(parts) > 1:
        last = parts[-1]
        vowels = "aeiouyéèêëàâîïôöùûü"
        if last.endswith('e'):
            has_other_vowels = any(v in last[:-1] for v in vowels)
            if not has_other_vowels:
                parts[-2] = parts[-2] + parts[-1]
                parts.pop()
                
    return parts

def enrich_files():
    if not BASE_DIR.exists():
        print(f"Le dossier {BASE_DIR} n'existe pas.")
        return

    count = 0
    for json_file in BASE_DIR.rglob("*.json"):
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)

            if 'mot' in data:
                word = data['mot']
                syllables = get_syllables(word)
                
                data['syllabes'] = syllables
                data['syllabes_texte'] = " - ".join(syllables)
                
                with open(json_file, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=4)
                
                count += 1
            
        except Exception as e:
            print(f"Erreur sur {json_file}: {e}")

    print(f"\nTerminé ! {count} fichiers mis à jour dans {BASE_DIR}.")

if __name__ == "__main__":
    enrich_files()
