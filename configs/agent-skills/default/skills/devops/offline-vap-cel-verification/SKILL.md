---
name: offline-vap-cel-verification
description: "Verify or safely change a Kubernetes ValidatingAdmissionPolicy (CEL) offline when the live admission gate is unavailable — golden-pin exact expressions, generate fixtures from the real renderer, run an independent intent-evaluator, and get an independent review."
---

# Offline verification of a Kubernetes ValidatingAdmissionPolicy (CEL)

Use when you must author or change a VAP's CEL but cannot run the live admission gate (cluster down, or the change is on a feature branch). The usual repo render test pins only the policy's source strings and does NOT evaluate CEL, so a logic bug (wrong host in a conditional, flipped `compareTo`, missing `has()` guard) passes every offline check. Close that gap with four layers:

## 1. Golden-pin the exact expressions
Render the overlay, extract the policy's `spec.variables` and `spec.validations` with whitespace compacted (`" ".join(expr.split())`), and write them to a reviewed golden JSON (e.g. `tests/golden/<policy>.json`). The render test asserts the rendered compacted lists equal the golden. Now any CEL change forces a visible, reviewable golden diff — shipped == reviewed.

## 2. Generate positive fixtures FROM the real renderer
Do not hand-author positive fixtures. Render them from the exact code path that produces real submissions (e.g. the launcher's `manifests.py`). Commit them, and add a drift guard: the test regenerates into a temp dir and `diff -rq` against the committed fixtures. A renderer change not reflected in the fixtures fails offline instead of only surfacing live.

## 3. Independent CEL-intent evaluator
Write a small, self-contained Python re-encoding of the policy (`evaluate_*(obj, *, resource, username) -> list[violated_messages]`) using the SAME verbatim `message` strings as the VAP. Author deterministic hostile fixtures as single-rule mutations of a positive, each with an expected message. Run every fixture through the evaluator: positives -> `[]`, hostiles -> non-empty containing the expected message. This proves the intended admit/deny partition offline.

## 4. Independent review
Dispatch a `code-reviewer` subagent to reconcile the CEL LOGIC (not just messages) rule-by-rule against the evaluator, the contract, and actual rendered manifests — looking for wrong-host conditionals, flipped compares, missing guards, and expressions that would error on the apiserver.

## CEL gotchas to check
- **DefaultTolerationSeconds**: the apiserver injects `node.kubernetes.io/not-ready` and `node.kubernetes.io/unreachable` `NoExecute` tolerations on **Pod** CREATE (not Job CREATE). A toleration-allowlist rule MUST permit those two defaults or every live Pod admission is denied. It fires on the job-controller-created Pod and standalone Pods, not on the Job object's template.
- **Ternary totality**: host/label-conditional `quantity()` ceilings must have a safe default branch; upstream validations should already reject any host outside the known set.
- **Index guards**: never index a possibly-absent map key without a preceding `has()`/`in` guard, or the expression errors (deny under failurePolicy: Fail, but confusing).
- The authoritative check remains the live gate (e.g. a `check-*-admission.sh` server-dry-run). Record it as the confirming step once the
