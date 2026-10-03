# Capabilities and enforcement

Scope: distinguish what a schema, client, test, runtime guard, or capability actually prevents.

## Declared constraints and enforcement

- A schema declaration alone does not show that invalid input is rejected. Evidence is stronger when the same violating input is examined at construction, explicit runtime boundaries, and tests; the claim should name the weakest observed rejection layer and who can still bypass it. String foreign keys do not enforce topology, and a free discriminator can disagree with its subclass unless pinned or checked elsewhere. (src: classify-enforcement-layer, 2026-09-01)
- Does a check inspect the same object, identity, and population that the action authorizes? A count, row existence, metadata, or a run's own narrowed input scope can agree while a wider destructive selector targets incomplete or different data. (src: adjacent-verification-audit, 2026-07-27)

## Client behavior versus authority

- A client that sends an `If-Match`/`If-None-Match` header and sees expected success/precondition statuses demonstrates cooperative client behavior, not that a signed URL or other capability binds the header. If `X-Amz-SignedHeaders` contains only `host`, conditional headers are advisory to the URL holder. The same URL tested without its precondition distinguishes client behavior from capability authority; a tampered-signature rejection proves signature validation, not that a particular header is signed. (src: presigned-capability-precondition-audit, 2026-09-07)
- Which parts of a presigned URL are bound—method, key/URI, expiry, and headers—and what can a holder still change? Capability scope and preconditions are separate facts; an omitted-header negative control on the same URL distinguishes whether that condition is bound. (src: presigned-capability-precondition-audit, 2026-09-07)
- An independent reference derivation using fixed credentials and a fixed clock is stronger evidence than a self-generated expected signature, which can repeat the implementation's canonicalization error. Acceptance alone does not prove scope or expiry binding. (src: signing-client-live-validation, 2026-08-19)
- An injectable clock makes expiry behavior testable, and an injected transport can exercise a real verifier. Rejected tampered-signature and expired-URL cases provide distinct negative evidence; unexpected 403/500 responses are not evidence of absence. (src: signing-client-live-validation, 2026-08-19)
- A successful read is weaker than a byte-for-byte body comparison with expected content. Authorization failures are not benign absence. (src: signing-client-live-validation, 2026-08-19; presigned-capability-precondition-audit, 2026-09-07)

## Test boundaries

- A status-only assertion can miss a durable journal, event, or database write; persisted-state evidence matters when persistence is part of the claim. (src: false-green-verification-traps, 2026-08-12)
- A test that fails first for the expected missing behavior shows that it can detect it; a test that passes immediately has not established that. Mocks can erase relevant side effects, so evidence is stronger when isolation occurs at the lowest boundary that removes only slow or external behavior. A real-component integration test can be clearer when complex mocks obscure the behavior. (src: test-driven-development, 2026-06-22)
- Test-only lifecycle helpers usually fit better in test utilities than production classes. (src: test-driven-development, 2026-06-22)
