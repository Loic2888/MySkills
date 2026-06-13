---
name: create-course
description: Génère une formation complète et approfondie sur un sujet donné, sous forme de page HTML navigable (chapitres, leçons, exemples, exercices). À utiliser quand l'utilisateur demande de créer une "formation", un "cours complet", un "tutoriel détaillé", un module d'apprentissage ou une ressource pédagogique sur un sujet précis.
argument-hint: [sujet de la formation]
arguments: [sujet]
---

# Créer une formation complète sur : $sujet

## Niveau d'exigence

Le livrable est une page HTML autonome (ouvrable dans un navigateur), organisée comme un vrai cours en ligne : chapitres, leçons, navigation, exemples, exercices.

Règle non négociable : la formation doit couvrir "$sujet" EN PROFONDEUR — les fondamentaux ET les sujets avancés, les edge cases, les pièges courants, les bonnes pratiques. Une leçon qui se contente de définir un terme en deux phrases est un échec. Chaque leçon doit pouvoir remplacer un chapitre de livre technique sur le sujet.

Ne te précipite pas vers le HTML final. Le contenu (étapes 1 et 3) est ce qui distingue une vraie formation d'une page jolie mais vide.

## Étape 1 — Cartographier le sujet

Avant d'écrire le moindre contenu :

1. Découpe "$sujet" en 5 à 10 modules (chapitres), des fondamentaux vers l'avancé.
2. Pour chaque module, liste 3 à 6 leçons précises (des titres concrets, pas "Introduction" / "Concepts avancés").
3. Pense aussi aux sujets transverses qu'on oublie souvent : limites/erreurs courantes, comparaison avec des alternatives, cas d'usage réels, débogage/troubleshooting, sécurité ou performance si pertinent pour le sujet.
4. Si "$sujet" est technique et évolue vite (frameworks, outils, librairies récentes), fais 1 à 2 recherches web pour vérifier l'état actuel avant de figer le plan.

Affiche ce plan (liste des modules + leçons) à l'utilisateur et attends une validation rapide, sauf s'il a explicitement demandé de tout générer d'un coup sans étape intermédiaire.

## Étape 2 — Direction visuelle

Avant de coder, choisis une identité visuelle spécifique à "$sujet" — pas un template générique. En 4-5 lignes :

- **Palette** : 4 à 6 couleurs nommées (hex), qui évoquent quelque chose du sujet (pas juste "bleu corporate").
- **Typographie** : une police d'affichage (titres) + une police de texte courant, choisies pour le ton du sujet (académique, ludique, technique...).
- **Signature** : un seul élément distinctif (un motif récurrent, une façon de présenter les exemples, une mise en page de la sidebar...) qui rendra cette formation reconnaissable.

Évite les trois défauts par défaut de "design IA" : fond crème + serif + accent terracotta ; fond noir + un seul accent fluo ; mise en page "broadsheet" avec colonnes denses. Si rien dans le sujet ne justifie l'un de ces choix, pars sur autre chose.

## Étape 3 — Rédiger le contenu, module par module

Travaille module par module (pas tout d'un coup) pour garder de la profondeur sur chaque section sans tronquer. Si le sujet est très large, écris chaque module dans un fichier markdown ou HTML temporaire séparé, puis assemble à l'étape 5.

Pour CHAQUE leçon, inclus :

- **Le concept** : explique le "pourquoi" et le "comment", pas seulement une définition.
- **Exemple(s) concret(s)** : code, schéma en ASCII, cas réel — adapté au sujet.
- **Pièges courants** : erreurs fréquentes, malentendus, limites.
- **Exercice ou question de réflexion** en fin de leçon, pour ancrer l'apprentissage.

Si le sujet a évolué récemment (nouvelle version d'un outil, nouvelle pratique), vérifie par une recherche web plutôt que de t'appuyer uniquement sur tes connaissances.

## Étape 4 — Structure technique de la page

Voir [structure-reference.md](structure-reference.md) pour le squelette HTML/CSS/JS : sidebar de navigation par module/leçon, barre de progression, coloration syntaxique du code, responsive mobile. Adapte les couleurs/typos de ce squelette à la direction visuelle choisie à l'étape 2 — ne le reprends pas tel quel.

## Étape 5 — Auto-relecture (profondeur)

Avant de livrer, relis chaque leçon et pose-toi la question : "Si quelqu'un ne connaît rien à ce sous-sujet, repart-il avec une compréhension réelle et opérationnelle, ou juste un vocabulaire ?" Étoffe toute section qui reste superficielle (moins de 3-4 paragraphes substantiels, ou sans exemple concret).

## Étape 6 — Livraison

Assemble le tout dans un seul fichier HTML autonome (CSS et JS inclus, pas de dépendances locales hormis CDN pour la coloration de code). Sauvegarde-le, puis indique à l'utilisateur où l'ouvrir. Si la formation est vraiment volumineuse (15+ leçons), propose plutôt un fichier par module + une page `index.html` qui sert de sommaire/navigation.
