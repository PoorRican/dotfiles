---
name: code-review
description: Use when reviewing code changes or pull requests for consequential defects and security risks.
---

# Code review

Review changes for correctness, security, error handling and test coverage in the context of the actual behavior and trust boundaries. A checklist or passing tests alone cannot establish that a change is safe.

Prioritize actionable findings with evidence and impact. Check that failures propagate or are handled at the appropriate boundary and that resources are released; neither local exception handlers nor a particular cleanup construct are universally required.

Check security at the relevant trust boundaries: exposed credentials, validation of user input and file paths, parameterized SQL, and authentication and authorization where needed. Check that logs and user-facing errors do not disclose sensitive data or internals.

Exercise review judgment on empty inputs, nulls and boundaries, and on both successful and error paths; consider whether tests cover the changed behavior. Explain why each issue matters and suggest a fix where useful. Separate must-fix issues from suggestions and questions.
