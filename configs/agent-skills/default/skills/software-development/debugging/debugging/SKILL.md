---
name: debugging
description: "Use for root-causing bugs, test failures, and unexpected behavior; tracing values and failures through call chains and component boundaries; choosing Python debuggers such as pdb and debugpy; and diagnosing Linux authentication, device, memory-pressure, Btrfs, and block-device problems. Also covers async pollers, native output on strict stdout, exceptions across process boundaries, HTTP-feed failure attribution, GPU driver mismatch, and pausing supervised processes."
---

# Debugging

A common mistake is to patch the first visible failure before finding where the bad value or state entered the system. The references collect tracing and asynchronous-waiting insights, Python debugger selection and failure modes, and durable Linux host behavior without prescribing a universal debugging sequence.

| When you are… | Open |
|---|---|
| tracing a failure through callers, comparing component boundaries, or reasoning about asynchronous waits | [references/root-cause-tracing.md](references/root-cause-tracing.md) |
| choosing a Python debugger or diagnosing a breakpoint that does not stop where expected | [references/python-debuggers.md](references/python-debuggers.md) |
| investigating PAM lockouts, Linux devices or memory pressure, Btrfs, or a busy block device with no visible host mount | [references/linux-host.md](references/linux-host.md) |
| a rate-limited asyncio poller or recorder that starves, busy-spins, or misses cadence changes | [references/async-schedulers-and-pollers.md](references/async-schedulers-and-pollers.md) |
| a strict stdout protocol (JSON RPC, parsed CLI output) corrupted by a native library's output | [references/native-output-streams.md](references/native-output-streams.md) |
| exceptions that cross process boundaries, or telling transport, HTTP-status, and parse failures apart at an HTTP feed | [references/root-cause-tracing.md](references/root-cause-tracing.md) |
| a GPU driver/module mismatch, pausing a supervised process safely, or a file watcher that misses a hard-link publish | [references/linux-host.md](references/linux-host.md) |
