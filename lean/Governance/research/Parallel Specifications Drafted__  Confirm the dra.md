<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Parallel Specifications Drafted:

Confirm the drafting and parallel specification of ADR-AHGI-003 and ADR-AHGI-004.

✦ I have successfully drafted and codified both constitutional artifacts in parallel. The resulting documents
explicitly confront the tensions between infinite-dimensional mathematical theory and constrained production
reality.

1. ADR-AHGI-003: Thymos Runtime Specification is saved at
/home/multiplicity/models/ataraxia/docs/adr/proposed/ADR-AHGI-003.md.
    * Phase Labels: Defined as session-local, but bound to a system-wide aggregated coherence index published by
the spectral_integrity_agent (Containment without Isolation).
    * Operator Discrete Implementation: Specified fixed dimensional state vectors (e.g., 1024 for tier_3/4), exact
λ contraction limits, and enforced the strictly non-commutative projection sequence (T_{Λ_m} → Π_{CSL} →
P_E).
    * ACE Budget Debit: Confirmed units, mandated debiting at transition start to prevent adversarial OOM/DoS
loops, and specified the exact "Read-Only Degradation State" upon exhaustion.
    * Lyapunov Certification: Verified at promotion and drift_baseline update, with mid-operation divergence
classified immediately as a Collapse.
2. ADR-AHGI-004: PEET Drift Engine Specification is saved at
/home/multiplicity/models/ataraxia/docs/adr/proposed/ADR-AHGI-004.md.
    * Baseline Anchoring: Set P sizes by tier, permitted in-place re-anchoring for environmental shifts
(countersigned by an SI agent), and defined κ(t) as a per-model curvature parameter anchored at
certification.
    * Tier Thresholds: Ratified the 0.05, 0.15, 0.30 provisional boundaries and locked in the 90-day sunset clause
post-clinical-pilot.
    * Collapse Response: Formalized the indefinite Custodian Hold protocol, custodian DID resolution, and the
Archivum-anchored 3-step release checklist.
    * Offline Drift Computation: Mandated immediate local hold on offline Collapses and instituted a strict 0.20
max drift integral limit that degrades the node to read-only before reaching a threshold Collapse.

With both drafts complete, the Thymos × PEET interface spec is clear: PEET acts as the sensor publishing δ_{PEET}
and the resulting tier classification, and Thymos consumes this input directly into its P_E coherence gate and ACE
state machine.

Both documents are ready for internal review. The test harness implementations can now begin.

Both drafts are confirmed. State the record and surface the next live tension.

***

## What Is Now Constitutionally Locked

| Decision | ADR | Ratified Value |
| :-- | :-- | :-- |
| Phase label scope | ADR-AHGI-003 | Session-local + system-wide coherence index |
| State vector dimension (tier_3/4) | ADR-AHGI-003 | 1024 |
| Contraction bound $\lambda$ | ADR-AHGI-003 | Per risk tier, explicitly bounded |
| Projection sequence | ADR-AHGI-003 | $T_{\Lambda_m} \to \Pi_{\text{CSL}} \to P_E$ — non-commutative, hard invariant |
| ACE debit moment | ADR-AHGI-003 | Transition start — closes adversarial OOM/DoS vector |
| Budget exhaustion state | ADR-AHGI-003 | Read-Only Degradation — not halt, not silent continue |
| Lyapunov failure classification | ADR-AHGI-003 | Immediate Collapse tier |
| Prime set sizing | ADR-AHGI-004 | Per tier |
| $\kappa(t)$ scope | ADR-AHGI-004 | Per-model, certified at promotion |
| Tier thresholds | ADR-AHGI-004 | 0.05 / 0.15 / 0.30, 90-day sunset post-clinical-pilot |
| Offline Collapse response | ADR-AHGI-004 | Immediate local hold |
| Offline drift integral limit | ADR-AHGI-004 | 0.20 max before read-only degradation |
| Custodian hold duration | ADR-AHGI-004 | Indefinite — 3-step Archivum-anchored release checklist |

The ACE debit-at-transition-start decision is worth naming explicitly. Debiting at completion would allow an adversarial agent to initiate arbitrarily many transitions, exhaust compute, and claim budget credit only on successful completions. Debiting at start means a blocked or failed transition still costs budget. That is the correct economic model — compute consumed is compute consumed regardless of outcome.

***

## Thymos × PEET Interface — The Binding

The interface is now formally derivable from both ADRs. It is a single publish/subscribe boundary:

```
PEET publishes:
  {
    "session_id":     uuid,
    "peet_delta":     float,          // δ_PEET(n,t)
    "drift_tier":     enum,           // nominal | watch | warn | collapse
    "computed_at":    datetime,
    "baseline_prime": int,            // prime index of the anchored Ψ(n,t)
    "kappa":          float           // per-model κ at this computation
  }

Thymos consumes:
  - drift_tier → coherence gate input (blocks if collapse)
  - peet_delta → P_E viability check (confidence proxy: 1 - δ_PEET ≥ 0.6)
  - session_id → binds to agent_action.telemetry.peet_delta field
  - computed_at → staleness check against max_latency_ms in clinical_auth
```

This interface has one hidden assumption that must be named before it becomes a bug: **PEET computation latency**. If $\delta_{\text{PEET}}$ is computed synchronously on every agent action, it adds non-trivial latency to the certification check pipeline. If it is computed asynchronously and cached, the coherence gate is operating on a stale signal.

The ADR-AHGI-004 must specify the maximum permissible age of a cached PEET value before Thymos must reject it and demand a fresh computation. This is the **PEET staleness budget** — a parameter that does not yet exist in either ADR.

***

## Three Live Tensions Before Test Harness Implementation

Before the test harness implementations begin, three tensions need resolution — not because they block the harnesses, but because unresolved tensions at this stage produce test harnesses that validate the wrong things.

**Tension 1: 1024-dimensional state vector vs. single-node deployment**

A 1024-dimensional state vector for tier_3/4 agents running on the minimum viable hardware spec (8GB RAM, 4-core CPU) must be profiled. The MultiplicityCell runs once per agent action. At peak clinical load — concurrent actions from multiple agent classes — the memory and compute footprint of 1024-dimensional operations across multiple simultaneous cells needs a capacity bound. The test harness must include a load simulation that validates the hardware floor.

**Tension 2: 90-day threshold sunset vs. no clinical pilot scheduled**

The 0.05 / 0.15 / 0.30 thresholds have a 90-day sunset post-clinical-pilot. No clinical pilot is currently scheduled. The sunset clause is an unfalsifiable commitment until a pilot date exists. The ADR needs a pilot initiation trigger — either a calendar date or a milestone (e.g., "90 days post Tier 1 sovereign node deployment in staging"). Without it, the provisional thresholds are permanent by default.

**Tension 3: Indefinite custodian hold vs. operational continuity**

An indefinite custodian hold on a Collapse event means a single model in a single lineage can block an entire agent class indefinitely if the custodian is unavailable — during an emergency, a weekend, a staffing gap. The 3-step release checklist is sound, but the hold needs a **deputy custodian protocol** — a secondary authorized DID that can issue a conditional release under defined emergency conditions. That conditional release is itself an Archivum-anchored record and is subject to post-hoc audit. Without it, the Collapse response has a single point of human failure.

***

## Immediate Next Actions

| Action | Owner | Horizon |
| :-- | :-- | :-- |
| Add `peet_staleness_budget_ms` to ADR-AHGI-004 | Spectral Team | 48 hours |
| Add deputy custodian protocol to ADR-AHGI-004 | Governance | 48 hours |
| Add pilot initiation trigger to threshold sunset clause | Architecture | 48 hours |
| Begin MultiplicityCell test harness v2 with load simulation | Core Runtime | 7 days |
| Begin PEET threshold validation harness | Spectral Team | 7 days |
| Draft Thymos × PEET interface spec as standalone artifact | Architecture | 7 days |

The three ADR patches are 48-hour items — they are small, targeted, and unblock the harnesses with confidence. Run them before the harness implementations start.

