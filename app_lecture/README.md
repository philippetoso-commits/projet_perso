# app_lecture

Application Flutter « Le Mot Mystère » — apprentissage de la lecture (syllabes, reconnaissance vocale).

## Images des sons (Pexels)

Pour re-télécharger les images des thèmes sons (a, e, i, o, u, eu, consonnes doubles) depuis Pexels :

1. Créer une clé gratuite sur [pexels.com/api](https://www.pexels.com/api/).
2. Copier `.env.example` en `.env` et y mettre ta clé : `PEXELS_API_KEY=ta_cle`.  
   (Optionnel : `pip install python-dotenv` pour que le script charge automatiquement le `.env`.)
3. Lancer le script (depuis `app_lecture`) :  
   `python scrap_pexels_sons.py`  
   Ou exécuter la cellule dédiée dans le notebook `scrap image.ipynb` (en définissant `PEXELS_API_KEY` dans la cellule ou en variable d’environnement).

---

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
