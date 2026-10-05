#!/bin/sh
# The local gate: flutter analyze, then the FULL test suite.
#
#   sh scripts/check.sh
#
# The pre-push hook runs this. Run it yourself ahead of a push and the push
# goes straight through: when the gate passes and no file changed while it
# ran, it records the fingerprint of the exact code it checked (a git tree
# hash of every tracked and untracked, non-ignored file as it is on disk) in
# .git/esperanza-mobile-verified-trees, never committed. The hook skips the
# gate for a push whose every commit holds exactly such code: the same content
# already passed this same gate. The backend repo does the same.
#
# Why: measured warm on the macOS lane the gate takes about a minute, but on
# an 8 GB Windows laptop analyze alone took 5-8 minutes and a push about 20
# (2026-10-05), every time, even for code that had just passed.
set -e

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
APP_DIR="$ROOT/Esperanza-Mobile-App"
[ -d "$APP_DIR" ] || { echo "check: $APP_DIR not found - is this the right repo?"; exit 1; }

command -v flutter >/dev/null 2>&1 || {
  echo "check: flutter is not on PATH. Refusing to pass a gate that did not run."
  echo "       (A gate that cannot run must fail, not succeed quietly.)"
  exit 1
}

# The fingerprint, built in a scratch index so the real index is untouched.
worktree_tree() {
  idx="$(mktemp)" || return 1
  cp "$(git rev-parse --git-path index)" "$idx" 2>/dev/null || :
  if GIT_INDEX_FILE="$idx" git add -A . >/dev/null 2>&1; then
    GIT_INDEX_FILE="$idx" git write-tree 2>/dev/null
  fi
  rm -f "$idx"
}
TREE_AT_START="$(worktree_tree)"

cd "$APP_DIR"
echo "check: flutter analyze"
flutter analyze || { echo "check: BLOCKED - analyze failed."; exit 1; }

echo "check: flutter test"
flutter test || { echo "check: BLOCKED - tests failed."; exit 1; }

cd "$ROOT"
NOW="$(worktree_tree)"
if [ -n "$TREE_AT_START" ] && [ "$NOW" = "$TREE_AT_START" ]; then
  echo "$NOW $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$(git rev-parse --git-path esperanza-mobile-verified-trees)"
  echo "check: OK. Recorded: pushing this exact code will not run the gate again."
else
  echo "check: OK. Not recorded: files changed while the gate ran, so the next push runs it again."
fi
