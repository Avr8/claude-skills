# Claude Skills: engineering workflows for AI agents

A collection of practical, tested [Agent Skills](https://www.anthropic.com/news/skills) for Claude Code and Claude.ai. They work with other agents that read a skills folder, but they're only tested on Claude.

Writing code is one part of engineering. The rest is reviewing an infra change before applying it, understanding a PR before approving it, writing a blameless postmortem, checking a repo before making it public, and being able to explain the code you maintain. Each skill here turns one of those recurring workflows into a procedure an agent can follow, with explicit safety boundaries and test cases that check whether it actually improves the result.

The underlying idea: **agent instructions are engineering artifacts.** They can be tested, measured and improved like code. See [how the skills are evaluated](docs/evaluation.md).

Each skill is a folder with a `SKILL.md` and, where useful, small scripts you can read in a minute. No network calls, no telemetry, and nothing runs that the README doesn't list. Anything irreversible or visible to others (push, apply, rewriting history, publishing) needs your approval.

**See it work:** [terraform-plan-reviewer on a plan that would wipe a database](docs/demo-terraform-plan-reviewer.md)

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

### Engineering workflows

| Skill | What it does | Runs locally | Install |
|---|---|---|---|
| [terraform-plan-reviewer](skills/terraform-plan-reviewer) | Reviews Terraform/OpenTofu/Terragrunt plans: data-loss replaces and why each happens, partial-apply risk, IAM widening, `0.0.0.0/0`, disabled protections | `scripts/plan_summary.py` (stdlib only; never runs `apply`) | `/plugin install terraform-plan-reviewer --marketplace Avr8/claude-skills` |
| [stacked-pr-splitter](skills/stacked-pr-splitter) | Turns a huge branch into a stack of small PRs that each build and pass, verifies the stack matches the original diff exactly, and waits for your approval before creating branches | `git` (asks before pushing) | `/plugin install stacked-pr-splitter --marketplace Avr8/claude-skills` |
| [pr-explainer-quiz](skills/pr-explainer-quiz) | Explains a PR with a Mermaid diagram of the risky path and risk notes, then quizzes you so "LGTM" means something | `git`, `gh` (read-only) | `/plugin install pr-explainer-quiz --marketplace Avr8/claude-skills` |
| [incident-postmortem](skills/incident-postmortem) | Turns incident threads, alerts and metrics into a blameless postmortem with a UTC timeline, trigger kept separate from root cause, and owned action items | nothing (queries observability tools only if you have them connected) | `/plugin install incident-postmortem --marketplace Avr8/claude-skills` |
| [oss-ready](skills/oss-ready) | Pre-publication sweep: secrets in code *and history*, internal hostnames, emails, code ownership, licenses, community files | `scripts/scan.sh` (read-only; uses gitleaks if installed) | `/plugin install oss-ready --marketplace Avr8/claude-skills` |

### Engineering communication and learning

| Skill | What it does | Runs locally | Install |
|---|---|---|---|
| [codebase-viva-prep](skills/codebase-viva-prep) | Gets you ready to explain and defend a codebase: architecture map with verified `file:line` references, predicted questions with answers, mock viva, live-modification drills | nothing | `/plugin install codebase-viva-prep --marketplace Avr8/claude-skills` |
| [md-to-doc](skills/md-to-doc) | Markdown → Word/PDF with tables intact. Word output gets bordered tables; PDF falls back through typst → LaTeX → weasyprint → headless Chrome → LibreOffice → MS Word | `pandoc`, plus whichever PDF engine it finds | `/plugin install md-to-doc --marketplace Avr8/claude-skills` |
| [anti-slop-editor](skills/anti-slop-editor) | Removes the patterns that make writing read as AI-generated (filler, hedges, stock words) without inventing facts or losing the author's voice | nothing | `/plugin install anti-slop-editor --marketplace Avr8/claude-skills` |

## Quality bar

Every skill in this repo:
- has a `description` written to trigger on the way people actually ask, not just on the skill's name
- explains *why* it does each step, so Claude can adapt instead of following rules blindly
- asks before doing anything irreversible or visible to others (push, publish, apply, rewrite history)
- ships test cases under `evals/` that run with `claude plugin eval`

## How these were tested

Each skill was evaluated with task-specific test cases. A separate grader agent checked every output against explicit assertions, such as "timeline converted to UTC", "no branches created before approval", "no invented facts" or "table has visible borders", comparing results with and without the skill. Three rounds were run, with each round's failures fed back into the skills and the assertions made sharper. Round 3 (below) used Claude Sonnet for both generation and grading. Full method, results by round, and limitations: [docs/evaluation.md](docs/evaluation.md).

| Skill | With skill | Without | What the skill changes |
|---|---|---|---|
| incident-postmortem | 10/10 | 6/10 | UTC timeline, roles not names, correct interval maths, priorities on every action |
| pr-explainer-quiz | 8/8 | 2/8 | Diagram of the risky path, one-at-a-time quiz, and only what you asked for |
| stacked-pr-splitter | 9/9 | 4/9 | Waits for approval, PRs ≤400 lines, opening vs tightening network rules, Terragrunt deletion pitfalls |
| terraform-plan-reviewer | 12/12 | 8/12 | Partial-apply risk, disabled protections rated critical, guardrails recommended |
| oss-ready | 9/10 | 6/10 | Backup before rewriting history, asks who owns the code, no internal names in new files |
| codebase-viva-prep | 7/8 | 5/8 | Verified `file:line` references, questions that target real flaws |
| anti-slop-editor | 9/10 | 8/10 | No invented details; keeps the audience and facts |
| md-to-doc | 8/8 | 7/8 | Bordered Word tables, absolute output path |
| **Total** | **72/75 (96%)** | **46/75 (61%)** | |

This is a small evaluation, not a benchmark: two prompts per skill per round, synthetic inputs, and a grader from the same model family. It is a feedback loop for improving the skills, not a statistical claim. To run the tests yourself: `claude plugin eval skills/<name> --allow-tools Write,Edit,Bash --scaffold`.

## Roadmap

Workflows being considered next. Open an issue to vote, or suggest another.

- **pr-feedback-resolver**: triage review comments on a PR, fix the valid ones, reply to the rest
- **pr-description-writer**: PR descriptions and reviewer guides built from the diff and the linked ticket
- **migration-safety-reviewer**: check database migrations for locking, irreversible steps, and rollback paths
- **k8s-manifest-reviewer**: catch missing resource limits, probes and PodDisruptionBudgets, and risky rollout settings before deploy
- **runbook-writer**: turn an incident or an on-call thread into a runbook that someone else can follow
- Evals: more cases per skill, multiple runs per case, and a non-Claude grader for cross-checking

## Contributing

Ideas and PRs are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and start from [`template/`](template). If you want a skill that doesn't exist yet, open an issue with the **Skill request** template.

## License

[MIT](LICENSE)
