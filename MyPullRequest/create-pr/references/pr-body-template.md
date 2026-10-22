# Modèle de description de PR

À utiliser quand le projet n'a pas de `.github/pull_request_template.md`. S'il en
a un, remplir **ses** sections et ajouter à la fin celles d'ici qui manquent
(Risque, Comment revert, Review IA).

Écrire pour le reviewer humain qui ouvre la PR sans contexte : il doit savoir en
30 secondes ce qui change, comment c'est vérifié et ce qu'il doit regarder.
Supprimer une section vide plutôt que d'écrire « N/A ».

---

~~~markdown
## Résumé

<!-- 1-3 phrases : ce que fait la PR et pourquoi. Lien vers le ticket s'il y en a un. -->

## Changements

<!-- Puces, par intention et non par fichier. 3-7 puces. -->
-

## Tests

<!-- Commandes réellement lancées et leur résultat. Pas de « testé localement » sans détail. -->
- `npm run lint` ✅
- `npm test` ✅ (142 passed)
- Vérification manuelle : <ce qui a été fait, captures si UI>

## Risque : <bas | moyen | haut>

<!-- Pourquoi ce niveau : zones sensibles touchées (d'après REVIEW.md) ou leur absence.
Approbations humaines attendues : bas = 0 si checks verts, moyen = 1, haut = 2. -->

## Comment revert

<!-- Une ligne si `git revert` suffit. Sinon : migration inverse, flag à couper,
données à corriger, ordre des opérations. -->

## Review IA

<!-- Ce que la review pré-PR a trouvé et ce qui en a été fait. -->
- Corrigé : <n> (<résumé court>)
- Laissé volontairement : <remarque> — <raison>
- Préexistant, hors périmètre : <remarque> — <fichier:ligne>

## À regarder en priorité

<!-- Optionnel. 1-3 endroits où l'avis d'un humain compte le plus. -->
~~~
