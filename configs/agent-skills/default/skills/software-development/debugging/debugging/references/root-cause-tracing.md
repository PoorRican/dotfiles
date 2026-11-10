# Root-cause tracing

Scope: techniques for locating the origin of a failure and distinguishing condition waits from timing guesses.

## Original triggers and component boundaries


- When an error appears deep in a call chain, which value or state reached the failing operation? Tracing its callers can reveal that the first failing operation only exposed an earlier bad input or assumption. (src: systematic-debugging; 2026-06-22)

- In a multi-component failure, where is the first boundary whose outgoing value, configuration, or state differs from the next component's incoming view? Comparing both sides localizes the divergence before a component is blamed. (src: systematic-debugging; 2026-06-22)
- When several fixes fail, do the new observations undermine the causal explanation or show a different boundary failing? Repeated failures are a prompt to reassess the hypothesis or architecture when evidence warrants it, not a universal cutoff or proof of architectural fault. (src: systematic-debugging; 2026-06-22)
- A bounded auto-fix loop's attempt count sets an operational handoff point, not an architectural diagnosis. Do failed changes suggest a revised causal hypothesis? Repeated failure is a prompt to reassess, not an automatic architecture verdict. (src: github-pr-workflow; systematic-debugging; 2026-06-22)





## Condition-based versus time-based waits


- For asynchronous behavior, what observable condition means the operation under test is complete? Waiting for that condition is less sensitive to machine load than an arbitrary sleep. (src: systematic-debugging; 2026-06-22)
- Is elapsed time itself the behavior being tested, or is there a known interval in the system contract? A fixed delay is informative only when tied to known timing behavior; otherwise it can hide races or make tests flaky. (src: systematic-debugging; 2026-06-22)


## Exceptions across process boundaries

- Python worker exceptions whose diagnostic state holds a `types.MappingProxyType` fail to pickle (`TypeError: cannot pickle 'mappingproxy' object`) and can replace the domain error with a `TypeError` in the parent. Define `__reduce__` carrying a detached `dict` plus the exact type, message, and category, and test the real process-pool failure path for every public error subclass rather than only raising in-process. (src: pickle-boundary-exceptions, 2026-11-08)

## Attributing failures at an HTTP boundary

- Keep transport failures, HTTP-status failures, and parse failures as distinct error kinds, each carrying the URL, content type, and a short body snippet, and parse JSON only after confirming a 2xx. A 403 XML body then surfaces as an availability problem instead of a misleading deserialization error; a unit test with a 403 XML response keeps it that way. (src: http-feed-failure-attribution)
- Capture raw first and parse second: keep the raw response (URL, status, fetch time, content type, body) and quarantine raw bodies on non-2xx responses and parse failures, so schema drift can be investigated and replayed without the live feed. (src: http-feed-failure-attribution)

## NumPy scalar identity traps

- Tallying NumPy-derived flags with `sum(x is True for x in values)` silently counts 0 when the values are `np.True_`, because `np.True_ is True` is false. Convert with `bool(value)` and guard explicitly with `value is not None` first, so a missing flag is not counted as false. (src: numpy-bool-identity-tally, 2026-11-10)
