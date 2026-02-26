import os
import json

# Chemin vers les fichiers
TXT_FILE = "mots_decoupesV4.txt"
JSON_DIR = "assets/data"

def get_accented_words():
    """Lit le fichier texte et retourne un dictionnaire {mot_sans_accent (minuscule): mot_avec_accent}"""
    accented_dict = {}
    
    if not os.path.exists(TXT_FILE):
        print(f"Erreur: Le fichier {TXT_FILE} n'existe pas.")
        return {}
        
    with open(TXT_FILE, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            # Ignorer les lignes vides, l'en-tête et la ligne de total
            if not line or line.startswith("=") or line.startswith("Liste") or line.startswith("Total:"):
                continue
                
            parts = line.split("\t")
            if len(parts) >= 1:
                accented_word = parts[0].strip()
                # On utilise une version la plus brute possible comme clé pour le match avec le JSON actuel
                import unicodedata
                unaccented = ''.join(c for c in unicodedata.normalize('NFD', accented_word)
                                    if unicodedata.category(c) != 'Mn').lower()
                
                accented_dict[unaccented] = accented_word
                # On ajoute aussi le mot accentué lui-même comme clé, au cas où il soit déjà partiellemnt accentué
                accented_dict[accented_word.lower()] = accented_word
                
    return accented_dict

def update_json_files(accented_dict):
    """Parcourt les JSON et met à jour le champ 'mot' si une version accentuée existe"""
    
    if not os.path.exists(JSON_DIR):
        print(f"Directory {JSON_DIR} not found.")
        return
        
    updated_count = 0
    total_count = 0
    
    for theme_dir in os.listdir(JSON_DIR):
        theme_path = os.path.join(JSON_DIR, theme_dir)
        if not os.path.isdir(theme_path):
            continue
            
        for file in os.listdir(theme_path):
            if not file.endswith(".json"):
                continue
                
            total_count += 1
            file_path = os.path.join(theme_path, file)
            
            with open(file_path, "r", encoding="utf-8") as f:
                try:
                    data = json.load(f)
                except Exception as e:
                    print(f"Erreur de lecture {file_path}: {e}")
                    continue
            
            if "mot" in data:
                current_word = data["mot"]
                
                # Normalisation pour la recherche
                import unicodedata
                current_unaccented = ''.join(c for c in unicodedata.normalize('NFD', current_word)
                                    if unicodedata.category(c) != 'Mn').lower()
                                    
                if current_unaccented in accented_dict:
                    correct_word = accented_dict[current_unaccented]
                    
                    if current_word != correct_word:
                        print(f"Correction: {current_word}  ->  {correct_word} ({file})")
                        data["mot"] = correct_word
                        
                        # On sauvegarde
                        with open(file_path, "w", encoding="utf-8") as f:
                            json.dump(data, f, ensure_ascii=False, indent=2)
                        updated_count += 1
                else:
                    # Cas spécifiques (ex: les mots avec articles dans le JSON mais pas dans le txt)
                    # ou les mots pas présents.
                    pass
                    
    print(f"\nTerminé ! {updated_count} fichiers JSON mis à jour sur {total_count} analysés.")

if __name__ == "__main__":
    print("Analyse du fichier de référence...")
    accented_words = get_accented_words()
    print(f"{len(accented_words) // 2} mots uniques trouvés dans le dictionnaire.")
    
    print("\nMise à jour des fichiers JSON...")
    update_json_files(accented_words)
