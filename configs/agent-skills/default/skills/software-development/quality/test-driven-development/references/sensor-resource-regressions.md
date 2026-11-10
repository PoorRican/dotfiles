# Sensor Resource-Resolution Regressions

**Load this reference when:** testing resource injection in factory-built Dagster sensors without touching live systems.

## Exercise the Tick Path

- Read the repository instructions and inspect the installed Dagster version and its invocation and resource-resolution paths before changing the sensor. Direct invocation and tick evaluation may supply resources differently; a direct call alone may miss a tick-path regression. In Dagster 1.13.26, direct invocation supplies required resource keys as keyword arguments, while tick evaluation supplies resource-annotated parameters; unannotated `**kwargs` can therefore be empty.
- Reproduce the failure through `sensor.evaluate_tick(dg.build_sensor_context(resources={resource_key: dg.ResourceDefinition.hardcoded_resource(fake)}))`. Use a local test instance and fake external clients rather than live state or storage.
- Parameterize actual sensor registrations with independently specified keys. Assert the relevant defaults, interval, job, run configuration, cursor and skip behavior, and that evaluation creates no stored runs.
- For dynamically named resources, use `getattr(context.resources, resource_key)`. Retain an ignored `**_resources` parameter if direct calls must accept resource keywords; exercise both invocation paths against the installed version.

## Verify and Report

- After observing the expected regression failure, run a bounded targeted test followed by the complete affected sensor test file, serially when concurrent tests could interfere.
- Protect concurrent checkouts; use an isolated worktree when needed. When borrowing an environment, verify the imported source path and use a compatible or separate environment rather than mutating a shared one.
- Report the exact worktree and base revision, changed files, patch artifact and observed test counts. Distinguish local verification from deployment or runtime adoption.
