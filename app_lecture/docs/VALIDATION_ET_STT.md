# Validation et reconnaissance vocale — fonctionnement et pistes d’amélioration

Ce document décrit comment fonctionnent aujourd’hui le choix du moteur STT (Vosk vs système), la validation des réponses et la gestion des échecs, puis propose des améliorations.

---

## 1. Qui parle ? (Vosk vs système)

### Où c’est décidé

**Fichier :** `lib/services/speech/hybrid_speech_service.dart`

À chaque appel à `listen()`, le service choisit entre Vosk et le STT système (Android/iOS).

### Règles actuelles

1. **Vosk** n’est utilisé que si :
   - `_voskAvailable == true` (init Vosk réussie),
   - **et** `grammar.isNotEmpty` (une liste de mots/phrases attendus est fournie).

2. **Sur Windows** (détection `Platform.isWindows`) :
   - Si le STT système est disponible → **on force le système**, même si Vosk est dispo et qu’il y a une grammaire.
   - Donc sur PC, c’est **toujours** le système (pas Vosk).

3. **Sur Android / iOS** :
   - Si Vosk est dispo **et** qu’il y a une grammaire → **Vosk**.
   - Sinon (pas de grammaire ou Vosk en échec) → **système**.

### Pourquoi “parfois pas Vosk” ?

- **Sur émulateur/PC** : le code force le système, donc tu ne verras jamais Vosk.
- **Sur Android** :  
  - Si l’init Vosk échoue (modèle absent, erreur au chargement) → fallback système.  
  - Si `_buildGrammar()` renvoyait une liste vide pour un mot (cas limite) → système.  
- La grammaire est bien remplie dans `game_screen` (mot + déterminants + homophones), donc en conditions normales sur téléphone avec Vosk OK, c’est bien Vosk.

En résumé : **sur téléphone = Vosk quand dispo + grammaire ; sur Windows = toujours système.**

---

## 2. Grammaire envoyée au STT

### Où c’est défini

**Fichier :** `lib/screens/game_screen.dart` → `_buildGrammar(String target)`

### Contenu actuel

- Le **mot cible** (ex. `"loup"`).
- **Déterminants** : `"le loup"`, `"la loup"`, `"un loup"`, `"une loup"` (pour “le/la/un/une” + mot).
- **Homophones manuels** : toutes les entrées de `PedagogicUtils.manualHomophones` pour le mot normalisé (ex. pour “lait” : `"les"`, `"laid"`, etc.).

Remarque : **Vosk** utilise cette liste pour restreindre la reconnaissance (vocabulaire fermé). Le **système** ne reçoit pas de grammaire (API Android/iOS ne le permet pas comme Vosk), donc il reconnaît “en ouvert” et peut proposer n’importe quel mot.

---

## 3. Validation : est-ce que l’enfant a “réussi” ?

### Entrée

- **Texte reconnu** : ce que le STT renvoie (peut être en plusieurs morceaux, concaténés dans un buffer).
- **Mot cible** : le mot à lire (ex. `"loup"`).

### Où c’est fait

**Fichier :** `lib/services/pedagogic_utils.dart` → `isValidReading(spoken, target)`

**Fichier :** `lib/services/adaptive_reader.dart` → `onSpeech()` / `_commitAttempt()` appellent cette validation et décident succès / échec / trop d’échecs.

### Étapes de validation (dans l’ordre)

1. **Normalisation**  
   `spoken` et `target` sont normalisés (minuscules, `œ`→`oe`, `æ`→`ae`, suppression de la ponctuation, accents conservés).

2. **Déterminants**  
   Si `spoken` commence par un déterminant connu (`"le "`, `"la "`, `"un "`, `"une "`, etc.), ce préfixe est enlevé et on ne garde que la suite pour la suite des tests.

3. **Homophones manuels**  
   Si le **mot cible** a une liste d’homophones (ex. “lait” → `["les","laid",...]`) :  
   - **Règle actuelle :** `nSpoken == variant` **ou** `nSpoken.contains(variant)`.  
   - Problème : `contains` est très permissif. Ex. cible “lait”, variant “le” → la phrase “le pain” contient “le” et serait acceptée comme “lait”. Autre ex. : “il a dit les” pourrait valider “lait” à cause de “les”.

4. **Match exact**  
   Après normalisation (et sans le déterminant), si `spoken == target` → **valide**.

5. **Levenshtein (distance d’édition)**  
   - Mots **courts** (≤ 3 caractères) : au plus **1** erreur.  
   - Mots **longs** (≥ 4 caractères) : au plus **2** erreurs.  
   - Mots d’**1 caractère** : 0 erreur (match exact uniquement).  
   Ex. “chat” vs “chou” → distance 2, accepté pour un mot de 4 lettres ; “lit” vs “vit” → 1 erreur, accepté.

6. **Contenance**  
   Pour les mots cible **≥ 4 caractères** uniquement : si le mot cible (normalisé) est **contenu** dans `spoken` → **valide**.  
   Ex. phrase “c’est le chocolat” pour cible “chocolat” → accepté.  
   Les mots courts sont exclus pour éviter que “le” soit validé par “table”, “os” par “gros”, etc.

### Synthèse “trop permissif”

- **Homophones + `contains`** : une phrase contenant un homophone peut valider un autre mot (ex. “le” partout pour “lait”).
- **Levenshtein 2** sur 4 caractères : “chat” / “chou” ou “chien” / “chant” peuvent passer.
- **Contenance** : une longue phrase contenant le mot peut suffire, sans exiger que l’enfant ait vraiment dit ce mot seul ou comme noyau de la phrase.

---

## 4. Décision succès / échec / “trop d’échecs” (AdaptiveReader)

### Où c’est fait

**Fichier :** `lib/services/adaptive_reader.dart`

Le flux est :

- Chaque reconnaissance partielle ou finale est ajoutée à un **buffer** et concaténée en une chaîne “dite jusqu’ici”.
- Dès que `isValidReading(spokenSoFar, target)` est vrai → on entre dans `_handleSuccess()` (succès possible).
- Si un **silence** suffisamment long est détecté après une phrase → `_commitAttempt()` : on valide une dernière fois avec le buffer actuel ; si pas valide → `_handleFail()` (échec).

### Règles après “validation vraie” (dans `_handleSuccess`)

Même si `isValidReading` a dit vrai, le lecteur peut **rejeter** le succès pour des raisons “techniques” (éviter les faux positifs) :

1. **Substitution lexicale** (`_lexicalMismatch`)  
   Si la longueur de `spoken` et de `target` (normalisés) diffère de **≥ 4** → rejet (considéré comme un autre mot).

2. **Trop rapide** (durée < `minDurationMs`)  
   - Pour les **mots courts** (cible < 3 caractères) : si la durée de l’énoncé est trop courte → rejet (“guess”).  
   - Pour les **mots longs** (≥ 3 caractères) : cette règle ne s’applique pas (on accepte un match rapide, artefact Vosk).

3. **Match “forcé”** (`_isForcedMatch`)  
   - Si le texte reconnu est **exactement** le mot cible (après norm.) **et** que le mot fait **< 3 caractères** **et** soit :
     - un seul chunk dans le buffer,  
     - soit durée < `minDurationMs`,  
   → rejet (soupçon de hasard ou de reconnaissance trop facile).

4. **Streak de succès**  
   - Il faut **2 succès consécutifs** (`requiredStreak == 2`) pour obtenir **mastered**.  
   - Un seul succès valide → `ReadingResult.success` (mot révélé, bravo, mais pas “maîtrisé”).

### Gestion des échecs

- À chaque rejet (validation fausse ou rejet dans `_handleSuccess`) → `_handleFail()` :
  - `failCount` augmente,
  - `successStreak` est remis à 0 (ou décrémenté).
- **Règle “2 échecs”** : si `failCount >= 2` → `ReadingResult.tooManyAttempts` → on affiche le mot, on dit “Bravo, le mot est X”, on enregistre un échec en SRS, pas de mot suivant auto.

### Paramètres par niveau (PS, MS, GS, CP)

- **Silence** pour considérer la phrase “terminée” : 800–1500 ms selon le niveau.
- **Latence max** avant premier son : 2000–5000 ms (au-delà = échec “démarrage tardif”).
- **Durée min** de l’énoncé pour accepter un succès (mots courts) : 300–600 ms.

---

## 5. Propositions d’amélioration

### 5.1 Utilisation de Vosk

- **Option “forcer Vosk” sur Android**  
  Ajouter un réglage (ex. dans les paramètres ou un flag debug) pour ignorer le fallback système sur Android quand Vosk est dispo, afin de tester toujours dans les mêmes conditions.
- **Log clair au démarrage de l’écoute**  
  Logger explicitement : “Moteur utilisé pour cette écoute : VOSK” ou “SYSTEM”, pour déboguer sans ambiguïté.
- **Décision par plateforme**  
  Documenter ou rendre configurable la règle “sur Windows = toujours système” (utile pour les tests PC).

### 5.2 Validation moins permissive

- **Homophones**  
  Pour les homophones manuels, ne plus accepter `nSpoken.contains(variant)`.  
  Exiger par exemple :
  - soit `nSpoken == variant`,
  - soit “mot isolé” après strip des déterminants (et éventuellement ponctuation) égal à un variant,
  - ou au minimum que le segment pertinent de `spoken` (ex. dernier mot ou mot le plus long) soit un variant, plutôt que n’importe quelle sous-chaîne.
- **Levenshtein**  
  - Garder 1 erreur pour les mots courts.  
  - Pour les mots ≥ 4 lettres : soit garder 2 avec des garde-fous (ex. refuser si la première lettre diffère), soit passer à 1 erreur max pour plus de rigueur, quitte à ajouter des homophones ciblés.
- **Contenance**  
  - Soit désactiver la règle “target contenu dans spoken” pour les phrases longues.  
  - Soit l’autoriser seulement si `spoken` est “proche” du mot (ex. “le chocolat”, “chocolat”) et pas une phrase sans rapport où le mot apparaît (ex. “je veux du chocolat et des bonbons”).
- **Exigence “mot principal”**  
  Après strip du déterminant, exiger que le reste soit soit le mot cible (ou un homophone), soit une chaîne très proche (Levenshtein 0 ou 1), plutôt qu’une longue phrase qui “contient” le mot.

### 5.3 Comportement des échecs et feedback

- **Différencier “pas compris” et “mal lu”**  
  Si le STT renvoie du bruit ou une phrase incohérente (ex. rien en commun avec le mot), ne pas toujours incrémenter `failCount` de la même façon qu’un “lit” pour cible “loup”. Possibilité : un compteur “reconnaissance inutilisable” qui n’entre pas dans la règle des 2 échecs.
- **Nombre d’échecs avant révélation**  
  Rendre le seuil (actuellement 2) configurable par niveau (ex. 3 pour les plus grands) ou via les paramètres.
- **Feedback plus explicite**  
  Après un échec, donner un indice (ex. “Écoute la première syllabe”, “Recommence en disant bien [syllabe]”) sans révéler le mot, pour garder un côté pédagogique avant “trop d’échecs”.

### 5.4 Robustesse et UX

- **Timeout de silence**  
  Revoir les valeurs `silenceMs` (800–1500 ms) : trop court = coupure en plein mot ; trop long = attente longue avant de trancher. Possibilité d’adapter par niveau ou par longueur du mot.
- **Un seul “chunk” pour les mots courts**  
  La règle actuelle qui rejette le “match forcé” sur un seul chunk pour les mots courts est saine ; on peut la conserver et documenter clairement pour éviter de la détendre par erreur.
- **Tests de non-régression**  
  Ajouter des tests unitaires sur `isValidReading` (ex. paires (spoken, target) attendues valides / invalides) et sur la décision Vosk vs système pour une grammaire donnée, pour figer le comportement et éviter de redevenir trop permissif après des changements.

---

## 6. Résumé

| Sujet | Comportement actuel | Piste d’amélioration |
|--------|----------------------|----------------------|
| **Qui parle ?** | Android : Vosk si dispo + grammaire ; Windows : toujours système. | Log explicite “VOSK”/“SYSTEM”, option “forcer Vosk” sur Android. |
| **Homophones** | `spoken.contains(variant)` → très permissif. | N’accepter que mot (ou segment pertinent) égal à un variant. |
| **Levenshtein** | 2 erreurs pour mots ≥ 4 lettres. | Garde-fous (ex. première lettre) ou seuil 1. |
| **Contenance** | Mot cible dans une phrase longue = succès. | Restreindre (ex. phrase courte ou “mot principal” uniquement). |
| **Échecs** | 2 échecs → révélation + SRS échec. | Seuil configurable ; distinguer “non reconnu” vs “mal lu”. |
| **Feedback** | “Essaie encore” / “Écoute bien…”. | Indices par syllabe ou par type d’erreur (attaque / finale). |

Tu peux utiliser ce document comme base pour ajuster la logique (validation, échecs, choix STT) sans changer le reste de l’app, en modifiant d’abord les parties qui te semblent les plus gênantes (par ex. homophones + contenance).
