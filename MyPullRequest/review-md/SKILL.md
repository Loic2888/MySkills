---
name: review-md
description: "Génère un premier brouillon de REVIEW.md pour un projet : le fichier qui dit au reviewer (IA ou humain) ce qui compte vraiment dans ce code. Analyse la stack, les fichiers d'instructions existants (CLAUDE.md, CODEOWNERS, CI), l'historique git (reverts, commits de fix, fichiers les plus modifiés) et les zones sensibles (auth, paiement, migrations, CI, infra), puis propose un brouillon où chaque règle est justifiée par une preuve, à valider avant écriture définitive. Déclenche ce skill quand l'utilisateur demande de créer, générer, initialiser ou améliorer un REVIEW.md, des règles de code review pour un projet, ou de préparer un projet pour la review IA / le skill create-pr."
---

# review-md — Générer un premier REVIEW.md

## Ce que fait ce skill

Produit un brouillon de `REVIEW.md` **propre au projet** : les modes de panne
réels, les zones sensibles avec leur niveau de risque, les classes de bugs
récurrentes, ce qu'il faut ignorer et les commandes de vérification.

Un REVIEW.md générique (« attention à la sécurité, aux performances… ») ne sert
à rien : le reviewer le sait déjà. La valeur vient de ce qu'il ne peut pas
deviner, et ça se trouve dans l'historique et le code du projet. Donc **chaque
ligne du brouillon doit s'appuyer sur une preuve** : un commit, un fichier, une
config. Ce qui n'en a pas est marqué `[À CONFIRMER]` ou retiré.

Le fichier est ensuite lu par `/code-review`, par Code Review for Claude Code,
et par le skill `create-pr` (qui en tire les vérifications et le niveau de
risque de la PR).

## Quand s'arrêter et demander

- Le projet à analyser n'est pas évident (plusieurs repos en contexte) : demander lequel.
- Un `REVIEW.md` existe déjà : ne pas l'écraser. Proposer une **mise à jour** : lire l'existant, appliquer le même processus, et présenter uniquement les ajouts/retraits suggérés avec leur preuve.

## Workflow

### Étape 1 — Collecter les signaux

```bash
bash <chemin_du_skill>/scripts/git_signals.sh <chemin_du_projet> [fenetre]
```

Utiliser le chemin réel depuis lequel ce SKILL.md a été chargé. La fenêtre vaut
`"12 months"` par défaut ; la réduire (`"6 months"`) sur un gros repo très actif.
Le script est en lecture seule et sort tout sur stdout : stack et scripts
disponibles, fichiers d'instructions existants, reverts, fichiers touchés par
des commits de fix, churn, chemins sensibles par dossier, fichiers générés.

Si l'historique est vide ou shallow, le dire à l'utilisateur : le brouillon
reposera alors uniquement sur le code, avec plus de `[À CONFIRMER]`.

### Étape 2 — Lire le contexte existant

Lire `CLAUDE.md` (et `AGENTS.md`, `CONTRIBUTING.md`, `CODEOWNERS`, workflows CI
s'ils existent). Ne pas dupliquer dans REVIEW.md ce que CLAUDE.md dit déjà
(stack, conventions générales) : REVIEW.md ne parle que de review.

Dans les monorepos, repérer les sous-projets. Un seul REVIEW.md à la racine
suffit en général, avec des chemins préfixés par sous-projet.

### Étape 3 — Creuser l'historique

Les compteurs du script ne suffisent pas : il faut comprendre **ce qui a cassé**.

- **Reverts** : pour chacun (jusqu'à ~10), `git show --stat <hash>` puis le
  commit reverté. Se demander : quel symptôme, quel fichier, quelle vérification
  l'aurait attrapé ?
- **Commits de fix** : lire les 15-20 derniers messages et, pour ceux qui
  touchent du code (pas `fix(ui)` cosmétique), `git show <hash>`. Regrouper par
  cause : c'est là qu'apparaissent les **classes de bugs récurrentes** (ex. trois
  fix « filtre la suppression par compte » = classe « requête de mutation sans
  filtre de propriétaire »).
- **Fichiers chauds** : un fichier à la fois très modifié *et* souvent fixé est
  un candidat zone sensible, même si son nom ne le suggère pas. Ignorer les
  fichiers de doc/mémoire dans ce classement.
- **Messages de PR** (si `gh` est disponible et authentifié) :
  `gh pr list --state merged --limit 30 --search "fix OR revert OR hotfix"` peut
  compléter.

### Étape 4 — Confirmer les zones sensibles dans le code

Le script repère des chemins **par leur nom**. Ouvrir les fichiers principaux de
chaque dossier listé pour confirmer qu'ils portent vraiment un risque
(contrôle d'accès, argent, données perso, schéma, secrets, déploiement) et
pour trouver ce que le nom ne dit pas (ex. `api/_lib/app.ts` qui monte tous les
middlewares d'auth). Assigner un niveau :

- **haut** (2 approbations) : auth et contrôle d'accès, migrations de schéma,
  paiement, secrets/crypto, workflows CI/CD et infra de déploiement.
- **moyen** (1 approbation) : code produit ordinaire et zones délicates sans être
  critiques (cache, rate limit, webhooks, emails transactionnels, prompts système).
- **bas** (0 si les checks passent) : doc, textes, tests seuls, ajouts derrière un flag.

Ajuster à la réalité du projet : un side project sans utilisateurs n'a pas
besoin de deux approbateurs pour sa CI. Si le projet n'a qu'un contributeur,
le signaler et proposer « haut = relecture humaine attentive du diff » plutôt
qu'un nombre de personnes.

### Étape 5 — Rédiger le brouillon

Suivre `references/review-md-template.md`. Règles :

- **40 à 80 lignes.** Couper avant d'ajouter.
- Langue : celle de la doc du projet (CLAUDE.md / README). Français par défaut.
- Modes de panne formulés comme des **symptômes vérifiables**, pas des catégories.
- Commandes de vérification : uniquement celles qui existent (scripts npm,
  Makefile, CI). Préférer un script `verify` s'il existe déjà.
- Garder la section « Règles de signalement » du modèle telle quelle, sauf
  raison propre au projet : elle est ce qui réduit le bruit.
- Ce qui n'a pas de preuve : `[À CONFIRMER]` en fin de ligne.

Écrire le brouillon dans `REVIEW.draft.md` à la racine du projet (pas
`REVIEW.md` : il n'est pas encore validé, et les outils ne doivent pas le lire).

### Étape 6 — Présenter pour validation

Dans la réponse, ne pas recopier le fichier. Donner :

1. Le chemin du brouillon.
2. Un tableau **règle → preuve** pour les modes de panne, zones sensibles et
   classes de bugs (ex. « Requête de mutation sans filtre de propriétaire →
   `5cb4656`, `1cb7267`, `d8b414f` »).
3. Les points `[À CONFIRMER]` sous forme de **questions courtes** auxquelles
   l'utilisateur peut répondre oui/non (ex. « `CRM/api/_lib/` porte-t-il de
   l'auth ? »). Trois à six questions, pas plus.

Après la réponse de l'utilisateur : appliquer ses corrections, retirer les
marqueurs `[À CONFIRMER]` (confirmés → gardés, infirmés → supprimés), renommer
`REVIEW.draft.md` en `REVIEW.md`. Ne pas committer sauf demande explicite.

## Après coup

Rappeler en une ligne que le REVIEW.md s'améliore à l'usage : quand une remarque
de review est du bruit, ajouter une ligne dans « À ignorer » ; quand un bug passe
la review, ajouter son symptôme dans « Ce qui casse vraiment ».
