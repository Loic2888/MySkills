#!/usr/bin/env bash
# detect_and_scan.sh — Détecte la stack du projet et exécute les outils
# d'audit de sécurité disponibles. Conçu pour être tolérant aux échecs :
# chaque outil manquant est simplement signalé, jamais bloquant.
#
# Usage: ./detect_and_scan.sh <chemin_du_projet>
# Sortie: résultats bruts dans ./secureme_scan_results/ (créé dans le cwd)

set -uo pipefail

PROJECT_DIR="${1:-.}"
OUT_DIR="./secureme_scan_results"
mkdir -p "$OUT_DIR"

echo "=== secureMe — détection de stack et scan ==="
echo "Projet : $PROJECT_DIR"
echo ""

STACK_REPORT="$OUT_DIR/stack_detected.txt"
> "$STACK_REPORT"

detect() {
  local label="$1"
  local pattern="$2"
  if compgen -G "$PROJECT_DIR/$pattern" > /dev/null 2>&1; then
    echo "$label" >> "$STACK_REPORT"
    return 0
  fi
  return 1
}

# --- Détection de stack ---
detect "Node.js / npm" "package.json"
detect "Python (pip)" "requirements.txt"
detect "Python (poetry)" "pyproject.toml"
detect "Python (pipenv)" "Pipfile"
detect "Docker" "Dockerfile"
detect "Docker Compose" "docker-compose*.yml"
detect "Git repo" ".git"
detect "Ruby" "Gemfile"
detect "Go" "go.mod"
detect "Rust" "Cargo.toml"
detect "PHP / Composer" "composer.json"

echo "Stack détectée :"
cat "$STACK_REPORT" 2>/dev/null || echo "(aucune détectée — analyse manuelle uniquement)"
echo ""

# --- npm audit ---
if [ -f "$PROJECT_DIR/package.json" ]; then
  echo "--> npm audit"
  if command -v npm >/dev/null 2>&1; then
    if [ ! -f "$PROJECT_DIR/package-lock.json" ]; then
      echo "    Pas de package-lock.json — génération d'un lockfile temporaire pour permettre l'audit (lecture seule, n'affecte pas le projet)"
      echo "ALERTE: package-lock.json absent du projet — versions de dépendances non figées, risque de supply chain (voir checklist section 6)" >> "$STACK_REPORT"
      TMP_AUDIT_DIR=$(mktemp -d)
      cp "$PROJECT_DIR/package.json" "$TMP_AUDIT_DIR/" 2>/dev/null
      (cd "$TMP_AUDIT_DIR" && npm install --package-lock-only --silent >/dev/null 2>&1 && npm audit --json) > "$OUT_DIR/npm_audit.json" 2>"$OUT_DIR/npm_audit.err" \
        && echo "    OK (lockfile temporaire) -> $OUT_DIR/npm_audit.json" \
        || echo "    npm audit a trouvé des vulnérabilités ou a échoué (pas de réseau ?) -> voir $OUT_DIR/npm_audit.json"
      rm -rf "$TMP_AUDIT_DIR"
    else
      (cd "$PROJECT_DIR" && npm audit --json) > "$OUT_DIR/npm_audit.json" 2>"$OUT_DIR/npm_audit.err" \
        && echo "    OK -> $OUT_DIR/npm_audit.json" \
        || echo "    npm audit a trouvé des vulnérabilités ou a échoué -> voir $OUT_DIR/npm_audit.json"
    fi
  else
    echo "    npm non disponible — skip (Claude analysera package.json manuellement)"
  fi
fi

# --- pip-audit ---
if [ -f "$PROJECT_DIR/requirements.txt" ] || [ -f "$PROJECT_DIR/pyproject.toml" ]; then
  echo "--> pip-audit"
  if command -v pip-audit >/dev/null 2>&1; then
    if [ -f "$PROJECT_DIR/requirements.txt" ]; then
      pip-audit -r "$PROJECT_DIR/requirements.txt" -f json > "$OUT_DIR/pip_audit.json" 2>"$OUT_DIR/pip_audit.err" \
        && echo "    OK -> $OUT_DIR/pip_audit.json" \
        || echo "    pip-audit a trouvé des vulnérabilités ou a échoué -> voir $OUT_DIR/pip_audit.json"
    fi
  else
    echo "    pip-audit non installé — tentative d'installation locale (pip install --break-system-packages pip-audit)"
    if pip install --break-system-packages -q pip-audit 2>"$OUT_DIR/pip_audit_install.err"; then
      if [ -f "$PROJECT_DIR/requirements.txt" ]; then
        pip-audit -r "$PROJECT_DIR/requirements.txt" -f json > "$OUT_DIR/pip_audit.json" 2>"$OUT_DIR/pip_audit.err" \
          && echo "    OK -> $OUT_DIR/pip_audit.json" \
          || echo "    pip-audit a trouvé des vulnérabilités ou a échoué -> voir $OUT_DIR/pip_audit.json"
      fi
    else
      echo "    Installation impossible (pas de réseau / pas de droits) — skip, Claude analysera requirements.txt manuellement"
    fi
  fi
fi

# --- git-secrets / détection de secrets (fallback grep si outil absent) ---
echo "--> Détection de secrets (pattern scan)"
SECRETS_OUT="$OUT_DIR/secrets_scan.txt"
> "$SECRETS_OUT"

# Patterns courants de secrets — volontairement large, les faux positifs seront
# filtrés par Claude lors de l'analyse contextuelle.
PATTERNS=(
  'AKIA[0-9A-Z]{16}'                       # AWS Access Key
  'sk_live_[0-9a-zA-Z]{24,}'               # Stripe live secret key
  'AIza[0-9A-Za-z_-]{35}'                  # Google API key
  'ghp_[0-9A-Za-z]{36}'                    # GitHub personal access token
  '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
  '(api[_-]?key|apikey)\s*[:=]\s*["\047][0-9A-Za-z_\-]{16,}["\047]'
  '(secret|password|passwd|pwd)\s*[:=]\s*["\047][^"\047]{6,}["\047]'
  'Bearer [A-Za-z0-9_\-\.=]{20,}'
)

if command -v grep >/dev/null 2>&1; then
  for pattern in "${PATTERNS[@]}"; do
    grep -rnE --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=venv \
      --exclude-dir=dist --exclude-dir=build --exclude-dir=.next \
      "$pattern" "$PROJECT_DIR" 2>/dev/null >> "$SECRETS_OUT"
  done

  # Scan dédié aux fichiers .env* : format clé=valeur sans guillemets,
  # les patterns ci-dessus (qui exigent des guillemets) les ratent sinon.
  ENV_KEY_PATTERN='^[A-Za-z0-9_]*(SECRET|PASSWORD|PASSWD|PWD|TOKEN|API_KEY|APIKEY|PRIVATE_KEY)[A-Za-z0-9_]*\s*=\s*\S+'
  find "$PROJECT_DIR" -maxdepth 3 -name ".env*" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | while read -r envfile; do
    grep -HnE "$ENV_KEY_PATTERN" "$envfile" 2>/dev/null >> "$SECRETS_OUT"
  done

  COUNT=$(wc -l < "$SECRETS_OUT" | tr -d ' ')
  echo "    $COUNT correspondance(s) potentielle(s) -> $SECRETS_OUT (à vérifier manuellement, faux positifs probables)"
fi

# --- Vérification .env vs .gitignore ---
echo "--> Vérification .env / .gitignore"
ENV_CHECK="$OUT_DIR/env_gitignore_check.txt"
> "$ENV_CHECK"
if [ -f "$PROJECT_DIR/.env" ]; then
  if [ -f "$PROJECT_DIR/.gitignore" ] && grep -qE '^\.env$|^\.env\*|^\*\.env' "$PROJECT_DIR/.gitignore"; then
    echo ".env présent et listé dans .gitignore — OK" >> "$ENV_CHECK"
  else
    echo "ALERTE: .env présent mais absent de .gitignore (ou .gitignore manquant) — risque de commit de secrets" >> "$ENV_CHECK"
  fi
  if [ -d "$PROJECT_DIR/.git" ] && command -v git >/dev/null 2>&1; then
    if (cd "$PROJECT_DIR" && git ls-files --error-unmatch .env >/dev/null 2>&1); then
      echo "CRITIQUE: .env est actuellement TRACKÉ par git (déjà commité)" >> "$ENV_CHECK"
    fi
  fi
fi
cat "$ENV_CHECK" 2>/dev/null

# --- Dockerfile checks rapides ---
if [ -f "$PROJECT_DIR/Dockerfile" ]; then
  echo "--> Vérification Dockerfile"
  DOCKER_CHECK="$OUT_DIR/dockerfile_check.txt"
  > "$DOCKER_CHECK"
  grep -n "USER root" "$PROJECT_DIR/Dockerfile" >> "$DOCKER_CHECK" 2>/dev/null
  grep -nE "^\s*USER\s" "$PROJECT_DIR/Dockerfile" > /dev/null 2>&1 || echo "Aucune directive USER trouvée -> conteneur tourne probablement en root par défaut" >> "$DOCKER_CHECK"
  cat "$DOCKER_CHECK" 2>/dev/null
fi

echo ""
echo "=== Scan terminé. Résultats bruts dans $OUT_DIR ==="
echo "Claude doit maintenant lire ces fichiers + le code source pour produire secureMe.md"
