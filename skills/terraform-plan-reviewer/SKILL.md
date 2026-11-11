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
- `prevent_destroy` removed, `deletion_protection`/`purge_protection` set false, backup retention lowered, `skip_final_snapshot = true`.
- Kubernetes cluster or node pool replacement.

**High**
- IAM/RBAC widening: `*` actions or resources, Owner/Contributor/Admin role assignments, new service-account keys, trust policies with broad principals.
- Ingress opened to `0.0.0.0/0` / `*` / `Internet`, especially on 22, 3389, DB ports; public network access enabled; public blob/bucket access.
- Encryption disabled or TLS minimum lowered.
- Resources removed from state (`removed` blocks, `moved` mismatches) — usually intentional but verify.

**Medium**
- Updates that cause restarts/downtime (instance size changes, app settings that recycle workers, node pool upgrades).
- Tags/labels drift only — usually noise; group and de-emphasize.
- Unknown values (`(known after apply)`) on attributes other resources depend on.

## 3. Explain replacements
For every `-/+` or `+/-`, name the attribute(s) that forced it (the script reads `replace_paths`; in text, look for `# forces replacement`) and say whether it can be avoided — e.g. `lifecycle { ignore_changes = [...] }`, a `moved` block for a renamed address, `create_before_destroy` to avoid downtime, or reverting an accidental change to an immutable field (name, location, zone, SKU tier).

## 4. Output
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
