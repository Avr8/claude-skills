# claude-skills

Practical [Agent Skills](https://www.anthropic.com/news/skills) for Claude Code and Claude.ai, built from workflows that come up every week: shipping documents, reviewing PRs and infra changes, writing postmortems, preparing to defend your code.

Each skill is a folder with a `SKILL.md` and, where useful, small scripts you can read in a minute. No network calls and no telemetry, and nothing runs that the README doesn't list.

## Install

**Claude Code: one line per skill (Claude Code 2.1.275+)**
```
/plugin install md-to-doc --marketplace Avr8/claude-skills
/plugin install anti-slop-editor --marketplace Avr8/claude-skills
/plugin install stacked-pr-splitter --marketplace Avr8/claude-skills
/plugin install pr-explainer-quiz --marketplace Avr8/claude-skills
/plugin install oss-ready --marketplace Avr8/claude-skills
/plugin install incident-postmortem --marketplace Avr8/claude-skills
/plugin install terraform-plan-reviewer --marketplace Avr8/claude-skills
/plugin install codebase-viva-prep --marketplace Avr8/claude-skills
```

**Older Claude Code: add the marketplace, then pick skills**
```
/plugin marketplace add Avr8/claude-skills
/plugin install md-to-doc@avr8-skills
```
Install only the skills you want, or browse them with `/plugin`.

**Claude Code: manual**
```bash
git clone https://github.com/Avr8/claude-skills
cp -r claude-skills/skills/<skill-name> ~/.claude/skills/
```

**Claude.ai**: zip a skill folder and upload it under *Settings → Capabilities → Skills*.

## Skills

| Skill | What it does | Runs locally |
|---|---|---|
| [md-to-doc](skills/md-to-doc) | Markdown → Word/PDF with tables intact. Detects which PDF engine you have and falls back through typst → LaTeX → weasyprint → LibreOffice → MS Word | `pandoc`, plus whichever PDF engine it finds |
| [anti-slop-editor](skills/anti-slop-editor) | Removes the patterns that make writing read as AI-generated (filler, hedges, stock words, em-dash confetti) and keeps the author's voice | nothing |
| [stacked-pr-splitter](skills/stacked-pr-splitter) | Turns a huge branch into a stack of small PRs that each build and pass, and verifies the stack matches the original diff exactly | `git` (asks before pushing) |
| [pr-explainer-quiz](skills/pr-explainer-quiz) | Explains a PR with a Mermaid diagram and risk notes, then quizzes you so "LGTM" means something | `git`, `gh` (read-only) |
| [oss-ready](skills/oss-ready) | Pre-publication sweep: secrets in code *and history*, internal hostnames, emails, licenses, community files | `scripts/scan.sh` (read-only; uses gitleaks if installed) |
| [incident-postmortem](skills/incident-postmortem) | Turns incident threads, alerts and metrics into a blameless postmortem with a UTC timeline and owned action items | nothing (queries observability tools only if you have them connected) |
| [terraform-plan-reviewer](skills/terraform-plan-reviewer) | Reviews Terraform/OpenTofu/Terragrunt plans: data-loss replaces, why each replace happens, IAM widening, `0.0.0.0/0`, disabled protections | `scripts/plan_summary.py` (stdlib only; never runs `apply`) |
| [codebase-viva-prep](skills/codebase-viva-prep) | Gets you ready to defend a codebase: architecture map, predicted questions with answers, mock viva, live-modification drills | nothing |

## Quality bar

Every skill in this repo:
- has a `description` written to trigger on the way people actually ask, not just on the skill's name
- explains *why* it does each step, so Claude can adapt instead of following rules blindly
- asks before doing anything irreversible or visible to others (push, publish, apply, rewrite history)
- ships test cases under `evals/` that run with `claude plugin eval`

## Contributing

Ideas and PRs are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and start from [`template/`](template). If you want a skill that doesn't exist yet, open an issue with the **Skill request** template.

## License

[MIT](LICENSE)
