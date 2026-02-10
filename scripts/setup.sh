#!/bin/bash
# Banh Mi Ops - Cross-Platform Installer
# Works on macOS, Linux, and Windows (Git Bash / WSL)
#
# Usage:
#   bash setup.sh --global              Install to ~/.claude/
#   bash setup.sh --local               Install to .claude/ in current project
#   bash setup.sh --both                Install to both locations
#   bash setup.sh --uninstall           Remove installed files
#   bash setup.sh --team drupal     Also install Drupal division workers
#   bash setup.sh --team react      Also install React division workers
#   bash setup.sh --team generic    Default, always installed
#
# Author: Abraham Nguyen (github.com/nguyenab)
# License: MIT

set -euo pipefail

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BANHMI_SRC="${BANHMI_SRC:-"$(dirname "$SCRIPT_DIR")"}"

# Defaults
INSTALL_MODE=""
UNINSTALL=false
DIVISIONS=("generic")
VERBOSE=false

# Colors (disabled if not a terminal)
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

usage() {
  cat <<EOF
${BOLD}Banh Mi Ops Installer v${VERSION}${RESET}

Usage: bash setup.sh [OPTIONS]

Options:
  --global              Install to ~/.claude/ (all projects)
  --local               Install to .claude/ in current directory
  --both                Install to both global and local
  --uninstall           Remove Banh Mi Ops files from target locations
  --team <name>     Include a team pack (drupal, react, generic)
                        Can be specified multiple times
  --verbose             Show detailed output
  --help                Show this help message

Examples:
  bash setup.sh --global
  bash setup.sh --local --team drupal
  bash setup.sh --both --team drupal --team react
  bash setup.sh --uninstall --global
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
    --uninstall) UNINSTALL=true; shift ;;
    --team)
      [[ -z "${2:-}" ]] && fatal "--team requires a value (drupal, react, generic)"
      DIVISIONS+=("$2"); shift 2 ;;
    --verbose)   VERBOSE=true; shift ;;
    --help|-h)   usage ;;
    *)           fatal "Unknown option: $1. Use --help for usage." ;;
  esac
done

# Deduplicate divisions
DIVISIONS=($(printf '%s\n' "${DIVISIONS[@]}" | sort -u))

# ---------------------------------------------------------------------------
# OS Detection
# ---------------------------------------------------------------------------
detect_os() {
  local uname_out
  uname_out="$(uname -s)"
  case "$uname_out" in
    Linux*)   OS="linux" ;;
    Darwin*)  OS="macos" ;;
    CYGWIN*|MINGW*|MSYS*) OS="windows" ;;
    *)        OS="unknown" ;;
  esac
  info "Detected OS: ${BOLD}${OS}${RESET}"
}

# ---------------------------------------------------------------------------
# Prerequisite checks
# ---------------------------------------------------------------------------
check_prerequisites() {
  info "Checking prerequisites..."
  local missing=()

  # Claude Code CLI
  if command -v claude &>/dev/null; then
    success "  Claude Code CLI found: $(command -v claude)"
  else
    missing+=("Claude Code CLI (https://docs.anthropic.com/en/docs/claude-code)")
  fi

  # Node.js
  if command -v node &>/dev/null; then
    local node_version
    node_version="$(node --version 2>/dev/null || echo "unknown")"
    local node_major="${node_version#v}"
    node_major="${node_major%%.*}"
    if [[ "$node_major" -ge 18 ]] 2>/dev/null; then
      success "  Node.js found: ${node_version}"
    else
      warn "  Node.js ${node_version} found but 18+ recommended"
    fi
  else
    missing+=("Node.js 18+ (https://nodejs.org)")
  fi

  # Bash
  if command -v bash &>/dev/null; then
    success "  Bash found: $(bash --version | head -1)"
  else
    missing+=("Bash")
  fi

  # Git
  if command -v git &>/dev/null; then
    success "  Git found: $(git --version)"
  else
    missing+=("Git (https://git-scm.com)")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing prerequisites:"
    for dep in "${missing[@]}"; do
      error "  - ${dep}"
    done
    fatal "Install the missing dependencies and try again."
  fi

  success "All prerequisites met."
}

# ---------------------------------------------------------------------------
# Directory setup
# ---------------------------------------------------------------------------
resolve_targets() {
  TARGETS=()
  case "$INSTALL_MODE" in
    global) TARGETS+=("$HOME/.claude") ;;
    local)  TARGETS+=("$(pwd)/.claude") ;;
    both)   TARGETS+=("$HOME/.claude" "$(pwd)/.claude") ;;
    *)      fatal "No install mode specified. Use --global, --local, or --both." ;;
  esac
}

# ---------------------------------------------------------------------------
# File installation
# ---------------------------------------------------------------------------
install_to_target() {
  local target="$1"
  info "Installing to ${BOLD}${target}${RESET}..."

  # Create directory structure
  mkdir -p "${target}/commands"
  mkdir -p "${target}/agents"
  mkdir -p "${target}/scripts"
  mkdir -p "${target}/templates"

  # Copy core scripts
  if [[ -d "${BANHMI_SRC}/scripts" ]]; then
    cp -r "${BANHMI_SRC}/scripts/"*.sh "${target}/scripts/" 2>/dev/null || true
    cp -r "${BANHMI_SRC}/scripts/"*.js "${target}/scripts/" 2>/dev/null || true
    if [[ -f "${BANHMI_SRC}/scripts/package.json" ]]; then
      cp "${BANHMI_SRC}/scripts/package.json" "${target}/scripts/"
    fi
  fi

  # Copy templates
  if [[ -d "${BANHMI_SRC}/templates" ]]; then
    cp -r "${BANHMI_SRC}/templates/"* "${target}/templates/" 2>/dev/null || true
  fi

  # Copy protocols
  if [[ -f "${BANHMI_SRC}/protocols.md" ]]; then
    cp "${BANHMI_SRC}/protocols.md" "${target}/protocols.md"
  fi

  # Copy skill files (skills/banhmi/ -> commands/, skills/sweep/ -> commands/)
  if [[ -d "${BANHMI_SRC}/skills/banhmi" ]]; then
    cp -r "${BANHMI_SRC}/skills/banhmi/"*.md "${target}/commands/" 2>/dev/null || true
  fi
  if [[ -d "${BANHMI_SRC}/skills/sweep" ]]; then
    cp -r "${BANHMI_SRC}/skills/sweep/"*.md "${target}/commands/" 2>/dev/null || true
  fi

  # Copy agent files (agents/)
  if [[ -d "${BANHMI_SRC}/agents" ]]; then
    cp -r "${BANHMI_SRC}/agents/"*.md "${target}/agents/" 2>/dev/null || true
  fi

  # Division packs
  for division in "${DIVISIONS[@]}"; do
    local div_dir="${BANHMI_SRC}/teams/${division}"
    if [[ -d "$div_dir" ]]; then
      info "  Installing division: ${BOLD}${division}${RESET}"
      # Copy division worker files directly into agents/
      cp -r "${div_dir}/"*.md "${target}/agents/" 2>/dev/null || true
    else
      if [[ "$division" != "generic" ]]; then
        warn "  Division '${division}' not found at ${div_dir}, skipping."
      fi
    fi
  done

  # Make scripts executable
  chmod +x "${target}/scripts/"*.sh 2>/dev/null || true

  success "  Files installed to ${target}"
}

install_npm_deps() {
  local target="$1"
  local scripts_dir="${target}/scripts"

  if [[ -f "${scripts_dir}/package.json" ]]; then
    info "Installing npm dependencies in ${scripts_dir}..."
    if command -v npm &>/dev/null; then
      (cd "$scripts_dir" && npm install --production --silent 2>/dev/null) && \
        success "  npm dependencies installed." || \
        warn "  npm install failed. Report rendering may not work."
    else
      warn "  npm not found. Skipping dependency install."
    fi
  fi
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------
uninstall_from_target() {
  local target="$1"
  info "Removing Banh Mi Ops files from ${BOLD}${target}${RESET}..."

  local banhmi_files=(
    "scripts/setup.sh"
    "scripts/setup-permissions.sh"
    "scripts/extract-tokens.sh"
    "scripts/render-report.js"
    "scripts/package.json"
    "templates/operation-debrief.html"
    "protocols.md"
  )

  # Skill files installed to commands/
  local skill_files=(
    "commands/OPERATIONS_DIRECTOR.md"
    "commands/OPERATION.md"
    "commands/TESTING.md"
    "commands/SKILL.md"
  )

  # Agent files
  local agent_files=(
    "agents/worker.md"
    "agents/code-reviewer.md"
    "agents/visual-reviewer.md"
    "agents/testing-worker.md"
    "agents/report-writer.md"
    "agents/planner.md"
    "agents/backend-worker.md"
    "agents/frontend-worker.md"
    "agents/fullstack-worker.md"
  )

  for f in "${banhmi_files[@]}" "${skill_files[@]}" "${agent_files[@]}"; do
    if [[ -f "${target}/${f}" ]]; then
      rm -f "${target}/${f}"
      [[ "$VERBOSE" == true ]] && info "  Removed ${f}"
    fi
  done

  # Clean up node_modules in scripts
  if [[ -d "${target}/scripts/node_modules" ]]; then
    rm -rf "${target}/scripts/node_modules"
  fi

  success "  Banh Mi Ops files removed from ${target}"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print_summary() {
  echo ""
  echo -e "${BOLD}============================================${RESET}"
  echo -e "${BOLD}  Banh Mi Ops v${VERSION} - Installation Complete${RESET}"
  echo -e "${BOLD}============================================${RESET}"
  echo ""
  echo -e "  Install mode:  ${CYAN}${INSTALL_MODE}${RESET}"
  echo -e "  Divisions:     ${CYAN}${DIVISIONS[*]}${RESET}"
  echo -e "  OS:            ${CYAN}${OS}${RESET}"
  echo ""
  for target in "${TARGETS[@]}"; do
    echo -e "  Target: ${GREEN}${target}${RESET}"
  done
  echo ""
  echo -e "  Next steps:"
  echo -e "    1. Run ${CYAN}bash setup-permissions.sh${RESET} to pre-authorize tools"
  echo -e "    2. Start Claude Code in your project: ${CYAN}cd ~/your-project && claude${RESET}"
  echo -e "    3. Type ${CYAN}/banhmi${RESET} to begin"
  echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  echo -e "${BOLD}Banh Mi Ops Installer v${VERSION}${RESET}"
  echo ""

  detect_os

  if [[ -z "$INSTALL_MODE" && "$UNINSTALL" == false ]]; then
    fatal "No install mode specified. Use --global, --local, or --both. See --help."
  fi

  resolve_targets

  if [[ "$UNINSTALL" == true ]]; then
    for target in "${TARGETS[@]}"; do
      uninstall_from_target "$target"
    done
    success "Uninstall complete."
    exit 0
  fi

  check_prerequisites

  for target in "${TARGETS[@]}"; do
    install_to_target "$target"
    install_npm_deps "$target"
  done

  print_summary
}

main
