---
name: incident-postmortem
description: Turn raw incident material — Slack/Teams threads, alert history, Grafana/Datadog screenshots or queries, logs, deploy and config-change history, on-call notes — into a blameless postmortem with a precise UTC timeline, impact numbers, root cause and contributing factors (5 whys), what went well/poorly, and owned, dated action items. Use whenever someone mentions a postmortem, RCA, incident report, outage write-up, "what happened during the incident", a SEV/P1 review, or pastes an incident channel and asks for a summary — even if they only ask for "a timeline".
---

# Incident postmortem

A good postmortem lets someone who wasn't there understand what happened, why the system allowed it, and what will stop it recurring. A bad one assigns blame or ends with "be more careful".

## 1. Collect evidence before writing
Gather whatever the user has; ask for what's missing (don't block on it — write with gaps marked `[TBD]`):
- Detection: first alert / first customer report, with timestamps
- The incident channel or chat thread
- Metrics: error rate, latency, saturation for the affected service(s) — and if observability MCP tools (Grafana, Datadog, Prometheus, Loki) are connected, query them directly for the incident window and a baseline window before it
- Changes in the 72h before: deploys, config changes, feature flags, infra changes, certificate rotations, dependency updates
- Mitigation and resolution actions

### Stay inside the evidence
The postmortem is a record of *this* incident. Use only what the user gave you or what you queried for this incident window. Don't bring in details from other incidents, earlier conversations or remembered context, even if they look related. Readers can't tell where those came from, and it makes the document unreliable. Don't describe or allude to other incidents, even in chat. If a recurrence check would help, ask the neutral question "Has anything like this happened before?" and leave it at that.

Use **roles, not names**, everywhere in the document, including the timeline ("on-call SRE acked", not "Priya acked"). Names belong in the incident channel, not in a blameless review.

## 2. Build the timeline first
Everything else is derived from it. Rules:
- **All times in UTC** with date, `YYYY-MM-DD HH:MM`. Convert local times explicitly and note the source timezone once.
- One line per event: time · what happened · source (alert name, message link, graph). Facts only, no interpretation.
- Compute every interval from the timeline's own timestamps and re-check the arithmetic before writing it in prose ("12 minutes before the first alert"). Mismatched numbers are the first thing reviewers notice.
- Mark the key moments: **trigger** (change/event that started it), **impact start**, **detected**, **mitigated**, **resolved**. Compute time-to-detect and time-to-mitigate from these.
- Gaps of >30 min with no entries during active impact are worth a note — often where the real lesson is.

## 3. Root cause
Use 5 whys, but stop at a cause the team can actually act on, and separate:
- **Trigger** — what started it (a config change, traffic spike)
- **Root cause(s)** — why the system was vulnerable to that trigger
- **Contributing factors** — what made it worse or slower to fix (missing alert, misleading dashboard, runbook out of date)

Systems, not people: "the deploy pipeline allowed an unreviewed config change to reach prod" — not "Alex pushed a bad config". Use roles ("the on-call engineer") instead of names in the body.

If evidence is inconclusive, say so and list the hypotheses with what would confirm each. Don't present a guess as the root cause.

## 4. Write it
Use the structure in `references/template.md`. Keep the summary to 3–4 sentences a VP could read. Quantify impact (requests failed, % of users, duration, revenue/SLA if known).

## 5. Action items
Each one must be: specific, owned (a role or team named in the material, or `TBD — suggest: <role>`; don't invent team names), prioritized (P0 prevents recurrence / P1 reduces impact / P2 improves response), and dated. Prefer actions that prevent the *class* of problem (guardrail, alert, automated check) over one-off fixes. Avoid "improve monitoring" — say which alert, on which signal, at what threshold.

## 6. Deliver
Default to Markdown. If the user publishes to Confluence/Notion/Google Docs and a connector is available, offer to publish — don't do it unprompted.
