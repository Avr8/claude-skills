---
name: oss-ready
description: Prepare a private or internal repository to be published as open source — scans code and full git history for secrets, internal hostnames, emails and company references; adds LICENSE, README, CONTRIBUTING, SECURITY and CODE_OF_CONDUCT; checks dependency licenses; and produces a go/no-go checklist. Use whenever someone says "open source this", "make this repo public", "publish to GitHub", "is this safe to share", "clean this up before release", or is about to flip a repo's visibility — even for a small personal project.
---

# OSS-ready

Making a repo public is irreversible in practice: forks, caches and scrapers keep what you pushed. Secrets in **old commits** are the classic mistake — deleting a file doesn't remove it from history. This skill finds the problems first, fixes what it safely can, and lists what the human must decide.

## Match the request
If the user only asks a question ("is this safe to publish?"), stay **read-only**: scan, report, and offer the fixes. Don't create `.gitignore`, `.env.example`, LICENSE or anything else until they say so. If they ask you to add files or fix things, do that and still run the scan, because they'll want to know about blockers before going public.

## 1. Scan (read-only)
Run the bundled scanner from the repo root:
```bash
bash <skill-dir>/scripts/scan.sh            # working tree + full git history
bash <skill-dir>/scripts/scan.sh --org acme # also flag the internal org/company name
```
It uses `gitleaks` or `trufflehog` if installed (much better), and falls back to a regex pass otherwise. It also lists internal-looking hostnames, private IPs, email addresses, and large binaries.

Read every finding yourself. Classify each as: **real secret**, **internal reference** (hostnames, ticket IDs, colleague names, customer names), or **false positive**.

## 2. Handle secrets correctly
For any real secret — even one that's "only in history":
1. Tell the user to **rotate/revoke it first**. Rewriting history does not un-leak a key that's already been pushed anywhere.
2. Then offer to purge it from history with `git filter-repo` (preferred) or BFG — show the command, and only run after confirmation, on a **fresh clone** (`git clone --mirror`), since it rewrites every commit hash. Never suggest `reflog expire` / `gc --prune=now` in the user's only copy without a backup.
3. If the repo has very few commits, starting a fresh history (`rm -rf .git && git init`, one clean commit) is often simpler than filter-repo. Say so.
4. Anything already pushed to a remote may survive in forks, clones, CI caches and GitHub's own cache of old commits. Rotation is the real fix, and the history purge is just cleanup.
5. Move config to environment variables and add a `.env.example` with placeholder values.

## 2b. Ownership
Before suggesting a license holder, ask who owns the code. If the README, hostnames, package names or emails point to a company ("acme", an internal domain, a work email in the commits), the copyright probably belongs to the employer or client. Open-sourcing it may need their approval, and the LICENSE should name them. Raise this as a NEEDS DECISION item.

## 3. Add the community files
Files you write must be ready to publish: no leftover placeholders like `<EMAIL>`. If a value is missing, prefer a route that needs none (GitHub private vulnerability reporting) and name the gap in your reply. Never put the internal company/org name or internal hostnames in new files.

Ask which license if not specified (suggest MIT for "just let people use it", Apache-2.0 if patents matter, GPL-3.0 if they want copyleft). Create, if missing:
- `LICENSE` (exact SPDX text, correct year + holder name)
- `README.md` — what it is, a 30-second quickstart, requirements, license badge. Rewrite internal jargon.
- `CONTRIBUTING.md` — how to set up, run tests, PR expectations
- `SECURITY.md` — how to report vulnerabilities privately (GitHub private vulnerability reporting or an email)
- `CODE_OF_CONDUCT.md` — Contributor Covenant, if they want one
- `.gitignore` entries for env files, build output, editor folders

## 4. Dependency licenses
Check for copyleft dependencies that conflict with the chosen license (e.g. AGPL dependency in an MIT project). Use the ecosystem's tool if available (`npx license-checker --summary`, `pip-licenses`, `go-licenses`, `cargo deny`), otherwise read the manifest and flag unknowns.

## 5. Report
End with a checklist the user can act on:
```
BLOCKERS (must fix before going public)
  [ ] AWS key in config/old.yaml (commit a1b2c3, 2024-03) — rotate, then purge history
NEEDS DECISION
  [ ] 14 references to "acme-internal.net" in docs/ — replace or remove?
DONE
  [x] Added MIT LICENSE, README, SECURITY.md
```
Never change repo visibility yourself — that's the user's call after the blockers are clear.
