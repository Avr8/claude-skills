---
tags: [stacked-pr-splitter]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

I have a terragrunt PR that adds a new AKS node pool, changes NSG rules on the existing subnet, and deletes the old VM scale set. How should I split this up?
