# Demo: terraform-plan-reviewer

This is a real test case from the repo's evals, not a mock-up. The plan is synthetic (an Azure stack with six changes); the outputs below are what the skill actually produced.

**Prompt:** `is this plan safe to apply? Input files: plan.json` ([plan](demo-plan.json))

## Step 1: the bundled script reads the JSON plan

`python3 scripts/plan_summary.py plan.json` (stdlib only, read-only):

```
SUMMARY: 3 create · 2 update · 1 replace
TERRAFORM_EQUIVALENT: Plan: 4 to add, 2 to change, 1 to destroy.

REPLACEMENTS (attribute forcing replacement)
  azurerm_mssql_database.main [replace] ← collation

CRITICAL
  - azurerm_mssql_database.main will be REPLACE — data-bearing resource (azurerm_mssql_database)
  - azurerm_network_security_rule.ssh: open to * at source_address_prefix — sensitive ports 22
  - azurerm_key_vault.kv: purge_protection_enabled = false (was true)

HIGH
  - azurerm_role_assignment.ci: privileged role 'Owner'

NOISE: 1 tag/label-only update(s)

SUGGESTED_VERDICT: DONT_APPLY_YET  (heuristic — confirm by reading the plan)
```

## Step 2: the agent's review (verbatim, eval round 3, Claude Sonnet)

> **VERDICT: ⛔ Don't apply yet**
>
> Summary: 3 add · 2 change · 1 replace · 0 pure destroy
> Terraform's line should read: `Plan: 4 to add, 2 to change, 1 to destroy.` (the replace counts as one add plus one destroy). I did not run terraform; this is read from plan.json.
>
> **Critical (3)**
> 1. `azurerm_mssql_database.main` will be REPLACED (delete then create), forced by `collation` (SQL_Latin1_General_CP1_CI_AS -> Latin1_General_100_CI_AS). Collation is immutable here, so the database is dropped and recreated empty. Data loss.
>    -> Revert the collation change unless it is deliberate. If it is, take a backup or export first and plan a migration (new DB with the new collation, copy data, cut over). `ignore_changes = ["collation"]` would avoid the replace and keep the data, but config and reality would then stay permanently out of sync.
> 2. `azurerm_network_security_rule.ssh`: new Allow rule for port 22 from source `*` (any address). SSH exposed to the internet is scanned within minutes.
>    -> Restrict source_address_prefix to a bastion, VPN or office CIDR, or use Azure Bastion / JIT access.
> 3. `azurerm_key_vault.kv`: purge_protection_enabled true -> false. Azure does not allow purge protection to be turned off once enabled, so this update will fail during apply.
>    -> Set it back to true in config. See the partial-apply warning below.
>
> **High (1)**
> 4. `azurerm_role_assignment.ci`: new `Owner` role at scope /subscriptions/x. That gives the CI identity full control of the whole subscription, including granting access to others.
>    -> Use a least-privilege role (e.g. Contributor on the specific resource group, or a narrower custom role).
>
> **Partial-apply risk**
> Terraform applies independent resources in parallel. The Key Vault update is guaranteed to fail, but the database drop and recreate, the open SSH rule and the Owner assignment have no dependency on it, so they may already have been applied by the time it errors. You could end up with an emptied database, SSH open to the world and CI as Owner, plus a failed run. Fix the Key Vault item and the other issues before applying anything.
>
> **Guardrails to add**
> - `azurerm_mssql_database.main` and `azurerm_key_vault.kv` hold data or secrets: add `lifecycle { prevent_destroy = true }` and an Azure `CanNotDelete` management lock on each.
>
> **Noise (safe to skim)**
> - `azurerm_resource_group.rg`: tag-only update (a: 1 -> 2)
> - `azurerm_linux_web_app.app`: plain create, nothing risky in the plan
>
> Next step: fix items 1-4 in the config, re-run `terraform plan`, and send me the new output.

One wording issue the grader flagged: "guaranteed to fail" overstates it. The skill has since been changed to say "very likely to fail".

## Without the skill

Same prompt, same model, no skill. It also said not to apply and caught the database replace, open SSH and Owner role. It missed:

- the **partial-apply risk**: the database can be dropped before the Key Vault error stops the run
- rating the Key Vault change as **blocking**: it was hedged as "likely to fail"
- **guardrails**: no `prevent_destroy` or delete lock

Score on this case: **7/7 with the skill, 5/7 without.** See [evaluation.md](evaluation.md) for how it was graded.
