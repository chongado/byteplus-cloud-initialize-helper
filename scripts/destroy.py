#!/usr/bin/env python3
"""Review and execute full teardown, letting VKE remove required add-ons."""

import datetime
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "terraform_script"
CLUSTER = "bytepluscc_vke_cluster.vke_cluster"
REQUIRED_ADDONS = (
    "bytepluscc_vke_addon.addon_core_dns",
    "bytepluscc_vke_addon.addon_metrics_server",
)


def terraform(*args, capture=False):
    result = subprocess.run(
        ["terraform", *args], cwd=MODULE,
        text=True, stdout=subprocess.PIPE if capture else None,
        check=True,
    )
    return result.stdout if capture else None


def deletions(plan):
    result = {}
    for change in plan.get("resource_changes", []):
        actions = change["change"]["actions"]
        if actions == ["no-op"]:
            continue
        if actions != ["delete"]:
            raise RuntimeError(f"Unexpected teardown action: {change['address']} {actions}")
        result[change["address"]] = (change["change"].get("before") or {}).get("id")
    return result


def main():
    os.umask(0o077)
    if any(arg in ("-h", "-help", "--help") for arg in sys.argv[1:]):
        terraform("destroy", "-help")
        return
    auto_approve = False
    input_enabled = True
    plan_options = []
    apply_options = []
    arguments = iter(sys.argv[1:])
    for arg in arguments:
        if arg in ("-auto-approve", "-auto-approve=true"):
            auto_approve = True
        elif arg == "-auto-approve=false":
            auto_approve = False
        else:
            plan_options.append(arg)
            if arg == "-input=false":
                input_enabled = False
            elif arg == "-input=true":
                input_enabled = True
            # Apply-time execution controls still apply to the saved plan.
            if arg in ("-parallelism", "-lock-timeout", "-lock"):
                value = next(arguments)
                plan_options.append(value)
                apply_options.extend([arg, value])
            elif arg == "-no-color" or arg.startswith(("-parallelism=", "-lock-timeout=", "-lock=")):
                apply_options.append(arg)

    archive = ROOT / ".terraform-teardown"
    archive.mkdir(mode=0o700, exist_ok=True)
    archive.chmod(0o700)
    prefix = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ-")
    work = Path(tempfile.mkdtemp(prefix=prefix, dir=archive))

    def make_plan(name):
        filename = work / name
        terraform("plan", "-destroy", "-var-file=var.tfvars", *plan_options, f"-out={filename}")
        return filename, json.loads(terraform("show", "-json", str(filename), capture=True))

    filename, original = make_plan("review.tfplan")
    approved = deletions(original)
    if not approved:
        print("No resources to destroy.", flush=True)
        return

    delegated = [address for address in REQUIRED_ADDONS if address in approved]
    if delegated and CLUSTER not in approved:
        raise RuntimeError("Required VKE add-ons can only be removed together with their cluster. Use a full destroy.")
    if delegated:
        print("Required add-ons will be removed by VKE when its cluster is deleted:", flush=True)
        print("\n".join(delegated), flush=True)
    print(f"Private teardown records: {work}", flush=True)

    # Confirmation precedes state removal, so cancellation leaves ownership intact.
    if not auto_approve:
        if not input_enabled or not sys.stdin.isatty():
            raise RuntimeError("No state changed. Use -auto-approve for an already-authorized non-interactive destroy.")
        if input("Destroy these resources? Type yes to continue: ").strip() != "yes":
            print("Destroy cancelled; no state changed.", flush=True)
            return

    (work / "before.tfstate").write_text(terraform("state", "pull", capture=True))
    (work / "actions.json").write_text(json.dumps({"approved": approved, "delegated_to_cluster": delegated}, indent=2))
    if delegated:
        terraform("state", "rm", *delegated)
        filename, revised = make_plan("execute.tfplan")
        remaining = deletions(revised)
        expected = {key: value for key, value in approved.items() if key not in delegated}
        if any(key not in expected or expected[key] != value for key, value in remaining.items()):
            raise RuntimeError("Teardown scope changed after review. Inspect the saved plans and backup before retrying.")

    terraform("apply", "-input=false", *apply_options, str(filename))


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        sys.exit(exc.returncode)
    except (RuntimeError, StopIteration, EOFError) as exc:
        print(f"Destroy stopped: {exc}", file=sys.stderr)
        sys.exit(1)
