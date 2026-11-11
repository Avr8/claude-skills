---
tags: [incident-postmortem]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

we had an outage yesterday, our API was returning 502s for about 40 mins after a deploy. write up the postmortem
