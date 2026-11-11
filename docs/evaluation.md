# How the skills are evaluated

The idea behind this repo: agent instructions are engineering artifacts, so test them the way you'd test code. Write cases, check outputs against explicit expectations, fix what fails, and test again.

## Method

1. **Test cases.** Each skill has two prompts under `skills/<name>/evals/<case>/`, written the way a user would type them. Where a task needs input (a diff, a Terraform plan, an incident thread, a git repo with a secret in its history, a small Flask app), it lives in the case's `files/`, and `place-files.sh` sets it up. All inputs are synthetic.
2. **Two runs per case.** The same prompt is run once **with** the skill and once **without** it (plain Claude, which must not read the repo). Each run works in its own copy of the inputs.
3. **Explicit assertions.** Each case has 3–7 checks in `graders/`, each one a single verifiable statement. Examples:
   - "The timeline uses UTC times correctly converted from IST (e.g. 14:32 IST → 09:02 UTC)"
   - "No new branches were created and no commits were made"
   - "The rewritten post invents no details about the systems, outcomes or the author's feelings"
   - "The table in status-report.docx has visible borders"
4. **A separate grader agent** reads each output and marks every assertion pass or fail, with evidence. Where possible it checks the result directly instead of trusting the answer: it inspects git branches and the reflog, unzips the .docx XML, renders PDF pages, re-checks every `file:line` reference against the code, and recomputes timezone and interval arithmetic.
5. **Iterate.** Failures and grader notes go back into the skills, and assertions that both versions passed trivially were replaced with sharper ones. Three rounds were run.

## Results

| Round | Model (runs and grading) | With skills | Without |
|---|---|---|---|
| 1 | Claude Opus | 48/49 | 42/49 |
| 2 | Claude Opus, sharper assertions | 74/77 (96%) | 60/77 (78%) |
| 3 | Claude Sonnet, sharper again | **72/75 (96%)** | **46/75 (61%)** |

The baseline score falls each round because the assertions got better at catching real differences, not because the base model got worse.

Per-skill round-3 results are in the [README](../README.md#how-these-were-tested).

## Things the tests caught

- **Plain Claude acted without asking.** In one round-2 run, asked to "split this into smaller PRs", it created 6 branches and commits in the repo straight away. With the skill, it proposed a plan and waited for approval. (In round 3, plain Claude on Sonnet didn't do this, so treat it as a single observation.)
- **Invented facts.** Asked to de-AI a LinkedIn post, plain Claude added claims the author never made ("I learned more there than anywhere else", call-volume details). The skill uses placeholders for missing facts instead.
- **Context leaking in.** Both versions sometimes pulled details of a real past incident from the user's saved memory into a postmortem. The skill now keeps the document strictly to the evidence provided.
- **The skill losing.** In round 1, plain Claude did better on md-to-doc: it added table borders and found headless Chrome as a PDF engine. Both went into the skill.

## Limitations

- **Small sample.** Two prompts per skill per round, one run each. This is a sanity check, not a benchmark, and no statistical claim is made.
- **Same model family.** The grader is also Claude, so it isn't an independent judge. Assertions were written to be checkable against files and git state wherever possible to reduce this.
- **Synthetic inputs.** Real repos, plans and incidents are messier.
- **Skill-author bias.** The same person wrote the skills and the assertions.
- **Round 3** ran the two cases for each skill and configuration in a single agent to save tokens, so the second case may have been slightly influenced by the first.

## Run it yourself

```bash
claude plugin eval skills/terraform-plan-reviewer --allow-tools Write,Edit,Bash --scaffold
```
These are real, billed model runs.
