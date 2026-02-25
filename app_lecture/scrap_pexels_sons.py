#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Re-télécharge les images des thèmes « sons » (a, e, i, o, u, eu, consonnes doubles)
depuis Pexels et met à jour les JSON dans assets/data.
À lancer depuis app_lecture : python scrap_pexels_sons.py
Clé API gratuite : https://www.pexels.com/api/
"""
import requests
import os
import time
import json
import unicodedata
import logging
from pathlib import Path

# Charger .env si présent (pip install python-dotenv)
try:
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).resolve().parent / ".env")
except ImportError:
    pass

PEXELS_API_KEY = os.getenv("PEXELS_API_KEY", "")
ASSETS = Path(__file__).resolve().parent / "assets"
IMAGES_DIR = ASSETS / "images"
DATA_DIR = ASSETS / "data"
DELAY_PEXELS = 0.5

# Contourner le proxy système : session qui n'utilise pas les variables proxy (HTTP_PROXY, etc.)
def _session():
    s = requests.Session()
    s.trust_env = False  # ignore proxy env + paramètres système
    s.proxies = {"http": None, "https": None}
    return s

THÈMES_SONS = [
    "niveau_1_cv_son_a",
    "niveau_1_cv_son_e_eu",
    "niveau_1_cv_son_i_y",
    "niveau_1_cv_son_o",
    "niveau_1_cv_son_u",
    "niveau_1_consonnes_doubles",
]

VOCAB_SONS = {
    "niveau_1_cv_son_a": [
        "papa", "tata", "lama", "sac", "lac", "rat", "chat", "plat", "bras", "camera",
        "sofa", "bocal", "bavoir", "lavabo", "ananas", "banane", "cabane", "salade", "tomate", "fac",
        "macaque", "matelas", "canard", "dinde", "navet", "cafe", "cacao", "boa", "ara", "panda",
        "puma", "tapis", "radis", "pyjama", "pirate", "parachute", "canape", "patate", "pate", "farine",
    ],
    "niveau_1_cv_son_o": [
        "moto", "velo", "domino", "robot", "polo", "piano", "radio", "video", "lasso", "loto",
        "dynamo", "bol", "col", "vol", "sol", "loup", "ours", "pot", "lot", "mot",
        "sot", "bout", "mou", "trou", "clou", "chou", "pou", "fou", "cou", "sou",
        "roti", "soda", "dos", "os", "judo", "karate", "gros", "trop", "flot", "croc",
    ],
    "niveau_1_cv_son_i_y": [
        "lit", "nid", "kiwi", "sirene", "fil", "vif", "riz", "tic", "pic", "dodo",
        "maki", "zebu", "biche", "caniche", "figue", "olive", "livre", "tigre", "vit", "dit",
        "rit", "pli", "cri", "gris", "prix", "riz", "tapis", "vis", "amis", "avis",
    ],
    "niveau_1_cv_son_u": [
        "lune", "mur", "jus", "bus", "fusee", "tortue", "rue", "vue", "nue", "grue",
        "cru", "dru", "lu", "pu", "su", "tu", "vu", "bu", "sur", "pur",
        "dur", "pull", "duc", "bulle", "jupe", "flute", "plume", "sucre", "lute", "mule",
    ],
    "niveau_1_cv_son_e_eu": [
        "bebe", "fee", "tele", "epee", "puree", "bidet", "pneu", "fer", "mer", "sel",
        "ver", "bec", "chef", "cerf", "oeuf", "boeuf", "neuf", "nez", "pas", "main",
        "pied", "tete", "joue", "ble", "cle", "pre", "the", "de", "ne", "verre",
    ],
    "niveau_1_consonnes_doubles": [
        "pomme", "balle", "botte", "carotte", "classe", "gomme", "nappe", "patte", "poubelle", "tasse",
        "terre", "liasse", "crasse", "bosse", "fosse", "brosse", "tresse", "presse", "fesse", "caisse",
        "graisse", "laisse", "chaise", "fraise", "chasse", "masse", "passe", "tache", "vache", "cache",
    ],
}


def clean_filename(text):
    nfkd = unicodedata.normalize("NFKD", text)
    ascii_only = nfkd.encode("ASCII", "ignore").decode("ASCII")
    return ascii_only.lower().replace(" ", "_").replace("'", "_")


def search_pexels(mot, api_key, session=None):
    session = session or _session()
    url = "https://api.pexels.com/v1/search"
    headers = {"Authorization": api_key}
    params = {"query": mot, "per_page": 3, "locale": "fr-FR"}
    try:
        r = session.get(url, headers=headers, params=params, timeout=10)
        r.raise_for_status()
        data = r.json()
        photos = data.get("photos", [])
        return photos[0] if photos else None
    except Exception as e:
        logging.warning("Pexels API '%s': %s", mot, e)
        return None


def download_file(url, dest_path, session=None):
    session = session or _session()
    try:
        r = session.get(url, stream=True, timeout=15)
        r.raise_for_status()
        with open(dest_path, "wb") as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
        return True
    except Exception as e:
        logging.warning("Téléchargement %s: %s", dest_path, e)
        return False


def main():
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    if not PEXELS_API_KEY:
        logging.error("Définir PEXELS_API_KEY (variable d'environnement ou modifier le script).")
        return
    total = sum(len(mots) for mots in VOCAB_SONS.values())
    n = 0
    session = _session()
    for theme in THÈMES_SONS:
        mots = VOCAB_SONS.get(theme, [])
        (IMAGES_DIR / theme).mkdir(parents=True, exist_ok=True)
        data_theme = DATA_DIR / theme
        data_theme.mkdir(parents=True, exist_ok=True)
        for mot in mots:
            n += 1
            fbase = clean_filename(mot)
            image_path = IMAGES_DIR / theme / f"{fbase}.jpg"
            json_path = data_theme / f"{fbase}.json"
            logging.info("[%s/%s] %s — %s...", n, total, theme, mot)
            photo = search_pexels(mot, PEXELS_API_KEY, session)
            if not photo:
                logging.warning("  aucun résultat Pexels")
                time.sleep(DELAY_PEXELS)
                continue
            src = photo.get("src", {})
            url = src.get("medium") or src.get("large") or src.get("original")
            if not url:
                logging.warning("  pas d'URL image")
                time.sleep(DELAY_PEXELS)
                continue
            if download_file(url, image_path, session):
                rel_image = f"assets/images/{theme}/{fbase}.jpg"
                meta = {}
                if json_path.exists():
                    with open(json_path, "r", encoding="utf-8") as f:
                        meta = json.load(f)
                meta["mot"] = mot
                meta["theme"] = theme
                meta["image_path"] = rel_image
                meta["pexels_id"] = photo.get("id")
                meta["photographer"] = photo.get("photographer")
                if "syllabes" not in meta:
                    meta["syllabes"] = [mot]
                if "level" not in meta:
                    meta["level"] = 1
                with open(json_path, "w", encoding="utf-8") as f:
                    json.dump(meta, f, ensure_ascii=False, indent=4)
                logging.info("  OK (Pexels)")
            else:
                logging.warning("  échec téléchargement")
            time.sleep(DELAY_PEXELS)
    logging.info("Terminé. Photos fournies par Pexels (pexels.com).")


if __name__ == "__main__":
    main()
