# Contributing

## Adding a skill

1. Copy `template/example-skill/` to `skills/<your-skill-name>/` (lowercase, hyphens).
2. Write `SKILL.md`:
   - **`name`** must match the folder name.
   - **`description`** decides whether Claude ever uses your skill. Say what it does *and* list the situations and phrasings that should trigger it, including ones where the user doesn't name the skill. Keep it under 1024 characters.
   - Body: explain the workflow and **why** each step matters. Prefer reasoning over ALL-CAPS rules. Keep it under ~500 lines and move long reference material into `references/`.
3. Put deterministic, repeatable work in `scripts/`. Scripts must:
   - be readable in a couple of minutes
   - make no network calls unless that is the skill's purpose, and say so in the README if it does
   - use only the standard library or clearly documented CLI tools
   - be read-only by default, asking before anything destructive
4. Add at least two test cases under `evals/<case-name>/` (`prompt.md`, `case.yaml`, `graders/`). Copy the format from an existing skill.
5. Add the skill to `.claude-plugin/marketplace.json` and to the table in `README.md`.
6. Run `python3 scripts/validate.py` before opening a PR. CI runs it too.

## What gets accepted

- Skills that encode real expertise or a real workflow. A thin prompt wrapper ("You are an expert X") won't be accepted.
- Nothing that impersonates people or organizations, collects credentials, or hides what it executes.
- No secrets, internal hostnames or company-specific data. Run the `oss-ready` scanner on your branch.

## Requesting a skill

Open an issue using the **Skill request** template. Describe the task you keep repeating, what a good result looks like, and an example input.
