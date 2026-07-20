#!/usr/bin/env bash
# Remove only symlinks created by install.sh. Never delete copied or unrelated files.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="write-korean-cover-letter"
SKILL_DIR="$REPO_DIR/$SKILL_NAME"
SKILL_CANONICAL="$(cd -P "$SKILL_DIR" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.agents/skills}"
DO_CLAUDE=yes
DO_CODEX=yes

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [--claude-only | --codex-only]

Remove only the symlinks created by install.sh.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --claude-only) DO_CODEX=no ;;
    --codex-only) DO_CLAUDE=no ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

remove_link() {
  local destination="$1"
  local linked_canonical=""

  if [ -L "$destination" ]; then
    linked_canonical="$(cd -P "$destination" 2>/dev/null && pwd || true)"
  fi

  if [ -L "$destination" ] && [ "$linked_canonical" = "$SKILL_CANONICAL" ]; then
    rm "$destination"
    echo "Removed: $destination"
  elif [ -e "$destination" ] || [ -L "$destination" ]; then
    echo "Skip (not this install): $destination"
  else
    echo "Not installed: $destination"
  fi
}

if [ "$DO_CLAUDE" = yes ]; then
  remove_link "$CLAUDE_HOME/skills/$SKILL_NAME"
fi

if [ "$DO_CODEX" = yes ]; then
  remove_link "$CODEX_SKILLS_DIR/$SKILL_NAME"
fi
