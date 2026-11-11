#!/usr/bin/env bash
# Install individual skills from github.com/Avr8/claude-skills — only the ones you name.
#
#   bash install.sh --list                       # show available skills
#   bash install.sh md-to-doc oss-ready          # install into ~/.claude/skills (all your projects)
#   bash install.sh --project md-to-doc          # install into ./.claude/skills (this project only)
#   bash install.sh --dir ~/.agents/skills md-to-doc   # any other skills folder
#   bash install.sh --all                        # everything
#
# What it does: downloads the repo tarball from GitHub, copies skills/<name>/ (without its
# evals/ test folder) into the target directory, and nothing else. No sudo, no other writes.
set -euo pipefail

REPO="${CLAUDE_SKILLS_REPO:-Avr8/claude-skills}"
REF="${CLAUDE_SKILLS_REF:-main}"
DEST="$HOME/.claude/skills"
ALL=0; LIST=0; FORCE=0; NAMES=()

usage() { sed -n '2,11p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//' || true; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) DEST="$PWD/.claude/skills" ;;
    --dir) DEST="$2"; shift ;;
    --all) ALL=1 ;;
    --list) LIST=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 1 ;;
    *) NAMES+=("$1") ;;
  esac
  shift
done

command -v curl >/dev/null && command -v tar >/dev/null || { echo "needs curl and tar" >&2; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF" | tar -xz -C "$TMP"
SRC="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -1)/skills"
[[ -d "$SRC" ]] || { echo "could not find skills/ in $REPO@$REF" >&2; exit 1; }

AVAILABLE=()
for d in "$SRC"/*/; do AVAILABLE+=("$(basename "$d")"); done

if [[ $LIST -eq 1 ]]; then
  for n in "${AVAILABLE[@]}"; do
    desc="$(awk '/^description:/{sub(/^description: */,""); print; exit}' "$SRC/$n/SKILL.md" | cut -c1-90)"
    printf '%-26s %s…\n' "$n" "$desc"
  done
  exit 0
fi

[[ $ALL -eq 1 ]] && NAMES=("${AVAILABLE[@]}")
[[ ${#NAMES[@]} -gt 0 ]] || { echo "name at least one skill (or --list / --all)" >&2; exit 1; }

mkdir -p "$DEST"
for n in "${NAMES[@]}"; do
  if [[ ! -d "$SRC/$n" ]]; then echo "✗ $n: no such skill (try --list)" >&2; continue; fi
  if [[ -e "$DEST/$n" && $FORCE -eq 0 ]]; then
    echo "• $n: already installed at $DEST/$n (use --force to overwrite)"; continue
  fi
  rm -rf "$DEST/$n"
  mkdir -p "$DEST/$n"
  (cd "$SRC/$n" && tar -cf - --exclude ./evals .) | (cd "$DEST/$n" && tar -xf -)
  echo "✓ $n → $DEST/$n"
done
echo "Restart Claude Code (or start a new session) to pick up new skills."
