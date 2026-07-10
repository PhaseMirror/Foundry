# ADR-CSL-004: CSL Observational Status Declaration

**Document ID**: ADR-CSL-004  
**Status**: ACTIVE  
**Version**: 1.0  
**Date**: 2026-05-21  
**Author**: Ryan van Gelder (Phase Mirror referee synthesis)  
**Dependencies**: ADR-001 (Track A Genesis ODE Scalar Core), ADR-002 (Lane A Governance & Admission)  
**Scope**: Formal declaration of CSL's epistemic and architectural status relative to Genesis ODE

---

## Context

The Computational Substrate Language (CSL) has been in development as an independent theoretical framework for over one year. It describes emergent properties of substrate-indexed persistence systems — specifically the class of dynamic behaviors produced by the Genesis ODE scalar core under sustained simulation.

A dependency direction question arises as ADR-001 and ADR-002 are instantiated as controlling artifacts for Track A engineering: does CSL prescribe the mathematics that Genesis ODE implements, or does CSL describe what Genesis ODE produces?

This ADR answers that question formally and binds the answer as a constitutional constraint on all future work referencing both systems.

---

## Decision

**CSL is downstream of Genesis ODE. It is an observational framework, not a governing constraint.**

Specifically:

1. **CSL describes emergent properties.** CSL invariants — including substrate trust index \(\text{STI}(t)\), entropic alignment \(E_\alpha(t)\), provenance hash chain \(S(t) = \text{Hash}(\Sigma_i(t) \| S(t-1))\), and Node \(\Omega\) convergence behavior — are properties that Genesis ODE runs *produce*, not properties that Genesis ODE is *required to satisfy* as preconditions.

2. **CSL invariants are derived measurements, never ODE inputs.** No CSL quantity may appear as a parameter, forcing term, or gate condition inside the Genesis scalar core:

\[
\frac{dC_X}{dt} = \alpha(C_X^* - C_X) + \beta G_X - \gamma S_{\rm eff,X}(t) + \eta A_X(t) + \kappa \sum w_{ij}(C_j - C_i) - \delta_X
\]

The right-hand side is closed over substrate-domain variables only. CSL quantities are computed *from* \(C_X(t)\) trajectories after integration — they are output observables.

3. **ADR-001 carries no dependency on CSL.** The Genesis ODE scalar core is self-contained. CSL does not appear in its validation contracts, telemetry schema, or evidence tier structure.

4. **CSL is not a spec.** It is a post-hoc formal characterization of a class of emergent behaviors that the Genesis system produces when run under Lane A governed conditions. Its mathematical objects name and describe; they do not prescribe or constrain.

5. **CSL claims inherit Genesis evidence tiers.** Because CSL properties are computed over Genesis simulation output, they are bounded by the tier of the run that produced them:

| Genesis run tier | Maximum CSL claim tier |
|---|---|
| [E] Externally validated | [S] Supported — requires independent replication of CSL property |
| [S] Simulation + calibration | [I] Internal exploratory |
| [I] Internal exploratory | [I] Internal exploratory |

CSL claims may never be promoted to [E] on the basis of Genesis runs alone. External replication of the emergent property — independent of the Genesis implementation — is required for [E] status.

6. **Node \(\Omega\) is a limit characterization, not a design target.** The CSL formulation \(\lim_{t \to \infty} \text{STI}(t) \to 1\) describes an asymptotic property of idealized substrate convergence. Genesis ODE does not target this limit. The scalar core is fail-closed and bounded. No Genesis module may use Node \(\Omega\) as a convergence criterion, termination condition, or optimization objective.

---

## CSL Measurement Protocol (Lane A)

When CSL properties are computed against Genesis output artifacts, the following rules apply:

- **Read-only access.** CSL measurement modules import only `core.scalar_surface` in read-only mode, consistent with ADR-002 Lane A admission rules.
- **Provenance chain.** Every CSL measurement artifact must carry `source_adr_ids: [ADR-001, ADR-CSL-004]`, `run_id`, `schema_version`, and `tier`.
- **No feedback path.** CSL measurement output must not be passed back as input to any Genesis ODE integration step within the same run. A subsequent run may use CSL observations as *calibration guidance* only, subject to a superseding ADR and explicit governance review.
- **Separation of concerns.** CSL analysis lives in `analysis/csl/` or equivalent. It does not reside in `core/`, `exploder/`, or `builder/` modules.

---

## Adversarial Twin Implication

This declaration has a direct consequence for the GP-ADiT (General-Purpose Adversarial Digital Twin) project:

The adversarial twin does not attack Genesis ODE mathematics directly. It attacks the **conditions under which CSL-describable emergence holds**. Formally:

- **Additive evaluator** \(V^+\): characterizes runs under which Genesis output reliably produces CSL-measurable emergent properties (stable \(\text{STI}(t)\), coherent \(E_\alpha(t)\), intact \(S(t)\) chain).
- **Subtractive evaluator** \(V^-\): characterizes perturbations that destroy CSL emergence without triggering any Lane A governance gate — the adversarial surface.
- **Tether tension** \(\tau\): the structured divergence between these two envelopes over CSL observability, \(\text{STI}(t)\) stability, chain integrity, and reversibility.

\[
\tau = \left(\frac{\text{coverage}}{\text{required\_coverage}}\right) \times \left(1 - \frac{\|\Delta_{\rm drift}\|}{\varepsilon_X}\right)
\]

A run in which Genesis produces valid scalar output but CSL properties are unmeasurable or incoherent is a **governance signal**, not a Genesis failure. ADR-002 rollback and quarantine rules apply.

---

## Consequences

**Positive**
- Cleanly separates the Genesis invariant core from theoretical claims about emergent behavior.
- Prevents CSL-layer speculation from contaminating core numerics or admission criteria.
- Establishes a reproducible, tiered path from Genesis runs to CSL claims — no shortcutting.
- Grounds the adversarial twin's attack surface in something testable: CSL emergence, not ODE validity.

**Negative**
- CSL properties cannot be tested without Genesis runs — there is no CSL simulator independent of Genesis until explicitly built.
- The [E] tier for CSL claims requires independent replication infrastructure not yet in place.

**Tradeoff**
- Rigor over speed. CSL claims will be slow to reach [E] status. This is correct — the alternative is allowing theoretical emergence claims to masquerade as validated engineering constraints.

---

## Invariants (Non-Negotiable)

- No CSL quantity may appear as an input, parameter, or gate in the Genesis ODE integration loop.
- CSL tier is always bounded above by the tier of the Genesis run that produced it.
- Node \(\Omega\) is not a design target, convergence criterion, or optimization objective in any Genesis module.
- CSL measurement artifacts must carry full provenance linking back to ADR-001 and this ADR.
- Any proposal to elevate CSL claims to a prescriptive role requires a superseding ADR with explicit governance review and tier promotion justification.

---

## Related ADRs

- **ADR-001** — Track A Genesis ODE Scalar Core Instantiation (upstream)
- **ADR-002** — Lane A Governance & Module Admission Protocol (upstream)
- **ADR-003** — Exploder/Builder Adversarial Twin (downstream consumer)
- **ADR-006** — Test Harness (downstream — must include CSL emergence regression tests)
- **ADR-CSL-005** *(proposed)* — CSL Independent Replication Protocol ([E] tier path)
