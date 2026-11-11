---
name: terraform-plan-reviewer
description: Review a Terraform, OpenTofu or Terragrunt plan before apply — summarizes creates/updates/replaces/destroys, flags dangerous changes (data-bearing resources being destroyed or replaced, forced replacements from immutable attributes, IAM/RBAC widening, security groups or NSGs opened to 0.0.0.0/0, public exposure, disabled deletion protection or backups, state moves), explains *why* each replace happens, and gives an apply / don't-apply verdict. Use whenever someone pastes or points to a `terraform plan` / `tofu plan` / `terragrunt plan` / `run-all plan` output or plan JSON, asks "is this safe to apply", "review my plan", "why is it replacing X", or is about to apply infra changes in any cloud (AWS, Azure, GCP, Kubernetes).
---

# Terraform plan reviewer

The plan output is the last line of defence before infrastructure changes. A 400-line plan hides the one `-/+` that recreates a database. This skill reads the whole plan, ranks what matters, and explains it.

## 1. Get a machine-readable plan if possible
Text plans are fine, but JSON is unambiguous:
```bash
terraform plan -out=tfplan && terraform show -json tfplan > plan.json
# terragrunt: terragrunt plan -out=tfplan && terragrunt show -json tfplan > plan.json
# run-all: do this per module, or review the text output per module
```
Then run the summarizer:
```bash
python3 <skill-dir>/scripts/plan_summary.py plan.json          # or: ... - < plan.json
```
It prints action counts, every destroy/replace with the attributes forcing replacement, and pattern-based risk flags. For text-only plans, read them directly and apply the same checklist.

**Never run `apply`**, and don't run `plan` against an environment without the user asking — plans can take locks and read secrets.

## 2. Risk checklist (what the script flags, and what you should check by reading)

**Critical — stop and confirm with the user**
- Destroy or replace of anything holding data: databases (RDS, Azure SQL/Postgres/MySQL, Cloud SQL, Cosmos, DynamoDB), storage accounts/buckets, disks/volumes, Key Vaults/KMS keys, Redis, Kafka/Event Hubs, file shares, DNS zones.
- Replace of networking that everything depends on: VNets/VPCs, subnets, gateways, load balancers, public IPs (IP changes break allowlists and DNS).
- `prevent_destroy` removed, `deletion_protection`/`purge_protection` set false, backup retention lowered, `skip_final_snapshot = true`. (Azure Key Vault purge protection cannot be turned off once it's on, so that apply will fail partway. Say so, because the resources applied before it will already have changed.)
- Kubernetes cluster or node pool replacement.
- Admin or database ports (22, 3389, 1433, 3306, 5432, 6379, 27017, 9200) opened to `0.0.0.0/0` / `*` / `Internet`. These are actively scanned within minutes of exposure.

**High**
- IAM/RBAC widening: `*` actions or resources, Owner/Contributor/Admin role assignments, new service-account keys, trust policies with broad principals.
- Other ingress opened to `0.0.0.0/0` / `*` / `Internet` (web ports, unknown ports); public network access enabled; public blob/bucket access.
- Encryption disabled or TLS minimum lowered.
- Resources removed from state (`removed` blocks, `moved` mismatches) — usually intentional but verify.

**Medium**
- Updates that cause restarts/downtime (instance size changes, app settings that recycle workers, node pool upgrades).
- Tags/labels drift only — usually noise; group and de-emphasize.
- Unknown values (`(known after apply)`) on attributes other resources depend on.

## 3. Explain replacements
For every `-/+` or `+/-`, name the attribute(s) that forced it (the script reads `replace_paths`; in text, look for `# forces replacement`) and say whether it can be avoided — e.g. `lifecycle { ignore_changes = [...] }`, a `moved` block for a renamed address, `create_before_destroy` to avoid downtime, or reverting an accidental change to an immutable field (name, location, zone, SKU tier).

## 3b. Things reviewers often miss
- **Partial applies.** Terraform applies independent resources in parallel. If one change is guaranteed to fail (e.g. disabling Key Vault purge protection, a name already taken), the others may already have run. A destroy-and-recreate of a database can complete *before* the failing step. Say this whenever the plan mixes a likely failure with a destructive change.
- **Recommend guardrails** on every data-bearing resource in the plan: `lifecycle { prevent_destroy = true }`, plus a cloud-side delete lock (Azure `CanNotDelete`, AWS deletion protection, GCP `deletion_protection`).
- **Globally unique names** (storage accounts, S3 buckets, Key Vaults) mean `create_before_destroy` can't avoid downtime, and a freshly deleted name may not be reusable straight away.
- **Counts must match.** If you say "6 changes, 3 serious", list exactly 3. Quote Terraform's own `Plan: X to add, Y to change, Z to destroy` line too (a replace counts as one add plus one destroy), so the user can match it against their terminal.
- **Don't overclaim provider behaviour.** Whether an attribute forces replacement can vary by provider version (e.g. azurerm LRS↔ZRS). Rely on the plan's own `# forces replacement` / `replace_paths` markers, and when you say what *would* happen in another configuration, hedge or say how to check (`terraform plan` after the change).
- **`ignore_changes` is a real option, just a misleading one.** Ignoring the forcing attribute does avoid the replace and keep the data, but it leaves config and reality permanently out of sync. Present it that way, not as "won't help".

## 4. Output
Match the question. For "is this safe to apply?", use the full format below. For a narrow question ("why is it replacing X?"), answer it directly first (cause, consequence, fix) in a few short paragraphs, and add a one-line verdict at the end instead of the full report.
```
VERDICT: ⛔ Don't apply yet | ⚠️ Apply with care | ✅ Looks safe
Summary: 3 add · 5 change · 1 replace · 0 destroy  (module.x, module.y)

Critical
  1. azurerm_mssql_database.main will be REPLACED — forced by `collation`. Data loss.
     → revert collation or migrate data first.
High
  …
Noise (safe to skim)
  12 tag-only updates
```
Lead with the verdict. Group noise. Keep each finding to one or two lines with the resource address and a concrete next step.
