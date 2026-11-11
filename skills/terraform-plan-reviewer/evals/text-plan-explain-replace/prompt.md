---
tags: [terraform-plan-reviewer]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

why is terraform trying to replace my storage account??

  # azurerm_storage_account.logs must be replaced
-/+ resource "azurerm_storage_account" "logs" {
      ~ account_replication_type = "LRS" -> "ZRS"
      ~ location                 = "westeurope" -> "northeurope" # forces replacement
        name                     = "prodlogs01"
    }
Plan: 1 to add, 0 to change, 1 to destroy.
