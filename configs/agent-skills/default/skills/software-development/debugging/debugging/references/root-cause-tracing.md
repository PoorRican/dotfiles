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

