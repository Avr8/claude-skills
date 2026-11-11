---
name: example-skill
description: One sentence on what this skill does. Then: Use this whenever <situations>, <phrasings users actually type>, or <adjacent cases where it should still win> — even if they don't mention <the obvious keyword>.
---

# Example skill

One paragraph: the problem this solves and why doing it well is not obvious.

## Workflow

1. **Gather** — what to read or ask for first, and why.
2. **Do** — the core steps. Point to `scripts/` for anything deterministic:
   ```bash
   python3 <skill-dir>/scripts/do_thing.py input
   ```
3. **Check** — how to verify the result is correct before reporting.
4. **Report** — the exact output format.

## Pitfalls

- The mistake people (and models) usually make, and how to avoid it.

## Don't

- Anything irreversible or outward-facing without asking.
