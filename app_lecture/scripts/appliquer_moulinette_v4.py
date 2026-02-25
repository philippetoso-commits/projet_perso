# -*- coding: utf-8 -*-
"""
Moulinette légère pour découpe proche de l'oreille (apprentissage de la lecture).
Objectif : garder le maximum de mots découpés en syllabes ; ne fusionner que quand
un graphème complexe est vraiment coupé à la frontière (ex. "a"+"u" → "au"),
pas quand il est entier dans une syllabe (ex. garder "gât-eau").
Lit mots_decoupesV3.txt → écrit mots_decoupesV4.txt + rapport_corrections.csv
"""
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# -------------------------
# CONFIGURATION
# -------------------------

GRAPHÈMES_COMPLEXES = [
    "eau", "au", "ai", "oi", "ou",
    "an", "en", "on", "in", "un",
    "ch", "gn", "qu"
]

GROUPES_CONSONANTIQUES = [
    "tr", "pr", "br", "dr", "cr", "fr",
    "pl", "bl", "gl", "cl"
]

VOYELLES = "aeiouyàâäéèêëîïôöùûüÿœ"

# Découpage proche de l'oreille : ne pas fusionner les groupes consonantiques
# (sinon on perd des syllabes comme pois-son, cha-mpi-gnon)
APPLIQUER_GROUPES_CONSONANTIQUES = False

# -------------------------
# FONCTIONS
# -------------------------


def contient_voyelle(s):
    return any(c in VOYELLES for c in s.lower())


def corriger_graphèmes(mot, syllabes):
    """
    Fusionne UNIQUEMENT si un graphème complexe est coupé à la frontière
    (ex. "a"+"u" → "au"). Ne fusionne PAS si le graphème est déjà entier
    dans une syllabe (ex. garder "gât-eau" car "eau" est entier dans la 2e).
    """
    i = 0
    while i < len(syllabes) - 1:
        s1, s2 = syllabes[i], syllabes[i + 1]
        merged = False
        for g in GRAPHÈMES_COMPLEXES:
            # Le graphème g est coupé à la frontière ssi pour un j dans 1..len(g)-1
            # s1 se termine par g[:j] et s2 commence par g[j:]
            for j in range(1, len(g)):
                if s1.endswith(g[:j]) and s2.startswith(g[j:]):
                    syllabes[i] = s1 + s2
                    del syllabes[i + 1]
                    merged = True
                    i -= 1
                    break
            if merged:
                break
        i += 1

    return syllabes


def corriger_consonne_isolée(syllabes):
    """
    Supprime les syllabes composées uniquement d'une consonne.
    """
    i = 0
    while i < len(syllabes):
        if not contient_voyelle(syllabes[i]):
            if i > 0:
                syllabes[i - 1] += syllabes[i]
                del syllabes[i]
                continue
            elif i < len(syllabes) - 1:
                syllabes[i + 1] = syllabes[i] + syllabes[i + 1]
                del syllabes[i]
                continue
        i += 1
    return syllabes


def corriger_groupes_consonantiques(syllabes):
    """
    Évite de couper un groupe naturel (tr, pl, fr…)
    """
    i = 0
    while i < len(syllabes) - 1:
        fin = syllabes[i][-1] if syllabes[i] else ""
        debut = syllabes[i + 1][:1]

        cluster = fin + debut
        if cluster in GROUPES_CONSONANTIQUES:
            syllabes[i] += debut
            syllabes[i + 1] = syllabes[i + 1][1:]
            if syllabes[i + 1] == "":
                del syllabes[i + 1]
                continue
        i += 1

    return syllabes


def nettoyer_decoupage(mot, decoupage):
    syllabes = decoupage.split("-")

    syllabes = corriger_consonne_isolée(syllabes)
    syllabes = corriger_graphèmes(mot, syllabes)
    if APPLIQUER_GROUPES_CONSONANTIQUES:
        syllabes = corriger_groupes_consonantiques(syllabes)

    # Nettoyage final
    syllabes = [s for s in syllabes if s.strip() != ""]

    return "-".join(syllabes)


# -------------------------
# TRAITEMENT FICHIER (format .txt mot\tdécoupe)
# -------------------------


def traiter_fichier(input_txt, output_txt, rapport_csv):
    input_txt = Path(input_txt)
    output_txt = Path(output_txt)
    rapport_csv = Path(rapport_csv)

    lines = input_txt.read_text(encoding="utf-8").splitlines()
    out_lines = []
    corrections = []

    for line in lines:
        stripped = line.strip()
        if not stripped:
            out_lines.append(line)
            continue
        if stripped.startswith("Liste "):
            out_lines.append("Liste des mots et leur découpe syllabique (Lexique 4 / syllabation orale → orthographe, découpe proche de l'oreille)")
            continue
        if stripped.startswith("==") or stripped.startswith("Total:"):
            out_lines.append(line)
            continue
        if "\t" not in stripped:
            out_lines.append(line)
            continue

        mot, decoupage = stripped.split("\t", 1)
        mot = mot.strip()
        decoupage = decoupage.strip()
        nouveau = nettoyer_decoupage(mot, decoupage)

        out_lines.append(f"{mot}\t{nouveau}")

        if nouveau != decoupage:
            corrections.append([mot, decoupage, nouveau])

    output_txt.write_text("\n".join(out_lines), encoding="utf-8")

    rapport_csv.parent.mkdir(parents=True, exist_ok=True)
    with open(rapport_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["mot", "ancien", "corrigé"])
        w.writerows(corrections)

    print("Nettoyage terminé.")
    print(f"  Écrit : {output_txt}")
    print(f"  Rapport : {rapport_csv} ({len(corrections)} corrections)")


# -------------------------
# LANCEMENT
# -------------------------

if __name__ == "__main__":
    traiter_fichier(
        input_txt=ROOT / "mots_decoupesV3.txt",
        output_txt=ROOT / "mots_decoupesV4.txt",
        rapport_csv=ROOT / "rapport_corrections.csv"
    )
