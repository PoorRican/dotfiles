# Live API assumption validation

Scope: confirming what an external API actually returns before building tooling, fixtures, or architecture on a design document's claims.

## Probe before building

- List every endpoint, query parameter, and returned field the design claims, then probe the live API with tiny requests. Per endpoint check that filters work, that the response shape matches, that the status values in requests equal the status values on returned objects, and that `limit` and cursors are honored (do not assume `limit` is). Mark each assumption confirmed, brittle, or wrong. (src: live-api-assumption-validation; 2026-04)

## Turn the result into artifacts

- When the validated API feeds a library, capture raw payloads as grouped fixtures with a manifest (source URLs, shared identifiers, capture date) and write fixture contract tests before typed models. (src: live-api-assumption-validation; 2026-04)
- Let the live evidence re-center the design on the authoritative source and demote workarounds to fallbacks; keep superseded design documents as short pointers. (src: live-api-assumption-validation; 2026-04)
- Behavior observed on one date is a dated observation about that vendor; record the capture date and recheck before relying on it.
