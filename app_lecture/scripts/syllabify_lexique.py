# -*- coding: utf-8 -*-
"""
Moteur de découpage syllabique basé sur Lexique 4.
Syllabation phonétique projetée sur l'orthographe (affichage lisible pour enfant).
"""
import csv
import re
import unicodedata
from pathlib import Path
from typing import Optional

# Chemins par défaut : lexique dans divers/
SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent
DIVERS_DIR = ROOT / "divers"
# Essayer aussi à la racine du projet perso (parent de app_lecture)
PROJECT_ROOT = ROOT.parent
DIVERS_ALT = PROJECT_ROOT / "divers"

# Noms de colonnes possibles dans Lexique (Open Lexicon / Lexique 3-4)
# Lexique4.tsv utilise : 1_Mot, 2_Phono, 25_SyllPhono
ORTHO_KEYS = ("1_mot", "ortho", "orthographe", "1_ortho", "Ortho", "Mot")
PHON_KEYS = ("2_phono", "phon", "phonétique", "phonetique", "2_phon", "Phon", "Phono")
SYLL_KEYS = ("25_syllphono", "syll", "syllab", "syllabation", "phonsyll", "3_syll", "Syll", "SyllPhono")


def _detect_delimiter(path: Path) -> str:
    """Détecte si le fichier est CSV (,) ou TSV (tab)."""
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        first = f.readline()
    return "\t" if "\t" in first else ","


def _normalize_ortho(s: str) -> str:
    """Normalise une forme orthographique pour la clé de recherche."""
    return s.lower().strip()


def _remove_accents(s: str) -> str:
    """Retire les accents pour la recherche (é → e, à → a, etc.)."""
    nfd = unicodedata.normalize("NFD", s)
    return "".join(c for c in nfd if unicodedata.category(c) != "Mn")


def load_lexique(
    csv_path: Optional[Path] = None,
    encoding: str = "utf-8",
) -> dict:
    """
    Charge le Lexique depuis un CSV/TSV et construit le dictionnaire
    { "mot": { "orthographe", "phon", "syll_phon", "syll_ortho" } }.
    Chargement unique en mémoire, optimisé pour 700+ mots.
    """
    if csv_path is None:
        for base in (DIVERS_DIR, DIVERS_ALT, ROOT):
            for name in ("Lexique404", "Lexique400", "Lexique4", "Lexique383", "Lexique382"):
                for ext in (".tsv", ".csv"):
                    p = base / f"{name}{ext}"
                    if p.exists():
                        csv_path = p
                        break
                if csv_path is not None:
                    break
            if csv_path is not None:
                break
        if csv_path is None:
            return {}

    csv_path = Path(csv_path)
    if not csv_path.exists():
        return {}

    delim = _detect_delimiter(csv_path)
    lex: dict = {}

    with open(csv_path, "r", encoding=encoding, errors="replace", newline="") as f:
        reader = csv.DictReader(f, delimiter=delim)
        if not reader.fieldnames:
            return lex
        headers = [h.strip() for h in reader.fieldnames]

        def get_col(keys):
            for k in keys:
                for h in headers:
                    if h and h.strip().lower() == k.lower():
                        return h
            return None

        ortho_col = get_col(ORTHO_KEYS)
        phon_col = get_col(PHON_KEYS)
        syll_col = get_col(SYLL_KEYS)

        if not ortho_col:
            return lex

        for row in reader:
            ortho = (row.get(ortho_col) or "").strip()
            if not ortho:
                continue
            phon = (row.get(phon_col) or "").strip() if phon_col else ""
            syll_phon = (row.get(syll_col) or "").strip() if syll_col else ""

            # Éviter doublons : garder la première entrée (ou la plus complète)
            key = _normalize_ortho(ortho)
            if key in lex and syll_phon and not lex[key].get("syll_phon"):
                pass  # on garde l’ancienne si la nouvelle n’a pas de syllabation
            elif key not in lex or syll_phon:
                syll_ortho = _project_syllabation_onto_orthography(
                    ortho, phon, syll_phon
                )
                lex[key] = {
                    "orthographe": ortho,
                    "phon": phon,
                    "syll_phon": syll_phon,
                    "syll_ortho": syll_ortho,
                }

    return lex


def _project_syllabation_onto_orthography(
    ortho: str, phon: str, syll_phon: str
) -> str:
    """
    Projette la découpe syllabique phonétique sur l'orthographe.
    Ne jamais afficher la phonétique ; retourne une chaîne orthographique syllabée (ex: a-man-de).
    """
    if not syll_phon or not ortho:
        return ortho

    sylls_phon = [s.strip() for s in syll_phon.split("-") if s.strip()]
    if len(sylls_phon) <= 1:
        return ortho

    # Enlever les tirets pour obtenir la chaîne phonétique continue
    phon_flat = phon.replace("-", "").replace(" ", "")
    if not phon_flat:
        return _fallback_syll_ortho_by_ratio(ortho, sylls_phon)

    # Longueurs en "unités" phonétiques (chaque caractère = 1 dans Lexique)
    lengths_phon = [len(s) for s in sylls_phon]
    total_phon = sum(lengths_phon)
    total_ortho = len(ortho)

    if total_phon <= 0:
        return ortho

    # Répartition orthographique proportionnelle aux longueurs phonétiques
    # On utilise floor pour les n-1 premières et le reste pour la dernière
    boundaries = []
    acc = 0
    for i in range(len(lengths_phon) - 1):
        acc += int(total_ortho * lengths_phon[i] / total_phon)
        boundaries.append(acc)
    # Dernière syllabe : tout le reste
    segments = []
    start = 0
    for b in boundaries:
        segments.append(ortho[start:b])
        start = b
    segments.append(ortho[start:])

    result = "-".join(segments)
    if "".join(segments) != ortho:
        result = _fallback_syll_ortho_by_ratio(ortho, sylls_phon)
    return result


def _fallback_syll_ortho_by_ratio(ortho: str, sylls_phon: list) -> str:
    """Découpe orthographe en segments dont les longueurs suivent le ratio des syllabes phonétiques."""
    if not sylls_phon or len(sylls_phon) <= 1:
        return ortho
    lengths = [len(s) for s in sylls_phon]
    total_phon = sum(lengths)
    n = len(ortho)
    if total_phon <= 0:
        return ortho
    boundaries = []
    acc = 0
    for i in range(len(lengths) - 1):
        acc += max(1, int(n * lengths[i] / total_phon))
        boundaries.append(min(acc, n - 1))
    start = 0
    segments = []
    for b in boundaries:
        segments.append(ortho[start:b])
        start = b
    segments.append(ortho[start:])
    return "-".join(segments)


def _fallback_cv_syllabify(word: str) -> str:
    """Découpe type CV pour les mots absents du lexique (réutilise SyllableSplitter si dispo)."""
    try:
        from export_mots_syllabes import SyllableSplitter
        return SyllableSplitter.split_word(word)
    except Exception:
        pass
    # Règles CV minimales si import impossible
    w = word.lower().strip()
    if not w:
        return ""
    vowels = set("aeiouyàâäéèêëïîôùûüœæ")
    syllables = []
    current = []
    i = 0
    while i < len(w):
        current.append(w[i])
        if w[i] in vowels and i + 1 < len(w) and w[i + 1] not in vowels:
            syllables.append("".join(current))
            current = []
        i += 1
    if current:
        syllables.append("".join(current))
    return "-".join(syllables)


# Instance globale du lexique (chargement unique)
_LEXIQUE: dict = {}
_LEXIQUE_LOADED = False
# Index: forme sans accent -> orthographe avec accents (pour réintégrer les accents)
_NO_ACCENT_TO_ORTHO: dict = {}


def get_lexique(force_reload: bool = False, csv_path: Optional[Path] = None) -> dict:
    """Retourne le dictionnaire Lexique (chargé une seule fois en mémoire)."""
    global _LEXIQUE, _LEXIQUE_LOADED, _NO_ACCENT_TO_ORTHO
    if not _LEXIQUE_LOADED or force_reload:
        _LEXIQUE = load_lexique(csv_path=csv_path)
        _NO_ACCENT_TO_ORTHO = {}
        for entry in _LEXIQUE.values():
            ortho = entry["orthographe"]
            k = _remove_accents(ortho.lower())
            if k not in _NO_ACCENT_TO_ORTHO:
                _NO_ACCENT_TO_ORTHO[k] = ortho
        _LEXIQUE_LOADED = True
    return _LEXIQUE


def get_no_accent_to_ortho() -> dict:
    """Retourne l'index forme sans accent -> orthographe (après get_lexique())."""
    if not _LEXIQUE_LOADED:
        get_lexique()
    return _NO_ACCENT_TO_ORTHO


def accentify_word(part: str, no_accent_to_ortho: Optional[dict] = None) -> str:
    """
    Réintègre les accents sur un mot en s'appuyant sur le Lexique.
    Ex: "ecole" -> "école", "gateau" -> "gâteau". Si pas de correspondance, retourne le mot inchangé.
    """
    if no_accent_to_ortho is None:
        no_accent_to_ortho = get_no_accent_to_ortho()
    part_clean = part.strip()
    if not part_clean:
        return part
    key = _remove_accents(part_clean.lower())
    return no_accent_to_ortho.get(key, part)


def accentify_compound(mot: str, no_accent_to_ortho: Optional[dict] = None) -> str:
    """
    Réintègre les accents sur un mot ou une expression (mots composés, apostrophes).
    Ex: "pomme de terre" -> "pomme de terre", "jus d'orange" -> "jus d'orange" (orange accentué si présent).
    """
    if no_accent_to_ortho is None:
        no_accent_to_ortho = get_no_accent_to_ortho()
    mot = mot.strip()
    if not mot:
        return mot
    # Parties séparées par des espaces
    parts = mot.split()
    result = []
    for p in parts:
        # Parties avec apostrophe (ex: d'orange)
        if "'" in p:
            subparts = p.split("'")
            accented = [accentify_word(s, no_accent_to_ortho) for s in subparts]
            result.append("'".join(accented))
        else:
            result.append(accentify_word(p, no_accent_to_ortho))
    return " ".join(result)


def syllabify_word(
    word: str,
    lexique: Optional[dict] = None,
    use_fallback: bool = True,
) -> str:
    """
    Syllabe un mot pour affichage enfant (orthographe uniquement).

    - Cherche le mot dans Lexique, récupère la syllabation phonétique,
      projette sur l'orthographe.
    - Mots composés : chaque partie est syllabée, joint par " - ".
    - Pluriels : si absent, tente sans 's' final.
    - Mots absents : fallback vers règle CV simple si use_fallback=True.
    """
    if not word or not word.strip():
        return ""

    raw = word.strip()
    # Mots composés : découper uniquement sur les espaces (pas l'apostrophe "d'orange")
    if " " in raw:
        parts = [p.strip() for p in raw.split() if p.strip()]
        result = []
        for p in parts:
            sub = syllabify_word(p, lexique=lexique, use_fallback=use_fallback)
            result.append(sub)
        return " ".join(result)

    ortho_lower = _normalize_ortho(raw)
    if lexique is None:
        lexique = get_lexique()
    # Recherche avec forme sans accent si pas trouvé (ex: "ecole" -> "école")
    if ortho_lower not in lexique:
        no2ortho = get_no_accent_to_ortho()
        key_no_acc = _remove_accents(ortho_lower)
        if key_no_acc in no2ortho:
            ortho_lower = _normalize_ortho(no2ortho[key_no_acc])

    # Recherche exacte
    if ortho_lower in lexique:
        entry = lexique[ortho_lower]
        out = entry.get("syll_ortho") or entry.get("orthographe", raw)
        return out if out else raw

    # Pluriel : retirer 's' ou 'x' final et réessayer
    if ortho_lower.endswith("s") and len(ortho_lower) > 1:
        singular = ortho_lower[:-1]
        if singular in lexique:
            entry = lexique[singular]
            base_syll = entry.get("syll_ortho") or entry.get("orthographe", singular)
            return base_syll + "-s" if base_syll else raw
    if ortho_lower.endswith("x") and len(ortho_lower) > 1:
        singular = ortho_lower[:-1] + "s"
        if singular in lexique:
            entry = lexique[singular]
            base_syll = entry.get("syll_ortho") or entry.get("orthographe", singular)
            if base_syll:
                return base_syll.rsplit("-", 1)[0] + "-x" if "-" in base_syll else base_syll + "-x"
            return raw

    if use_fallback:
        return _fallback_cv_syllabify(raw)
    return raw


def export_results_csv(
    words_with_syllabation: list[tuple[str, str]],
    out_path: Path,
    encoding: str = "utf-8",
) -> None:
    """Exporte (mot, découpe_ortho) en CSV."""
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding=encoding, newline="") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["mot", "syll_ortho"])
        w.writerows(words_with_syllabation)
    print(f"Export CSV : {out_path}")


def process_mots_decoupes_file(
    input_path: Path,
    output_path: Path,
    lexique_path: Optional[Path] = None,
    encoding: str = "utf-8",
) -> tuple[int, int]:
    """
    Lit un fichier type mots_decoupes.txt (lignes 'mot\\tdécoupe') et produit
    une version V2 avec la syllabation Lexique (ou fallback).
    Retourne (nb_lignes_traitées, nb_fallback).
    """
    input_path = Path(input_path)
    output_path = Path(output_path)
    lex = get_lexique(csv_path=lexique_path)

    lines = input_path.read_text(encoding=encoding).splitlines()
    out_lines = []
    treated = 0
    fallback_count = 0

    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped:
            out_lines.append(line)
            continue
        if stripped.startswith("Liste "):
            out_lines.append("Liste des mots et leur découpe syllabique (Lexique 4 / syllabation orale → orthographe)")
            continue
        if stripped.startswith("=="):
            out_lines.append(line)
            continue
        if stripped.startswith("Total:"):
            out_lines.append(line)
            continue
        if "\t" not in stripped:
            out_lines.append(line)
            continue

        mot, _old_decoupe = stripped.split("\t", 1)
        mot = mot.strip()
        new_decoupe = syllabify_word(mot, lexique=lex, use_fallback=True)
        if " " not in mot and _normalize_ortho(mot) not in lex:
            fallback_count += 1
        out_lines.append(f"{mot}\t{new_decoupe}")
        treated += 1

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(out_lines), encoding=encoding)
    return treated, fallback_count


def rewrite_list_with_accents(
    input_path: Path,
    output_list_path: Path,
    output_v2_path: Path,
    lexique_path: Optional[Path] = None,
    encoding: str = "utf-8",
) -> tuple[int, int]:
    """
    Réintègre les accents pour tous les mots (via Lexique) et repasse toute la liste
    en syllabation. Écrit la liste avec accents dans output_list_path et la version
    « Lexique » dans output_v2_path.
    Retourne (nb_mots_traités, nb_fallback).
    """
    input_path = Path(input_path)
    output_list_path = Path(output_list_path)
    output_v2_path = Path(output_v2_path)
    lex = get_lexique(csv_path=lexique_path)
    no_accent = get_no_accent_to_ortho()

    lines = input_path.read_text(encoding=encoding).splitlines()
    list_lines = []
    v2_lines = []
    treated = 0
    fallback_count = 0

    for line in lines:
        stripped = line.strip()
        if not stripped:
            list_lines.append(line)
            v2_lines.append(line)
            continue
        if stripped.startswith("Liste "):
            list_lines.append("Liste des mots et leur découpe syllabique (accents réintégrés + Lexique)")
            v2_lines.append("Liste des mots et leur découpe syllabique (Lexique 4 / syllabation orale → orthographe)")
            continue
        if stripped.startswith("=="):
            list_lines.append(line)
            v2_lines.append(line)
            continue
        if stripped.startswith("Total:"):
            list_lines.append(line)
            v2_lines.append(line)
            continue
        if "\t" not in stripped:
            list_lines.append(line)
            v2_lines.append(line)
            continue

        mot_old = stripped.split("\t", 1)[0].strip()
        new_mot = accentify_compound(mot_old, no_accent)
        new_decoupe = syllabify_word(new_mot, lexique=lex, use_fallback=True)
        if " " not in new_mot and _normalize_ortho(new_mot) not in lex:
            fallback_count += 1
        list_lines.append(f"{new_mot}\t{new_decoupe}")
        v2_lines.append(f"{new_mot}\t{new_decoupe}")
        treated += 1

    output_list_path.parent.mkdir(parents=True, exist_ok=True)
    output_v2_path.parent.mkdir(parents=True, exist_ok=True)
    output_list_path.write_text("\n".join(list_lines), encoding=encoding)
    output_v2_path.write_text("\n".join(v2_lines), encoding=encoding)
    return treated, fallback_count


def list_fallback_words(
    input_path: Path,
    lexique_path: Optional[Path] = None,
    encoding: str = "utf-8",
) -> list[str]:
    """
    Retourne la liste des mots du fichier qui ne sont pas dans le Lexique
    (traités en fallback CV). Uniquement les mots simples (sans espace).
    """
    lex = get_lexique(csv_path=lexique_path)
    input_path = Path(input_path)
    lines = input_path.read_text(encoding=encoding).splitlines()
    fallback_words = []
    for line in lines:
        stripped = line.strip()
        if not stripped or "\t" not in stripped:
            continue
        if stripped.startswith("Liste ") or stripped.startswith("==") or stripped.startswith("Total:"):
            continue
        mot = stripped.split("\t", 1)[0].strip()
        if " " not in mot and _normalize_ortho(mot) not in lex:
            fallback_words.append(mot)
    return sorted(set(fallback_words))


# --- Exemple d'utilisation et point d'entrée ---
if __name__ == "__main__":
    import sys

    lex = get_lexique()
    print(f"Lexique chargé : {len(lex)} entrées")
    if not lex:
        print("Aucun fichier Lexique trouvé dans 'divers/'. Utilisation du fallback CV uniquement.")
        print("Placez par ex. Lexique404.tsv dans app_lecture/divers/ ou projet_perso/divers/")

    examples = [
        "amande", "bonbon", "fraise", "gaufre", "oignon", "ordinateur",
        "abricot", "ananas", "pomme de terre",
    ]
    print("\nExemples syllabify_word():")
    for w in examples:
        res = syllabify_word(w, lexique=lex)
        print(f"  {w!r} -> {res!r}")

    # Export CSV optionnel
    if len(sys.argv) > 1 and sys.argv[1] == "export":
        pairs = [(w, syllabify_word(w, lexique=lex)) for w in examples]
        export_results_csv(pairs, ROOT / "syllabation_export.csv")

    # Génération mots_decoupesV2.txt depuis mots_decoupes.txt
    in_file = ROOT / "mots_decoupes.txt"
    out_file = ROOT / "mots_decoupesV2.txt"
    if in_file.exists():
        n, fallback = process_mots_decoupes_file(in_file, out_file)
        print(f"\nFichier {out_file.name} généré : {n} mots traités ({fallback} en fallback CV)")

    # Option : réintégrer les accents et repasser toute la liste
    if len(sys.argv) > 1 and sys.argv[1] in ("--accents", "accents"):
        list_file = ROOT / "mots_decoupes.txt"
        v2_file = ROOT / "mots_decoupesV2.txt"
        n, fallback = rewrite_list_with_accents(in_file, list_file, v2_file)
        print(f"\nAccents réintégrés et liste repassée : {n} mots ({fallback} en fallback CV)")
        print(f"  {list_file.name} et {v2_file.name} mis à jour.")

    # Option : lister les mots non traités par le Lexique (fallback)
    if len(sys.argv) > 1 and sys.argv[1] in ("--list-fallback", "list-fallback"):
        fallback_list = list_fallback_words(in_file)
        print(f"\nMots non trouvés dans le Lexique ({len(fallback_list)} mots, découpe en fallback CV) :")
        for w in fallback_list:
            print(f"  {w}")
        if fallback_list:
            out_list = ROOT / "mots_fallback_lexique.txt"
            out_list.write_text("\n".join(fallback_list), encoding="utf-8")
            print(f"\nListe enregistrée dans {out_list.name}")
