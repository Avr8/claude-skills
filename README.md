# claude-skills

Practical [Agent Skills](https://www.anthropic.com/news/skills) for Claude Code and Claude.ai, built from workflows that come up every week: shipping documents, reviewing PRs and infra changes, writing postmortems, preparing to defend your code.

Each skill is a folder with a `SKILL.md` and, where useful, small scripts you can read in a minute. No network calls and no telemetry, and nothing runs that the README doesn't list.

## Install only what you need

Every skill installs on its own. Pick any of these routes, then copy the line for each skill you want from the [Skills](#skills) table.

### 1. Claude Code plugin (recommended: updates come through `/plugin`)
```
/plugin install md-to-doc --marketplace Avr8/claude-skills
```
Each skill is a separate plugin, so this installs **only** `md-to-doc`. On Claude Code older than 2.1.275, add the marketplace once with `/plugin marketplace add Avr8/claude-skills`, then run `/plugin install md-to-doc@avr8-skills`. You can also browse and toggle skills interactively with `/plugin`.

### 2. Install script (no plugin system; works for any agent that reads a skills folder)
```bash
curl -fsSL https://raw.githubusercontent.com/Avr8/claude-skills/main/install.sh -o install.sh
less install.sh                                # it's short, so read it first
bash install.sh --list                         # see what's available
bash install.sh md-to-doc oss-ready            # → ~/.claude/skills (all projects)
bash install.sh --project terraform-plan-reviewer   # → ./.claude/skills (this repo only, commit it for your team)
bash install.sh --dir ~/.agents/skills md-to-doc    # any other skills folder
```
It copies only the named skill folders, without their test cases, and never overwrites without `--force`.

### 3. Claude.ai
Download the zip for the skill you want from the [latest release](https://github.com/Avr8/claude-skills/releases/latest) (`md-to-doc.zip`, `oss-ready.zip`, …), then upload it under *Settings → Capabilities → Skills*.

### Uninstall
`/plugin uninstall <skill>`. If you used the script, delete `~/.claude/skills/<skill>`.

## Skills

| Skill | What it does | Runs locally | Install |
|---|---|---|---|
| [md-to-doc](skills/md-to-doc) | Markdown → Word/PDF with tables intact. Detects which PDF engine you have and falls back through typst → LaTeX → weasyprint → headless Chrome → LibreOffice → MS Word. Word output gets bordered tables | `pandoc`, plus whichever PDF engine it finds | `/plugin install md-to-doc --marketplace Avr8/claude-skills` |
| [anti-slop-editor](skills/anti-slop-editor) | Removes the patterns that make writing read as AI-generated (filler, hedges, stock words, em-dash confetti) and keeps the author's voice | nothing | `/plugin install anti-slop-editor --marketplace Avr8/claude-skills` |
| [stacked-pr-splitter](skills/stacked-pr-splitter) | Turns a huge branch into a stack of small PRs that each build and pass, and verifies the stack matches the original diff exactly | `git` (asks before pushing) | `/plugin install stacked-pr-splitter --marketplace Avr8/claude-skills` |
| [pr-explainer-quiz](skills/pr-explainer-quiz) | Explains a PR with a Mermaid diagram and risk notes, then quizzes you so "LGTM" means something | `git`, `gh` (read-only) | `/plugin install pr-explainer-quiz --marketplace Avr8/claude-skills` |
| [oss-ready](skills/oss-ready) | Pre-publication sweep: secrets in code *and history*, internal hostnames, emails, licenses, community files | `scripts/scan.sh` (read-only; uses gitleaks if installed) | `/plugin install oss-ready --marketplace Avr8/claude-skills` |
| [incident-postmortem](skills/incident-postmortem) | Turns incident threads, alerts and metrics into a blameless postmortem with a UTC timeline and owned action items | nothing (queries observability tools only if you have them connected) | `/plugin install incident-postmortem --marketplace Avr8/claude-skills` |
| [terraform-plan-reviewer](skills/terraform-plan-reviewer) | Reviews Terraform/OpenTofu/Terragrunt plans: data-loss replaces, why each replace happens, IAM widening, `0.0.0.0/0`, disabled protections | `scripts/plan_summary.py` (stdlib only; never runs `apply`) | `/plugin install terraform-plan-reviewer --marketplace Avr8/claude-skills` |
| [codebase-viva-prep](skills/codebase-viva-prep) | Gets you ready to defend a codebase: architecture map, predicted questions with answers, mock viva, live-modification drills | nothing | `/plugin install codebase-viva-prep --marketplace Avr8/claude-skills` |

## Quality bar

Every skill in this repo:
- has a `description` written to trigger on the way people actually ask, not just on the skill's name
- explains *why* it does each step, so Claude can adapt instead of following rules blindly
- asks before doing anything irreversible or visible to others (push, publish, apply, rewrite history)
- ships test cases under `evals/` that run with `claude plugin eval`

## How these were tested

Each skill has test prompts under `evals/`. Every prompt was run twice, once with the skill and once without (plain Claude), and an independent grader checked each answer against specific assertions such as "timeline converted to UTC", "no branches created before approval", "no invented facts" or "table has visible borders". Two rounds were run. Round 1's findings went back into the skills, and the tests were made harder for round 2.

| Skill | With skill | Without | What the skill changes |
|---|---|---|---|
| incident-postmortem | 9/10 | 4/10 | UTC timeline, roles not names, owner + priority on every action, no outside facts |
| pr-explainer-quiz | 8/8 | 5/8 | Diagram + one-at-a-time quiz; respects "just the summary" |
| codebase-viva-prep | 7/7 | 5/7 | ~45 `file:line` references, all verified correct |
| oss-ready | 12/12 | 10/12 | Back up before rewriting history; asks who owns the code |
| stacked-pr-splitter | 9/10 | 8/10 | Proposes a plan and waits; without it Claude built 6 branches unasked |
| md-to-doc | 8/8 | 7/8 | Word tables get visible borders |
| anti-slop-editor | 8/9 | 8/9 | Placeholders instead of invented details |
| terraform-plan-reviewer | 13/13 | 13/13 | Same score; the skill flags partial-apply risk and rates disabled protections critical |
| **Total** | **74/77 (96%)** | **60/77 (78%)** | |

Small sample (two prompts per skill, one run each), so treat it as a sanity check, not a benchmark. Run the tests yourself with `claude plugin eval skills/<name> --allow-tools Write,Edit,Bash --scaffold`.

## Contributing

Ideas and PRs are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and start from [`template/`](template). If you want a skill that doesn't exist yet, open an issue with the **Skill request** template.

## License

[MIT](LICENSE)
