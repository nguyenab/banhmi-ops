#!/bin/bash
# Banh Mi Ops - D2 Diagram Compiler
# Compiles all .d2 diagram files in this directory to SVG.
#
# Prerequisites: d2 (https://d2lang.com)
#
# Usage:
#   bash build.sh              Compile all .d2 files to SVG
#   bash build.sh --png        Compile to PNG instead
#   bash build.sh --check      Check if d2 is installed
#
# Author: Abraham Nguyen (github.com/nguyenab)
# License: MIT

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMAT="svg"

# Colors
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  CYAN='\033[0;36m'
  RESET='\033[0m'
else
  GREEN='' YELLOW='' RED='' CYAN='' RESET=''
fi

info()    { echo -e "${CYAN}[banhmi]${RESET} $*"; }
success() { echo -e "${GREEN}[banhmi]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[banhmi]${RESET} $*"; }
error()   { echo -e "${RED}[banhmi]${RESET} $*" >&2; }

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --png)   FORMAT="png"; shift ;;
    --svg)   FORMAT="svg"; shift ;;
    --check)
      if command -v d2 &>/dev/null; then
        success "d2 found: $(d2 --version 2>/dev/null || echo 'version unknown')"
      else
        error "d2 not found. Install from https://d2lang.com"
        exit 1
      fi
      exit 0
      ;;
    --help|-h)
      echo "Usage: bash build.sh [--svg|--png|--check|--help]"
      exit 0
      ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

# Check for d2
if ! command -v d2 &>/dev/null; then
  error "d2 is not installed."
  echo ""
  echo "  Install d2 from: https://d2lang.com"
  echo ""
  echo "  macOS:   brew install d2"
  echo "  Linux:   curl -fsSL https://d2lang.com/install.sh | sh -s --"
  echo "  Windows: scoop install d2"
  echo ""
  exit 1
fi

# Compile all .d2 files
count=0
for d2_file in "${SCRIPT_DIR}"/*.d2; do
  [[ -f "$d2_file" ]] || continue

  basename="${d2_file%.d2}"
  output="${basename}.${FORMAT}"

  info "Compiling: $(basename "$d2_file") -> $(basename "$output")"
  d2 --theme 200 "$d2_file" "$output" 2>/dev/null && \
    success "  Done: $(basename "$output")" || \
    error "  Failed: $(basename "$d2_file")"

  ((count++))
done

if [[ $count -eq 0 ]]; then
  warn "No .d2 files found in ${SCRIPT_DIR}"
  echo "  Create a .d2 file and run this script again."
else
  success "Compiled ${count} diagram(s)."
fi
