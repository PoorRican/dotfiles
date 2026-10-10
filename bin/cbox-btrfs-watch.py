#!/usr/bin/env python3
"""One-shot, alert-only Btrfs pressure monitor (Python stdlib, no root needed).

Only filesystem queries are findmnt --json and btrfs filesystem usage -b;
all sysfs access is read-only. No cleanup, balance, snapshot, or repair paths.

CLI: --uuid and --state-dir required; --mount /; --btrfs btrfs;
--findmnt findmnt; --notify-send notify-send; --sysfs-root /sys/fs/btrfs.
--no-notify still publishes a sample. --print-only never creates/writes state,
locks, or notifications, including on failure; it may read existing history.

One JSON object goes to stdout (schema_version=1). ok means this execution
completed, NOT that pressure is healthy. Exit 0 for any completed severity,
1 on query/state/notification failure. Errors also go to stderr for journals.
Notification IDs report desktop-server acceptance, not proof of user visibility.

state.json version 1: uuid; current (full measurement plus severity/reasons);
history (timestamp/metadata_used_bytes only); last_alert (null or timestamp,
severity, notification_id); alert_pending (boolean retry intent, cleared only
after accepted notification or healthy recovery). Keep <=2016 points and <=7 days. State is measured
information, not an authoritative success receipt: use stdout and exit status.
Atomic replacement + file/directory fsync are attempted; failure after replace
cannot be rolled back and is reported as failure, not a durability promise.
"""
import argparse
from contextlib import AbstractContextManager
import fcntl
import json
import math
import os
from pathlib import Path
import re
import secrets
import stat
import subprocess
import sys
import time

GIB = 1024 ** 3
MAX_BYTES = 1024 * 1024
MAX_POINTS = 2016
MAX_AGE = 7 * 86400
COMMAND_TIMEOUT = 15
UINT64_MAX = 2 ** 64 - 1
UUID_PATTERN = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
COUNTERS = ("total_bytes", "bytes_used", "bytes_reserved", "bytes_may_use",
            "bytes_pinned", "bytes_readonly", "bytes_zone_unusable", "disk_total")
ERRORS = ("write_errs", "read_errs", "flush_errs", "corruption_errs", "generation_errs")
REASONS = {
    "metadata_usage_warning", "metadata_usage_critical", "metadata_margin_warning",
    "metadata_margin_critical", "device_unallocated_warning", "device_unallocated_critical",
    "metadata_growth_warning", "read_only_mount", "recorded_device_errors",
}
PRESSURE_NOTE = ("Effective metadata margin is a pressure indicator, not guaranteed writable bytes; "
                 "sysfs counters are a non-atomic live sample. Recorded device errors are not a scrub result.")


class MonitorError(Exception):
    pass


def require(condition, message):
    if not condition:
        raise MonitorError(message)


def unsigned(value, label):
    require(type(value) is int and 0 <= value <= UINT64_MAX, f"invalid unsigned counter: {label}")
    return value


def number(value, label, *, timestamp=False):
    require(type(value) in (int, float), f"invalid number: {label}")
    try:
        finite = math.isfinite(value)
    except OverflowError:
        finite = False
    require(finite, f"nonfinite number: {label}")
    if timestamp:
        require(0 < value < 10 ** 12, f"invalid timestamp: {label}")
    return value


def decimal(text, label):
    require(re.fullmatch(r"[0-9]{1,20}", text) is not None, f"invalid counter: {label}")
    return unsigned(int(text), label)


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f"duplicate JSON key: {key}")
        result[key] = value
    return result


def decode_json(text, label):
    try:
        return json.loads(text, object_pairs_hook=unique_object)
    except (ValueError, RecursionError, MonitorError) as exc:
        raise MonitorError(f"invalid {label} JSON: {exc}") from exc


def command(argv):
    """Fixed argument arrays only; finite timeout and locale-stable parsing."""
    try:
        proc = subprocess.run(argv, capture_output=True, text=True, encoding="utf-8",
                              errors="strict", timeout=COMMAND_TIMEOUT, check=False,
                              env=dict(os.environ, LC_ALL="C"))
    except subprocess.TimeoutExpired as exc:
        raise MonitorError(f"{Path(argv[0]).name} timed out after {COMMAND_TIMEOUT}s") from exc
    except (OSError, UnicodeError) as exc:
        raise MonitorError(f"{Path(argv[0]).name} query failed: {exc}") from exc
    require(len(proc.stdout) <= MAX_BYTES and len(proc.stderr) <= MAX_BYTES,
            f"{Path(argv[0]).name} output exceeds limit")
    require(proc.returncode == 0,
            f"{Path(argv[0]).name} failed (exit {proc.returncode}): {proc.stderr.strip()[:4096]}")
    return proc.stdout, proc.stderr.strip()


def small_read(path):
    try:
        with path.open("r", encoding="ascii") as stream:
            text = stream.read(4097)
    except (OSError, UnicodeError) as exc:
        raise MonitorError(f"cannot read {path}: {exc}") from exc
    require(len(text) <= 4096, f"oversized sysfs signal: {path}")
    return text.strip()


def metadata_values(root):
    values: dict[str, int | float] = {name: decimal(small_read(root / name), str(root / name)) for name in COUNTERS}
    require(values["total_bytes"] > 0 and values["disk_total"] > 0, "metadata allocation total is zero")
    values["effective_margin_bytes"] = max(0, values["total_bytes"] - sum(values[k] for k in COUNTERS[1:-1]))
    values["used_percent"] = values["bytes_used"] * 100 / values["total_bytes"]
    return values


def device_errors(root):
    try:
        devices = sorted(root.iterdir(), key=lambda path: path.name)
    except OSError as exc:
        raise MonitorError(f"cannot read devinfo {root}: {exc}") from exc
    require(0 < len(devices) <= 1024, f"missing or oversized devinfo: {root}")
    result = {}
    for device in devices:
        require(re.fullmatch(r"[1-9][0-9]*", device.name) is not None and device.is_dir(),
                f"invalid devinfo entry: {device}")
        path = device / "error_stats"
        values = {}
        for line in small_read(path).splitlines():
            fields = line.split()
            require(len(fields) == 2 and fields[0] in ERRORS and fields[0] not in values,
                    f"invalid or duplicate error_stats line: {path}")
            values[fields[0]] = decimal(fields[1], str(path))
        require(set(values) == set(ERRORS), f"incomplete error_stats: {path}")
        result[device.name] = values
    return result


def collect(args, history):
    text, findmnt_stderr = command([args.findmnt, "--json", "--target", args.mount,
                                  "--output", "TARGET,FSTYPE,UUID,OPTIONS"])
    data = decode_json(text, "findmnt")
    require(isinstance(data, dict), "invalid findmnt mount object")
    filesystems = data.get("filesystems")
    require(isinstance(filesystems, list) and len(filesystems) == 1 and isinstance(filesystems[0], dict),
            "findmnt must return exactly one filesystem")
    mount = filesystems[0]
    require(mount.get("fstype") == "btrfs", "findmnt target is not Btrfs")
    require(mount.get("uuid") == args.uuid, "findmnt filesystem UUID does not match required UUID")
    require(isinstance(mount.get("target"), str) and mount["target"].startswith("/"),
            "findmnt target is missing or invalid")
    options = mount.get("options")
    require(isinstance(options, str), "findmnt mount options missing")
    flags = options.split(",")
    require(("ro" in flags) != ("rw" in flags), "findmnt mount options must identify ro or rw")
    text, btrfs_stderr = command([args.btrfs, "filesystem", "usage", "-b", args.mount])
    usage = {}
    for label, key in (("Device size", "device_size_bytes"), ("Device unallocated", "device_unallocated_bytes")):
        matches = re.findall(r"^\s*" + re.escape(label) + r":[^\S\n]*(.*?)\s*$", text, re.MULTILINE)
        require(len(matches) == 1, f"btrfs usage missing or duplicate {label}")
        usage[key] = decimal(matches[0], label)
    require(usage["device_size_bytes"] > 0 and usage["device_unallocated_bytes"] <= usage["device_size_bytes"],
            "invalid btrfs device size/unallocated values")
    root = Path(args.sysfs_root) / args.uuid
    metadata = metadata_values(root / "allocation" / "metadata")
    errors = device_errors(root / "devinfo")
    now = number(time.time(), "sample time", timestamp=True)
    require(not history or history[-1]["timestamp"] <= now, "state history is in the future (clock moved backwards)")
    window = [p for p in history if 2700 <= now - p["timestamp"] <= 4500]
    growth = None
    if window:
        oldest = min(window, key=lambda p: p["timestamp"])
        span = now - oldest["timestamp"]
        growth = {"span_seconds": span,
                  "bytes_per_hour": (metadata["bytes_used"] - oldest["metadata_used_bytes"]) * 3600 / span}
    return {"timestamp": now, "mount": {"target": mount["target"], "fstype": "btrfs", "uuid": args.uuid,
                                        "options": options, "readonly": "ro" in flags},
            **usage, "metadata": metadata, "device_errors": errors, "growth": growth,
            "pressure_note": PRESSURE_NOTE,
            "query_warnings": [s[:4096] for s in (findmnt_stderr, btrfs_stderr) if s]}


def classify(measurement):
    meta = measurement["metadata"]
    reasons = []
    if meta["bytes_used"] * 100 >= meta["total_bytes"] * 95:
        reasons.append("metadata_usage_critical")
    elif meta["bytes_used"] * 100 >= meta["total_bytes"] * 85:
        reasons.append("metadata_usage_warning")
    for value, warn, critical, prefix in (
        (meta["effective_margin_bytes"], 20 * GIB, 5 * GIB, "metadata_margin"),
        (measurement["device_unallocated_bytes"], 50 * GIB, 10 * GIB, "device_unallocated"),
    ):
        if value <= critical:
            reasons.append(prefix + "_critical")
        elif value <= warn:
            reasons.append(prefix + "_warning")
    growth = measurement["growth"]
    if growth is not None and growth["bytes_per_hour"] >= GIB:
        reasons.append("metadata_growth_warning")
    if measurement["mount"]["readonly"]:
        reasons.append("read_only_mount")
    if any(any(counts.values()) for counts in measurement["device_errors"].values()):
        reasons.append("recorded_device_errors")
    critical = any(r.endswith("_critical") or r in ("read_only_mount", "recorded_device_errors") for r in reasons)
    return ("critical" if critical else "warning" if reasons else "healthy"), reasons


def validate_state(state, uuid, now):
    """Reject, never reset, malformed existing state, including nonfinite data."""
    def check(condition, message):
        require(condition, "invalid state: " + message)

    def timestamp(value):
        value = number(value, "state timestamp", timestamp=True)
        check(value <= now, "future timestamp (clock moved backwards)")
        return value

    def finite_tree(value):
        if isinstance(value, dict):
            for child in value.values():
                finite_tree(child)
        elif isinstance(value, list):
            for child in value:
                finite_tree(child)
        elif type(value) in (int, float):
            number(value, "state number")

    check(isinstance(state, dict) and set(state) == {"version", "uuid", "current", "history", "last_alert", "alert_pending"},
          "schema keys")
    check(type(state["version"]) is int and state["version"] == 1, "unsupported version")
    check(state["uuid"] == uuid, "UUID mismatch")
    check(type(state["alert_pending"]) is bool, "alert_pending is not boolean")
    finite_tree(state)
    history = state["history"]
    check(isinstance(history, list) and 0 < len(history) <= MAX_POINTS, "history size")
    previous = None
    for point in history:
        check(isinstance(point, dict) and set(point) == {"timestamp", "metadata_used_bytes"}, "history point")
        current = timestamp(point["timestamp"])
        unsigned(point["metadata_used_bytes"], "state history metadata_used_bytes")
        check(previous is None or current > previous, "history timestamps not strictly ordered")
        previous = current
    current = state["current"]
    expected = {"timestamp", "mount", "device_size_bytes", "device_unallocated_bytes", "metadata",
                "device_errors", "growth", "pressure_note", "query_warnings", "severity", "reasons"}
    check(isinstance(current, dict) and set(current) == expected, "current measurement keys")
    timestamp(current["timestamp"])
    check(current["timestamp"] == history[-1]["timestamp"], "current timestamp differs from latest history")
    meta = current["metadata"]
    check(isinstance(meta, dict) and set(meta) == set(COUNTERS) | {"used_percent", "effective_margin_bytes"},
          "metadata keys")
    for key in (*COUNTERS, "effective_margin_bytes"):
        unsigned(meta[key], "state metadata " + key)
    check(meta["total_bytes"] > 0 and meta["disk_total"] > 0, "zero metadata total")
    check(meta["bytes_used"] == history[-1]["metadata_used_bytes"], "current metadata differs from history")
    check(meta["effective_margin_bytes"] == max(0, meta["total_bytes"] - sum(meta[k] for k in COUNTERS[1:-1])),
          "inconsistent effective margin")
    check(type(meta["used_percent"]) in (int, float) and
          meta["used_percent"] == meta["bytes_used"] * 100 / meta["total_bytes"], "inconsistent used percent")
    size = unsigned(current["device_size_bytes"], "state device size")
    free = unsigned(current["device_unallocated_bytes"], "state device unallocated")
    check(size > 0 and free <= size, "device size/unallocated")
    mount = current["mount"]
    check(isinstance(mount, dict) and set(mount) == {"target", "fstype", "uuid", "options", "readonly"}, "mount keys")
    check(mount["fstype"] == "btrfs" and mount["uuid"] == uuid, "mount identity")
    check(isinstance(mount["target"], str) and mount["target"].startswith("/"), "mount target")
    check(type(mount["readonly"]) is bool and isinstance(mount["options"], str), "mount options")
    flags = mount["options"].split(",")
    check(("rw" in flags) != ("ro" in flags) and mount["readonly"] == ("ro" in flags), "mount readonly mismatch")
    errors = current["device_errors"]
    check(isinstance(errors, dict) and 0 < len(errors) <= 1024, "device_errors size")
    for devid, counts in errors.items():
        check(re.fullmatch(r"[1-9][0-9]*", devid) is not None and isinstance(counts, dict) and set(counts) == set(ERRORS),
              "device_errors keys")
        for value in counts.values():
            unsigned(value, "state device error")
    growth = current["growth"]
    if growth is not None:
        check(isinstance(growth, dict) and set(growth) == {"span_seconds", "bytes_per_hour"}, "growth keys")
        check(2700 <= number(growth["span_seconds"], "state growth span") <= 4500, "growth span")
        number(growth["bytes_per_hour"], "state growth rate")
    check(isinstance(current["pressure_note"], str), "pressure note")
    check(isinstance(current["query_warnings"], list) and
          all(isinstance(w, str) for w in current["query_warnings"]), "query warnings")
    check(isinstance(current["reasons"], list) and
          all(isinstance(r, str) and r in REASONS for r in current["reasons"]), "reason codes")
    check((current["severity"], current["reasons"]) == classify(current), "severity/reasons differ from measurement")
    check(not state["alert_pending"] or current["severity"] != "healthy", "healthy sample cannot have pending alert")
    alert = state["last_alert"]
    if alert is not None:
        check(isinstance(alert, dict) and set(alert) == {"severity", "timestamp", "notification_id"}, "last_alert keys")
        check(alert["severity"] in ("warning", "critical"), "last_alert severity")
        timestamp(alert["timestamp"])
        notification_id(alert["notification_id"])
    return state


def private(fd, directory=False):
    info = os.fstat(fd)
    valid_type = stat.S_ISDIR(info.st_mode) if directory else stat.S_ISREG(info.st_mode)
    require(valid_type and info.st_uid == os.geteuid() and not (info.st_mode & 0o077) and
            (directory or info.st_nlink == 1), "state must be private, owned, non-symlink regular files/directory")


class StateStore(AbstractContextManager):
    """One nonblocking advisory lock, held through sampling and notification."""
    def __init__(self, path, readonly):
        self.path = Path(path)
        self.readonly = readonly
        self.directory = None
        self.lock = None

    def __enter__(self):
        try:
            if not self.readonly:
                self.path.mkdir(mode=0o700, parents=True, exist_ok=True)
            try:
                self.directory = os.open(self.path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
            except FileNotFoundError:
                if self.readonly:
                    return self
                raise
            private(self.directory, directory=True)
            if not self.readonly:
                self.lock = os.open("lock", os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC,
                                    0o600, dir_fd=self.directory)
                private(self.lock)
                try:
                    fcntl.flock(self.lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                except BlockingIOError as exc:
                    raise MonitorError("state lock is held; sample was not completed") from exc
            return self
        except (OSError, MonitorError) as exc:
            self.__exit__(None, None, None)
            raise MonitorError(f"state open/lock failed: {exc}") from exc

    def __exit__(self, *args):
        if self.lock is not None:
            os.close(self.lock)
            self.lock = None
        if self.directory is not None:
            os.close(self.directory)
            self.directory = None
        return False

    def read(self, uuid, now):
        empty = {"version": 1, "uuid": uuid, "current": None, "history": [], "last_alert": None, "alert_pending": False}
        if self.directory is None:
            return empty
        try:
            try:
                fd = os.open("state.json", os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC,
                             dir_fd=self.directory)
            except FileNotFoundError:
                return empty
            with os.fdopen(fd, "rb") as stream:
                private(stream.fileno())
                require(os.fstat(stream.fileno()).st_size <= MAX_BYTES, "oversized state file")
                raw = stream.read(MAX_BYTES + 1)
            require(len(raw) <= MAX_BYTES, "oversized state file")
            return validate_state(decode_json(raw.decode("utf-8"), "state"), uuid, now)
        except (OSError, UnicodeError, MonitorError, RecursionError) as exc:
            raise MonitorError(f"state read/validation failed: {exc}") from exc

    def publish(self, state):
        if self.readonly or self.directory is None or self.lock is None:
            raise MonitorError("state publication attempted without exclusive lock")
        directory = self.directory
        raw = (json.dumps(state, allow_nan=False, separators=(",", ":")) + "\n").encode("utf-8")
        require(len(raw) <= MAX_BYTES, "state publication exceeds size limit")
        temporary = f".state-{os.getpid()}-{secrets.token_hex(8)}.json"
        created = False
        stage = "temporary file create"
        try:
            fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC,
                         0o600, dir_fd=directory)
            created = True
            with os.fdopen(fd, "wb") as stream:
                os.fchmod(stream.fileno(), 0o600)
                stage = "file write/flush/fsync"
                stream.write(raw)
                stream.flush()
                os.fsync(stream.fileno())
            stage = "atomic replace"
            os.replace(temporary, "state.json", src_dir_fd=directory, dst_dir_fd=directory)
            stage = "post-replacement directory fsync"
            os.fsync(directory)
        except OSError as exc:
            raise MonitorError(f"state publication {stage} failed: {exc}; state is not a success receipt") from exc
        finally:
            if created:
                try:
                    os.unlink(temporary, dir_fd=directory)
                except FileNotFoundError:
                    pass


def notification_id(text):
    require(isinstance(text, str) and re.fullmatch(r"[1-9][0-9]{0,9}", text) is not None and
            int(text) <= 2 ** 32 - 1, "notify-send returned invalid notification ID")
    return text


def notify(args, severity, title, body):
    text, _ = command([args.notify_send, "--print-id", "--app-name", "Btrfs Watch",
                       "--urgency", "critical" if severity == "critical" else "normal",
                       "--expire-time", "0", title, body])
    return {"status": "accepted", "id": notification_id(text.strip())}


def alert_due(severity, previous, now, previous_severity):
    ranks = {"healthy": 0, "warning": 1, "critical": 2}
    if ranks[severity] > ranks[previous_severity]:
        return True
    if previous is None:
        return True
    if severity == "critical" and previous["severity"] == "warning":
        return True
    cooldown = 3600 if severity == "critical" else 6 * 3600
    return now - previous["timestamp"] >= cooldown


def alert_body(measurement, reasons):
    meta = measurement["metadata"]
    body = (f"Metadata used {meta['used_percent']:.2f}% ({meta['bytes_used'] / GIB:.2f} GiB logical); "
            f"effective margin {meta['effective_margin_bytes'] / GIB:.2f} GiB; "
            f"device-unallocated {measurement['device_unallocated_bytes'] / GIB:.2f} GiB. "
            f"Reasons: {', '.join(reasons)}. ")
    if measurement["growth"] is not None:
        growth = measurement["growth"]
        body += (f"Metadata growth {growth['bytes_per_hour'] / GIB:.2f} GiB/hour "
                 f"over {growth['span_seconds'] / 60:.1f} minutes. ")
    return body + PRESSURE_NOTE


class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise MonitorError("CLI argument error: " + message)


def parser():
    result = Parser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter,
                    allow_abbrev=False)
    result.add_argument("--uuid", required=True, help="exact canonical lowercase filesystem UUID")
    result.add_argument("--mount", default="/")
    result.add_argument("--state-dir", required=True, help="private monitor-only state directory")
    result.add_argument("--btrfs", default="btrfs")
    result.add_argument("--findmnt", default="findmnt")
    result.add_argument("--notify-send", default="notify-send")
    result.add_argument("--sysfs-root", default="/sys/fs/btrfs")
    result.add_argument("--no-notify", action="store_true")
    result.add_argument("--print-only", action="store_true")
    return result


def main(argv=None):
    status = {"schema_version": 1, "ok": False, "uuid": None, "mode": "sample",
              "severity": "critical", "reasons": [], "measurement": None, "history_points": 0,
              "state_published": False, "notification": {"status": "not-attempted", "id": None},
              "failure_notification": None, "monitor_failure": False, "error": None}
    args = None
    stage = "arguments"
    try:
        args = parser().parse_args(argv)
        status["uuid"] = args.uuid
        status["mode"] = "print-only" if args.print_only else "sample"
        require(UUID_PATTERN.fullmatch(args.uuid) is not None, "UUID must be literal canonical lowercase UUID")
        require(args.mount.startswith("/"), "mount must be an absolute path")
        require(Path(args.state_dir).is_absolute(), "state directory must be an absolute path")
        now = number(time.time(), "clock", timestamp=True)
        stage = "state"
        with StateStore(args.state_dir, args.print_only) as store:
            state = store.read(args.uuid, now)
            stage = "query"
            measurement = collect(args, state["history"])
            severity, reasons = classify(measurement)
            status.update(measurement=measurement, severity=severity, reasons=reasons)
            now = measurement["timestamp"]
            previous_severity = state["current"]["severity"] if state["current"] is not None else "healthy"
            due = severity != "healthy" and (state["alert_pending"] or
                                             alert_due(severity, state["last_alert"], now, previous_severity))
            state["alert_pending"] = due
            history = [p for p in state["history"] if now - MAX_AGE <= p["timestamp"] < now]
            history.append({"timestamp": now, "metadata_used_bytes": measurement["metadata"]["bytes_used"]})
            state["history"] = history[-MAX_POINTS:]
            state["current"] = dict(measurement, severity=severity, reasons=reasons)
            status["history_points"] = len(state["history"])
            if args.print_only:
                status["notification"] = {"status": "disabled", "id": None}
            else:
                stage = "state"
                store.publish(state)
                status["state_published"] = True
                if args.no_notify:
                    status["notification"] = {"status": "disabled", "id": None}
                elif severity == "healthy":
                    status["notification"] = {"status": "not-needed", "id": None}
                elif not due:
                    status["notification"] = {"status": "cooldown", "id": None}
                else:
                    stage = "notification"
                    status["notification"] = {"status": "failed", "id": None}
                    status["notification"] = notify(args, severity, f"Btrfs Watch {severity}", alert_body(measurement, reasons))
                    state["last_alert"] = {"timestamp": now, "severity": severity,
                                           "notification_id": status["notification"]["id"]}
                    state["alert_pending"] = False
                    stage = "state"
                    status["state_published"] = False
                    store.publish(state)
                    status["state_published"] = True
        status["ok"] = True
    except (MonitorError, OSError, ValueError, RecursionError) as exc:
        status.update(ok=False, severity="critical", reasons=["monitor_failure"],
                      monitor_failure=True, error=f"{stage}: {exc}")
        print("Btrfs Watch monitor failure: " + status["error"], file=sys.stderr)
        if args is not None and not args.print_only and not args.no_notify and stage in ("state", "query"):
            try:
                status["failure_notification"] = notify(args, "critical", "Btrfs Watch monitor failure",
                                                        "Monitor could not complete; filesystem condition is unknown. " + status["error"])
            except (MonitorError, OSError, ValueError) as alert_exc:
                status["failure_notification"] = {"status": "failed", "id": None, "error": str(alert_exc)}
                print("Btrfs Watch failure notification failed: " + str(alert_exc), file=sys.stderr)
    print(json.dumps(status, allow_nan=False, separators=(",", ":")))
    return 0 if status["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
