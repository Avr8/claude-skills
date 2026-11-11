---
name: stacked-pr-splitter
description: Break a large branch or pull request into a stack of small, independently reviewable and mergeable PRs, each building on the previous one, with a split plan, branch creation, per-PR descriptions and a verification step that the stack reproduces the original diff exactly. Use whenever someone says a PR is "too big", "hard to review", "split this branch", "stack these changes", "break into smaller PRs", has a 1000+ line diff, or a reviewer asked for smaller PRs — works for app code, Terraform/IaC and config changes alike.
---

# Stacked PR splitter

Reviewers approve small PRs faster and catch more bugs in them. This skill turns one big branch into an ordered stack where each PR is small, has one purpose, and leaves the codebase working.

## Principles (why the plan looks the way it does)

- **Each PR must stand alone.** It builds, tests pass, and deploying it alone is safe. A stack where PR 2 breaks the build until PR 4 lands is worse than one big PR.
- **Order by dependency, not by file.** Foundations first (types, schemas, interfaces, new modules unused by anything), then callers, then wiring/flags, then removals of old code.
- **One reason to change per PR.** Mechanical changes (renames, formatting, moves) go in their own PR so reviewers can skim them.
- **Target size**: ~200–400 changed lines of non-generated code. Lockfiles and generated files don't count but should travel with the change that caused them.
- **The stack must be lossless.** The tip of the last branch must equal the original branch's tree. Verify it.

## Workflow

### 1. Understand the diff
```bash
git fetch origin
BASE=$(git merge-base origin/main HEAD)   # adjust main → default branch
git diff --stat $BASE...HEAD
git log --oneline $BASE..HEAD
```
Read the actual changes. Group hunks by purpose. Note dependencies: "file B imports the new function from file A" → A's PR precedes B's.

### 2. Propose the plan — and wait for approval
Present a table before touching any branches:

| # | Branch | Purpose | Files (hunks) | ~Lines | Depends on | Safe alone? |
|---|---|---|---|---|---|---|

Call out anything that can't be split cleanly (e.g. a migration and the code that requires it) and how you'll handle it (feature flag, keep together, or add a temporary compatibility shim).

For **Terraform / IaC**, split by blast radius: new resources unused by anything → modules/variables → wiring that changes existing resources → deletions. Never put a destroy in the same PR as the resource that replaces it unless the plan shows it's an in-place swap. Note which PRs need `terraform plan` attached. Also check how each deletion actually happens:
- **Deleting a Terragrunt unit directory does not destroy its resources.** `run-all` simply stops seeing the unit, and the resources keep running unmanaged. Run `terragrunt destroy` in that unit first, then remove the directory in the PR, or remove the resource blocks inside it so the plan shows the destroy.
- Remove `dependency` blocks and `mock_outputs` that point at the thing being deleted, or the next plan fails.
- Split network rule changes into **opening** (early, before the new thing needs them) and **tightening** (after the old thing is gone), since tightening too early breaks live traffic.

### 3. Build the stack
Prefer this approach — it works regardless of how messy the original commits are:
```bash
ORIG=$(git rev-parse --abbrev-ref HEAD)
git switch -c stack/01-<slug> $BASE
git checkout $ORIG -- <paths for PR 1>        # whole files
# or for partial files: git diff $BASE $ORIG -- <file> > /tmp/p.patch, edit hunks, git apply /tmp/p.patch
git commit -m "<message>"
git switch -c stack/02-<slug>
...
```
After each branch: run the project's build/test/lint command. If something fails, fix it in that PR (usually a missing import or a hunk that belongs earlier), not later.

If `git-spr`, `gh stack`, Graphite (`gt`) or `git-branchless` is installed and the user uses it, use that tool instead — mention it as an option.

### 4. Verify losslessness
```bash
git diff stack/NN-<last> $ORIG --stat   # must be empty
```
If not empty, the remaining diff shows exactly what got lost. Fix before continuing.

### 5. Write PR descriptions
For each PR: one-line purpose, "Part N of M" with links/branch names of neighbours, what to focus on in review, how it was tested. Base each PR on the previous branch (not main) so diffs stay small.

### 6. Push and open — only when the user says so
Pushing and opening PRs is visible to the team. Show the commands (`git push -u origin stack/01-…`, `gh pr create --base stack/01-… --head stack/02-…`) and run them after confirmation. Leave the original branch untouched as a backup.

## Merging advice to give the user
Merge bottom-up. After merging PR 1 with squash, rebase the rest: `git rebase --onto origin/main stack/01-<slug> stack/02-<slug>` (and so on), or let the stack tool do it.
