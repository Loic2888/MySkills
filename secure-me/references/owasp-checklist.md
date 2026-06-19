# Checklist de vulnérabilités — référence détaillée

Cette checklist couvre OWASP Top 10 (2021), OWASP API Security Top 10 (2023), un
sous-ensemble pertinent d'OWASP ASVS (niveaux L1/L2), et des checks transverses
spécifiques au code généré par IA ("vibe coding"). Parcours les catégories
pertinentes selon la stack détectée — pas besoin de tout vérifier si le projet
n'a pas d'API, pas de DB, etc.

Pour chaque vulnérabilité trouvée, note : fichier, ligne, catégorie, sévérité,
et un fix concret. La sévérité suit ce barème :

- **Critique** : exploitable directement, impact majeur (RCE, auth bypass, fuite de secrets, injection SQL)
- **Élevée** : exploitable avec conditions, impact significatif (XSS stocké, IDOR, SSRF)
- **Moyenne** : nécessite des conditions particulières ou impact limité (XSS réfléchi, CSRF sans action sensible, info disclosure)
- **Faible** : bonne pratique non respectée, durcissement (headers manquants, verbosité des erreurs)

---

## 1. Injection (OWASP A03:2021)

- **SQL Injection** : requêtes construites par concaténation/template string au lieu de requêtes paramétrées/préparées. Chercher : concaténation de variables dans des strings SQL, `f"SELECT...{var}"`, `` `SELECT...${var}` ``, `.format()` dans du SQL.
- **NoSQL Injection** : objets de requête MongoDB construits depuis l'input utilisateur sans validation (`$where`, opérateurs injectés via JSON).
- **Command Injection** : `exec()`, `eval()`, `os.system()`, `subprocess` avec `shell=True`, `child_process.exec()` recevant de l'input utilisateur non sanitizé.
- **LDAP/XPath/Template Injection** : même logique — input utilisateur interpolé dans un langage de requête/template sans échappement (attention aux moteurs de template type Jinja2/EJS en mode non-autoescape, ou `eval`-like dans les templates).
- **Path Traversal** : chemins de fichiers construits avec input utilisateur sans validation (`../`), `fs.readFile(userInput)`, `open(request.args.get('file'))`.

## 2. Authentification et gestion de session (OWASP A07:2021)

- Mots de passe stockés en clair ou avec hash faible (MD5, SHA1 sans salt). Vérifier l'usage de bcrypt/argon2/scrypt.
- Absence de limitation de tentatives de connexion (brute force possible).
- Tokens JWT : vérifier l'algorithme (`alg: none` accepté ? vérification de signature présente ?), durée d'expiration absente ou trop longue, secret faible/hardcodé.
- Sessions : cookies sans `HttpOnly`, `Secure`, `SameSite`.
- Politique de mot de passe absente côté backend (uniquement côté frontend = contournable).
- Réinitialisation de mot de passe : token prévisible, pas d'expiration, pas de vérification d'identité.
- Endpoints d'authentification exposant des messages différents pour "user inexistant" vs "mauvais mot de passe" (énumération de comptes).

## 3. Contrôle d'accès (OWASP A01:2021)

- **IDOR (Insecure Direct Object Reference)** : accès à une ressource via un ID dans l'URL/body sans vérifier que l'utilisateur authentifié en est bien propriétaire (`GET /api/orders/:id` sans check `order.userId === req.user.id`).
- **Broken Function Level Authorization** : routes admin/sensibles accessibles sans vérification de rôle, ou vérification faite seulement côté frontend.
- CORS mal configuré : `Access-Control-Allow-Origin: *` combiné à `Access-Control-Allow-Credentials: true`, ou origine reflétée dynamiquement sans whitelist.
- Absence de middleware d'autorisation centralisé — vérifications dupliquées/oubliées route par route.

## 4. Conception non sécurisée / Configuration (OWASP A04, A05:2021)

- Mode debug activé en production (`DEBUG=True`, stack traces exposées aux utilisateurs).
- Headers de sécurité HTTP manquants : `Content-Security-Policy`, `X-Content-Type-Options`, `X-Frame-Options`, `Strict-Transport-Security`.
- CORS, CSP ou permissions trop permissifs par défaut.
- Services/ports exposés inutilement dans la config Docker (`0.0.0.0` au lieu de `127.0.0.1` quand non nécessaire).
- Permissions de fichiers trop larges (notamment scripts, clés).
- Composants par défaut non désactivés (comptes de démo, endpoints de debug, panneaux d'admin par défaut).

## 5. Secrets et données sensibles (OWASP A02, A05:2021)

- **Secrets hardcodés** dans le code source : clés API, tokens, mots de passe DB, secrets JWT. Chercher patterns : `api_key=`, `password=`, `secret=`, `Bearer `, clés au format connu (AWS `AKIA...`, Stripe `sk_live_...`, etc.).
- Fichiers `.env` commités dans git (vérifier `.gitignore`).
- Clés privées (`.pem`, `.key`) présentes dans le repo.
- Données sensibles loggées en clair (mots de passe, tokens, PII dans les logs).
- Absence de chiffrement pour les données sensibles au repos (PII, données de paiement).
- Connexions non chiffrées (HTTP au lieu de HTTPS pour des échanges sensibles, DB sans SSL en prod).

## 6. Dépendances vulnérables (OWASP A06:2021)

- Dépendances avec CVE connues — utiliser les outils d'audit natifs (voir SKILL.md).
- Dépendances non maintenues / versions très obsolètes.
- Lockfile absent (`package-lock.json`, `poetry.lock`) → versions non figées, risque de supply chain.
- Dépendances installées depuis des sources non officielles.

## 7. Intégrité des données et du code (OWASP A08:2021)

- Désérialisation non sécurisée : `pickle.loads()` sur input non fiable (Python), `eval(JSON)` au lieu de `JSON.parse()`, désérialisation YAML non sécurisée (`yaml.load` au lieu de `yaml.safe_load`).
- Mises à jour auto ou CI/CD sans vérification d'intégrité (signatures, checksums).
- Absence de validation de schéma sur les inputs API (pas de Zod/Joi/Pydantic/validation côté backend).

## 8. Logging et monitoring (OWASP A09:2021)

- Absence de logs sur les événements de sécurité (échecs d'auth, accès refusés, erreurs serveur).
- Logs contenant des données sensibles (voir section 5).
- Pas d'alerting / pas de traçabilité en cas d'incident.

## 9. SSRF (OWASP A10:2021)

- Requêtes serveur vers une URL fournie par l'utilisateur sans validation/whitelist (`fetch(userProvidedUrl)`, `requests.get(user_input)`) — risque d'accès aux ressources internes (metadata cloud, réseau interne).

## 10. XSS (Cross-Site Scripting)

- **Stocké** : input utilisateur stocké puis réaffiché sans échappement.
- **Réfléchi** : input utilisateur réinjecté immédiatement dans la réponse sans échappement.
- **DOM-based** : usage de `innerHTML`, `dangerouslySetInnerHTML` (React), `v-html` (Vue) avec du contenu non sanitizé.
- Absence de CSP comme défense en profondeur.

## 11. CSRF (Cross-Site Request Forgery)

- Actions sensibles (changement de mot de passe, transactions, suppression) exécutables sans token CSRF ni vérification d'origine, sur des routes utilisant l'authentification par cookie.

## 12. OWASP API Security Top 10 — spécifique aux API

- **Excessive Data Exposure** : endpoints retournant des objets complets (ex. `User` avec `passwordHash`) au lieu de DTOs filtrés.
- **Mass Assignment** : body de requête mappé directement sur le modèle DB sans whitelist de champs (`req.body` passé tel quel à un `.create()`/`.update()`, permettant à un attaquant d'injecter `role: "admin"`).
- **Absence de rate limiting** sur les endpoints publics/sensibles (login, recherche, endpoints coûteux).
- **Lack of Resources & Rate Limiting** : absence de pagination, de limite de taille de payload, de timeout.
- Versionning d'API absent → anciennes versions vulnérables restées accessibles.

## 13. Validation des inputs (transverse, ASVS V5)

- Absence de validation de type/format/longueur sur les inputs (frontend ET backend — la validation frontend seule ne compte pas).
- Upload de fichiers : absence de vérification du type MIME réel (pas juste l'extension), absence de limite de taille, fichiers exécutables acceptés, pas de renommage/isolation du fichier uploadé.
- Désérialisation/parsing JSON sans limite de profondeur/taille (DoS possible).

## 14. Checks spécifiques "vibe coding" / code généré par IA

Ces problèmes apparaissent fréquemment dans du code généré rapidement par un
assistant IA sans revue de sécurité :

- Endpoints CRUD générés en série où l'auth/autorisation a été ajoutée sur certains mais oubliée sur d'autres (incohérence à travers les routes).
- Copier-coller de logique d'auth avec une variable mal adaptée (vérifie le bon champ utilisateur dans chaque route).
- Configuration de exemple/tutoriel laissée telle quelle (secrets d'exemple, `CHANGE_ME` non changé, configs Docker/CORS "permissives pour le dev" jamais durcies).
- Gestion d'erreur générique qui renvoie l'erreur brute (stack trace, message DB) au client.
- TODOs ou commentaires indiquant une sécurité non finalisée (`// TODO: add auth`, `// FIXME: validate input`).
