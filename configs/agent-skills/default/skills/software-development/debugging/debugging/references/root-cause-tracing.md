# Root-cause tracing

Compare the values, configuration and state on both sides of a component boundary to locate the first divergence. When repeated fixes fail, reconsider the causal hypothesis rather than treating an attempt limit as proof of an architectural problem.

For asynchronous tests, wait for the observable completion condition instead of an arbitrary sleep; a fixed delay is appropriate when elapsed time itself is the contract.

## Boundary failures

- An exception crossing a Python process boundary must be serializable: diagnostic state containing `MappingProxyType` can replace the original exception with a pickling error in the parent. Make the exception reconstructible with detached serializable state and test the actual process-pool failure path.
- Distinguish transport, HTTP status and response parsing failures. Inspect status and content type when interpreting a response; an error response may contain useful JSON or a non-JSON body. Retain diagnostic response data only as appropriate for its sensitivity and retention policy.
- `np.True_ is True` is false: identity tests can silently undercount NumPy boolean flags. Convert non-missing values with `bool`, keeping missing values distinct.

## Python breakpoints

- `debugpy.listen()` does not pause execution; wait for the client when attachment must precede a breakpoint.
- Interactive pdb is unavailable inside pytest-xdist workers; run the test without xdist for an interactive prompt.
- `PYTHONBREAKPOINT=0` disables `breakpoint()`, so a missed stop need not indicate unreachable code. Breakpoints can also hang non-interactive runs.
- A debugger attached to one process does not automatically cover every child process; inspect attachment and breakpoint placement across process boundaries.

`pdb` debugs the current thread; a child process needs its own hook or attachment. `debugpy` is thread-aware.

## Async pollers

- A scheduler loop that does not yield can enqueue initial work and then busy-spin, starving its own coroutines. High loop-thread CPU and repeated in-flight skip messages can masquerade as request contention.
- Discovery bursts can crowd out periodic polls under a shared admission limit. Bound outstanding work and reserve capacity when core polling needs priority.
- When cadence changes, re-arm existing targets as needed; otherwise old due times can silently preserve the prior cadence. Exercise realistic follow-up volume and inspect rolling request windows and per-target gaps.

## Native output and strict stdout

`contextlib.redirect_stdout` replaces Python's `sys.stdout`, not file descriptor 1; native writes can still corrupt a JSON-over-stdout protocol. If native output cannot be disabled, preserve a separate protocol descriptor and redirect fd 1 to stderr around the native call, restoring it in `finally`. Descriptor changes affect the process, so account for concurrent writers; test with actual native writes. Library progress settings may be connection-local and must be applied to each relevant connection.
