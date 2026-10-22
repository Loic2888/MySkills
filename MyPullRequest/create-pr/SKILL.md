---
name: create-pr
description: "Prépare et ouvre une pull request GitHub en s'appuyant sur le REVIEW.md du projet : lance les vérifications qu'il liste, fait une review du diff par un sous-agent en contexte vierge selon ses règles, corrige les remarques importantes (3 tours max), calcule le niveau de risque d'après les zones sensibles touchées, rédige la description (tests, risque, comment revert, résultat de la review IA), puis pousse la branche et crée la PR avec gh après confirmation. Déclenche ce skill quand l'utilisateur demande de faire, ouvrir, créer ou préparer une PR / pull request / merge request, ou de « pousser pour review »."
argument-hint: "[branche-de-base] [--draft]"
---

# create-pr — Ouvrir une PR guidée par REVIEW.md

## Ce que fait ce skill

Fait passer un changement par les étapes « avant la PR » d'un pipeline de review
moderne, puis ouvre la PR :

1. vérifications (lint, types, tests, build) avec leur sortie réelle ;
2. review du diff par un sous-agent qui n'a pas écrit le code ;
3. correction des remarques importantes ;
4. niveau de risque déterminé par **le changement**, pas par l'auteur ;
5. description qui donne au reviewer humain les preuves, pas des promesses.

Le `REVIEW.md` du projet fournit le contexte : commandes de vérification, modes
de panne, zones sensibles et leur niveau, règles de signalement. Le skill porte
le processus, le fichier porte la connaissance du projet.

Arguments : `$ARGUMENTS`. Premier argument optionnel = branche de base (sinon
la branche par défaut du dépôt). `--draft` force une PR brouillon.

## Préconditions

Vérifier, et s'arrêter avec un message clair si l'une échoue :

- Dépôt git avec un remote (`git remote -v`).
- `gh` installé et authentifié (`gh auth status`). Sinon, proposer de tout
  préparer quand même (commits, description dans un fichier) et de laisser
  l'utilisateur pousser.
- Branche de base : argument, sinon `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`,
  sinon `main`/`master`. `git fetch origin <base>` pour comparer à jour.

## Workflow

### Étape 1 — Charger le contexte

Lire `CLAUDE.md` et `REVIEW.md` à la racine (et dans le sous-projet concerné pour
un monorepo). Lire aussi `.github/pull_request_template.md` et `CODEOWNERS`
s'ils existent.

**Pas de REVIEW.md** : le dire en une ligne, proposer le skill `review-md` pour
la suite, et continuer avec des règles génériques (vérifications détectées dans
les scripts du projet, zones sensibles = auth, paiement, migrations, CI/infra,
secrets ; règles de signalement = celles de la consigne du sous-agent, étape 4).

### Étape 2 — Cerner le changement

```bash
git status --short
git log --oneline <base>..HEAD
git diff --stat <base>...HEAD
```

- **Sur la branche de base** : créer une branche avant tout commit. Nom selon la
  convention visible dans `git branch -a` / l'historique ; sinon `<type>/<sujet-court>`.
- **Changements non commités** : les montrer. Committer ceux qui appartiennent au
  changement, avec des messages au format de l'historique du projet. Ne jamais
  ajouter `.env`, clés, dumps ou fichiers de build. S'il y a des changements sans
  rapport entre eux, demander lesquels inclure.
- **Taille** : au-delà de ~400 lignes modifiées hors lockfiles/générés, ou si le
  diff mélange plusieurs intentions (refacto + feature, plusieurs features),
  proposer de découper avant de continuer. Les petites PR se relisent, se
  déboguent et se revertent mieux. Continuer si l'utilisateur le décide.

### Étape 3 — Vérifications

Lancer les commandes de la section « Vérifications » de REVIEW.md, sinon celles
de CLAUDE.md, sinon celles détectées (`lint`, `check`/`typecheck`, `test`,
`build` dans package.json, Makefile, pyproject…). Dans un monorepo, seulement
celles des sous-projets touchés.

- Garder la sortie réelle (résumé : nombre de tests, erreurs). Ne jamais écrire
  « les tests passent » sans l'avoir vu.
- Échec causé par le diff : corriger, relancer.
- Échec préexistant (vérifiable en lançant la même commande sur `<base>`) : ne
  pas corriger ici, le noter pour la description.
- Échec non résolu : s'arrêter et demander, ou continuer en PR **draft** si
  l'utilisateur le veut.

### Étape 4 — Review en contexte vierge

Lancer un sous-agent (outil Agent) qui **n'a pas vu la conversation**. Lui
donner uniquement : le contenu de REVIEW.md (ou les règles génériques), le
CLAUDE.md, la commande pour obtenir le diff (`git diff <base>...HEAD`) et le
chemin du repo. Consigne :

> Relis ce diff comme un reviewer exigeant. Cherche les bugs de correction, les
> régressions et les violations des règles de REVIEW.md, en priorité sur ses
> « modes de panne » et ses « zones sensibles ». Pour chaque remarque :
> `fichier:ligne`, scénario concret qui casse, étiquette Important / Nit /
> Préexistant. Pas de style ni de formatage. Au plus 3 nits. Si tu trouves une
> instance d'une classe de bugs, cherche les autres dans le diff et signale la
> classe une fois. Commence par le nombre de remarques Important ; s'il n'y a
> rien, dis-le en une ligne.

Si le skill `code-review` est disponible, il peut remplacer ce sous-agent : il
lit lui-même REVIEW.md.

**Vérifier chaque remarque** avant d'agir : relire le code cité et confirmer que
le scénario est réel. Écarter celles qui ne tiennent pas (et le noter, pour
améliorer REVIEW.md plus tard).

### Étape 5 — Corriger et converger

- **Important** : corriger, relancer les vérifications concernées, committer.
- **Nit** : corriger seulement si trivial et sans risque, sinon laisser.
- **Préexistant** : ne pas corriger dans cette PR, le lister dans la description.

Refaire une review (étape 4) **sur le diff des corrections seulement**, sans
répéter les remarques déjà traitées. **3 tours maximum.** Au-delà, s'arrêter et
dire à l'utilisateur que l'approche mérite d'être reconsidérée : des remarques
qui ne convergent pas signalent souvent un problème de conception, pas de détail.

### Étape 6 — Niveau de risque

Croiser les fichiers modifiés (`git diff --name-only <base>...HEAD`) avec le
tableau « Zones sensibles » de REVIEW.md. Le niveau de la PR = le plus haut
niveau touché. Par défaut :

| Niveau | Exemples | Approbations humaines |
|---|---|---|
| bas | doc, textes, tests seuls, ajout derrière un flag | 0 si les checks sont verts |
| moyen | code produit ordinaire | 1 |
| haut | auth, migrations, paiement, secrets, CI/infra | 2 |

Règles : le niveau vient du changement, jamais de l'auteur ni de l'urgence. Une
validation par un agent ne compte pas comme une approbation humaine. Pour moyen
et haut, proposer des reviewers d'après `CODEOWNERS` (ou les auteurs récents des
fichiers touchés : `git log --format='%an' -- <fichier> | sort | uniq -c | sort -rn`).

### Étape 7 — Description

Titre : court, à l'impératif, au format des titres de PR/commits existants
(`gh pr list --state merged --limit 10` pour le voir).

Corps : `references/pr-body-template.md`, ou le template du projet complété par
les sections Risque, Comment revert et Review IA. Les sections Tests et Review
IA reprennent les résultats réels des étapes 3 à 5. « Comment revert » est
spécifique : une migration, un flag ou une donnée modifiée ne se revertent pas
avec `git revert` seul.

Respecter les conventions d'attribution des commits/PR de l'environnement
(ligne Co-Authored-By, mention de l'outil) quand elles existent.

### Étape 8 — Confirmer, pousser, créer

Pousser et ouvrir une PR est visible par d'autres : **montrer d'abord** le titre,
le niveau de risque, les reviewers proposés et un résumé du corps, et demander
confirmation (sauf si l'utilisateur a déjà dit d'y aller sans demander).

Puis :

```bash
git push -u origin HEAD
gh pr create --base <base> --title "<titre>" --body-file <fichier_temporaire> [--draft] [--reviewer <logins>]
```

Écrire le corps dans un fichier temporaire (répertoire scratchpad/temp, pas dans
le repo) pour éviter les problèmes d'échappement. `--draft` si demandé, ou si
des vérifications échouent encore.

### Étape 9 — Compte rendu

En quelques lignes : URL de la PR, niveau de risque et approbations attendues,
vérifications (vert/rouge), remarques corrigées / laissées, et ce qui reste à
faire. Si la review a écarté des remarques comme du bruit ou raté quelque chose
que REVIEW.md aurait dû couvrir, proposer la ligne à ajouter au REVIEW.md.
