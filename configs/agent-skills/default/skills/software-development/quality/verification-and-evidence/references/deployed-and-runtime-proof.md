# Deployed and runtime proof

## Promotion and provenance

- Source complete, merged, deployed, and live exercised are different states. A tag or mounted checkout does not establish the running image digest or imported module. Identify the artifact actually loaded and exercise the claimed behavior, including relevant negative cases.
- Runtime code overlays are not covered by an image build-input digest. Compare the actual shipped archives and recorded hashes, including member sets and non-code inputs; equivalent source ASTs alone do not establish equivalent data or import side effects.
- A hand-built image can be the only surviving copy of uncommitted behavior. Applying older declarative manifests can silently roll it back. Compare the running digest and embedded build identity with candidate source; where builds are reproducible, compare rebuilt binary bytes and sidecar contents before asserting provenance.
- After an authorized rollout, verify the running image identity and safety-relevant configuration, not just the desired manifest. A negative control that installs a bad artifact must not leave the canonical path in a bad state.

## Runtime boundaries

- A mounted executable can fail because its shebang interpreter is absent; a shell on the host does not prove that the target image contains that shell or required applets. Exercise the actual image, script, failure case, and scheduled architectures.
- A desired configuration or populated current store is not proof of durable behavior after recreation. Exercise the event relevant to the claim and read the resulting state independently.
- Dashboard JSON cannot exercise browser interpolation, frontend transforms, empty states, or resolved links. Check the rendered failure and empty states and follow the links in the deployed versions.
- A stale last-known-good file or cached log buffer can make a dead process appear healthy. Compare freshness and process identity against the system of record.
- A Deployment safety or readiness gate must follow the Pod → ReplicaSet → Deployment controller ownerReference chain by name and UID, not assume a direct Pod → Deployment link. Capture the chain before and after; fixtures can repeat the same mistaken ownership assumption.

## External API assumptions

- Before building on a design's API claims, use small permitted requests to check response shape, filters, status values, limits, and cursor behavior. A successful response does not establish complete historical coverage.
- Preserve raw responses separately from selected fixtures, with request identity, status, retrieval time and digest. A reserialized object is not the original wire body; recheck observed behavior when relying on it later.
