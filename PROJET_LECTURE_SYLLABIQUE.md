# Projet : Application de Lecture Syllabique "Le Mot Mystère"

## 1. Vision du Projet
Créer une application mobile (Android/Tablet) pédagogique, bienveillante et engageante.
L'objectif est de dépasser la simple "répétition" pour créer une **relation** avec l'enfant, en lui donnant du **contrôle** sur son apprentissage (autonomie) et en valorisant ses efforts (mémoire affective).

---

## 2. Le Concept : "Le Mot Mystère" & Le Compagnon
L'expérience est guidée par **un compagnon bienveillant** (mascotte : robot doux ou animal) qui dédramatise l'erreur.

### Le Flux (Mise à jour)
1.  **L'Énigme** : Image cachée, mot affiché avec aides visuelles.
2.  **Le Compagnon** : "À toi de jouer ! Si tu as besoin de moi, je suis là."
3.  **L'Action (Micro-Choix)** : L'enfant a le contrôle.
    *   🎙️ **Je lis** : Il active le micro ("Tap to Start").
    *   👀 **Un indice** : Il demande de l'aide (voir "Indices Graduels").
4.  **La Validation Nuancée** :
    *   *Succès immédiat* : "Wouah ! Tu l'as lu tout seul !" 🎉 + Sticker "Lu tout seul".
    *   *Succès hésitant* : "Bravo, c'était pas facile mais tu as réussi !" + Sticker "Champion de l'effort".
    *   *Raté* : Pas d'échec, mais une proposition : "Ce petit mot est coquin. On réessaie ou je te donne un indice ?"

---

## 3. Pédagogie Active & Scaffolding (Échafaudage)
Au lieu d'une correction automatique, on rend l'enfant acteur de son aide.

### A. Les Indices Graduels (Smart Hints)
Si l'enfant bloque ou demande de l'aide, on propose des niveaux d'indices progressifs :
1.  **Niveau 1 (Visuel)** : La syllabe difficile clignote ou change de couleur.
2.  **Niveau 2 (Auditif partiel)** : La syllabe est prononcée seule.
3.  **Niveau 3 (Auditif total)** : Le mot entier est prononcé lentement.

### B. Gestion des Confusions (Méta-cognitive)
L'IA détecte les erreurs typiques (B/P, D/T, CH/J) et intervient avec pédagogie :
*   *Feedback* : "Attention, le son [b] et le son [p] aiment bien se déguiser l'un en l'autre 😉"
*   *Action* : Proposition d'une mini-mission ciblée plus tard.

---

## 4. Architecture Technique & SRS Avancé

### Stack
*   **Flutter** + **Hive** (Base de données locale).
*   **Speech-to-Text** avec tolérance phonétique (Levenshtein).

### La Logique SRS "Non-Binaire"
Le système de répétition ne se contente pas de "Gagné/Perdu".
*   **Succès Facile** : Progression normale (Intervalle x2).
*   **Succès Hésitant** : Niveau inchangé, mais délai de révision raccourci. L'app sait qu'il faut consolider.
*   **Difficulté** : Priorité haute, mais présenté sous forme de **Mini-Missions Narratives**.
    *   *Exemple* : "Inspecteur [Nom de l'enfant], j'ai 3 mots mystères qui ont tous le son 'CH'. On les attrape ?"

---

## 5. Gamification Émotionnelle & Rétention

### Album d'Autocollants (Mémoire Affective)
On ne collecte pas juste des images, on collecte des souvenirs de réussite.
*   **Badges de contexte** : Sur le sticker, un petit badge indique "Lu tout seul" 🥇 ou "Lu avec aide" 🤝.
*   **Datation** : "Ta première réussite le [Date]".

### Diplômes et Export
*   **Diplôme PDF** : Génération d'un petit diplôme "A exploré 20 mots cette semaine".
*   **Partage** : Image générée pour les parents à partager sur WhatsApp ("Jules a libéré le Lion !").

---

## 6. Fonctionnalités Parents & Accessibilité

### Mode Parents "Zéro Culpabilité"
Un tableau de bord ultra-simplifié :
*   "Ce qui progresse super bien" 🚀
*   "Les petits blocages du moment" 🚧
*   "Le conseil de la mascotte" (ex: "Jules confond un peu B et P, jouez à faire des bruits de bulles !").

### Mode "Lecture Silencieuse" (Inclusivité)
Pour les enfants timides ou fatigués :
1.  L'enfant lit dans sa tête.
2.  Il appuie sur "Je l'ai !".
3.  L'app révèle l'image et prononce le mot.
4.  L'enfant confirme "Oui c'était ça" ou "Ah non". (Confiance basée sur l'honnêteté, sans stress du micro).

---

## 7. Plan d'Action (Roadmap Mise à jour V3)
1.  [x] **Data Prep** : Fichiers de base prêts.
2.  [ ] **Data Strucutre V3** : Adapter le JSON pour supporter l'historique détaillé (type de succès, date, badges).
3.  [ ] **Prototype Flutter UI** :
    *   Écran de jeu avec la Mascotte (Image statique au début).
    *   Implémentation des boutons "Micro-Choix".
4.  [ ] **Logique Core** :
    *   Algorithme de validation floue.
    *   Gestionnaire d'indices graduels.
5.  [ ] **Module Parents & Export**.
