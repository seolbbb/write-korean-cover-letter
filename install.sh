#!/usr/bin/env bash
# Clone once, then link this Skill into the global Claude Code and Codex locations.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="write-korean-cover-letter"
SKILL_DIR="$REPO_DIR/$SKILL_NAME"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.agents/skills}"
DO_CLAUDE=auto
DO_CODEX=auto
INSTALLED=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--claude-only | --codex-only]

Auto-detect Claude Code and Codex, then create global symlinks to this clone.
  Claude Code: ~/.claude/skills/write-korean-cover-letter
  Codex:       ~/.agents/skills/write-korean-cover-letter

Options:
  --claude-only  Install only for Claude Code.
  --codex-only   Install only for Codex.
  -h, --help     Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --claude-only) DO_CLAUDE=yes; DO_CODEX=no ;;
    --codex-only) DO_CLAUDE=no; DO_CODEX=yes ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[ -f "$SKILL_DIR/SKILL.md" ] || { echo "Skill folder not found: $SKILL_DIR" >&2; exit 2; }
SKILL_CANONICAL="$(cd -P "$SKILL_DIR" && pwd)"

should_install_claude() {
  [ "$DO_CLAUDE" = yes ] || { [ "$DO_CLAUDE" = auto ] && { command -v claude >/dev/null 2>&1 || [ -d "$CLAUDE_HOME" ]; }; }
}

should_install_codex() {
  [ "$DO_CODEX" = yes ] || { [ "$DO_CODEX" = auto ] && { command -v codex >/dev/null 2>&1 || [ -d "$HOME/.agents" ]; }; }
}

create_symlink() {
  if uname -s | grep -Eq 'MINGW|MSYS|CYGWIN'; then
    MSYS=winsymlinks:nativestrict ln -s "$SKILL_DIR" "$1"
  else
    ln -s "$SKILL_DIR" "$1"
  fi
}

install_link() {
  local destination="$1"
  local linked_canonical=""

  if [ -L "$destination" ]; then
    linked_canonical="$(cd -P "$destination" 2>/dev/null && pwd || true)"
    if [ "$linked_canonical" = "$SKILL_CANONICAL" ]; then
      echo "Already linked: $destination"
      INSTALLED=$((INSTALLED + 1))
      return 0
    fi
    echo "Refusing to replace an existing symlink: $destination" >&2
    return 1
  fi

  if [ -e "$destination" ]; then
    echo "Refusing to replace an existing file or directory: $destination" >&2
    return 1
  fi

  mkdir -p "$(dirname "$destination")"
  if ! create_symlink "$destination" || [ ! -L "$destination" ]; then
    echo "Could not create a real symbolic link at: $destination" >&2
    echo "On Windows, use WSL or enable Developer Mode before running this script." >&2
    exit 1
  fi
  echo "Linked: $destination -> $SKILL_DIR"
  INSTALLED=$((INSTALLED + 1))
}

if should_install_claude; then
  install_link "$CLAUDE_HOME/skills/$SKILL_NAME"
else
  echo "Skip Claude Code (not detected). Use --claude-only to install anyway."
fi

if should_install_codex; then
  install_link "$CODEX_SKILLS_DIR/$SKILL_NAME"
else
  echo "Skip Codex (not detected). Use --codex-only to install anyway."
fi

[ "$INSTALLED" -gt 0 ] || { echo "No supported agent was detected." >&2; exit 1; }
echo "Installation complete."
