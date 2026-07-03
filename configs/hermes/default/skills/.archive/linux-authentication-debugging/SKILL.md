---
name: linux-authentication-debugging
description: "Archived after consolidation into linux-system-debugging. Debug Linux login/password failures, PAM stacks, and account lockouts before changing auth config."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    archived_into: linux-system-debugging
    tags: [linux, pam, authentication, faillock, lockout, debugging]
    related_skills: [systematic-debugging, linux-system-debugging]
---

# Linux Authentication Debugging — Archived

This skill package was consolidated into `linux-system-debugging` during the umbrella-building pass. The class-level instructions now live under the authentication/PAM/faillock section of that umbrella skill.

Preserved package references:

- `references/screen-locker-shared-faillock-case.md`
- `references/i3-lockscreen-replacement-faillock.md`

## Original scope

Use when a Linux user reports known-password rejection, lockout earlier than expected, or differing auth behavior across `sudo`, TTY login, SSH, display manager, or screen unlock. Gather non-sudo evidence (`id`, `whoami`, `loginctl`, account state, `faillock --user`) before changing PAM. Correlate journal lines for `faillock`, PAM services, `i3lock`, display managers, TTY logins, and SSH. Avoid blind sudo probes because failed sudo can consume another shared `pam_faillock` failure.

Core durable lesson: `pam_faillock` tracks failures by user across participating PAM services, so a later prompt can appear to lock early because another service already added failures.
