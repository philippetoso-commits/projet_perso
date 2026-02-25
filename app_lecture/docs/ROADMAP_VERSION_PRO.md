# Roadmap — Version Pro / Monétisation

Ce document détaille les fonctionnalités à développer pour une version **Premium** de l’app (vente sur stores, aux écoles ou aux orthophonistes), avec un modèle **Freemium** suggéré.

---

## Modèle économique suggéré : Freemium

| Contenu | Gratuit | Payant (achat unique ou abo) |
|--------|----------|------------------------------|
| **Niveau 1** (syllabes CV, Petite section) | ✅ Complet | — |
| **Niveaux 2 et 3** (MS, GS, CP) | 🔒 Verrouillés | Débloqués |
| **Suivi de progression / Dashboard** | ❌ | ✅ |
| **Profils multi-enfants** | 1 profil | Illimité |
| **Carte / Parcours (gamification)** | Niveau 1 seulement | Tous niveaux |

**Options de monétisation :**
- **In-App Purchase** : déblocage à vie (ex. 4,99 € – 9,99 €).
- **Abonnement** (optionnel) : 1,99 €/mois ou 14,99 €/an pour mises à jour contenu + analytics avancés.
- **Licence école / pro** : tarif dédié, déploiement multi-appareils.

---

## 1. Profils multi-enfants / multi-élèves

**Objectif :** Un parent avec plusieurs enfants, ou un ortho/enseignant avec plusieurs élèves, peut créer un profil par enfant et suivre la progression séparément.

### Spécifications

- **Modèle de données**
  - Entité `Profile` : `id`, `name`, `avatarId` (ou chemin image), `createdAt`, `levelUnlocked` (1, 2, 3), `settings` (optionnel : voix TTS, vitesse).
  - Les mots vus, réussites/échecs, et stats SRS sont liés au `Profile` (clé étrangère ou box Hive dédiée par profil).
- **UI**
  - **Écran d’accueil** : si plusieurs profils → choix du profil (cartes avec prénom + avatar) puis entrée dans l’app.
  - **Création de profil** : nom, choix d’avatar (galerie prédéfinie ou photo).
  - **Paramètres** : accès à la liste des profils + édition/suppression.
- **Stockage**
  - Hive : box `profiles`, box `progress_<profileId>` (ou une box `progress` avec `profileId` dans l’objet).
  - Profil “courant” : stocké en préférence (SharedPreferences ou Hive) pour rouvrir directement le bon profil.

### Tâches techniques (ordre suggéré)

1. Créer le modèle `Profile` (Hive typeId dédié) et adapter `Word`/progression pour inclure `profileId`.
2. Écran de sélection/création de profils au premier lancement (ou depuis paramètres).
3. Sauvegarder le `profileId` courant et filtrer toutes les données (mots vus, stats, SRS) par ce profil.
4. Écran paramètres : liste des profils, ajout, édition (nom, avatar), suppression (avec confirmation).

---

## 2. Dashboard Parents / Pro (analytics)

**Objectif :** Un espace protégé (code PIN ou calcul simple) où l’adulte voit les statistiques détaillées : quels mots/sons posent problème, taux de reconnaissance vocale, temps passé.

### Spécifications

- **Accès sécurisé**
  - Bouton discret “Espace Parents” ou “Pro” (ex. dans paramètres ou après 5 tap sur la mascotte).
  - Vérification par **code PIN** (4–6 chiffres) ou **question mathématique** (ex. “3 + 5 = ?”) pour éviter que l’enfant y accède.
  - Stockage du hash du PIN (jamais le PIN en clair) ou validation côté client uniquement pour la question math.

- **Contenu du dashboard**
  - **Profil sélectionné** (ou résumé multi-profils si plusieurs).
  - **Statistiques globales**
    - Nombre de mots vus / réussis / en difficulté.
    - Temps total de jeu (estimation par sessions).
    - Taux de réussite reconnaissance vocale (succès / total tentatives).
  - **Mots / sons en difficulté**
    - Liste des mots avec taux d’échec élevé ou marqués “à revoir” par l’algo SRS.
    - Filtre par niveau, par thème, par phonème (si tu exposes les phonèmes par mot).
  - **Export** (optionnel) : export CSV/PDF des stats pour les pros (orthophonistes, enseignants).

### Tâches techniques

1. Écran de vérification (PIN ou question math) puis navigation vers le dashboard.
2. Modèle de données pour “sessions” et “tentatives” (mot, profil, succès/échec, timestamp) si pas déjà en place.
3. Écran dashboard : résumé chiffré + liste “mots en difficulté”.
4. (Optionnel) Graphiques simples (ex. courbe de réussite par jour) et export fichier.

---

## 3. Algorithme de répétition espacée (SRS)

**Objectif :** Les mots sur lesquels l’enfant a buté (reconnaissance vocale) sont proposés plus souvent ; les mots maîtrisés apparaissent moins souvent.

### Spécifications

- **Données par mot (et par profil)**
  - `successCount`, `failCount`, `lastSeen`, `nextReview` existent déjà sur `Word` (Hive). À lier au **profil** : donc soit un objet `WordProgress(profileId, wordId, successCount, failCount, lastSeen, nextReview)` soit une map dans le profil.
- **Règles de révision**
  - Après une **réussite** : augmenter l’intervalle (ex. +1 jour, puis +2, +4, plafond 7 jours).
  - Après un **échec** : réduire l’intervalle (réviser bientôt, ex. prochaine session ou +0 jour).
  - Algorithme type SM-2 simplifié ou règle maison (ex. 3 succès d’affilée = mot “maîtrisé”, moins souvent proposé).
- **Intégration dans le jeu**
  - Lors du choix du “prochain mot” (ex. `_nextWord` dans `game_screen`), ne plus tirer au hasard parmi tous les mots du niveau : **prioriser** les mots dont `nextReview <= now` ou qui ont le plus faible taux de réussite.
  - Mélanger pour éviter l’ennui : 70 % SRS (mots à revoir) + 30 % aléatoire.

### Tâches techniques

1. Découpler la progression du modèle `Word` global : créer `WordProgress` (ou équivalent) par profil.
2. Mettre à jour `successCount` / `failCount` / `nextReview` après chaque tentative de lecture (déjà partiellement fait ; s’assurer que c’est par profil).
3. Implémenter la logique “prochaine date de révision” (règles d’intervalle).
4. Dans `_nextWord` (ou service dédié “word picker”), sélectionner le prochain mot selon SRS + niveau courant.

---

## 4. Récompenses et gamification (parcours du héros)

**Objectif :** Remplacer le tirage aléatoire par une **carte de progression** type Duolingo/Candy Crush : l’enfant débloque des niveaux, gagne des étoiles ou des pièces, et peut personnaliser sa mascotte.

### Spécifications

- **Carte / Map**
  - Niveaux 1, 2, 3 représentés comme des “îles” ou “étapes” sur un chemin.
  - Chaque étape contient N mots (ou N objectifs). Déblocage de l’étape suivante après X mots réussis ou X étoiles.
  - Visuel : fond de carte, noeuds débloqués (colorés) vs verrouillés (gris), animation à la validation.
- **Étoiles / Pièces**
  - **Étoiles** : 1 à 3 par mot selon la performance (ex. 1 étoile = réussi avec 2 essais, 3 = du premier coup). Cumul par étape ou par niveau.
  - **Pièces** (ou “bonus”) : optionnel, gagnées par étoiles ou par séries (ex. 5 mots d’affilée). Utilisées pour débloquer des skins de mascotte ou des thèmes.
- **Mascotte**
  - Plusieurs apparences (chapeaux, couleurs, accessoires) débloquables avec les pièces ou les étoiles.
  - Écran “Ma mascotte” : choix du skin, affichage sur l’accueil et en jeu.

### Tâches techniques

1. Définir la structure de la carte (niveaux → étapes → mots ou objectifs) en données (JSON ou code).
2. Écran “Carte” : affichage des noeuds, état débloqué/verrouillé, navigation vers le jeu pour une étape donnée.
3. Règles de déblocage (ex. “3 étoiles sur l’étape 1” pour débloquer l’étape 2).
4. Système d’étoiles (calcul après chaque mot) et stockage par profil.
5. (Optionnel) Pièces + boutique / personnalisation mascotte.

---

## 5. Qualité audio studio

**Objectif :** Remplacer le TTS robotique par une voix de meilleure qualité pour une prononciation française parfaite (important pour l’apprentissage).

### Options techniques

- **Enregistrements humains**
  - Enregistrer chaque mot (et chaque syllabe si lecture syllabée) en studio. Fichiers audio par mot/syllabe, joués via `audioplayers`. Qualité maximale, coût de production élevé et lourdeur (nombre de fichiers).
- **TTS neuronal / premium**
  - Utiliser un service type **ElevenLabs**, **Google Cloud TTS** (WaveNet), **Azure Speech** (neuronal), ou **Amazon Polly** (voix neurales) avec une voix française. Qualité très bonne, coût par requête ou abonnement, besoin d’une connexion (ou cache des fichiers générés).
- **Compromis**
  - TTS du système (actuel) en gratuit ; voix “premium” (TTS neuronal ou pack audio studio) en payant, téléchargement des audios pour les mots du niveau débloqué.

### Tâches techniques

1. Définir le format d’audio (fichier local vs URL vs appel API).
2. Intégrer un fournisseur TTS premium (ex. API ElevenLabs ou Google) avec fallback sur le TTS actuel.
3. Cache local : pour les mots déjà écoutés (ou pour tout le niveau acheté), stocker l’audio pour lecture offline.
4. (Optionnel) Pour une version “studio” : pipeline d’enregistrement + nommage des fichiers (ex. `assets/audio/words/<theme>_<mot>.mp3`) et lecture dans `TtsService` ou un service dédié.

---

## Ordre de mise en œuvre suggéré

1. **Profils multi-enfants** — base indispensable pour tout le reste (progression, SRS, dashboard).
2. **SRS** — améliore directement l’efficacité pédagogique avec les données existantes.
3. **Dashboard** — valorise l’app pour les parents/pros et justifie le prix.
4. **Gamification (carte + étoiles)** — différenciation forte et rétention.
5. **Audio studio / TTS premium** — en dernier ou en parallèle, selon budget et priorité.

---

## Fichiers à créer / modifier (référence)

| Fonctionnalité | Fichiers à créer | Fichiers à modifier |
|----------------|------------------|---------------------|
| Profils | `models/profile.dart`, `screens/profile_select_screen.dart`, `screens/profile_edit_screen.dart` | `main.dart`, `home_screen.dart`, `game_screen.dart`, data_loader / Hive |
| Dashboard | `screens/parent_dashboard_screen.dart`, `screens/pin_lock_screen.dart`, `services/analytics_service.dart` | Navigation, paramètres |
| SRS | `models/word_progress.dart`, `services/srs_service.dart` | `game_screen.dart` (_nextWord, _handleReadingResult), data_loader |
| Gamification | `models/map_level.dart`, `screens/map_screen.dart`, `screens/mascotte_shop_screen.dart` | `home_screen.dart`, `game_screen.dart` (étoiles) |
| Audio | `services/premium_tts_service.dart`, cache audio | `tts_service.dart`, config |

Tu peux utiliser ce document comme cahier des charges pour développer la version Pro étape par étape. Si tu veux, on peut détailler une section (par ex. SRS ou profils) en tâches de code concrètes fichier par fichier.
