ADR-003 — Track A Metallurgical Exploder
MVP
Minimum Governed End-to-End Validation Loop
Status: ALPHA
Date: 2026-05-20
Decision Type: Architecture / Governance
Supersedes: None




Depends On
   •   ADR-001 — Genesis ODE Governance Baseline
       DOI: 10.5281/zenodo.20278072
   •   ADR-002 — Experimental Branch Governance
       DOI: 10.5281/zenodo.20278161

Existing ADR-001 and ADR-002 records SHALL remain canonical until formally superseded
through explicit ADR amendment or replacement.




Related Artifacts
   •   SOFTWARE_AUDIT_AND_RELEASE_READINESS.md
   •   SUBSTRATES_EVIDENCE_TIERS.md
   •   VALIDATION_CONTRACT.md
   •   BRANCH_STATUS_REGISTRY.md




1. Context
ADR-001 established the Track A scalar core as the sole canonical nonlinear persistence engine.

ADR-002 established Lane A governance boundaries, including:

   •   immutable scalar core,
   •   provenance requirements,
   •   evidence-tier separation,
   •   fail-closed behavior,
   •   and module-boundary governance.

Subsequent RC4 engineering review identified:

   •   mature governance architecture,
   •   but pre-alpha engineering maturity,
   •   incomplete benchmark infrastructure,
   •   limited regression depth,
   •   and elevated risk of execution drift during rapid architecture expansion.

External implementation input from Dr. Ryan van Gelder proposed:

   •   Exploder / Builder / Tether architecture,
   •   canonical schema contracts,
   •   perturbation families,
   •   architecture-boundary testing,
   •   and phased repository governance.

Independent review concluded that the architecture direction is correct, but that the proposed full
scaffold exceeds current implementation maturity.

A smaller, fully validated end-to-end metallurgy loop is therefore required before broader
repository expansion.

The purpose of ADR-003 is to define the minimum governed executable loop required before
broader Lane A implementation proceeds.




2. Decision
The project SHALL implement a minimum governed metallurgy validation loop before
instantiating the complete Lane A repository architecture.

This minimum loop SHALL be referred to as:

MVP-A1

MVP-A1 SHALL contain only the minimum components required to demonstrate:

   •   immutable scalar-core execution,
   •   deterministic perturbation application,
   •   telemetry capture,
   •    drift measurement,
   •    tether computation,
   •    canonical artifact emission,
   •    RunManifest locking,
   •    and governance-boundary enforcement.

The implementation SHALL remain metallurgy-only during MVP-A1.

No additional substrates SHALL be introduced during this phase.




3. Scope
3.1 Immutable Track A Scalar Core
The canonical scalar persistence engine defined by ADR-001 SHALL remain:

   •    read-only,
   •    deterministic,
   •    and semantically immutable.

No Exploder, Builder, governance, schema, or metadata logic may mutate:

   •    scalar equations,
   •    parameter semantics,
   •    impedance bridge behavior,
   •    substrate interpretation,
   •    or forcing semantics.

All forcing values SHALL remain explicit runtime inputs.




3.2 Metallurgical Substrate Only
The sole substrate for MVP-A1 SHALL be:

C_Met

using cyclic forcing:
[
S_{\mathrm{eff,Met}}(t) = S_0 \sin(\omega t)
]

The metallurgical substrate is selected because:

   •   perturbation is measurable,
   •   hysteresis is observable,
   •   impedance growth is physically interpretable,
   •   and failure behavior is experimentally grounded.

No semantic, cognitive, organizational, symbolic, or multi-substrate coupling systems SHALL
be implemented during MVP-A1.




3.3 Initial Metallurgical Drift Tolerance
The metallurgical substrate tolerance SHALL initially be defined as:

[
\varepsilon_{\mathrm{Met}} = 0.10
]

This value:

   •   originates from the current RuntimeConfig default,
   •   is provisional,
   •   is implementation-level only,
   •   and SHALL NOT be interpreted as empirically calibrated metallurgy.

Any future modification to ε_Met SHALL require:

   •   explicit calibration rationale,
   •   updated validation tests,
   •   and ADR-level documentation.




3.4 Single Perturbation Family
MVP-A1 SHALL implement exactly one perturbation family:

AmplitudeRampPerturbation
The perturbation SHALL:

    •   operate deterministically,
    •   expose explicit bounds,
    •   preserve fixed-seed reproducibility,
    •   and declare all forcing values explicitly.

Additional perturbation families are deferred.




3.5 Canonical Artifact Emission
MVP-A1 SHALL emit exactly one valid:

ShrapnelMap

artifact.

The artifact SHALL include:

    •   tier,
    •   provenance,
    •   drift metrics,
    •   perturbation identifiers,
    •   tether tension,
    •   schema version,
    •   run identifier,
    •   substrate identifier,
    •   and executed perturbation manifest references.

Missing provenance or missing tier SHALL hard-fail validation.




3.6 Minimal RunManifest Requirement
MVP-A1 SHALL include a minimal:

RunManifest

schema artifact.

RunManifest SHALL minimally contain:

    •   run_id,
   •   substrate,
   •   planned_perturbation_cases,
   •   epsilon_met,
   •   required_coverage,
   •   fixed_seed,
   •   tier,
   •   provenance,
   •   and schema_version.

RunManifest SHALL be created before execution begins.




3.7 Tether Metric
The canonical tether metric SHALL be:

[
\tau =
\left(
\frac{\mathrm{coverage}}
{\mathrm{required_coverage}}
\right)
\times
\left(
1-
\frac{||\Delta_{\mathrm{drift}}||}
{\varepsilon_X}
\right)
]

Subject to:

   •   clamp(τ, 0.0, 1.0)
   •   hard-fail if ( ||\Delta_{\mathrm{drift}}|| \ge \varepsilon_X )

The tether metric SHALL function as:

   •   a governance gate,
       NOT:
   •   a metaphysical confidence score.
4. Operational Coverage Definition (MVP-
A1)
For MVP-A1, coverage SHALL be defined operationally as:

coverage =
executed_valid_perturbation_cases
/
planned_perturbation_cases

Coverage SHALL therefore represent:

   •   successful deterministic execution coverage,
       NOT:
   •   exhaustive perturbation-space exploration.

This definition is intentionally:

   •   discrete,
   •   finite,
   •   deterministic,
   •   and operationally computable.

Continuous parameter-space coverage estimation is deferred.




4.1 Coverage Locking Rule
The following governance constraint SHALL apply:

planned_perturbation_cases SHALL be declared in RunManifest prior to run
execution and SHALL NOT be modified after execution begins.

This rule exists to prevent:

   •   retrospective coverage inflation,
   •   post-run denominator manipulation,
   •   and governance drift.




5. Governance Constraints
MVP-A1 SHALL preserve the following constraints inherited from ADR-001 and ADR-002.




5.1 Fail-Closed Behavior
The system SHALL fail closed on:

   •   missing provenance,
   •   missing tier,
   •   invalid schema fields,
   •   invalid perturbation bounds,
   •   drift beyond ε_X,
   •   architecture-boundary violations,
   •   undeclared perturbation schedules,
   •   or invalid RunManifest state.

Silent coercion is prohibited.




5.2 Metadata Isolation
Prime signatures, symbolic identifiers, and metadata fields:

   •   SHALL remain metadata only,
   •   SHALL never drive ODE updates,
   •   SHALL never alter scalar evolution,
   •   SHALL never bypass governance rules,
   •   and SHALL never influence tether calculations.

Metadata is descriptive only.




5.3 Architecture Boundaries
The following architecture boundaries SHALL be enforced:

        Rule                                    Requirement
Core isolation       core may not import Exploder, Builder, governance, tether, or schemas
Exploder isolation Exploder may not mutate core
Governance isolation governance may not alter scalar state
Schema isolation     schemas may not import engines
        Rule                                     Requirement
Builder isolation     Builder may not directly modify production state
Metadata isolation    metadata may not drive scalar evolution

Boundary tests SHALL be implemented before expansion beyond MVP-A1.




6. Deferred Scope
The following are explicitly deferred until MVP-A1 is validated:

   •   additional perturbation families,
   •   Builder expansion,
   •   ResistanceCertificate generation,
   •   parameter-space coverage estimation,
   •   advanced telemetry infrastructure,
   •   semantic substrates,
   •   cognitive substrates,
   •   organizational substrates,
   •   Lane D analogues,
   •   interoperability bridges,
   •   multi-substrate coupling,
   •   adaptive perturbation scheduling,
   •   and autonomous Builder promotion logic.

Deferred scope SHALL NOT be implemented pre-emptively.




7. Success Criteria
MVP-A1 SHALL be considered complete when all of the following conditions are met.




Required Conditions
   •   one deterministic metallurgical Exploder run completes successfully,
   •   one valid ShrapnelMap artifact is emitted,
   •   one valid RunManifest artifact exists,
   •   tether τ computes deterministically,
   •   provenance is attached,
   •   tier is attached,
   •   architecture-boundary tests pass,
   •   no core contamination occurs,
   •   and coverage-locking rules remain intact throughout execution.




Optional Conditions
The following are optional during MVP-A1:

   •   CLI wrapper,
   •   RK4 integration,
   •   ResistanceCertificate support,
   •   advanced perturbation scheduling,
   •   and Builder proposal generation.




8. Consequences
Positive Consequences
   •   reduces execution-drift risk,
   •   constrains premature architecture expansion,
   •   improves inspectability,
   •   grounds the framework in measurable metallurgy,
   •   establishes an end-to-end governance validation loop,
   •   hardens architecture-boundary discipline early,
   •   and creates deterministic governance artifacts suitable for audit.




Negative Consequences
   •   slower feature expansion,
   •   delayed repository-scale implementation,
   •   limited early interoperability,
   •   intentionally reduced architectural ambition during MVP-A1,
   •   temporary restriction to a single perturbation family,
   •   and incomplete generality during the validation phase.

These constraints are accepted to preserve governance integrity.
9. Rationale
The project currently possesses:

   •   mature governance architecture,
   •   but pre-alpha engineering maturity.

A smaller verified metallurgy loop is therefore preferred over premature full-stack expansion.

The governing principle of MVP-A1 is:

One complete validated loop is more valuable than a partially implemented
architecture ecosystem.

This ADR intentionally prioritizes:

   •   determinism,
   •   governance enforcement,
   •   reproducibility,
   •   bounded complexity,
   •   operational auditability,
   •   and implementation discipline.

The objective is not rapid expansion.

The objective is:

   •   trustworthy architecture formation.




10. Related ADRs
     ADR                      Relationship
ADR-001        Defines immutable Track A scalar core
ADR-002        Defines Lane A governance boundaries
Future ADR-004 Reserved for additional perturbation families
Future ADR-005 Reserved for ResistanceCertificate expansion
Future ADR-006 Reserved for Builder proposal governance
11. Final Statement
ADR-003 establishes the minimum governed metallurgy validation loop required before broader
Lane A ecosystem expansion.

The purpose of MVP-A1 is not feature completeness.

The purpose is:

   •   governance verification,
   •   architecture-boundary enforcement,
   •   deterministic artifact generation,
   •   execution-drift prevention,
   •   operational validation of the Exploder/Tether pathway,
   •   and enforcement of immutable core boundaries.

Expansion beyond MVP-A1 SHALL occur only after the minimum loop has been validated end-
to-end.
