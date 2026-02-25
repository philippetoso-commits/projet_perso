import os
import json
import glob
import unicodedata
import shutil

# CONFIG : Phrase mappings for tool words (Mots Outils)
# User request: "LE CHAT", "JE mange"
# We map tool word -> (Target Phrase, Source Image Keyword)
TOOL_WORD_MAPPINGS = {
    "le": ("Le chat", "chat"),
    "la": ("La vache", "vache"),
    "un": ("Un loup", "loup"),
    "une": ("Une pomme", "pomme"),
    "les": ("Les frites", "frites"),
    "des": ("Des bonbons", "bonbon"), # bonbon.json exists? 'bonbon'
    "de": ("Pomme de terre", "pomme_de_terre"), # Contextual? "Jus de pomme"?
    "du": ("Du pain", "pain"),
    "il": ("Il dort", "dormir"),
    "elle": ("Elle chante", "chanter"),
    "je": ("Je mange", "manger"),
    "tu": ("Tu bois", "boire"),
    "nous": ("Nous courons", "courir"), # courir exists. 'courons' requires variation? 
                                        # Asset matching might be tricky if we don't have conjugated audio/text.
                                        # For now, let's Stick to simple ones or existing JSONs.
                                        # If "Je mange", we need "mange" syllable breakdown?
    "est": ("C'est un chat", "chat"), 
    "sur": ("Sur le vélo", "velo"),
    "dans": ("Dans le bus", "bus"),
    "avec": ("Avec maman", "maman"), # maman exists? maybe not.
    "pour": ("Pour toi", "cadeau"),
}

def remove_accents(input_str):
    if not input_str:
        return ""
    nfkd_form = unicodedata.normalize('NFKD', input_str)
    return "".join([c for c in nfkd_form if not unicodedata.combining(c)])

def normalize_key(text):
    return remove_accents(text.lower().strip())

# 1. Parse the progressive file
levels = {
    'PS': [],
    'MS': [],
    'GS': [],
    'CP_LEX': [],
    'CP_OUTILS': []
}

current_section = None

with open('liste_complete_triee_syllabique.txt', 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if not line: continue
        
        if line.startswith('#'):
            if 'PETITE SECTION' in line: current_section = 'PS'
            elif 'MOYENNE SECTION' in line: current_section = 'MS'
            elif 'GRANDE SECTION' in line: current_section = 'GS'
            elif 'DEBUT CP' in line: current_section = 'CP_LEX' # Mapped to CP
            continue
            
        if current_section:
            levels[current_section].append(line)

print(f"Parsed Levels: PS={len(levels['PS'])}, MS={len(levels['MS'])}, GS={len(levels['GS'])}, CP_LEX={len(levels['CP_LEX'])}, CP_TOOLS={len(levels['CP_OUTILS'])}")

# 2. Build a Map of existing JSON files for quick lookup
json_files = glob.glob('assets/data/**/*.json', recursive=True)
json_map = {} # normalized_key -> path

for path in json_files:
    with open(path, 'r', encoding='utf-8') as f:
        d = json.load(f)
        mot = d.get('mot', '')
        # Map both filename/mot to path
        json_map[normalize_key(mot)] = path
        basename = os.path.basename(path).replace('.json', '')
        json_map[normalize_key(basename)] = path

# 3. Process Lexical Words (Update Levels and Syllables)
section_level_map = {
    'PS': 1,
    'MS': 2,
    'GS': 3,
    'CP_LEX': 4,
    'CP_OUTILS': 4
}

for section, lines in levels.items():
    if section == 'CP_OUTILS': continue # Handle separately
    
    target_level = section_level_map[section]
    
    for line in lines:
        # line format: "ba-na-ne" or "chat" or "pom-me / de / ter-re"
        # Extract Clean Word
        raw_syllables = line.replace('/', '-').split('-')
        clean_syllables = [s.strip() for s in raw_syllables if s.strip()]
        
        # Reconstruct word from syllables (remove dashes/slashes)
        # Note: 'pom-me' -> 'pomme'. 'pom-me / de / ter-re' -> 'pomme de terre'
        # The line might create spaces if from slashes?
        # File "pom-me / de / ter-re" -> "pomme de terre"
        clean_mot = "".join(clean_syllables) 
        # Wait, simple join merges "pomme" "de" "terre" -> "pommedeterre" which is wrong.
        # We need to handle spaces based on original separators or just look up by "fuzzy" match.
        
        # Better approach: normalize the line to find the key
        normalized_lookup = normalize_key(line.replace('-', '').replace('/', '')) 
        # 'pom-me / de / ter-re' -> 'pommedeterre'
        
        # Find JSON
        # We need to check if we can find 'pommedeterre' in our map keys?
        # Our map keys are from json 'mot' (e.g. "pomme de terre") -> normalized "pommedeterre" matches?
        # Let's verify map keys normalization.
        
        path = None
        # Try direct match
        if normalized_lookup in json_map:
            path = json_map[normalized_lookup]
        else:
            # Try matching against keys which might have spaces
            # json key: "pomme de terre" -> norm "pomme de terre" (spaces kept?)
            pass

        # Let's refine json_map keys to remove spaces for matching
        # ... (Redoing map logic essentially)

for path in json_files:
     with open(path, 'r', encoding='utf-8') as f:
        d = json.load(f)
        mot = d.get('mot', '')
        
        # Normalize file mot for comparison
        # We check WHICH section this word belongs to.
        
        # Bruteforce/Reverse lookup:
        # For each word in our list, try to match this file.
        pass

# SIMPLER LOGIC: Iterate over the LIST, find the FILE, update it.
updated_files = set()

for section, lines in levels.items():
    if section == 'CP_OUTILS': continue

    target_level = section_level_map[section]
    
    for line in lines:
        # Construct lookup key
        # remove markers to find identifiers
        # "pom-me / de / ter-re" -> "pomme de terre"
        # "ba-na-ne" -> "banane"
        
        # Logic: Replace '-' with nothing. Replace '/' with space?
        # In file: "pom-me / de / ter-re" suggests / is word separator?
        # "jus / d’o-ran-ge"
        
        temp = line.replace(' / ', ' ') # handle explicit spaced separators
        temp = temp.replace('/', ' ') 
        temp = temp.replace('-', '')
        word_plain = temp.strip() # "pomme de terre", "banane"
        
        key = normalize_key(word_plain).replace(' ', '') # "pommedeterre"
        
        # Find path
        # Rebuild Map to be Space-Insensitive
        found_path = None
        for k, p in json_map.items():
            if k.replace(' ', '') == key:
                found_path = p
                break
        
        if found_path:
            # UPDATE
            try:
                with open(found_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                # Update Level
                data['level'] = target_level
                
                # Update Syllables (if line has dashes)
                if '-' in line or '/' in line:
                    # Parse syllables strictly from the line in the text file
                    # "ba-na-ne" -> ["ba", "na", "ne"]
                    # "pom-me / de / ter-re" -> ["pom", "me", "de", "ter", "re"]
                    
                    # split by - or / or space
                    import re
                    syls = re.split(r'[-\s/]+', line)
                    syls = [s for s in syls if s]
                    data['syllabes'] = syls
                
                with open(found_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=4, ensure_ascii=False)
                
                updated_files.add(found_path)
            except Exception as e:
                print(f"Error updating {found_path}: {e}")

print(f"Updated {len(updated_files)} lexical words.")

# 4. Handle Tool Words (Generate Phrases)
tool_dir = 'assets/data/mots_outils'
os.makedirs(tool_dir, exist_ok=True)

for tool_word in levels['CP_OUTILS']:
    tool_word = tool_word.strip()
    if not tool_word: continue
    
    mapping = TOOL_WORD_MAPPINGS.get(tool_word.lower())
    if mapping:
        phrase, image_keyword = mapping
        # phrases like "Le chat"
        # lookup image
        
        # Find image path from existing json matching keyword
        image_path = "assets/images/mascotte.png" # Default
        
        # convert keyword to path
        # Look in json_map
        keyword_key = normalize_key(image_keyword)
        ref_json_path = None
        for k, p in json_map.items():
             if k == keyword_key:
                 ref_json_path = p
                 break
        
        if ref_json_path:
            with open(ref_json_path, 'r', encoding='utf-8') as f:
                d = json.load(f)
                image_path = d.get('image_path', image_path)
        
        # Create JSON for the phrase
        filename = f"{tool_word}_{normalize_key(image_keyword)}.json" # le_chat.json
        full_path = os.path.join(tool_dir, filename)
        
        # Determine syllables for the phrase?
        # User wants "LE CHAT". Syllables: ["le", "chat"]?
        # Simple split by space
        phrase_syllables = phrase.split(' ') 
        # or reuse syllabic breakdown of the noun if known? 
        # "Le chat" -> "Le", "chat". "La pomme" -> "La", "pom", "me".
        
        new_word = {
            "mot": phrase,
            "syllabes": phrase_syllables, # Simplification
            "theme": "mots_outils",
            "image_path": image_path,
            "level": 4,
            "success_count": 0
        }
        
        with open(full_path, 'w', encoding='utf-8') as f:
            json.dump(new_word, f, indent=4, ensure_ascii=False)
            
        print(f"Created tool card: {phrase} ({full_path})")

