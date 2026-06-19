# Template du rapport secureMe.md

Utilise EXACTEMENT cette structure pour générer `secureMe.md`. Elle est conçue
pour que Claude Code (ou Claude lui-même, dans un second temps) puisse lire le
fichier et exécuter les corrections sans avoir besoin de contexte supplémentaire.

Règles de rédaction :
- Reste compact : une ligne de description du risque, pas de paragraphe.
- Chaque finding doit être actionnable seul, sans dépendre du contexte des autres — sauf dépendance explicite (voir champ `Dépend de`).
- Le fix doit être un snippet de code concret ou une commande exacte — jamais "il faudrait valider l'input" sans montrer comment.
- Classe les findings par sévérité décroissante, puis par catégorie.
- Chaque finding commence par un bloc métadonnée compact (voir format ci-dessous) avant le détail — ça permet à un agent de parser fichier/ligne/action sans devoir lire la prose.
- N'invente jamais une vulnérabilité non vérifiée dans le code : si un doute existe sur l'exploitabilité réelle, le signaler explicitement dans la note plutôt que de gonfler la sévérité.

### Critère AUTO-FIX vs VALIDATION MANUELLE

Le critère n'est PAS "ça touche à l'auth/aux paiements/aux données sensibles" —
beaucoup de fixes dans ces zones n'ont qu'une seule forme correcte (paramétrer
une requête SQL, ajouter un check `user_id` sur une route déjà protégée par un
middleware existant). Le vrai critère :

- **AUTO-FIX** : le fix a une seule réponse correcte techniquement, ET n'a pas
  d'effet de bord qui dépasse le code lui-même. Exemples : requête SQL
  paramétrée, ajout d'un header de sécurité, hash de mot de passe avec
  bcrypt au lieu du clair, bump de dépendance avec CVE connue, ajout d'une
  entrée `.gitignore`.
- **VALIDATION MANUELLE** : au moins une des conditions suivantes s'applique —
  - Le fix implique une action irréversible ou externe au code (révoquer une
    clé API, migrer des données existantes, casser la compatibilité d'un
    client existant).
  - Plusieurs implémentations correctes existent et le choix dépend d'une
    décision produit/métier (quelle politique de mot de passe, quel champ
    whitelister exactement, quelle stratégie de migration).
  - Le fix dépend d'un autre composant du projet non visible dans le fichier
    analysé (ex: un middleware d'auth qui pourrait déjà exister ailleurs) —
    dans ce cas, le signaler avec `À vérifier :` plutôt que de présumer.
  - Si un fix dépend d'un AUTRE finding du rapport (ex: régénérer un secret
    avant de l'utiliser), utilise le champ `Dépend de:` — ça ne rend pas le
    finding manuel en soi, juste ordonné.

```markdown
# Audit de sécurité — [nom du projet]

**Date** : [date du jour]
**Stack détectée** : [ex: Node.js/Express, React/TS, PostgreSQL]
**Fichiers analysés** : [nombre]
**Outils utilisés** : [ex: npm audit, grep patterns, lecture manuelle]
**Audit précédent** : [date du secureMe.md précédent s'il existait, sinon omettre cette ligne]

## Résumé

| Sévérité | Nombre |
|----------|--------|
| 🔴 Critique | X |
| 🟠 Élevée | X |
| 🟡 Moyenne | X |
| ⚪ Faible | X |

**Findings auto-fixables** : X / **Nécessitant validation manuelle** : X

---

## ✅ Résolu depuis le dernier audit

[Uniquement si un secureMe.md précédent existait. Liste courte : ancien ID du
finding + titre + confirmation que le fix a bien été appliqué dans le code
actuel. Si un ancien finding n'est plus présent dans le code mais qu'on ne
sait pas s'il a été corrigé ou juste supprimé/déplacé, le signaler comme tel
plutôt que de l'assumer résolu.]

---

## 🔴 Critique

### [C1] Titre court du problème

> `Action: AUTO-FIX` · `Fichier: chemin/vers/fichier.js:42` · `Catégorie: A03 Injection — SQL` · `Dépend de: —`

- **Risque** : Une phrase expliquant l'impact concret.
- **Code actuel** :
  ```js
  // extrait exact du code concerné
  ```
- **Fix** :
  ```js
  // code corrigé, prêt à appliquer
  ```
- **Note** : [si applicable — raison de la validation manuelle, action externe requise, dépendance à installer, etc.]

(Répéter pour chaque finding critique)

### [C2] Titre — problème répété sur plusieurs fichiers

> `Action: AUTO-FIX` · `Fichiers: routes/a.js:12, routes/b.js:30, routes/c.js:8 (+12 autres, voir liste)` · `Catégorie: ...` · `Dépend de: —`

- **Risque** : Description du problème commun à toutes ces occurrences.
- **Fix générique** : snippet ou commande à appliquer à chaque occurrence listée.
- **Note** : Utilise ce format groupé dès que 3+ occurrences quasi-identiques du même problème existent — ne duplique pas le bloc complet pour chaque fichier.

---

## 🟠 Élevée

(même structure)

---

## 🟡 Moyenne

(même structure)

---

## ⚪ Faible

(même structure)

---

## Findings non exploitables / faux positifs écartés

[Optionnel — si Claude a identifié puis écarté un pattern suspect après vérification du contexte, le noter ici brièvement plutôt que de le supprimer silencieusement. Aide la confiance dans le rapport.]

---

## Plan d'exécution recommandé pour Claude Code

1. Appliquer tous les findings `AUTO-FIX` dans l'ordre (Critique → Élevée → Moyenne → Faible), en respectant les champs `Dépend de`.
2. Pour chaque finding `VALIDATION MANUELLE`, présenter le fix proposé à l'utilisateur et attendre confirmation avant de modifier le fichier.
3. Relancer le skill `secureMe` après corrections pour vérifier que les findings sont résolus.
```
