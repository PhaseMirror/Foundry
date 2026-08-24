---
title: "Machine-Checked Viability Thresholds for Buurtzorg-Style Care Circles in Multiplicity Social Physics"
authors:
  - Ryan Van Gelder
  - Tyler Van Osdol
  - Amy McCae
date: 2026-08-22
abstract: |
  We formalize Buurtzorg-style care-circle governance inside the Multiplicity
  Social Physics framework as executable Lean 4 specifications with
  machine-checked proofs, using exact fixed-point arithmetic (scale N = 1024)
  and zero external dependencies beyond core Lean. The development comprises
  two modules: a patient-nurse bond model (Option B) whose normalized coupling
  repairs a spec defect in the upstream formulation, and a viability-threshold
  module (Option A) proving resonance-floor, embodied-capacity, and
  complexity-cap obligations together with the governance guarantee that an
  audit-passing circle is burnout-free under the model's encoding. All nine
  audited theorems depend only on propext and Quot.sound; none depends on
  sorryAx. We state scope precisely: results are guarantees about the formal
  encoding, not clinical claims.
---

## 1. Introduction

The Buurtzorg model of decentralized, self-managing nursing teams has
attracted interest as an organizational design, but its operational rules are
usually stated qualitatively. This work gives those rules a machine-checked
formal reading within the Multiplicity Social Physics framework, with two
goals: (i) every threshold used by the governance layer is either proved or
explicitly marked as an unprovable modeling choice; (ii) the gap between
aggregate compliance checks and member-level failure is made a theorem rather
than a cautionary footnote.

All artifacts live in a single Lake project (`Prime`, toolchain
`leanprover/lean4:v4.33.0-rc1`) and build with `lake build`.

## 2. Option B: Patient-Nurse Bonds (`Care.lean`)

The upstream specification defines coupling as `gamma = p_p * p_n *
exp(-|p_p - p_n|)` and multiplicity as `M = 1 + 2*gamma*c`. Taken literally,
full trust at equal pressures yields `M(2,2) = 9`, contradicting the same
document's interpretation table, which caps M at 3. The formalization repairs
this by normalizing the coupling to `(min/max) * exp(-|p-n|)`, encoded in
exact integer arithmetic via truncated subtraction.

Core definitions:

- `multiplicityPN g c := Scale + 2 * ((g * c) / Scale)`, for trust `c`
  bounded by the subtype `{x : Nat // x <= Scale}`.
- `multiplicity_bounded : g <= Scale -> Scale <= multiplicityPN g c /\ 
  multiplicityPN g c <= 3 * Scale`.
- `affinity_le_scale : affinityPN g c <= Scale`, bounding the derived
  affinity measure.

Composition is lifted to circles by `circle_multiplicity_bounded`
(`CareViability`): three valid dyads aggregate into `[3N, 9N]`.

## 3. Option A: Circle Viability Thresholds (`ADR/Theorems/CareViability.lean`)

Triad vitals are subtypes `{x : Nat // x <= Scale}` carrying resonance `r`
and embodied capacity `e`; bounds therefore hold by construction rather than
by unchecked assumptions. Three thresholds are formalized over
`CircleVital := TriadVital x 3` (explicit fields):

1. **Resonance floor.** `rMeanPass c := 3 * 870 <= rSum c` encodes mean
   resonance >= 0.85 at scale N = 1024. `rMeanPass_iff_avg` proves this sum
   form equivalent to the literal average form `870 <= rSum / 3`.
2. **Embodied viability limit.** `viableE c := 0 < eSum c`;
   `viableE_iff_some_pos` proves positive aggregate capacity equivalent to
   some single triad retaining capacity.
3. **Hundian complexity cap.** Six normalized structural loads must satisfy
   `complexity L <= Scale`. `cap_of_sixths` gives a sufficient condition
   (every load <= floor(N/6) = 170, since 6*170 = 1020 <= 1024);
   `cap_violation_possible` shows the cap is non-trivial via a fully-loaded
   witness.

The binary audit mirrors the governance claim:

```
phase_mirror_audit c := decide (rMeanPass c) && decide (viableE c)
```

and the central result discharges it:

```
theorem viable_circle_prevents_burnout (c : CircleVital)
    (h : phase_mirror_audit c = true) : viableE c ∧ rMeanPass c
```

"Burnout-free" here means exactly the conjunction above; Section 6 delimits
scope.

### 3.1 The averaging blind spot

Aggregate thresholds can mask individual failure.
`averaging_blind_spot` is a machine-checked witness: resonance triple
`(1024, 869, 1024)` passes the mean floor (sum 2917 >= 2610) although the
second triad sits below the per-triad floor (869 < 870). The proof obligation
is discharged so the policy gap cannot be quietly forgotten; closing it
requires per-triad checks, which the current specification deliberately does
not impose.

### 3.2 Kernel-level instances

Three concrete circles are decided by kernel evaluation:

| Circle           | R (raw)     | E (raw)   | Audit | Failure mode    |
|------------------|-------------|-----------|-------|-----------------|
| `healthyCircle`  | 900/880/910 | 700/640/760  | pass | —            |
| `strainedCircle` | 800/790/810 | 400/380/420  | fail | resonance (2400 < 2610) |
| `depletedCircle` | 900/880/910 | 0/0/0        | fail | viability |

`depletedCircle` shares `healthyCircle`'s resonance profile exactly, isolating
capacity as the discriminating variable and making
`viable_circle_prevents_burnout` non-vacuous.

## 4. Trustworthiness of the Proofs

Axiom audit (`#print axioms`, current tree):

```
'PhaseMirror.Care.multiplicity_bounded' depends on axioms: [propext, Quot.sound]
'PhaseMirror.Care.affinity_le_scale' depends on axioms: [propext]
'PhaseMirror.CareViability.rMeanPass_iff_avg' depends on axioms: [propext]
'PhaseMirror.CareViability.viableE_iff_some_pos' depends on axioms: [propext, Quot.sound]
'PhaseMirror.CareViability.cap_of_sixths' depends on axioms: [propext, Quot.sound]
'PhaseMirror.CareViability.viable_circle_prevents_burnout' depends on axioms: [propext]
'PhaseMirror.CareViability.averaging_blind_spot' does not depend on any axioms
'PhaseMirror.CareViability.circle_multiplicity_bounded' depends on axioms: [propext, Quot.sound]
'PhaseMirror.CareViability.cap_violation_possible' depends on axioms: [propext, Quot.sound]
```

No theorem depends on `sorryAx`; `propext` and `Quot.sound` are Lean's
standard logical foundations. CI (`.github/workflows/build.yml`) rebuilds and
re-runs both a sorry-tactic scan over governed modules and this audit on every
push; both checks were validated locally before being committed.

## 5. Execution Layer

A Rust port (`materia_commons::care_viability`) mirrors the audit's integer
semantics for runtime use: identical constants (SCALE = 1024, RES_FLOOR = 870),
range-checked construction mirroring the Lean subtypes, unit tests pinned to
the three kernel-decided circles, and a four-quadrant governance mapping
(evolve / contract / monitor / intervene) with no abrupt-halt branch. The
module type-checks as an rlib; test execution requires a C toolchain absent
from the authoring environment and is deferred to CI. A Lean FFI bridge is
specified (export wrapper ABI documented in-source) but intentionally not
linked until a Lean staticlib exists.

## 6. Scope and Limitations

1. **Model claims only.** Theorems quantify over the encoding. "Prevents
   burnout" means `viableE ∧ rMeanPass` follows from the audit passing;
   nothing here establishes a clinical or organizational outcome.
2. **Aggregate vs.\ per-triad.** The specified audit is aggregate;
   `averaging_blind_spot` proves aggregates insufficient. Per-triad floors
   are future policy, not current guarantees.
3. **Cap arithmetic.** `cap_of_sixths` verifies arithmetic feasibility of
   workload budgets; whether real workloads respect them is empirical.
4. **Parameter provenance.** That 0.85 is the right floor, or six loads the
   right decomposition, is inherited from the source framework and not
   derived.
5. **Execution layer parity.** The Rust port preserves the encoding by
   construction and review, but cross-layer equivalence is currently a
   testing discipline, not a proved refinement.

## 7. Conclusion

Two governance options from the Multiplicity Social Physics alignment review
are now formal artifacts: a repaired patient-nurse bond calculus and a
three-threshold circle viability audit with its burnout-prevention guarantee,
all kernel-checked with minimal axiomatic footprint. The remaining distance
to practice is engineering (FFI linkage, per-triad policy adoption) rather
than logical gaps.

## References

Internal technical reports; publication status not established here.

[1] Van Gelder, R.O., Van Osdol, T., McCae, A. "Multiplicity Social Physics:
From Atomics to Cryptocurrency." Citizen Gardens technical report, 2026.

[2] Van Gelder, R.O. "The Universal Atomic Calculator." Citizen Gardens
technical report, 2025.

[3] Buurtzorg Nederland. Public materials on self-managing teams in community
care.
