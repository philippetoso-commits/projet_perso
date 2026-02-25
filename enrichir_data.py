
import os
import json
import pyphen
from pathlib import Path

# Configuration
# On se base sur le dossier où se trouve le script (plus robuste)
# Cela marchera sur Windows ET dans n8n (/data/projet_perso/...)
SCRIPT_DIR = Path(__file__).parent.resolve()
BASE_DIR = SCRIPT_DIR / "images_lecture_syllabique"
# Initialiser Pyphen pour le français
dic = pyphen.Pyphen(lang='fr')

def get_syllables(word):
    """
    Découpe un mot en syllabes en utilisant Pyphen.
    Gère les cas où Pyphen ne renvoie pas de tirets (mots courts).
    """
    # Pyphen renvoie "é-lé-phant"
    hyphenated = dic.inserted(word)
    if hyphenated:
        parts = hyphenated.split('-')
    else:
        parts = [word]

    # Heuristique pédagogique (CP) :
    # Si le mot finit par "e" (muet) précédé d'une consonne, Pyphen a tendance à coller.
    # Ex: "soupe" -> "soupe" (Pyphen) vs "sou-pe" (Attendu CP)
    # Ex: "lampe" -> "lampe" -> "lam-pe"
    
    final_parts = []
    vowels = "aeiouyéèêëàâîïôöùûü"
    
    for part in parts:
        # Si la partie finit par 'e' et contient une voyelle avant (pour éviter 'de', 'le')
        # et n'est pas déjà coupée
        if len(part) > 3 and part.endswith('e') and part[-2] not in vowels:
             # On coupe avant la consonne finale : sou-pe
             # Sauf si c'est un digraphe comme 'ch', 'ph', 'gn', 'tr', 'bl'... 
             # Simplification: on coupe avant la dernière consonne.
             
             split_index = len(part) - 2
             # Check for double consonne or digraphs roughly
             if part[split_index-1] not in vowels and part[split_index-1] != part[split_index]:
                 # ex: 'sucre' -> 'su-cre' (c+r)
                 # Si 'tr', 'bl', 'cl' -> on coupe avant le groupe? 
                 # Pyphen gère souvent bien 'table' -> 'ta-ble'.
                 # Soupe -> So-upe ? Non Sou-pe.
                 pass
             
             # Cas simple: Voyelle + Consonne + e -> Voyelle-Consonne + e
             # Soupe -> Sou-pe
             base = part[:-2]
             end = part[-2:]
             final_parts.append(base)
             final_parts.append(end)
        else:
            final_parts.append(part)
            
    return final_parts

def enrich_files():
    if not BASE_DIR.exists():
        print(f"Le dossier {BASE_DIR} n'existe pas.")
        return

    count = 0
    # Parcourir récursivement tous les fichiers JSON
    for json_file in BASE_DIR.rglob("*.json"):
        try:
            # 1. Lire le fichier
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # 2. Vérifier si le champ 'mot' existe
            if 'mot' in data:
                word = data['mot']
                
                # 3. Générer les syllabes
                # Note: Le mot dans le JSON actuel semble ne pas avoir d'accents (ex: "elephant").
                # Pyphen fera de son mieux, mais idéalement il faudrait les accents.
                # Nous utilisons le mot tel qu'il est stocké.
                syllables = get_syllables(word)
                
                # Mise à jour des données
                data['syllabes'] = syllables
                data['syllabes_texte'] = " - ".join(syllables)
                
                # 4. Sauvegarder
                with open(json_file, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=4)
                
                print(f"Update: {word} -> {syllables}")
                count += 1
            
        except Exception as e:
            print(f"Erreur sur {json_file}: {e}")

    print(f"\nTerminé ! {count} fichiers mis à jour.")

if __name__ == "__main__":
    enrich_files()
