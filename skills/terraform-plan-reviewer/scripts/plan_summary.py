#!/usr/bin/env python3
"""Summarize a Terraform/OpenTofu JSON plan (`terraform show -json tfplan`) and flag risky changes.

Usage: plan_summary.py plan.json   |   plan_summary.py - < plan.json
Standard library only.
"""
import json
import re
import sys
from collections import Counter, defaultdict

DATA_BEARING = re.compile(
    r"(db_instance|rds_cluster|dynamodb_table|s3_bucket$|ebs_volume|efs_file_system|elasticache|"
    r"kms_key|secretsmanager_secret|"
    r"mssql_(server|database|managed_instance)|sql_(server|database)|postgresql|mysql|cosmosdb|"
    r"storage_account|storage_container|storage_share|managed_disk|key_vault$|key_vault_key|redis|eventhub|servicebus_namespace|"
    r"sql_database_instance|storage_bucket|compute_disk|bigtable|spanner|"
    r"persistent_volume|_dns_zone|route53_zone|kafka|opensearch|elasticsearch)",
)
CORE_NETWORK = re.compile(
    r"(vpc$|virtual_network$|subnet$|nat_gateway|internet_gateway|vpn_gateway|lb$|load_balancer|application_gateway|"
    r"public_ip|eip$|firewall$|compute_network|kubernetes_cluster|eks_cluster|container_cluster|node_pool|node_group)"
)
IAM = re.compile(r"(iam_|role_assignment|role_definition|rbac|service_account_key|policy)")
NETSEC = re.compile(r"(security_group|network_security|firewall_rule|compute_firewall|nsg)")
OPEN_CIDR = re.compile(r"^(0\.0\.0\.0/0|::/0|\*|Internet|any)$", re.I)
RISKY_PORTS = {"22", "3389", "1433", "3306", "5432", "6379", "27017", "9200"}
PROTECTION_KEYS = {
    "deletion_protection": False,
    "purge_protection_enabled": False,
    "prevent_destroy": False,
    "skip_final_snapshot": True,
    "public_network_access_enabled": True,
    "allow_nested_items_to_be_public": True,
    "publicly_accessible": True,
    "enable_https_traffic_only": False,
    "https_traffic_only_enabled": False,
    "storage_encrypted": False,
}


def walk(obj, path=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            yield from walk(v, f"{path}.{k}" if path else k)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from walk(v, f"{path}[{i}]")
    else:
        yield path, obj


def actions_label(actions):
    a = tuple(actions)
    return {
        ("create",): "create",
        ("update",): "update",
        ("delete",): "destroy",
        ("delete", "create"): "replace",
        ("create", "delete"): "replace(cbd)",
        ("read",): "read",
        ("no-op",): "no-op",
    }.get(a, "/".join(a))


def changed_keys(before, after):
    keys = set()
    if isinstance(before, dict) and isinstance(after, dict):
        for k in set(before) | set(after):
            if before.get(k) != after.get(k):
                keys.add(k)
    return keys


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "-"
    data = json.load(sys.stdin if src == "-" else open(src))
    rcs = data.get("resource_changes", [])
    counts = Counter()
    findings = defaultdict(list)  # severity -> [str]
    replaces, destroys = [], []
    tag_only = []

    for rc in rcs:
        addr = rc.get("address", "?")
        rtype = rc.get("type", "")
        ch = rc.get("change", {})
        label = actions_label(ch.get("actions", []))
        if label in ("no-op", "read"):
            continue
        counts[label] += 1
        before, after = ch.get("before") or {}, ch.get("after") or {}

        if label.startswith("replace"):
            forced = [".".join(str(p) for p in rp) for rp in ch.get("replace_paths", []) or []]
            replaces.append((addr, forced, label))
        if label == "destroy":
            destroys.append(addr)

        if label in ("destroy",) or label.startswith("replace"):
            if DATA_BEARING.search(rtype):
                findings["CRITICAL"].append(f"{addr} will be {label.upper()} — data-bearing resource ({rtype})")
            elif CORE_NETWORK.search(rtype):
                findings["CRITICAL"].append(f"{addr} will be {label.upper()} — core network/cluster resource ({rtype})")
            elif label == "replace" and not label.endswith("(cbd)"):
                findings["MEDIUM"].append(f"{addr} replaced destroy-before-create → brief downtime possible")

        if label == "update":
            ck = changed_keys(before, after)
            if ck and ck <= {"tags", "tags_all", "labels", "terraform_labels", "effective_labels"}:
                tag_only.append(addr)
                continue

        if label in ("create", "update") or label.startswith("replace"):
            for path, val in walk(after):
                leaf = path.split(".")[-1].split("[")[0]
                if leaf in PROTECTION_KEYS and val == PROTECTION_KEYS[leaf]:
                    prev = dict(walk(before)).get(path)
                    if prev != val:
                        findings["HIGH"].append(f"{addr}: {path} = {json.dumps(val)}" + (f" (was {json.dumps(prev)})" if prev is not None else ""))
                if leaf in ("backup_retention_period", "retention_days", "backup_retention_days") and isinstance(val, (int, float)):
                    prev = dict(walk(before)).get(path)
                    if isinstance(prev, (int, float)) and val < prev:
                        findings["HIGH"].append(f"{addr}: {path} lowered {prev} → {val}")
                if NETSEC.search(rtype) and isinstance(val, str) and OPEN_CIDR.match(val.strip()):
                    blob = json.dumps(after)
                    ports = sorted(p for p in RISKY_PORTS if re.search(rf'"{p}"|\b{p}\b', blob))
                    sev = "CRITICAL" if ports else "HIGH"
                    findings[sev].append(f"{addr}: open to {val} at {path}" + (f" — sensitive ports {', '.join(ports)}" if ports else ""))
                if IAM.search(rtype) and isinstance(val, str):
                    if val.strip() == "*" or re.search(r'"Action"\s*:\s*"\*"|"Resource"\s*:\s*"\*"', val):
                        findings["HIGH"].append(f"{addr}: wildcard permission at {path}")
                    if re.fullmatch(r"(Owner|Contributor|User Access Administrator|roles/owner|roles/editor|AdministratorAccess|cluster-admin)", val.strip()):
                        findings["HIGH"].append(f"{addr}: privileged role '{val}'")

    # Output
    order = ["create", "update", "replace", "replace(cbd)", "destroy"]
    summary = " · ".join(f"{counts[k]} {k}" for k in order if counts[k]) or "no changes"
    other = {k: v for k, v in counts.items() if k not in order}
    print(f"SUMMARY: {summary}" + (f" · other: {dict(other)}" if other else ""))

    drift = data.get("resource_drift") or []
    if drift:
        print(f"DRIFT: {len(drift)} resource(s) changed outside Terraform since last apply")

    if replaces:
        print("\nREPLACEMENTS (attribute forcing replacement)")
        for addr, forced, label in replaces:
            print(f"  {addr} [{label}] ← {', '.join(forced) if forced else 'unknown (check text plan for # forces replacement)'}")
    if destroys:
        print("\nDESTROYS")
        for addr in destroys:
            print(f"  {addr}")

    for sev in ("CRITICAL", "HIGH", "MEDIUM"):
        items = list(dict.fromkeys(findings[sev]))
        if items:
            print(f"\n{sev}")
            for it in items:
                print(f"  - {it}")
    if tag_only:
        print(f"\nNOISE: {len(tag_only)} tag/label-only update(s)")

    verdict = "DONT_APPLY_YET" if findings["CRITICAL"] else ("APPLY_WITH_CARE" if findings["HIGH"] or replaces or destroys else "LOOKS_SAFE")
    print(f"\nSUGGESTED_VERDICT: {verdict}  (heuristic — confirm by reading the plan)")


if __name__ == "__main__":
    main()
