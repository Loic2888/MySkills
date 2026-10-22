# Modèle de REVIEW.md

Squelette à remplir. Chaque section est optionnelle sauf « Ce qui casse vraiment »
et « Règles de signalement ». Viser **40 à 80 lignes** au total : le fichier est
chargé à chaque review, et chaque ligne inutile dilue celles qui comptent.

Les commentaires `<!-- -->` sont des consignes pour le rédacteur : les retirer
du fichier final.

---

~~~markdown
# REVIEW.md — <nom du projet>

<!-- 1-2 phrases. Ce que fait le projet et ce qu'une régression coûte (argent,
données, confiance, rien). Pas de description de la stack : CLAUDE.md s'en charge. -->
<Projet> est <quoi>. Une régression ici coûte surtout <quoi>.

## Ce qui casse vraiment

<!-- Les modes de panne réels, tirés de l'historique (reverts, fix récurrents)
et des zones sensibles. Formuler comme un symptôme vérifiable, pas comme une
catégorie générique. Mauvais : « attention à la sécurité ». Bon : « une route
API qui oublie le filtre tenant_id expose les données d'un autre client ». -->

- <Mode de panne concret> — <où regarder>.
- ...

## Zones sensibles

<!-- Chemins (globs) où une erreur coûte cher. Le niveau sert à create-pr pour
fixer le nombre d'approbations humaines : bas = 0, moyen = 1, haut = 2. -->

| Chemin | Pourquoi | Niveau |
|---|---|---|
| `src/auth/**` | Session et contrôle d'accès | haut |
| `supabase/migrations/**` | Schéma prod, irréversible sans migration inverse | haut |
| `.github/workflows/**` | Secrets CI, déploiement | haut |
| `src/billing/**` | Argent | moyen |

Tout le reste : **bas** par défaut (doc, copy, ajout derrière un flag).

## Classes de bugs récurrentes

<!-- Les bugs qui sont revenus plusieurs fois. Quand le reviewer en trouve une
instance, il doit chercher toutes les autres dans le diff et signaler la classe
une seule fois. -->

- <Classe> — vu dans <commit/PR>, <commit/PR>.

## À ignorer

<!-- Chemins à ne pas relire et types de remarques à ne pas faire. -->

- Fichiers générés / lockfiles : `package-lock.json`, `dist/**`, ...
- Style et formatage : couverts par <prettier/eslint/ruff>.
- <Autre chose propre au projet>

## Vérifications

<!-- Commandes exactes, depuis la racine, que l'auteur et create-pr lancent
avant d'ouvrir une PR. Uniquement des commandes qui existent vraiment. -->

```bash
npm run lint
npm run check
npm test
```

## Règles de signalement

- Chaque remarque cite `fichier:ligne` et explique le scénario concret qui casse. Sans preuve, pas de remarque.
- Étiqueter chaque remarque : **Important** (bloque), **Nit** (non bloquant), **Préexistant** (pas introduit par ce diff).
- Au plus 3 nits par review.
- Ne pas répéter une remarque déjà postée sur la PR.
- Le résumé commence par le nombre de remarques Important. S'il n'y a rien à corriger, le dire en une ligne.
~~~
