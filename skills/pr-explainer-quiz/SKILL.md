---
name: pr-explainer-quiz
description: Explain a pull request, diff, commit range or branch to a human reviewer — what changed, why, how data/control flows now, with a Mermaid diagram — then run a short interactive quiz to check they actually understood it before approving. Use whenever someone asks "explain this PR", "walk me through this diff", "help me review", "what does this change do", wants to onboard onto a teammate's change, or worries they're rubber-stamping AI-written code they don't understand.
---

# PR explainer + comprehension quiz

AI-assisted coding makes it easy to approve code you never really understood. This skill explains a change at the level a reviewer needs, then checks understanding with a few pointed questions — so "LGTM" means something.

## 1. Gather the change
Pick whichever applies:
```bash
gh pr view <num> --json title,body,baseRefName,headRefName,files   # GitHub PR
gh pr diff <num>
git diff <base>...<head>                                            # branch
git show <sha>                                                     # single commit
```
Read the PR description and linked issue if any. Then read the **surrounding code** of changed functions (callers, callees, tests) — a diff alone hides the context that matters.

## 2. Explain — in this order
1. **One-paragraph summary**: what behaviour changes for a user or caller. Not a list of files.
2. **Why**: the problem being solved, from the description/issue/commit messages. If the reason isn't stated anywhere, say so — that's a review finding.
3. **Diagram**: a Mermaid `sequenceDiagram` or `flowchart` of the *new* flow, highlighting what's new/changed (use a note or `:::changed` class). Keep it under ~15 nodes; diagram the core path, not everything.
4. **Walkthrough by concept, not by file**: group related hunks ("the retry logic", "the new config flag"). For each: what it does, and anything non-obvious (concurrency, error handling, edge cases, performance).
5. **Risk notes**: things a reviewer should look at hardest — changed public interfaces, migrations, deleted tests, error paths swallowed, security-sensitive code, missing tests for new branches. Be specific with `file:line`.

## 3. Quiz
Ask **3–5 questions**, one at a time, waiting for the answer before the next. Good questions require understanding, not recall:
- "What happens now if `<dependency>` times out during `<operation>`?"
- "Which existing caller is affected by the signature change, and how?"
- "Why does `<line>` need to come before `<line>`?"
- "If we roll this back after the migration ran, what breaks?"

Avoid trivia ("what's the new function called?"). Mix: at least one about failure/edge behaviour, one about why a design choice was made.

After each answer: say whether it's right, and give the correct explanation in 1–3 sentences with a code reference. If they're wrong on something important, suggest which part of the diff to re-read.

## 4. Wrap up
Score (e.g. 4/5) and a short verdict: "ready to review", or "re-read X before approving". Offer to draft review comments for any risks found.

## Scope to the request
The full flow (summary → why → diagram → walkthrough → risks → quiz) is the default for "walk me through this" or "help me review". When the user narrows the request, respect it:
- "no quiz" / "skip the quiz": steps 1–2 without step 3.
- "just the summary and risks": the one-paragraph summary and the risk notes, nothing else: no diagram, no walkthrough. Offer the rest in one closing line.
- "just the diagram": the diagram plus a two-sentence caption.

The first risk listed should be the one that changes behaviour for users or money (like a silent wrong charge), not the most technically interesting one.
