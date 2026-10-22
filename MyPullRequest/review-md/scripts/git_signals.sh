#!/usr/bin/env bash
# git_signals.sh — Collecte les signaux qui servent à rédiger un REVIEW.md :
# stack, fichiers d'instructions existants, reverts, commits de fix, fichiers
# les plus modifiés, chemins sensibles. Lecture seule : ne modifie rien dans
# le projet, tout sort sur stdout.
#
# Usage: ./git_signals.sh <chemin_du_projet> [fenetre]   (fenetre par défaut : "12 months")

set -uo pipefail

PROJECT_DIR="${1:-.}"
SINCE="${2:-12 months}"
TOP=20

# Fichiers qui faussent le classement par churn : lockfiles, générés, vendored.
NOISE='(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|bun\.lockb|poetry\.lock|Pipfile\.lock|uv\.lock|Cargo\.lock|go\.sum|composer\.lock|Gemfile\.lock)$|(^|/)(dist|build|vendor|node_modules|\.next|coverage)/|\.min\.(js|css)$|\.snap$|CHANGELOG'

# Chemins dont le nom suggère une zone sensible. À confirmer en lisant le code :
# un nom de fichier n'est qu'un indice.
SENSITIVE='auth|login|session|token|jwt|oauth|password|permission|rbac|acl|role|payment|billing|stripe|checkout|invoice|subscription|refund|webhook|crypto|secret|encrypt|migration|schema\.(sql|prisma)|\.github/workflows|\.gitlab-ci|Jenkinsfile|Dockerfile|docker-compose|terraform|\.tf$|helm|k8s|deploy|infra|\.env\.example|middleware|cron|queue|cache|updater|rate.?limit'

cd "$PROJECT_DIR" || { echo "Projet introuvable : $PROJECT_DIR"; exit 1; }

section() { echo; echo "=== $1 ==="; }

section "Stack et commandes de vérification"
# Racine + 2 niveaux, pour couvrir les monorepos.
MANIFESTS=$(find . -maxdepth 3 -not -path '*/node_modules/*' -not -path './.git/*' \
  \( -name package.json -o -name pyproject.toml -o -name requirements.txt -o -name Pipfile -o -name go.mod \
     -o -name Cargo.toml -o -name Gemfile -o -name composer.json -o -name pom.xml -o -name build.gradle \
     -o -name Makefile -o -name Dockerfile -o -name 'docker-compose*.yml' \) 2>/dev/null | sort)
echo "$MANIFESTS" | sed '/^$/d; s/^\.\//- /'
for pkg in $(echo "$MANIFESTS" | grep 'package\.json$'); do
  command -v node >/dev/null 2>&1 || break
  echo "Scripts npm de $pkg :"
  node -e 'const s=require(process.argv[1]).scripts||{};for(const[k,v]of Object.entries(s))console.log(`  ${k}: ${v}`)' "$(realpath "$pkg")" 2>/dev/null
done
for mk in $(echo "$MANIFESTS" | grep 'Makefile$'); do
  echo "Cibles de $mk :"
  grep -E '^[a-zA-Z0-9_-]+:' "$mk" | cut -d: -f1 | sed 's/^/  /' | head -20
done

section "Fichiers d'instructions et de process existants"
for f in CLAUDE.md REVIEW.md AGENTS.md CONTRIBUTING.md CODEOWNERS .github/CODEOWNERS docs/CODEOWNERS \
         .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md .claude/settings.json; do
  [ -e "$f" ] && echo "- $f ($(wc -l < "$f") lignes)"
done
ls .github/workflows 2>/dev/null | sed 's/^/- .github\/workflows\//'

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo; echo "Pas de dépôt git : signaux d'historique indisponibles."
  exit 0
fi

section "Dépôt"
echo "Branche courante : $(git branch --show-current 2>/dev/null)"
DEFAULT=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
[ -z "$DEFAULT" ] && for b in main master; do git rev-parse --verify -q "$b" >/dev/null && { DEFAULT="$b (déduit)"; break; }; done
echo "Branche par défaut : ${DEFAULT:-inconnue}"
echo "Commits total : $(git rev-list --count HEAD 2>/dev/null)"
echo "Commits sur la fenêtre ($SINCE) : $(git rev-list --count --since="$SINCE" HEAD 2>/dev/null)"
echo "Premier commit : $(git log --reverse --format='%ad' --date=short 2>/dev/null | head -1)"
[ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ] && echo "ATTENTION : clone shallow, l'historique est incomplet."

section "Reverts (tout l'historique)"
git log -i --grep='^revert' --grep='this reverts commit' --format='%h %ad %s' --date=short 2>/dev/null | head -$TOP
echo "-- fichiers touchés par ces reverts :"
git log -i --grep='^revert' --grep='this reverts commit' --name-only --format='' 2>/dev/null \
  | grep -v '^$' | grep -Ev "$NOISE" | sort | uniq -c | sort -rn | head -$TOP

section "Fichiers les plus touchés par des commits de fix ($SINCE)"
git log --no-merges --since="$SINCE" -i -E --grep='fix|bug|hotfix|regress|broken|crash|incident|rollback' --name-only --format='' 2>/dev/null \
  | grep -v '^$' | grep -Ev "$NOISE" | sort | uniq -c | sort -rn | head -$TOP
echo "-- derniers messages de fix :"
git log --no-merges --since="$SINCE" -i -E --grep='fix|bug|hotfix|regress|broken|crash|incident|rollback' --format='%h %s' 2>/dev/null | head -$TOP

section "Churn : fichiers les plus modifiés ($SINCE)"
git log --no-merges --since="$SINCE" --name-only --format='' 2>/dev/null \
  | grep -v '^$' | grep -Ev "$NOISE" | sort | uniq -c | sort -rn | head -$TOP

section "Chemins sensibles (d'après le nom, à confirmer) — nb de fichiers par dossier"
# Tests et docs exclus : on cherche le code qui porte le risque, pas sa description.
git ls-files 2>/dev/null | grep -Ev "$NOISE" | grep -iE "$SENSITIVE" \
  | grep -Ev '\.(md|mdx|txt)$|(^|/)(tests?|__tests__|specs?|docs?)/|\.(test|spec)\.' \
  | xargs -r -n1 dirname | sort | uniq -c | sort -rn | head -40

section "Fichiers générés ou vendored suivis par git (candidats à ignorer)"
git ls-files 2>/dev/null | grep -E "$NOISE" \
  | sed -E 's#^((.*/)?(dist|build|vendor|node_modules|\.next|coverage))/.*#\1/#' | sort -u | head -20
