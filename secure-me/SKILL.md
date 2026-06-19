---
name: secure-me
description: "Réalise un audit de sécurité complet et détaillé d'un projet de code source (n'importe quelle stack — Node.js, Python, React, Docker, etc.), équivalent à une revue faite par un expert en sécurité applicative. Couvre OWASP Top 10, OWASP API Security Top 10, et les vulnérabilités les plus fréquentes dans le code généré par IA ('vibe coding') : injections, auth/contrôle d'accès cassés, secrets exposés, dépendances vulnérables, XSS, CSRF, SSRF, mauvaise configuration, validation d'input manquante. Utilise les outils d'audit disponibles (npm audit, pip-audit) en complément de l'analyse de code. Génère un rapport secureMe.md structuré, classé par sévérité, avec un fix concret pour chaque problème — pensé pour être lu et exécuté directement par Claude Code. Déclenche ce skill dès que l'utilisateur demande un audit de sécurité, un scan de vulnérabilités, de sécuriser le code, de vérifier les failles, une revue de sécurité, ou mentionne secureMe / secureMe.md, même sans formulation exacte."
---

# secureMe — Audit de sécurité de code source

## Ce que fait ce skill

Analyse un projet de code source pour détecter les vulnérabilités de sécurité
les plus courantes et produit un rapport `secureMe.md` actionnable. C'est de
l'**analyse statique** (lecture de code, outils d'audit de dépendances,
recherche de patterns dangereux) — pas un pentest dynamique. Si l'utilisateur
a besoin de tests d'intrusion réels sur une application en ligne (scan actif,
exploitation), précise-le-lui : ce skill ne couvre pas ce périmètre.

## Quand s'arrêter et demander une précision

Si le chemin du projet à auditer n'est pas évident (plusieurs projets dans le
contexte de conversation, ou aucun chemin fourni alors que l'utilisateur n'a
pas de fichiers en cours), demande lequel auditer avant de commencer. Sinon,
procède directement avec le projet en contexte.

## Workflow

### Étape 1 — Scan automatisé (outils + détection de stack)

Exécute le script de détection et de scan :

```bash
bash <chemin_du_skill_secureMe>/scripts/detect_and_scan.sh <chemin_du_projet>
```

Le chemin du skill dépend de l'environnement (ex: `/mnt/skills/user/secureMe/`
ou `~/.claude/skills/secureMe/` selon où il est installé) — utilise le chemin
réel à partir duquel ce SKILL.md a été chargé. Ce script :
- Détecte la stack du projet (Node, Python, Docker, etc.)
- Lance `npm audit` / `pip-audit` si applicable et disponibles, sans bloquer si absents
- Cherche des patterns de secrets hardcodés (clés API, tokens, mots de passe en dur)
- Vérifie la cohérence `.env` / `.gitignore` et si un `.env` est déjà tracké par git
- Vérifie les bases d'un Dockerfile (utilisateur root par défaut, etc.)

Les résultats bruts sont dans `./secureme_scan_results/`. Lis-les avant de
continuer — ils orientent l'analyse manuelle (ex: si `npm audit` remonte 5 CVEs,
ce sont des findings tout faits ; pas besoin de les redécouvrir en lisant le code).

Si un outil n'est pas disponible et ne peut pas être installé (pas de réseau,
pas de droits), ne bloque pas : continue avec l'analyse manuelle de Claude pour
cette partie, et note dans le rapport final que l'outil n'a pas pu tourner
(transparence sur la méthode utilisée).

### Étape 2 — Analyse manuelle du code

Lis `references/owasp-checklist.md` pour la liste complète des catégories à
vérifier. Parcours le code source du projet (fichiers principaux : routes/API,
modèles, middlewares, config, Dockerfile, fichiers d'auth) en gardant cette
checklist en tête. Priorise :

1. Les fichiers liés à l'authentification et aux autorisations
2. Les routes/endpoints API (entrées utilisateur)
3. Les fichiers de configuration et variables d'environnement
4. Les requêtes base de données
5. Les composants frontend qui affichent du contenu dynamique (risque XSS)

N'analyse pas chaque fichier du projet ligne par ligne s'il y en a des
centaines — priorise les fichiers à risque et les patterns identifiés par le
scan automatisé. Pour un projet volumineux, cible en priorité (par nom de
dossier/fichier, indépendamment du langage) :

- `*auth*`, `*login*`, `*session*`, `*jwt*`, `*token*`
- `routes/`, `controllers/`, `api/`, `endpoints/`
- `middlewares/`, `middleware/`, `guards/`
- `models/`, `schemas/` (côté validation des entrées)
- `.env*`, `config/`, `*.config.js`, `docker-compose*.yml`, `Dockerfile`
- Tout fichier remonté par le scan automatisé (secrets, npm audit, etc.)

Si le projet a plus d'une cinquantaine de fichiers de routes/contrôleurs, ne
lis pas tout en détail un par un : repère le pattern dominant (ex: toutes les
routes utilisent le même middleware d'auth importé en haut de fichier) et
vérifie les exceptions à ce pattern plutôt que de tout relire identiquement.

Pour chaque problème identifié, vérifie le contexte réel avant de le retenir :
un pattern qui ressemble à une injection SQL mais qui utilise en fait une
requête paramétrée n'est pas un finding. Mieux vaut un rapport plus court mais
fiable qu'un rapport gonflé de faux positifs.

Ceci s'applique particulièrement aux résultats de `secrets_scan.txt` : le
pattern de détection est volontairement large et matche aussi des cas sans
risque, par exemple `const password = req.body.password` (variable nommée
"password" qui ne contient aucun secret, juste une donnée reçue de
l'utilisateur) ou `// password: à hasher` (commentaire). Ouvre chaque match et
vérifie qu'il s'agit bien d'une valeur secrète en dur avant de le lister comme
finding C3-type. Les valeurs lues depuis `process.env`, `req.body`, ou une
variable ne sont jamais des secrets hardcodés en elles-mêmes.

Si plusieurs occurrences quasi-identiques du même problème existent (ex: 15
routes différentes utilisant toutes le même pattern non sécurisé), ne crée pas
15 findings séparés. Regroupe-les en un seul finding avec la liste des
fichiers/lignes concernés et un seul fix générique à appliquer partout — ça
garde le rapport lisible et évite la répétition inutile pour Claude Code.

### Étape 3 — Génération du rapport secureMe.md

Lis `references/report-template.md` et suis-le exactement pour produire le
rapport. Points clés :
- Classement par sévérité (Critique → Élevée → Moyenne → Faible)
- Chaque finding = bloc métadonnée (fichier:ligne, action, catégorie, dépendance), risque en une phrase, code actuel, fix concret
- Le critère AUTO-FIX vs VALIDATION MANUELLE n'est PAS "ça touche à l'auth/aux
  paiements" — c'est : le fix a-t-il une seule forme techniquement correcte et
  sans effet de bord externe au code ? Si oui → AUTO-FIX, même pour de
  l'auth ou des données sensibles (ex: paramétrer une requête SQL). Si le fix
  implique une action irréversible/externe (révoquer une clé, migrer des
  données), un choix produit (quels champs whitelister), ou dépend d'un
  composant non visible dans le fichier analysé → VALIDATION MANUELLE.
  Détail complet du critère dans `references/report-template.md`.
- Si un finding dépend d'un autre (ex: régénérer un secret avant de l'utiliser
  ailleurs), le signaler avec le champ `Dépend de:` plutôt que de marquer les
  deux manuels par précaution.
- Le fix doit être directement applicable, pas une suggestion vague

Sauvegarde le fichier à la racine du projet audité : `<projet>/secureMe.md`.

### Étape 4 — Présentation à l'utilisateur

Donne un résumé court en conversation (nombre de findings par sévérité,
2-3 points les plus critiques) plutôt que de recopier tout le rapport dans le
chat — le fichier `secureMe.md` est la source de vérité détaillée. Propose
explicitement à l'utilisateur d'ouvrir Claude Code sur le projet et de lui
demander de lire `secureMe.md` pour appliquer les corrections.

Si un `secureMe.md` existe déjà à la racine du projet (run précédent), ne le
régénère pas en ignorant l'historique : vérifie d'abord pour chaque ancien
finding s'il est résolu dans le code actuel. Le nouveau rapport doit
distinguer clairement ce qui a été corrigé depuis le dernier audit (section
"Résolu depuis le dernier audit") de ce qui reste ouvert et des nouveaux
findings — ça permet à l'utilisateur et à Claude Code de vérifier que les
corrections appliquées ont vraiment fonctionné, et pas seulement de repartir
de zéro à chaque run.

## Limites à communiquer si pertinent

- Analyse statique uniquement : pas de scan réseau actif, pas de tentative d'exploitation.
- Les outils d'audit de dépendances (npm audit, pip-audit) ne couvrent que les vulnérabilités déjà publiées (CVE) — un code maison vulnérable mais sans CVE associée n'est détecté que par l'analyse manuelle.
- Pour une application déjà en production avec des données sensibles réelles, recommander en complément un audit par un professionnel certifié (pentest) si le contexte le justifie (données de santé, paiement, etc.) — ce skill est un excellent filet de sécurité pour du vibe coding, pas un substitut à une certification de conformité.

## Fichiers de référence

- `references/owasp-checklist.md` — Checklist détaillée de toutes les catégories de vulnérabilités à vérifier, avec exemples de patterns dangereux par langage.
- `references/report-template.md` — Template exact à suivre pour générer secureMe.md.
- `scripts/detect_and_scan.sh` — Script de détection de stack et d'exécution des outils d'audit disponibles.
