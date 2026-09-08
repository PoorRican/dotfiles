"""Reconcile Nix-declared cron jobs into a Hermes profile's cron/jobs.json.

Usage: reconcile-cron.py <jobs.json>   (HERMES_HOME selects the profile)

Declared jobs are keyed by name. Jobs that this script created carry
``managed_by: nix`` plus ``nix_spec`` (the declared record); only those are ever
updated or removed, so jobs created by the agent or ``hermes cron`` stay
untouched. Runtime state (next_run_at, last_status, run counters) is kept
because updates go through Hermes' own cron API instead of rewriting the file.
"""

import json
import sys

from cron import jobs as cron_jobs

MANAGED_BY = "nix"

# Declared fields that map 1:1 onto create_job keyword arguments.
CREATE_FIELDS = (
    "schedule",
    "prompt",
    "skills",
    "deliver",
    "model",
    "provider",
    "base_url",
    "script",
    "enabled_toolsets",
    "workdir",
    "no_agent",
    "reasoning_effort",
    "repeat",
    "failure_deliver",
    "monitor_script",
    "monitor_url",
    "context_from",
)


def update_fields(spec: dict) -> dict:
    """Fields to push through update_job so a changed spec fully replaces the old one."""
    updates = {field: spec.get(field) for field in CREATE_FIELDS}
    # create_job defaults an unset delivery target to "local"; keep updates symmetric.
    updates["deliver"] = spec.get("deliver") or "local"
    return updates


def main() -> int:
    with open(sys.argv[1], encoding="utf-8") as handle:
        declared = json.load(handle)

    managed = {
        job["name"]: job
        for job in cron_jobs.load_jobs()
        if job.get("managed_by") == MANAGED_BY
    }

    for name, spec in declared.items():
        job = managed.get(name)
        if job is None:
            created = cron_jobs.create_job(
                name=name, **{field: spec.get(field) for field in CREATE_FIELDS}
            )
            cron_jobs.update_job(created["id"], {"managed_by": MANAGED_BY, "nix_spec": spec})
            print(f"hermes cron: created {name} ({created['id']})")
        elif job.get("nix_spec") != spec:
            cron_jobs.update_job(job["id"], {**update_fields(spec), "nix_spec": spec})
            print(f"hermes cron: updated {name} ({job['id']})")

    for name, job in managed.items():
        if name not in declared:
            cron_jobs.remove_job(job["id"])
            print(f"hermes cron: removed {name} ({job['id']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
