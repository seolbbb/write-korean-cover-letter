#!/usr/bin/env bash
# Check the clone's upstream, fast-forward safely, then reapply its links.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_ONLY=no
INSTALL_ARGS=()

usage() {
  cat <<'EOF'
Usage: ./update.sh [--check] [--claude-only | --codex-only]

Check this clone's upstream. When an update is available, fast-forward pull and
reapply install.sh. --check only reports whether an update is available.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=yes ;;
    --claude-only|--codex-only) INSTALL_ARGS+=("$arg") ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Not a Git repository: $REPO_DIR" >&2
  exit 2
}

git -C "$REPO_DIR" diff --quiet && git -C "$REPO_DIR" diff --cached --quiet || {
  echo "Local changes found. Commit or stash them before updating." >&2
  exit 2
}

UPSTREAM="$(git -C "$REPO_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
[ -n "$UPSTREAM" ] || { echo "No upstream branch is configured." >&2; exit 2; }
REMOTE="${UPSTREAM%%/*}"

echo "Checking for updates…"
git -C "$REPO_DIR" fetch --quiet "$REMOTE"

LOCAL="$(git -C "$REPO_DIR" rev-parse HEAD)"
UPSTREAM_HEAD="$(git -C "$REPO_DIR" rev-parse "$UPSTREAM")"

if [ "$LOCAL" = "$UPSTREAM_HEAD" ]; then
  echo "Already up to date."
  exit 0
fi

BASE="$(git -C "$REPO_DIR" merge-base HEAD "$UPSTREAM")"
if [ "$BASE" = "$UPSTREAM_HEAD" ]; then
  echo "Local clone is ahead of $UPSTREAM; no remote update to apply."
  exit 0
fi

if [ "$BASE" != "$LOCAL" ]; then
  echo "Local branch has diverged from $UPSTREAM; refusing to merge automatically." >&2
  exit 2
fi

BEHIND="$(git -C "$REPO_DIR" rev-list --count "HEAD..$UPSTREAM")"
echo "Update available: $BEHIND commit(s)."

if [ "$CHECK_ONLY" = yes ]; then
  exit 10
fi

git -C "$REPO_DIR" pull --ff-only
"$REPO_DIR/install.sh" "${INSTALL_ARGS[@]}"
echo "Update complete."
