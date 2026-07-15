<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# v0.4.0 Recursion Policy Established:

Establishing v0.4.0 Recursion Policy and roadmap
alignment.

✦ The transition to the v0.4.0 Recursive Network is now
governed by a formal policy framework, defining how the
RPO/APO v1 stack will be enforced across the ecosystem.

1. v0.4.0 Recursion Policy (RECURSION-POLICY-V0.4.md)
I have established the normative governance document in
agi_os/docs/governance/ that defines the following
certification tiers:

- Tier 1 (Commons): Base Goldilocks STARK is mandatory. RPO
v1 is optional.
- Tier 2 (Pro): Base STARK + RPO v1 is mandatory. Achieves
full Ξ-Certified status.
- Tier 3 (Oracle): APO v1 (Aggregated Proof) is mandatory.
Used for batch cross-chain anchors.

2. Operational Constraints

- Aggregation Budget: APOs are limited to 4-16 RPOs to
balance latency and amortized cost.
- Chaining Depth: Recursive chains are permitted up to 8
layers.
- Fail-Closed: Pro-tier sessions lacking a valid recursive
seal must be downgraded to PROVISIONAL.

3. Roadmap Alignment
The Phase 7 roadmap now includes Task B.5: Policy
Ratification \& v0.4.0 Alignment, which focuses on:

- Formal board ratification of the recursion policy.
- Enforcing tier-based requirements in the verifier logic.
- Releasing the first v0.4.0-compatible manifest.

4. Transition Protocol
A 14-day opt-in period is established for v0.3.1 users,
followed by a Hard-Fork on Day 15 where RPO verification
becomes mandatory for all Pro-tier certifications.

1 \# To view the full v0.4.0 Recursion Policy:
2 cat agi_os/docs/governance/RECURSION-POLICY-V0.4.md

The horizontal compositional layer is now both technically
functional and constitutionally governed.

[Active Topic: v0.4.0 Recursion Policy Established]

The recursion policy you’ve written is coherent and sufficient to carry you into v0.4.0. At this point the emphasis shifts from “define” to “enforce and observe.”

Here’s what you’ve actually locked in, and what I’d pay attention to next.

## What the policy now guarantees

- **Tiered assurance**
    - Tier 1 (Commons): everyone gets a base Goldilocks STARK; recursion is an optional extra.
    - Tier 2 (Pro): base STARK + RPO v1 is required to be considered fully Ξ‑Certified.
    - Tier 3 (Oracle): APO v1 is required for batch anchors (e.g., cross-chain), ensuring that any anchor is backed by a bundled, recursively sealed proof set.
- **Bounded recursion**
    - Aggregation windows are capped (4–16 RPOs), preventing unbounded APO sprawl.
    - Recursion depth is capped (8 layers), preventing infinite proof chains and keeping proof lineage understandable.
    - Pro-tier sessions that lack a valid RPO are not silently accepted; they are explicitly labeled PROVISIONAL.
- **Governed rollout**
    - A clear 14‑day opt-in window, during which:
        - v0.3.1 clients can adopt RPO verification,
        - operators can test new manifests.
    - A hard fork on Day 15 that makes RPO mandatory for Pro-tier, enforced by:
        - the new v0.4.0-compatible manifest,
        - updated verifier logic,
        - governance signatures.

This keeps your recursion layer aligned with the same governance discipline you applied to v0.3.0.

## How this aligns with the roadmap

You’ve already done the hard parts of Task B.5:

- **Policy ratification path**: a concrete RECURSION-POLICY-V0.4.md and a plan for board-level ratification.
- **Verifier enforcement**: tier-based rules that can be compiled into the client and server verifier logic (e.g., Pro mode refusing proofs without RPO).
- **Manifest readiness**: a clear target for the first v0.4.0 manifest that:
    - declares recursive capabilities,
    - specifies outer verification keys,
    - sets `protocol_v` and tier expectations.

What remains is mostly execution:

- implement the tier logic in the verifier (Tier 1/2/3 behavior),
- cut and sign the v0.4.0 manifest,
- and run through the 14‑day transition in a controlled environment.


## What to watch during the transition

As you move into v0.4.0, the most important feedback signals will be:

- **Pro-tier behavior**:
    - how often sessions get downgraded to PROVISIONAL (missing or invalid RPO),
    - whether operators need better tooling to diagnose recursion failures.
- **Oracle-tier aggregation**:
    - whether the 4–16 RPO aggregation window feels natural,
    - whether proofs routinely hit the recursion-depth cap,
    - how APO size and latency behave in real workloads.
- **Client friction**:
    - how easy it is for existing clients to adopt RPO/APO verification,
    - whether error modes are clear (e.g., “recursive seal missing or invalid”).

If those signals look healthy, your recursion policy will have proved itself not just as a document but as a lived behavior.

If you’d like, the natural next artifact from here is a short “v0.4.0 Recursion Client Guide” aimed at integrators, explaining:

- what Tier 1/2/3 mean,
- how to verify RPO/APO v1,
- what failure cases to expect,
- and how the 14‑day transition affects them.

