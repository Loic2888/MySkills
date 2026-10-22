# MyPullRequest

Deux skills Claude Code pour une review de code adaptée au code écrit par des
agents, inspirés de la façon dont l'équipe Claude Code fait sa review
([Solving code review at Anthropic](https://claude.dev/blog/solving-code-review-at-anthropic/)).

L'idée : la review n'est plus un contrôle final où un humain lit chaque ligne,
mais une suite de vérifications. Chaque risque est confié au contrôle le mieux
placé pour l'attraper, et le temps humain va aux changements qui le méritent.

| Skill | Rôle | Usage |
|---|---|---|
| [`review-md`](review-md/) | Génère un premier `REVIEW.md` à partir du code et de l'historique git, à valider | `/review-md` |
| [`create-pr`](create-pr/) | Prépare et ouvre une PR en s'appuyant sur le `REVIEW.md` | `/create-pr [base] [--draft]` |

## Comment ils s'enchaînent

```
review-md  (une fois par projet, puis à enrichir)
   │  analyse : stack, CLAUDE.md, CI, reverts, commits de fix, churn, zones sensibles
   ▼
REVIEW.md  ── lu aussi par /code-review et Code Review for Claude Code
   │
   ▼
create-pr  (à chaque changement)
   vérifications → review en contexte vierge → corrections (3 tours max)
   → niveau de risque → description (tests, risque, revert) → push + gh pr create
```

`REVIEW.md` contient ce que le reviewer ne peut pas deviner : les pannes réelles
du projet, les zones sensibles et leur niveau (bas / moyen / haut = 0 / 1 / 2
approbations humaines), les classes de bugs récurrentes, ce qu'il faut ignorer,
les commandes de vérification et les règles qui réduisent le bruit.

## Installation

Chaque skill est autonome. Copier les dossiers voulus dans `~/.claude/skills/`
(tous les projets) ou dans `.claude/skills/` d'un projet :

```bash
cp -r MyPullRequest/review-md MyPullRequest/create-pr ~/.claude/skills/
```

Prérequis : `git`. `create-pr` a besoin de [`gh`](https://cli.github.com/)
authentifié pour pousser et créer la PR. Sans `gh`, il prépare tout et te laisse
pousser toi-même.

## Faire vivre le REVIEW.md

- Une remarque de review était du bruit : ajouter une ligne dans « À ignorer ».
- Un bug a échappé à la review : ajouter son symptôme dans « Ce qui casse vraiment ».
- Le même bug revient : l'ajouter aux « Classes de bugs récurrentes », ou mieux,
  en faire une règle de lint ou un test.
