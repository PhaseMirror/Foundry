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

You’ve now closed the loop on recursion in the same way you closed it on the original Pro ecosystem: there is a working stack (RPO/APO v1) and a governance layer (RECURSION-POLICY-V0.4) that dictates how and when it must be used.

Given your new policy, the important questions are: what have you actually constrained, what remains flexible, and what are the implicit tradeoffs you’ve accepted.

## What the v0.4.0 recursion policy really fixes

You’ve made three big moves:

1. **Tiered assurance model**
    - **Tier 1 (Commons)**
        - Base Goldilocks STARK: mandatory.
        - RPO v1: optional.
This keeps the Commons world open and lightweight—anyone can verify the base proof; recursion is an optional additional assurance.
    - **Tier 2 (Pro)**
        - Base STARK: mandatory.
        - RPO v1: mandatory.
This aligns with your “Ξ‑Certified” notion: Pro isn’t just “has a proof,” it “has a recursively sealed proof,” anchored in Pallas. This raises the bar for what counts as “certified” without forcing aggregation.
    - **Tier 3 (Oracle)**
        - APO v1: mandatory.
        - Designed for batch anchors and cross-domain / cross-chain publishing.
This tier makes explicit that some contexts (like cross-chain anchors) require not only per-proof assurance but *aggregated* assurance.

You’ve essentially created a stratified trust model: Commons → Pro → Oracle, each strictly stronger.
2. **Operational constraints that bound recursion**
    - **Aggregation budget (4–16 RPOs)**
        - Prevents unbounded aggregation that could:
            - blow up circuit complexity,
            - or create huge, unwieldy proof objects.
        - Encourages “batching in moderate groups,” which matches many real-world usage patterns.
    - **Chaining depth (≤ 8)**
        - Prevents unbounded recursive stacking where:
            - small verification errors could compound,
            - or the complexity of understanding proof lineage becomes too high.
        - Eight layers is enough to:
            - encode nontrivial networks of proofs,
            - while still being traceable by humans and machines.
    - **Fail-closed Pro tier**
        - If a Pro-tier session lacks a valid recursive seal:
            - it is downgraded to PROVISIONAL (not silently accepted).
        - This enforces:
            - “no recursion, no full certification,”
            - but allows the system to continue operating in a clearly marked degraded state.

These constraints respect both your performance baseline and your governance model: recursion can’t run away with the system.
3. **Explicit transition protocol**
    - **14-day opt-in window**
        - v0.3.1 users can:
            - adapt clients and infrastructure,
            - test RPO verification in their flows,
            - prepare for the hard-fork.
    - **Hard-Fork on Day 15**
        - At that point:
            - RPO verification is mandatory for Pro-tier,
            - the manifest and governance rules enforce this,
            - any client that hasn’t updated will see Pro proofs fail or be downgraded.

This mirrors a well-run network upgrade:
    - clear announcement,
    - overlap period,
    - then a decisive cutover.

## What remains flexible

Even with this policy, you’ve left yourself important degrees of freedom:

- The specific **aggregation policy** for Oracle tier:
    - You can vary how often you aggregate,
    - which proofs are allowed into the same APO,
    - how you schedule or batch operations.
- The **structure of Pallas aggregation circuits**:
    - ADR-036 defines required checks, but you can:
        - change circuit implementations,
        - improve constraint efficiency,
        - explore different commitment schemes,
as long as they respect the same RPO/APO semantics.
- The **exact contents of each tier’s manifest**:
    - Different domains can:
        - use different recursion depths (within your max),
        - choose different aggregation patterns,
        - adopt different policy profiles,
while still respecting the global recursion policy.


## Tradeoffs you’ve accepted

Your recursion policy hard-codes some important choices:

- **Strong guarantees over maximum flexibility**
    - You’ve chosen:
        - bounded aggregation sizes,
        - bounded recursion depth,
        - mandatory RPO for Pro,
which all tilt toward “safety and interpretability” over “unbounded compositional power.”
- **Governed hard-forks over soft drift**
    - The 14-day window + hard cutover is a strong stance:
        - no long-term regime where some Pro users require recursion and others do not,
        - a single canonical expectation for Pro-tier behavior.
- **Clear separation between Commons and Pro/Oracle**
    - Commons stays simpler and more optional,
    - Pro and Oracle become progressively more demanding,
    - which will shape how different communities choose where to anchor themselves.

These are good tradeoffs for a system that already prizes sealed manifests and bicameral governance.

## What to watch as you move into v0.4.0

Two areas will tell you whether this recursion policy is tuned correctly:

1. **Real usage vs constraints**
    - How often do:
        - Pro clients fail due to missing RPOs?
        - Oracle APOs hit aggregation limits?
        - Chains hit the 8-depth cap?

That will reveal:
    - whether your caps are generous, tight, or just right.
2. **Operator and client friction**
    - Do node operators:
        - find the recursion requirements manageable?
        - hit unexpected failure modes (e.g., PROVISIONAL downgrades)?
    - Do client integrators:
        - adapt easily to RPO/APO verification,
        - or struggle to handle new error cases?

That feedback will tell you:
    - whether v0.4.0 needs small policy adjustments,
    - or whether your governance documents already give enough guidance.

## Direct response

You’ve turned recursion from an internal capability into a governed, tiered policy:

- Commons must verify base STARKs;
- Pro must verify both base and RPO v1;
- Oracle must verify APO v1 aggregates;
- aggregation size, recursion depth, and failure semantics are all explicitly bounded;
- the transition is managed via a clear opt‑in and hard-fork process.

There’s no further invariant that obviously needs locking before you start running this in the wild. The most useful next move is to:

- deploy v0.4.0 in a controlled setting,
- watch how often the recursion policy bites,
- and refine your understanding of how much recursive assurance your actual users really want or need.

If you’d like, we can sketch a short “v0.4.0 Recursion Client Guide” that explains, in one place, how Tier 1/2/3 clients should handle RPO/APO verification and what new failure modes they must be prepared for.

