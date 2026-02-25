# -*- coding: utf-8 -*-
"""Extrait la liste des mots et leur découpe syllabique (SyllableSplitter)."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "assets" / "data"
OUT_FILE = ROOT / "mots_decoupes.txt"


class SyllableSplitter:
    complex_sounds = [
        "eau", "au", "ai", "oi", "ou",
        "an", "en", "on", "in", "un",
        "ch", "gn", "qu"
    ]
    # Ordre long → court pour que "eau" soit avant "au"
    complex_sounds = sorted(complex_sounds, key=len, reverse=True)

    consonant_clusters = [
        "tr", "pr", "br", "dr", "cr", "fr",
        "pl", "bl", "gl", "cl"
    ]

    vowels = "aeiouy"

    # Placeholders un seul caractère (pour ne pas couper @sound@ au milieu)
    _placeholders = [chr(0xE000 + i) for i in range(len(complex_sounds))]
    _sound_to_placeholder = dict(zip(complex_sounds, _placeholders))
    _placeholder_to_sound = dict(zip(_placeholders, complex_sounds))
    _vowels_and_placeholders = set(vowels) | set(_placeholders)

    @classmethod
    def protect_complex_sounds(cls, word):
        for sound in cls.complex_sounds:
            word = word.replace(sound, cls._sound_to_placeholder[sound])
        return word

    @classmethod
    def unprotect(cls, word):
        for ph, sound in cls._placeholder_to_sound.items():
            word = word.replace(ph, sound)
        return word

    @classmethod
    def is_vowel(cls, char):
        return char.lower() in cls._vowels_and_placeholders

    @classmethod
    def split_word(cls, word):
        w = word.lower()
        w = cls.protect_complex_sounds(w)

        chars = list(w)
        syllables = []
        current = ""

        i = 0
        while i < len(chars):
            current += chars[i]

            # Si voyelle (ou placeholder = noyau) → possible fin de syllabe
            if cls.is_vowel(chars[i]):
                if i + 1 < len(chars):

                    # Double consonne
                    if (
                        i + 2 < len(chars)
                        and chars[i + 1] == chars[i + 2]
                        and not cls.is_vowel(chars[i + 1])
                    ):
                        current += chars[i + 1]
                        syllables.append(current)
                        current = ""
                        i += 2
                        continue

                    # Groupe consonantique naturel
                    if i + 2 < len(chars):
                        cluster = chars[i + 1] + chars[i + 2]
                        if cluster in cls.consonant_clusters:
                            syllables.append(current)
                            current = ""
                            i += 1
                            continue

                    # Une seule consonne → va avec syllabe suivante
                    if not cls.is_vowel(chars[i + 1]):
                        syllables.append(current)
                        current = ""

            i += 1

        if current:
            syllables.append(current)

        syllables = [cls.unprotect(s) for s in syllables]
        return "-".join(syllables)


def main():
    lines = []
    lines.append("Liste des mots et leur découpe syllabique (SyllableSplitter)")
    lines.append("=" * 50)
    lines.append("")

    count = 0
    for theme_dir in sorted(DATA_DIR.iterdir()):
        if not theme_dir.is_dir():
            continue
        for json_path in sorted(theme_dir.glob("*.json")):
            try:
                with open(json_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                mot = data.get("mot", "")
                if not mot:
                    continue
                decoupe = SyllableSplitter.split_word(mot)
                lines.append(f"{mot}\t{decoupe}")
                count += 1
            except Exception as e:
                lines.append(f"# Erreur {json_path.name}: {e}")

    lines.append("")
    lines.append(f"Total: {count} mots")
    OUT_FILE.write_text("\n".join(lines), encoding="utf-8")
    print(f"Écrit: {OUT_FILE} ({count} mots)")


if __name__ == "__main__":
    # Tests rapides
    test_words = [
        "gomme", "amande", "fraise", "gaufre",
        "bonbon", "chocolat", "papillon", "ordinateur"
    ]
    for word in test_words:
        print(word, "->", SyllableSplitter.split_word(word))
    print()
    main()
