#!/bin/bash
# Banh Mi Ops - Token Extraction
# Reads Claude Code session logs and extracts token usage data.
#
# Usage:
#   bash extract-tokens.sh [SESSION_DIR]
#   bash extract-tokens.sh --latest
#   bash extract-tokens.sh --summary
#
# Output: NDJSON lines with token counts per interaction, or a summary.
#
# Author: Abraham Nguyen (github.com/nguyenab)
# License: MIT

set -euo pipefail

# Colors
if [[ -t 1 ]]; then
  CYAN='\033[0;36m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  CYAN='' GREEN='' YELLOW='' BOLD='' RESET=''
fi

info()  { echo -e "${CYAN}[banhmi]${RESET} $*" >&2; }
warn()  { echo -e "${YELLOW}[banhmi]${RESET} $*" >&2; }

# Default session log locations
CLAUDE_LOG_DIR="${CLAUDE_LOG_DIR:-$HOME/.claude/logs}"
MODE="extract"
TARGET=""

usage() {
  cat <<EOF
Banh Mi Ops - Token Extraction

Usage:
  bash extract-tokens.sh [OPTIONS] [SESSION_DIR]

Options:
  --latest      Process the most recent session log
  --summary     Print a human-readable summary instead of NDJSON
  --dir <path>  Specify custom log directory
  --help        Show this help

Examples:
  bash extract-tokens.sh --latest
  bash extract-tokens.sh --latest --summary
  bash extract-tokens.sh /path/to/session/logs
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --latest)   MODE="latest"; shift ;;
    --summary)  MODE="summary"; shift ;;
    --dir)      CLAUDE_LOG_DIR="$2"; shift 2 ;;
    --help|-h)  usage ;;
    *)          TARGET="$1"; shift ;;
  esac
done

# ---------------------------------------------------------------------------
# Find session logs
# ---------------------------------------------------------------------------
find_log_files() {
  local search_dir="${TARGET:-$CLAUDE_LOG_DIR}"

  if [[ ! -d "$search_dir" ]]; then
    warn "Log directory not found: ${search_dir}"
    warn "Set CLAUDE_LOG_DIR or pass a directory as argument."
    exit 1
  fi

  if [[ "$MODE" == "latest" || "$MODE" == "summary" ]]; then
    # Find the most recent log file
    find "$search_dir" -name "*.jsonl" -o -name "*.json" 2>/dev/null | \
      sort -t/ -k$(echo "$search_dir" | tr -cd '/' | wc -c | tr -d ' ') -r | \
      head -1
  else
    find "$search_dir" -name "*.jsonl" -o -name "*.json" 2>/dev/null | sort
  fi
}

# ---------------------------------------------------------------------------
# Extract tokens from a log file
# ---------------------------------------------------------------------------
extract_from_file() {
  local log_file="$1"

  if [[ ! -f "$log_file" ]]; then
    warn "File not found: ${log_file}"
    return 1
  fi

  info "Processing: ${log_file}"

  # Use python3 for robust JSON parsing
  python3 -c "
import json
import sys

log_file = '${log_file}'
total_input = 0
total_output = 0
interactions = 0
models = {}

with open(log_file, 'r') as f:
    for line_num, line in enumerate(f, 1):
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        # Look for token usage in various formats
        usage = None
        if isinstance(entry, dict):
            usage = entry.get('usage') or entry.get('token_usage')
            if not usage and 'message' in entry:
                msg = entry['message']
                if isinstance(msg, dict):
                    usage = msg.get('usage')

        if usage and isinstance(usage, dict):
            input_tokens = usage.get('input_tokens', 0) or usage.get('prompt_tokens', 0)
            output_tokens = usage.get('output_tokens', 0) or usage.get('completion_tokens', 0)
            total_input += input_tokens
            total_output += output_tokens
            interactions += 1

            model = entry.get('model', 'unknown')
            if isinstance(entry.get('message'), dict):
                model = entry['message'].get('model', model)
            if model not in models:
                models[model] = {'input': 0, 'output': 0, 'count': 0}
            models[model]['input'] += input_tokens
            models[model]['output'] += output_tokens
            models[model]['count'] += 1

            # NDJSON output
            record = {
                'input_tokens': input_tokens,
                'output_tokens': output_tokens,
                'model': model,
                'line': line_num
            }
            print(json.dumps(record))

# Summary to stderr
print(f'', file=sys.stderr)
print(f'Total interactions: {interactions}', file=sys.stderr)
print(f'Total input tokens: {total_input:,}', file=sys.stderr)
print(f'Total output tokens: {total_output:,}', file=sys.stderr)
print(f'Total tokens: {total_input + total_output:,}', file=sys.stderr)
if models:
    print(f'Models used:', file=sys.stderr)
    for m, data in sorted(models.items()):
        print(f'  {m}: {data[\"count\"]} calls, {data[\"input\"]:,} in / {data[\"output\"]:,} out', file=sys.stderr)
" 2>&1
}

# ---------------------------------------------------------------------------
# Summary mode
# ---------------------------------------------------------------------------
print_summary() {
  local log_file="$1"

  if [[ ! -f "$log_file" ]]; then
    warn "File not found: ${log_file}"
    return 1
  fi

  info "Generating summary for: ${log_file}"
  echo ""

  python3 -c "
import json

log_file = '${log_file}'
total_input = 0
total_output = 0
interactions = 0
models = {}

with open(log_file, 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        usage = None
        if isinstance(entry, dict):
            usage = entry.get('usage') or entry.get('token_usage')
            if not usage and 'message' in entry:
                msg = entry['message']
                if isinstance(msg, dict):
                    usage = msg.get('usage')

        if usage and isinstance(usage, dict):
            input_t = usage.get('input_tokens', 0) or usage.get('prompt_tokens', 0)
            output_t = usage.get('output_tokens', 0) or usage.get('completion_tokens', 0)
            total_input += input_t
            total_output += output_t
            interactions += 1

            model = entry.get('model', 'unknown')
            if isinstance(entry.get('message'), dict):
                model = entry['message'].get('model', model)
            if model not in models:
                models[model] = {'input': 0, 'output': 0, 'count': 0}
            models[model]['input'] += input_t
            models[model]['output'] += output_t
            models[model]['count'] += 1

total = total_input + total_output
print('Banh Mi Ops - Token Usage Summary')
print('=' * 42)
print(f'Interactions:    {interactions}')
print(f'Input tokens:    {total_input:>12,}')
print(f'Output tokens:   {total_output:>12,}')
print(f'Total tokens:    {total:>12,}')
print()
if models:
    print('By Model:')
    print('-' * 42)
    for m, data in sorted(models.items()):
        print(f'  {m}')
        print(f'    Calls:   {data[\"count\"]}')
        print(f'    Input:   {data[\"input\"]:>12,}')
        print(f'    Output:  {data[\"output\"]:>12,}')
"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local log_files
  log_files="$(find_log_files)"

  if [[ -z "$log_files" ]]; then
    warn "No log files found."
    warn "Check that CLAUDE_LOG_DIR (${CLAUDE_LOG_DIR}) contains session logs."
    exit 1
  fi

  if [[ "$MODE" == "summary" ]]; then
    local latest
    latest="$(echo "$log_files" | tail -1)"
    print_summary "$latest"
  else
    while IFS= read -r log_file; do
      [[ -n "$log_file" ]] && extract_from_file "$log_file"
    done <<< "$log_files"
  fi
}

main
