---
name: debugging
description: "Use for root-causing bugs, test failures, and unexpected behavior; tracing values and failures through call chains and component boundaries; choosing Python debuggers such as pdb and debugpy; and diagnosing Linux authentication, device, memory-pressure, Btrfs, and block-device problems."
---

# Debugging

A common mistake is to patch the first visible failure before finding where the bad value or state entered the system. The references collect tracing and asynchronous-waiting insights, Python debugger selection and failure modes, and durable Linux host behavior without prescribing a universal debugging sequence.

| When you are… | Open |
|---|---|
| tracing a failure through callers, comparing component boundaries, or reasoning about asynchronous waits | [references/root-cause-tracing.md](references/root-cause-tracing.md) |
| choosing a Python debugger or diagnosing a breakpoint that does not stop where expected | [references/python-debuggers.md](references/python-debuggers.md) |
| investigating PAM lockouts, Linux devices or memory pressure, Btrfs, or a busy block device with no visible host mount | [references/linux-host.md](references/linux-host.md) |
