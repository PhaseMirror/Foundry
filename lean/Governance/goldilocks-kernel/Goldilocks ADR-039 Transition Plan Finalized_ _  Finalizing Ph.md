<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# v0.4.0 Transition Plan Finalized:

Finalizing Phase 7 deliverables and v0.4.0 transition
plan.

✦ The transition plan for the v0.4.0 Recursive Network is now
finalized, including the technical guide for client-side
integration.

1. v0.4.0 Recursion Client Guide
I have created the comprehensive guide for integrators in
agi_os/docs/guides/V0.4.0-RECURSION-CLIENT-GUIDE.md. It
provides:

- Tier Definitions: Clear distinction between T1 (Base), T2
(Pro), and T3 (Oracle) assurance.
- Verification Protocols: Step-by-step instructions for
verifying RPO v1 (Recursive) and APO v1 (Aggregated)
artifacts.
- Diagnostics: A standard table of error codes
(ERR_SEAL_INVALID, STATUS_PROVISIONAL, etc.) to help
operators troubleshoot recursion failures.
- Transition Timeline: Explicitly documents the 14-day
opt-in period before the mandatory v0.4.0 hard-fork.

2. Strategic Roadmap Alignment
The Phase 7 Roadmap has been updated to include these
client-facing deliverables under Track C: Ecosystem \& WASM.
The next steps focus on compiling the verifier to WASM and
standing up the public reference node.
3. Consolidated State

- Protocol: RPO/APO v1 (Solidified in ADR-036).
- Enforcement: RECURSION-POLICY-V0.4.md.
- Education: V0.4.0-RECURSION-CLIENT-GUIDE.md.

1 \# To view the new Client Guide:
2 cat agi_os/docs/guides/V0.4.0-RECURSION-CLIENT-GUIDE.md

The system is now fully prepared for the v0.4.0 transition.
I have fulfilled all requested tasks for this phase.

[Active Topic: v0.4.0 Transition Plan Finalized]

You’ve closed Phase 7 cleanly. At this point, nothing essential is missing from the v0.4.0 transition story: there is a protocol, a governance policy, and now a client guide that tells others how to live inside that structure.

Given your last update, the most important thing now is not another artifact but clarity on how to *treat* what you’ve built.

## What you’ve locked for v0.4.0

You’ve now got three layers fully aligned:

- **Protocol**
    - RPO v1: single-wrapped recursive proofs with:
        - versioned schema,
        - deterministic Pallas commitments,
        - strictly defined packing from Goldilocks.
    - APO v1: multi-proof aggregates with:
        - aggregate Keccak root,
        - single Pedersen seal.
- **Enforcement**
    - Recursion policy v0.4.0:
        - Tier 1: base-only mandatory, recursion optional.
        - Tier 2: base + RPO mandatory.
        - Tier 3: APO mandatory for batch anchors.
    - Operational constraints:
        - aggregation window, recursion depth, fail‑closed semantics.
- **Education**
    - Client guide that:
        - teaches integrators the tier model,
        - gives concrete verification steps for RPO/APO,
        - defines error codes and what to do with them,
        - lays out the 14‑day transition and hard‑fork.

That combination is exactly what you want before turning recursion on for real clients.

## How to use this phase well

The most valuable thing you can do with this state is:

- **Run a controlled transition rehearsal**
    - Take a sandbox environment or internal deployment.
    - Pretend the 14‑day window starts today.
    - Use the client guide exactly as an external integrator would:
        - configure base-only clients (Tier 1),
        - upgrade Pro clients to RPO verification (Tier 2),
        - experiment with Oracle-tier APO for a small batch use case (Tier 3).
    - Log:
        - where the guide feels too vague,
        - which error codes actually occur,
        - what operators or integrators stumble on.

That rehearsal will tell you if anything in the guide, policy, or manifest needs tightening before you point this at a broader audience.

## Direct response

You’ve completed the Phase 7 deliverables and produced a coherent v0.4.0 transition plan, including:

- a solidified recursive protocol (RPO/APO v1),
- a governance policy for how recursion is required in each tier,
- and a client-facing guide that explains how to verify and debug recursive proofs.

The best next step is to run this as if you were an external integrator: follow your own client guide, observe where reality diverges from the document, and let that feedback inform the first iteration of v0.4.0 in practice.

If you’d like, we can now treat this as a live system and define a small set of concrete “recursion pilot scenarios” (one Commons, one Pro, one Oracle) to use as benchmarks for the first v0.4.0 deployments.

