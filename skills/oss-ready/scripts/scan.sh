#!/usr/bin/env bash
# scan.sh — pre-publication scan of a git repo (read-only).
# Usage: scan.sh [--org NAME]... [--no-history]
set -uo pipefail

ORGS=(); HISTORY=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORGS+=("$2"); shift ;;
    --no-history) HISTORY=0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not inside a git repo" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
hr() { printf '\n== %s ==\n' "$1"; }

hr "Secret scan"
if have gitleaks; then
  if [[ $HISTORY -eq 1 ]]; then gitleaks detect --source . --redact -v 2>&1 | tail -n 200
  else gitleaks detect --source . --no-git --redact -v 2>&1 | tail -n 200; fi
elif have trufflehog; then
  trufflehog git file://. --no-update 2>&1 | tail -n 200
else
  echo "(gitleaks/trufflehog not installed — using regex fallback; install gitleaks for real coverage: brew install gitleaks)"
  PATTERN='(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{60,}|xox[baprs]-[A-Za-z0-9-]{10,}|(^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{20,}|sk_live_[0-9a-zA-Z]{24,}|AIza[0-9A-Za-z_-]{35}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}|(password|passwd|secret|api[_-]?key|token|connection[_-]?string)[\"'"'"' ]*[:=][\"'"'"' ]*[^\"'"'"' ,;]{8,}|AccountKey=[A-Za-z0-9+/=]{20,})'
  echo "-- working tree --"
  git grep --untracked -nIiE "$PATTERN" -- . ':!*.lock' ':!package-lock.json' 2>/dev/null | cut -c1-200 | head -n 100
  if [[ $HISTORY -eq 1 ]]; then
    echo "-- history (added lines only) --"
    git log -p --all --no-color -G"$PATTERN" --pretty=format:'@@commit %h %ad %an' --date=short 2>/dev/null \
      | grep -E "^@@commit|^\+" | grep -iE "^@@commit|$PATTERN" \
      | awk '/^@@commit/{c=$0; next} {print c" | "$0}' | cut -c1-220 | head -n 100
  fi
fi

hr "Sensitive files ever committed"
git log --all --pretty=format: --name-only --diff-filter=A 2>/dev/null | sort -u \
  | grep -iE '(^|/)(\.env(\..*)?|id_rsa|id_ed25519|.*\.pem|.*\.p12|.*\.pfx|.*\.key|credentials(\.json)?|secrets?\.(ya?ml|json)|.*\.tfstate(\.backup)?|.*\.kubeconfig|kubeconfig)$' \
  | grep -v '\.example$' | head -n 50

hr "Internal hostnames / private IPs (working tree)"
git grep --untracked -nIoE '([a-z0-9-]+\.)+(internal|corp|local|lan|intra|svc\.cluster\.local)([^A-Za-z0-9.]|$)|(^|[^0-9.])(10\.[0-9]{1,3}|192\.168|172\.(1[6-9]|2[0-9]|3[01]))\.[0-9]{1,3}\.[0-9]{1,3}([^0-9]|$)' -- . 2>/dev/null | head -n 50

hr "Email addresses (working tree)"
git grep --untracked -nIoE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' -- . 2>/dev/null \
  | grep -viE 'noreply|example\.(com|org)|users\.noreply\.github\.com' | head -n 50

hr "Commit author emails (become public)"
git log --all --format='%ae' | sort | uniq -c | sort -rn | head -n 20

for o in ${ORGS[@]+"${ORGS[@]}"}; do
  hr "References to '$o'"
  git grep --untracked -nIi -- "$o" -- . 2>/dev/null | cut -c1-200 | head -n 50
  [[ $HISTORY -eq 1 ]] && echo "commits mentioning it in history: $(git log --all -i -S"$o" --oneline 2>/dev/null | wc -l | tr -d ' ')"
done

hr "Large files in history (>5MB)"
git rev-list --objects --all 2>/dev/null \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' 2>/dev/null \
  | awk '$1=="blob" && $3>5242880 {printf "%.1fMB %s\n", $3/1048576, $4}' | sort -rn | head -n 20

hr "Community files"
lic=$(ls -d LICENSE* COPYING* 2>/dev/null | head -1); [[ -n "$lic" ]] && echo "present: $lic" || echo "missing: LICENSE"
for f in README.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md .gitignore; do
  [[ -e "$f" ]] && echo "present: $f" || echo "missing: $f"
done
