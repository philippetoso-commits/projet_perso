# -*- coding: utf-8 -*-
"""Applique la moulinette de nettoyage des syllabes à mots_decoupesV2.txt → mots_decoupesV3.txt."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

GRAPHÈMES_COMPLEXES = [
    "eau", "au", "ai", "oi", "ou",
    "an", "en", "on", "in", "un",
    "ch", "gn", "qu"
]

GROUPES_CONSONANTIQUES = [
    "tr", "pr", "br", "dr", "cr", "fr",
    "pl", "bl", "gl", "cl"
]


def nettoyer_syllabes(syllabes):
    result = []
    i = 0
    syllabes = list(syllabes)  # copie pour pouvoir modifier

    while i < len(syllabes):
        syll = syllabes[i]

        # 1️⃣ Éviter syllabe = 1 consonne seule
        if len(syll) == 1 and syll not in "aeiouyàâäéèêëïîôùûüœæ":
            if i + 1 < len(syllabes):
                syllabes[i + 1] = syll + syllabes[i + 1]
            i += 1
            continue

        # 2️⃣ Éviter coupure dans graphème complexe
        merged = False
        for g in GRAPHÈMES_COMPLEXES:
            if syll.endswith(g[0]) and i + 1 < len(syllabes):
                if syllabes[i + 1].startswith(g[1:]):
                    syllabes[i + 1] = syll + syllabes[i + 1]
                    merged = True
                    i += 1
                    break
        if merged:
            continue

        result.append(syll)
        i += 1

    return result


def stabiliser_decoupage(mot_syllabe):
    syllabes = mot_syllabe.split("-")
    syllabes = nettoyer_syllabes(syllabes)
    syllabes = [s for s in syllabes if s.strip() != ""]
    return "-".join(syllabes)


def main():
    in_path = ROOT / "mots_decoupesV2.txt"
    out_path = ROOT / "mots_decoupesV3.txt"

    lines = in_path.read_text(encoding="utf-8").splitlines()
    out_lines = []

    for line in lines:
        stripped = line.strip()
        if not stripped or "\t" not in stripped:
            out_lines.append(line)
            continue
        if stripped.startswith("Liste "):
            out_lines.append("Liste des mots et leur découpe syllabique (Lexique 4 / syllabation orale → orthographe, moulinette V3)")
            continue
        if stripped.startswith("==") or stripped.startswith("Total:"):
            out_lines.append(line)
            continue

        mot, decoupe = stripped.split("\t", 1)
        mot = mot.strip()
        decoupe = decoupe.strip()
        new_decoupe = stabiliser_decoupage(decoupe)
        out_lines.append(f"{mot}\t{new_decoupe}")

    out_path.write_text("\n".join(out_lines), encoding="utf-8")
    print(f"Écrit : {out_path} ({len(out_lines)} lignes)")


if __name__ == "__main__":
    main()
