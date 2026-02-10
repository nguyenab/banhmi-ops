#!/bin/bash
# Banh Mi Ops - Permission Pre-Authorization
# Merges required tool permissions into Claude Code settings.json
#
# Usage:
#   bash setup-permissions.sh --global
#   bash setup-permissions.sh --local
#   bash setup-permissions.sh --both
#   bash setup-permissions.sh --global --team drupal
#   bash setup-permissions.sh --global --team react
#
# Author: Abraham Nguyen (github.com/nguyenab)
# License: MIT

set -euo pipefail

# Colors
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

info()    { echo -e "${CYAN}[banhmi]${RESET} $*"; }
success() { echo -e "${GREEN}[banhmi]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[banhmi]${RESET} $*"; }
error()   { echo -e "${RED}[banhmi]${RESET} $*" >&2; }
fatal()   { error "$*"; exit 1; }

# Defaults
INSTALL_MODE=""
DIVISIONS=("generic")

usage() {
  cat <<EOF
${BOLD}Banh Mi Ops - Permission Setup${RESET}

Usage: bash setup-permissions.sh [OPTIONS]

Options:
  --global              Update ~/.claude/settings.json
  --local               Update .claude/settings.json in current directory
  --both                Update both locations
  --team <name>     Include team-specific permissions (drupal, react)
  --help                Show this help

Examples:
  bash setup-permissions.sh --global
  bash setup-permissions.sh --local --team drupal
  bash setup-permissions.sh --both --team drupal --team react
EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --global)    INSTALL_MODE="global"; shift ;;
    --local)     INSTALL_MODE="local"; shift ;;
    --both)      INSTALL_MODE="both"; shift ;;
    --team)
      [[ -z "${2:-}" ]] && fatal "--team requires a value"
      DIVISIONS+=("$2"); shift 2 ;;
    --help|-h)   usage ;;
    *)           fatal "Unknown option: $1" ;;
  esac
done

DIVISIONS=($(printf '%s\n' "${DIVISIONS[@]}" | sort -u))

[[ -z "$INSTALL_MODE" ]] && fatal "No install mode specified. Use --global, --local, or --both."

# ---------------------------------------------------------------------------
# Permission definitions
# ---------------------------------------------------------------------------

# Core permissions (always included)
CORE_PERMISSIONS=(
  # Git read commands
  "Bash(git status*)"
  "Bash(git log*)"
  "Bash(git diff*)"
  "Bash(git config*)"
  "Bash(git branch*)"
  "Bash(git show*)"
  "Bash(git rev-parse*)"
  "Bash(git remote*)"

  # File reading
  "Bash(grep*)"
  "Bash(find*)"
  "Bash(ls*)"
  "Bash(cat*)"
  "Bash(head*)"
  "Bash(tail*)"
  "Bash(wc*)"
  "Bash(sort*)"
  "Bash(file*)"

  # File operations
  "Bash(mkdir*)"
  "Bash(cp*)"
  "Bash(chmod*)"
  "Bash(mv*)"
  "Bash(touch*)"

  # Utilities
  "Bash(shasum*)"
  "Bash(sed*)"
  "Bash(python3*)"
  "Bash(date*)"
  "Bash(tee*)"
  "Bash(jq*)"

  # Node.js
  "Bash(npm run build*)"
  "Bash(npm install*)"
  "Bash(node scripts/*)"
  "Bash(node ~/.claude/scripts/*)"

  # Banh Mi Ops scripts
  "Bash(bash scripts/*)"
  "Bash(bash ~/.claude/scripts/*)"
  "Bash(bash .claude/scripts/*)"
)

# Drupal division permissions
DRUPAL_PERMISSIONS=(
  "Bash(drush cr*)"
  "Bash(drush status*)"
  "Bash(drush config:get*)"
  "Bash(drush config:export*)"
  "Bash(drush pml*)"
  "Bash(drush eval*)"
  "Bash(vendor/bin/phpunit*)"
  "Bash(vendor/bin/phpcs*)"
  "Bash(vendor/bin/phpcbf*)"
  "Bash(composer validate*)"
  "Bash(composer info*)"
  "Bash(ddev drush*)"
)

# React division permissions
REACT_PERMISSIONS=(
  "Bash(npx*)"
  "Bash(npm test*)"
  "Bash(npm run dev*)"
  "Bash(npm run lint*)"
  "Bash(npm run format*)"
  "Bash(npm run typecheck*)"
  "Bash(node_modules/.bin/*)"
)

# ---------------------------------------------------------------------------
# Build the full permission list
# ---------------------------------------------------------------------------
build_permissions() {
  ALL_PERMISSIONS=("${CORE_PERMISSIONS[@]}")

  for division in "${DIVISIONS[@]}"; do
    case "$division" in
      drupal)
        info "Adding Drupal division permissions..."
        ALL_PERMISSIONS+=("${DRUPAL_PERMISSIONS[@]}")
        ;;
      react)
        info "Adding React division permissions..."
        ALL_PERMISSIONS+=("${REACT_PERMISSIONS[@]}")
        ;;
      generic)
        # No additional permissions
        ;;
      *)
        warn "Unknown division '${division}', skipping permissions."
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Merge permissions into settings.json
# ---------------------------------------------------------------------------
merge_permissions() {
  local settings_file="$1"
  local settings_dir
  settings_dir="$(dirname "$settings_file")"

  # Create directory if needed
  mkdir -p "$settings_dir"

  # Create settings file if it doesn't exist
  if [[ ! -f "$settings_file" ]]; then
    echo '{}' > "$settings_file"
    info "Created ${settings_file}"
  fi

  # Build JSON array of permissions
  local perms_json="["
  local first=true
  for perm in "${ALL_PERMISSIONS[@]}"; do
    if [[ "$first" == true ]]; then
      first=false
    else
      perms_json+=","
    fi
    perms_json+="\"${perm}\""
  done
  perms_json+="]"

  # Use python3 to merge (available on macOS, Linux, and most systems)
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys

settings_file = '${settings_file}'
new_perms = json.loads('${perms_json}')

try:
    with open(settings_file, 'r') as f:
        settings = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    settings = {}

existing = set(settings.get('permissions', {}).get('allow', []))
merged = list(existing | set(new_perms))
merged.sort()

if 'permissions' not in settings:
    settings['permissions'] = {}
settings['permissions']['allow'] = merged

with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print(f'Merged {len(new_perms)} permissions ({len(merged)} total after dedup)')
" && success "  Permissions merged into ${settings_file}" || fatal "Failed to merge permissions."
  elif command -v jq &>/dev/null; then
    # Fallback to jq
    local tmp_file
    tmp_file="$(mktemp)"
    echo "$perms_json" | jq -s '.[0] as $new |
      (input | if . == null then {} else . end) as $settings |
      ($settings.permissions.allow // []) as $existing |
      ($existing + $new | unique | sort) as $merged |
      $settings * {"permissions": {"allow": $merged}}
    ' - "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"
    success "  Permissions merged into ${settings_file}"
  else
    fatal "Neither python3 nor jq found. Install one and try again."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  echo -e "${BOLD}Banh Mi Ops - Permission Setup${RESET}"
  echo ""

  build_permissions
  info "Preparing ${#ALL_PERMISSIONS[@]} permissions..."

  case "$INSTALL_MODE" in
    global)
      merge_permissions "$HOME/.claude/settings.json"
      ;;
    local)
      merge_permissions "$(pwd)/.claude/settings.json"
      ;;
    both)
      merge_permissions "$HOME/.claude/settings.json"
      merge_permissions "$(pwd)/.claude/settings.json"
      ;;
  esac

  echo ""
  success "Permission setup complete."
  echo -e "  Divisions: ${CYAN}${DIVISIONS[*]}${RESET}"
  echo ""
}

main
