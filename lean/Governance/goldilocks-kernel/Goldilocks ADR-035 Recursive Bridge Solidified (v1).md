<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Recursive Bridge Solidified (v1):

Finalizing solidified ADR-036 and Recursive Bridge.

✦ The recursive bridge architecture is now solidified and the
interface is versioned (v1), establishing the canonical path
for Phase Mirror Pro horizontal composition.

1. Solidified ADR-036: RPO v1
I have established the Recursive Proof Object (RPO) v1
specification, establishing it as the stable interface for
recursive circuits.

- Versioned Schema: Added protocol_v to allow
forward-compatible bridge updates.
- Deterministic Encoding: Specified affine X/Y coordinates
for the Pallas Pedersen seal.
- Bridge Anchors: Defined how the base Goldilocks root is
lifted into the Pallas scalar field via 3-to-1 packing.

2. Manifest Integration
The core Manifest in prover/src/lib.rs now supports
recursive proofs natively.

- Recursive Section: Includes ec_field (Pallas), ec_curve,
and outer_verification_key.
- v0.4.0 Readiness: This metadata allows verifiers to
automatically switch between base STARK and
recursive-wrapped verification modes.

3. Hardened POC Implementation
The recursive-prover crate has been updated to align with
the v1 specification:

- wrap_stark: The primary API for generating versioned RPOs
from inner STARKs.
- wrap-proof CLI: Now generates a complete
recursive_proof.json containing the v1 bundle.

1 \# Generate a v1 Recursive Proof Object
2 cargo run -p recursive-prover --bin wrap-proof --release
-- prime_res_proof.json

4. Strategic Direction
With the RPO interface locked, the project is positioned to
implement:

- Aggregation: Folding multiple RPOs into a single Pallas
circuit.
- Chaining: Enabling deep transitive proof networks
(Proof_N verifies Proof_{N-1}).

We have successfully established the "Horizontal Bridge" as
a formal, stable protocol.

[Active Topic: Recursive Bridge Solidified (v1)]

You’ve done exactly the right thing with RPO v1: you turned a working bridge into a **protocol surface** with its own versioning, anchoring, and manifest integration. At this point, the most important moves are about how you *use* this v1 interface without destabilizing the rest of the ecosystem.

Here’s what you’ve actually locked in, and what it enables next.

## What RPO v1 now guarantees

You’ve given recursive composition a stable “wire format”:

- **Versioned schema (`protocol_v`)**
This is crucial: it means any future change to the recursive format must:
    - bump the protocol version,
    - keep v1 semantics frozen.
That protects v0.3.1 (and soon v0.4.0) from subtle breakage when you experiment with new packing, commitments, or circuit structures.
- **Deterministic EC encoding**
By pinning:
    - affine X/Y coordinates over Pallas for the Pedersen seal,
    - a specific generator pair $G, H$,
you’ve removed ambiguity about:
    - how commitments are represented,
    - how they’re compared,
    - how they feed into circuits.
Any verifier, in any language, can now treat the RPO’s `(X, Y)` as the canonical outer commitment.
- **Bridge anchor semantics**
The 3-to-1 packing is no longer a hidden implementation detail; it’s a spec-level choice:
    - three 64-bit Goldilocks elements → one 254-bit Pallas element,
    - with a defined order and endianness.
That’s what lets the recursive circuit “see” the Goldilocks root and other fields in a reversible, hash-stable way.

Together, those make RPO v1 a genuine protocol object, not just a serialized internal structure.

## Manifest integration: what changes for verifiers

By adding a recursive section to the manifest, you’ve told verifiers:

- **Base-only mode**
If the recursive section is absent or disabled, they:
    - verify only the Goldilocks STARK,
    - ignore any RPO artifacts.
- **Recursive mode**
If `ec_field = Pallas`, `ec_curve` and `outer_verification_key` are present, they:
    - can treat the RPO as an additional proof layer,
    - verify:
        - base STARK proof,
        - plus RPO (wrap proof) against the outer verification key.

That gives you a clean upgrade path to v0.4.0:

- v0.3.1: base STARK only.
- v0.4.0: base STARK + optional or required RPO v1 verification.

The key is that verifiers now *discover* recursive capability from the manifest, rather than guessing based on file presence.

## Hardened POC: what `wrap_stark` actually stabilizes

By turning the POC into:

- `wrap_stark` API, and
- `wrap-proof` CLI emitting a v1 RPO bundle,

you’ve enforced:

- every RPO v1:
    - uses the same packing,
    - uses the same Pedersen encoding,
    - includes the same fields in the same order.

That’s critical for:

- cross-language verifiers (Rust, WASM, etc.),
- auditability (everyone’s talking about the same object),
- future aggregation/chaining (they can treat RPOs as homogenous inputs).


## Strategic implications for aggregation and chaining

Now that the interface is solid:

- **Aggregation**
You can define a “multi-RPO” circuit that:
    - takes N RPO v1s as inputs,
    - verifies each,
    - produces a new outer commitment that attests to all of them.
Because RPO v1 is versioned and deterministic:
    - aggregation circuits can be written against a fixed format,
    - clients can interpret aggregated proofs without special-casing hacks.
- **Chaining**
You can define a recursive circuit where:
    - `Proof_N` verifies `Proof_{N-1}` by:
        - verifying the RPO v1 payload,
        - checking any additional invariants,
and outputs a new RPO v1 (or v2+) as the next link.
The key advantage: every recursive step sees the base proof in the *same* way, via RPO v1, rather than via ad hoc encodings.


## How to protect what you’ve just built

The main risk now is “success-driven erosion”: as you add aggregation and chaining, it becomes tempting to tweak RPO v1. You’ve already taken the right precaution (protocol_v), but a few extra guardrails will help:

- Treat RPO v1 as **immutable**:
    - no field removals,
    - no semantic changes,
    - only additive fields via new versions (v2, v3) if needed.
- Wire the manifest so that:
    - v0.3.1 manifests reference *no* RPO (base-only),
    - v0.4.0 manifests explicitly declare `protocol_v = 1` for recursive sections,
    - future versions must set `protocol_v > 1` and are considered distinct.
- Ensure clients:
    - fail fast on unknown `protocol_v`,
    - opt‑in explicitly to new versions.

That keeps your recursive bridge from silently morphing under the ecosystem’s feet.

## Direct response

With RPO v1 and manifest integration in place, you’ve turned recursion from “future design” into a **stable protocol surface**:

- base proofs stay Goldilocks,
- RPO v1 provides a clean, versioned bridge into Pallas,
- manifests tell verifiers exactly when and how to use that bridge.

From here, the two highest‑leverage next steps are:

- design a first aggregation circuit that consumes multiple RPO v1s, and
- decide, at the manifest/governance level, whether v0.4.0 should *require* recursive verification or treat it as an optional, higher‑tier assurance.

If you’d like, we can sketch the shape of that first aggregation circuit: what inputs it should accept, what invariants it should check, and how its output RPO should differ (if at all) from a simple single‑wrap RPO v1.

