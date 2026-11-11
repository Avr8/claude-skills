#!/usr/bin/env python3
"""Validate every skill in skills/ and the marketplace manifest. Stdlib only.

Checks: SKILL.md exists with frontmatter; name matches folder and is kebab-case;
description present and <= 1024 chars; body under 500 lines; marketplace lists every
skill and only existing ones; each skill has >= 2 eval cases with prompt.md, case.yaml
and at least one grader.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors, warnings = [], []


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        return None, text
    fm = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.startswith(" "):
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip()
    return fm, m.group(2)


skills = sorted(p for p in (ROOT / "skills").iterdir() if p.is_dir())
for sd in skills:
    sm = sd / "SKILL.md"
    if not sm.exists():
        errors.append(f"{sd.name}: missing SKILL.md")
        continue
    fm, body = frontmatter(sm.read_text())
    if fm is None:
        errors.append(f"{sd.name}: SKILL.md has no YAML frontmatter")
        continue
    name, desc = fm.get("name", ""), fm.get("description", "")
    if name != sd.name:
        errors.append(f"{sd.name}: frontmatter name '{name}' != folder name")
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name or "x X"):
        errors.append(f"{sd.name}: name must be kebab-case")
    if not desc:
        errors.append(f"{sd.name}: missing description")
    elif len(desc) > 1024:
        errors.append(f"{sd.name}: description is {len(desc)} chars (max 1024)")
    if len(body.splitlines()) > 500:
        warnings.append(f"{sd.name}: SKILL.md body > 500 lines; consider references/")
    for ref in re.findall(r"`((?:references|scripts|assets)/[^`\s]+)`", body):
        if not (sd / ref).exists():
            errors.append(f"{sd.name}: SKILL.md references missing file {ref}")
    cases = [c for c in (sd / "evals").iterdir() if c.is_dir()] if (sd / "evals").is_dir() else []
    if len(cases) < 2:
        errors.append(f"{sd.name}: needs >= 2 eval cases under evals/ (has {len(cases)})")
    for c in cases:
        for req in ("prompt.md", "case.yaml"):
            if not (c / req).exists():
                errors.append(f"{sd.name}/evals/{c.name}: missing {req}")
        if not list((c / "graders").glob("*.md")) if (c / "graders").is_dir() else True:
            errors.append(f"{sd.name}/evals/{c.name}: no graders/*.md")

mp = ROOT / ".claude-plugin" / "marketplace.json"
try:
    manifest = json.loads(mp.read_text())
    listed = set()
    for p in manifest.get("plugins", []):
        for s in p.get("skills", []):
            listed.add(Path(s).name)
            if not (ROOT / s).is_dir():
                errors.append(f"marketplace: plugin '{p.get('name')}' points to missing {s}")
    for sd in skills:
        if sd.name not in listed:
            errors.append(f"marketplace: skill '{sd.name}' not listed in marketplace.json")
except Exception as e:  # noqa: BLE001
    errors.append(f"marketplace.json: {e}")

readme = (ROOT / "README.md").read_text()
for sd in skills:
    if f"skills/{sd.name}" not in readme:
        warnings.append(f"README: no row for {sd.name}")

for w in warnings:
    print(f"warn:  {w}")
for e in errors:
    print(f"error: {e}")
print(f"{len(skills)} skills checked · {len(errors)} errors · {len(warnings)} warnings")
sys.exit(1 if errors else 0)
