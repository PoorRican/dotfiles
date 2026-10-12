#!/usr/bin/env python3
"""Conservative computebox retention previews; only UV supports --apply.
Nix/image/build-cache expiry is blocked. Never deletes containers, volumes or worktrees.
"""
import argparse
import datetime
import fcntl
import fnmatch
import http.client
import json
import math
import os
from pathlib import Path
import re
import socket
import subprocess
import tempfile
import time

DOCKER = ["/usr/bin/docker", "--host", "unix:///var/run/docker.sock"]
NIX_STORE = "/nix/var/nix/profiles/default/bin/nix-store"
KEEP_TAGS = ("*:latest", "*:stable", "*:rollback*")
ID_PATTERN = re.compile(r"sha256:[0-9a-f]{64}")
BLOCKED_APPLY = {
    "nix": "Stock profile deletion cannot atomically enforce the distinct-predecessor floor across concurrent profile changes.",
    "images": "Stock exact-ID removal cannot atomically enforce concurrent protected-tag or explicit-hold updates.",
    "build-cache": "Build-cache expiry is unavailable pending the backend-age discrepancy investigation.",
}


def blocked_apply(operation):
    return {"state": "blocked", "phase": "capability-check", "exit_code": 2,
            "reason": BLOCKED_APPLY[operation], "mutation_performed": False,
            "error": {"type": "UnsupportedApply", "message": BLOCKED_APPLY[operation]},
            "diagnostics": {}, "mutation_status": "not-started", "reclaim_verified": False}


def plan(rows, current, now, days=30, floor=5):
    rows = sorted(rows, key=lambda r: r["generation"])
    ids = [r["generation"] for r in rows]
    if len(ids) != len(set(ids)) or current not in ids or days <= 0 or floor < 1:
        raise ValueError("Invalid generation inventory or retention policy")
    cutoff = now - days * 86400
    keep = {current}
    keep.update(r["generation"] for r in rows[-floor:])
    keep.update(r["generation"] for r in rows if r["mtime"] >= cutoff)
    older = [r for r in rows if r["mtime"] < cutoff]
    if older:
        keep.add(older[-1]["generation"])
    keep.update(r["generation"] for r in rows if r["generation"] > current)
    targets = {next(r["target"] for r in rows if r["generation"] == current)}
    previous = 0
    for row in reversed(rows):
        if row["generation"] >= current or row["target"] in targets:
            continue
        if previous == floor:
            break
        targets.add(row["target"])
        keep.add(row["generation"])
        previous += 1
    return {"current": current,
            "keep_ids": [i for i in ids if i in keep],
            "delete_ids": [i for i in ids if i not in keep],
            "retention_days": days, "distinct_previous_closure_floor": floor,
            "cutoff_epoch": cutoff}


def snapshot(profile):
    p = Path(profile)
    link = os.readlink(p)
    match = re.fullmatch(re.escape(p.name) + r"-(\d+)-link", link)
    if not match:
        raise ValueError("Unexpected current profile link")
    current = int(match[1])
    rows = []
    for entry in p.parent.iterdir():
        match = re.fullmatch(re.escape(p.name) + r"-(\d+)-link", entry.name)
        if not match:
            continue
        if not entry.is_symlink():
            raise ValueError("Generation is not a symlink")
        st = entry.lstat()
        rows.append({"generation": int(match[1]), "mtime": st.st_mtime,
                     "mtime_ns": st.st_mtime_ns, "ctime_ns": st.st_ctime_ns,
                     "device": st.st_dev, "inode": st.st_ino,
                     "target": os.readlink(entry)})
    if current not in {r["generation"] for r in rows}:
        raise ValueError("Current generation missing")
    return sorted(rows, key=lambda r: r["generation"]), current


def run(cmd, timeout=600, env=None):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout,
                          env=env, check=False)


def closure_paths(targets):
    paths = set()
    for target in sorted(targets):
        command = [NIX_STORE, "--query", "--requisites", target]
        result = run(command, timeout=120)
        if result.returncode:
            raise subprocess.CalledProcessError(result.returncode, command,
                                                output=result.stdout, stderr=result.stderr)
        paths.update(result.stdout.splitlines())
    if not paths or any(not os.path.exists(p) for p in paths):
        raise RuntimeError("Protected closure has missing paths")
    return sorted(paths)


def nix_profiles(apply):
    if apply:
        return blocked_apply("nix")
    results = []
    for name in ("profile", "home-manager"):
        profile = Path.home() / ".local/state/nix/profiles" / name
        before = snapshot(profile)
        selection = plan(*before, time.time())
        protected = {r["target"] for r in before[0] if r["generation"] in selection["keep_ids"]}
        paths = closure_paths(protected)
        result = {"profile": str(profile), **selection,
                  "protected_targets": sorted(protected), "protected_closure_paths": paths}
        results.append(result)
    return {"state": "preview", "profiles": results, "observation": "point-in-time",
            "apply_supported": False, "store_gc_invoked": False}


class LocalDocker(http.client.HTTPConnection):
    def __init__(self):
        super().__init__("localhost", timeout=120)

    def connect(self):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.settimeout(self.timeout)
        self.sock.connect("/var/run/docker.sock")


def docker_get(endpoint):
    connection = LocalDocker()
    try:
        connection.request("GET", endpoint)
        response = connection.getresponse()
        payload = response.read()
        if response.status != 200:
            detail = payload[:1000].decode("utf-8", errors="replace")
            raise RuntimeError(f"Local Docker query {endpoint} failed: HTTP {response.status}: {detail}")
        return json.loads(payload)
    finally:
        connection.close()


def docker_snapshot():
    images = docker_get("/images/json?all=1")
    containers = docker_get("/containers/json?all=1")
    volumes = docker_get("/volumes").get("Volumes") or []
    return images, containers, volumes


def protected_sets(containers, volumes):
    return {"containers": sorted(c["Id"] for c in containers),
            "running": sorted(c["Id"] for c in containers if c["State"] == "running"),
            "referenced_images": sorted({c["ImageID"] for c in containers}),
            "volumes": sorted(v["Name"] for v in volumes)}


def image_candidates(images, containers, now, keep_ids=()):
    cutoff = now - 14 * 86400
    referenced = {c["ImageID"] for c in containers}
    if any(not isinstance(i, str) or ID_PATTERN.fullmatch(i) is None for i in keep_ids):
        raise ValueError("Malformed explicit image hold; refusing to normalize it")
    keep = set(keep_ids)
    candidates = []
    for image in images:
        image_id = image["Id"]
        if ID_PATTERN.fullmatch(image_id) is None:
            raise ValueError("Malformed image ID; refusing to normalize it")
        created = image.get("Created")
        if isinstance(created, float) and not math.isfinite(created):
            raise ValueError("Non-finite image Created timestamp")
        tags = image.get("RepoTags") or []
        tags = [t for t in tags if t != "<none>:<none>"]
        labels = image.get("Labels") or {}
        if image_id in referenced or image_id in keep:
            continue
        if isinstance(created, bool) or not isinstance(created, (int, float)) or created <= 0 or created >= cutoff:
            continue
        # No forced multi-repository deletion. Stable/release rollback holds.
        if len(tags) > 1 or labels.get("storage.retention") == "keep":
            continue
        if any(fnmatch.fnmatchcase(tag, pattern) for tag in tags for pattern in KEEP_TAGS):
            continue
        candidates.append(image_id)
    return sorted(set(candidates))


def docker_images(apply):
    if apply:
        return blocked_apply("images")
    before, containers, volumes = docker_snapshot()
    protected = protected_sets(containers, volumes)
    holds_file = Path.home() / ".config/storage-retention/keep-images.json"
    holds = json.loads(holds_file.read_text()) if holds_file.exists() else []
    if not isinstance(holds, list):
        raise ValueError("Image holds must be a JSON list of literal sha256 IDs")
    candidates = image_candidates(before, containers, time.time(), holds)
    return {"state": "preview", "candidate_ids": candidates,
            "before_ids": sorted(i["Id"] for i in before), "protected_before": protected,
            "observation": "point-in-time", "apply_supported": False,
            "no_container_or_volume_removal": True, "no_forced_image_removal": True}


def cache_command():
    return DOCKER + ["buildx", "prune", "--builder", "default", "--force",
                    "--filter", "until=336h", "--max-used-space", "100000000000",
                    "--reserved-space", "20000000000"]


def cache_snapshot():
    raw = docker_get("/system/df")
    return [{k: r.get(k) for k in ("ID", "InUse", "Shared", "Size", "CreatedAt", "LastUsedAt")}
            for r in raw.get("BuildCache") or []]


def docker_cache(apply):
    if apply:
        return blocked_apply("build-cache")
    _, containers, volumes = docker_snapshot()
    protected = protected_sets(containers, volumes)
    before = cache_snapshot()
    command = cache_command()
    return {"state": "preview", "command": command, "before": before,
            "protected_before": protected, "observation": "point-in-time",
            "apply_supported": False}


def uv_command(cache, executable):
    return [executable, "cache", "prune", "--cache-dir", cache,
            "--no-config", "--offline", "--no-python-downloads", "--no-progress"]


def uv_outcome(returncode, output):
    if returncode == 0:
        return "completed", 0
    if returncode < 0:
        return "failed", 128 - returncode
    # uv 0.11.21 exits 2 for this terminal cache-lock acquisition timeout.
    # A wait notice can precede successful acquisition and a real prune error;
    # accept only the complete verified diagnostic, never arbitrary extra output.
    notice = re.escape("Cache is currently in-use, waiting for other uv processes to finish (use `--force` to override)")
    terminal = (r"error: Timeout \(5s\) when waiting for lock on `[^`\r\n]+` at `[^`\r\n]+`, "
                r"is another uv process running\? You can set `UV_LOCK_TIMEOUT` to increase the timeout\.")
    if returncode == 2 and re.fullmatch(rf"(?:{notice}\n)?{terminal}\n?", output):
        return "deferred-busy", 75
    return "failed", returncode


def uv_prune(apply):
    executable = str(Path.home() / ".local/state/nix/profiles/home-manager/home-path/bin/uv")
    cache = str(Path.home() / ".cache/uv")
    command = uv_command(cache, executable)
    if not apply:
        return {"state": "preview", "command": command}, 0
    env = os.environ.copy()
    env["UV_LOCK_TIMEOUT"] = "5"
    operation = run(command, timeout=1800, env=env)
    output = operation.stdout + operation.stderr
    state, code = uv_outcome(operation.returncode, output)
    result = {"state": state, "command": command, "returncode": operation.returncode,
              "output": output, "diagnostics": {"stdout": operation.stdout, "stderr": operation.stderr},
              "lock_timeout_seconds": 5, "force_used": False}
    if state == "failed":
        result["error"] = {"type": "NativeCommandError", "message": "UV cache prune failed"}
    return result, code


def failure_result(error, phase):
    def text(value):
        return value.decode("utf-8", errors="replace") if isinstance(value, bytes) else value or ""
    timed_out = isinstance(error, subprocess.TimeoutExpired)
    diagnostics = {}
    if isinstance(error, (subprocess.CalledProcessError, subprocess.TimeoutExpired)):
        diagnostics = {"command": error.cmd, "stdout": text(error.output), "stderr": text(error.stderr)}
        if timed_out:
            diagnostics["timeout_seconds"] = error.timeout
        else:
            diagnostics["returncode"] = error.returncode
    return {"state": "failed", "phase": phase, "exit_code": 124 if timed_out else 1,
            "error": {"type": type(error).__name__, "message": str(error)},
            "diagnostics": diagnostics, "timed_out": timed_out,
            "mutation_status": "not-started", "reclaim_verified": False}


def receipt(operation, result):
    directory = Path.home() / ".local/state/storage-retention"
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    target = directory / (operation + ".latest.json")
    result["observed_at"] = datetime.datetime.now().astimezone().isoformat()
    # Busy/blocked invocations may also publish receipts; use exclusive unique
    # temporary files rather than racing on a shared .partial.json pathname.
    with tempfile.NamedTemporaryFile(mode="w", prefix=operation + ".", suffix=".partial.json",
                                     dir=directory, delete=False) as file:
        temporary = Path(file.name)
        json.dump(result, file, indent=2)
        file.flush()
        os.fsync(file.fileno())
    os.replace(temporary, target)
    fd = os.open(directory, os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)
    return str(target)


def publish(operation, result, apply, code):
    result.update(operation=operation, apply=apply, exit_code=code)
    try:
        path = receipt(operation, result)
    except Exception as error:
        failure = failure_result(error, "receipt")
        failure.update(operation=operation, apply=apply,
                       mutation_status=result.get("mutation_status", "not-started"))
        print(json.dumps(failure), flush=True)
        return failure["exit_code"]
    summary = {"state": result["state"], "receipt": path, "exit_code": code}
    if "reason" in result:
        summary["reason"] = result["reason"]
    print(json.dumps(summary), flush=True)
    return code


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=("nix", "images", "build-cache", "uv"))
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    phase = "capability-check"
    uv_started = False
    try:
        if args.apply and args.operation in BLOCKED_APPLY:
            result = blocked_apply(args.operation)
            return publish(args.operation, result, args.apply, result["exit_code"])
        if args.apply and socket.gethostname().split(".")[0] != "computebox":
            result = {"state": "blocked", "phase": "host-check", "mutation_status": "not-started",
                      "reason": "Live UV retention is restricted to computebox"}
            return publish(args.operation, result, args.apply, 2)
        phase = "maintenance-lock"
        directory = Path.home() / ".local/state/storage-retention"
        directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        with (directory / "maintenance.lock").open("a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                result = {"state": "deferred-busy", "phase": phase, "mutation_status": "not-started",
                          "reason": "another retention operation"}
                return publish(args.operation, result, args.apply, 75)
            action_phase = "uv-prune" if args.operation == "uv" and args.apply else args.operation + "-preview"
            phase = "receipt"
            receipt(args.operation, {"state": "in-progress", "phase": action_phase, "operation": args.operation,
                                     "apply": args.apply, "exit_code": None, "reclaim_verified": False,
                                     "mutation_status": "unknown-partial-possible" if args.operation == "uv" and args.apply else "not-started"})
            phase = action_phase
            try:
                if args.operation == "uv":
                    uv_started = args.apply
                    result, code = uv_prune(args.apply)
                else:
                    functions = {"nix": nix_profiles, "images": docker_images, "build-cache": docker_cache}
                    result = functions[args.operation](args.apply)
                    code = result.get("exit_code", 0)
            except Exception as error:
                result = failure_result(error, phase)
                code = result["exit_code"]
            result.setdefault("phase", phase)
            result["mutation_status"] = ("manager-reported-completed" if result["state"] == "completed"
                                         else "unknown-partial-possible") if uv_started else "not-started"
            result["reclaim_verified"] = False
            return publish(args.operation, result, args.apply, code)
    except Exception as error:
        result = failure_result(error, phase)
        if uv_started:
            result["mutation_status"] = "unknown-partial-possible"
        return publish(args.operation, result, args.apply, result["exit_code"])


if __name__ == "__main__":
    raise SystemExit(main())
