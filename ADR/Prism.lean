import ADR.Core
import ADR.Proofs

/-!
# ADR-0066: PrismPM / Langlands Prism — Zero-Sorry Semantic Model

This module formalizes the **semantic core** of ADR-0066 (PrismPM and Langlands
Prism) as a self-contained, zero-`sorry` Lean model that mirrors the fixed-point
governance gates implemented in `packages/rust/pirtm-engine`:

* `PIRTM` (the Clay) enforces **dynamical law**: recursive executions stay bounded
  inside a contractive manifold, `ρ(Λ) < 1 − ε`.
* `PrismPM` (the Kiln) enforces **process law**: artifacts are hermetic derivations
  of a locked semantic model.
* The **ACE veto gate** is *fail-closed*: any expansive state, non-contractive
  manifold, drift breach, or undischargeable semantic proof issues
  `SIG_GOV_KILL` and aborts the build (`SRC: docs/adr/accepted/0066` §"Pipeline
  Execution and The Veto Gate", §"Ensemble Manifest Structure").

All arithmetic is fixed-point `Nat` (scaled `u64`), mirroring
`packages/rust/pirtm-engine/src/ace.rs` and `src/tensor.rs`. Floating point is
strictly excluded, so every gate below is decidable and machine-checkable.

> **Deliberately minimal, yet extensible:** the "spectral radius bound" below is
> the row-sum (Gershgorin / ∞-norm-style) certificate on the fixed-point gain
> matrix. It is a *sufficient* certificate for contractivity (`ρ < 1`) and is used
> by construction in `verifyTransition`/`evalGate`. Replace this certificate with a
> full power-iteration spectral-radius computation inside a `@[implemented_by]`
> FFI later; every theorem that quantifies over `ContractiveCert` remains sound
> because the certificate is a conservative under-approximation of genericity.
-/

namespace ADR
namespace Prism

/-! ## 1. Fixed-Point Governance Constants
Mirrors `packages/rust/pirtm-engine/src/ace.rs` and `src/tensor.rs`.
-/

/-- Fixed-point unit scale: `1.0` is represented as `10^9 = 1_000_000_000`. -/
def CONTRACTIVITY_SCALE : Nat := 1_000_000_000

/-- Fixed-point contractivity epsilon `ε` (scaled): the 1−ε bound margin. -/
def CONTRACTIVITY_EPSILON_SCALED : Nat := 1_000_000

/-- The contractivity limit `(1 − ε) · scale = 999_000_000`; `ρ(Λ) < 1 − ε`
in scaled units. Written as a literal numeral so every `omega` goal below is
ground-decidable (given as a definitional identity with `scale − ε`). -/
def CONTRACTIVITY_LIMIT_SCALED : Nat := 999_000_000

/-- The contractivity limit satisfies the nominal definition `(1 − ε) · scale`:
`999_000_000 = 1_000_000_000 − 1_000_000`. -/
@[proof]
theorem limit_is_scale_minus_epsilon :
    CONTRACTIVITY_LIMIT_SCALED = CONTRACTIVITY_SCALE - CONTRACTIVITY_EPSILON_SCALED := by
  native_decide

/-- The contractivity limit is strictly below unity: `LIMIT < SCALE`. -/
@[proof]
theorem limit_lt_scale : CONTRACTIVITY_LIMIT_SCALED < CONTRACTIVITY_SCALE := by
  decide

/-- Bounded drift allowance (`DRIFT_LIMIT_SCALED = 30_000_000`). -/
def DRIFT_LIMIT_SCALED : Nat := 30_000_000

/-! ## 2. Fixed-Point Gain Matrix and Contractivity Certificate -/

/-- A 2×2 fixed-point gain matrix `Ψ` representing the recursive transition
between the `Add` (p=2) and `Multiply` (p=3) overlay operations. Entries are
elementwise non-negative scaled integers. -/
structure GainMatrix where
  /-- `Ψ₁₁` — self-gain of the additive (p=2) axis. -/
  a : Nat
  /-- `Ψ₁₂` — cross-gain from multiplicative (p=3) to additive axis. -/
  b : Nat
  /-- `Ψ₂₁` — cross-gain from additive to multiplicative axis. -/
  c : Nat
  /-- `Ψ₂₂` — self-gain of the multiplicative (p=3) axis. -/
  d : Nat
  deriving DecidableEq, Repr, Inhabited

/-- Scaled row-sum bound: `‖Ψ‖₊ = max(row₁, row₂)`, an ∞-norm-style certificate
bounding the spectral radius `ρ(Ψ)` (Gershgorin). In scaled `Nat`, `ρ < 1 − ε`
is re-expressed as `‖Ψ‖₊ < (1 − ε)·scale`. -/
def rowSumInf (M : GainMatrix) : Nat :=
  max (M.a + M.b) (M.c + M.d)

/-- The contractivity certificate: `‖Ψ‖₊ < (1 − ε)·scale`.
Sound because `ρ(Ψ) ≤ ‖Ψ‖₊` for non-negative entries (Gershgorin discs). -/
def ContractiveCert (M : GainMatrix) : Prop :=
  rowSumInf M < CONTRACTIVITY_LIMIT_SCALED

/-- The prime-indexed tensor overlay of `prism-calculator` operations
(ADR-0066 §"Semantic and Dimensional Mapping"): `Add → p₁ = 2`, `Multiply → p₂ = 3`. -/
inductive PrismOperation where
  | Add : PrismOperation
  | Multiply : PrismOperation
  deriving DecidableEq, Repr, Inhabited

/-- Prime index onto which a `PrismOperation` is injected. -/
def primeIndex : PrismOperation → Nat
  | .Add => 2
  | .Multiply => 3

@[proof]
theorem additive_prime_index : primeIndex .Add = 2 := by
  rfl

@[proof]
theorem multiplicative_prime_index : primeIndex .Multiply = 3 := by
  rfl

/-! ## 3. The Fail-Closed Veto Gate (`SIG_GOV_KILL`) -/

/-- The four `SIG_GOV_KILL` discriminants mandated by ADR-0066.
Mirrors `packages/rust/pirtm-engine/src/ace.rs` `enum SigGovKill`. -/
inductive SigGovKill where
  /-- `ρ(Ψ) ≥ 1 − ε`: spectral radius breached the contractivity bound. -/
  | ExpansiveState : SigGovKill
  /-- `Λ_m ≥ 1.0`: fixed-point contractivity invariant exceeded (band case). -/
  | NonContractiveLambda : SigGovKill
  /-- Execution drift exceeded the bounded drift allowance. -/
  | DriftBreach : SigGovKill
  /-- The semantic (PrismPM/LexLean) model was not provably valid. -/
  | SemanticProofInvalid : SigGovKill
  deriving DecidableEq, Repr, Inhabited

/-- Outcome of the governance gate: `ok` (transition admitted) or `kill` with the
precise discriminant (transition vetoed). Analogous to Rust `Result<(), SigGovKill>`. -/
inductive GateOutcome where
  | ok : GateOutcome
  | kill : SigGovKill → GateOutcome
  deriving DecidableEq, Repr, Inhabited

/-- The *provably safe* governance state: contractive manifold, bounded drift, and a
dischargeable semantic proof. This is the formal counterpart of the ADR-0066 mandate
that transitions must clear "both PrismPM's semantic proofs and PIRTM's mathematical
contractivity bounds" before ejection. -/
def Governable (M : GainMatrix) (d : Nat) (sp : Bool) : Prop :=
  ContractiveCert M ∧ d ≤ DRIFT_LIMIT_SCALED ∧ sp = true

/-- **The ACE governance gate** (mirrors `evaluate_ace_governance_gate` +
`verify_transition`):
1. `‖Ψ‖₊ ≥ scale` (`Λ_m ≥ 1.0`) → `ExpansiveState`;
2. `LIMIT ≤ ‖Ψ‖₊ < scale` (band where `ρ ≥ 1 − ε` is not provably below) → `NonContractiveLambda`;
3. `drift > DRIFT_LIMIT_SCALED` → `DriftBreach`;
4. semantic proof undischargeable (`¬ sp`) → `SemanticProofInvalid`;
5. otherwise `ok`.

Every comparison is between scaled `Nat`s, making the gate fully deterministic —
the exact property the Kani BMC harnesses verify for the Rust implementation. -/
def evalGate (M : GainMatrix) (d : Nat) (sp : Bool) : GateOutcome :=
  if CONTRACTIVITY_SCALE ≤ rowSumInf M then
    GateOutcome.kill SigGovKill.ExpansiveState
  else if CONTRACTIVITY_LIMIT_SCALED ≤ rowSumInf M then
    GateOutcome.kill SigGovKill.NonContractiveLambda
  else if DRIFT_LIMIT_SCALED < d then
    GateOutcome.kill SigGovKill.DriftBreach
  else if !sp then
    GateOutcome.kill SigGovKill.SemanticProofInvalid
  else
    GateOutcome.ok

/-- The semantic-model gate of ADR-0066 §"Pipeline Execution and The Veto Gate":
a semantically-valid PrismPM model is admitted only if the lifted gain matrix is
strictly contractive. Mirrors `verify_transition`. -/
def verifyTransition (M : GainMatrix) (semanticProofValid : Bool) : GateOutcome :=
  if semanticProofValid then
    if CONTRACTIVITY_LIMIT_SCALED ≤ rowSumInf M then
      GateOutcome.kill SigGovKill.ExpansiveState
    else
      GateOutcome.ok
  else
    GateOutcome.kill SigGovKill.SemanticProofInvalid

/-! ## 4. Gate Soundness (Zero-`sorry` Theorems) -/

/-- **OK implies Safe.** An admitted configuration is provably `Governable`:
the gate has no unsound approvals. -/
theorem evalGate_cert_of_ok (M : GainMatrix) (d : Nat) (sp : Bool)
    (hok : evalGate M d sp = GateOutcome.ok) : Governable M d sp := by
  by_cases h1 : CONTRACTIVITY_SCALE ≤ rowSumInf M
  · have hk : evalGate M d sp = GateOutcome.kill SigGovKill.ExpansiveState := by
      unfold evalGate
      rw [ite_eq_left h1]
    rw [hk] at hok
    contradiction
  · by_cases h2 : CONTRACTIVITY_LIMIT_SCALED ≤ rowSumInf M
    · have hk : evalGate M d sp = GateOutcome.kill SigGovKill.NonContractiveLambda := by
        unfold evalGate
        rw [ite_eq_right h1, ite_eq_left h2]
      rw [hk] at hok
      contradiction
    · by_cases h3 : DRIFT_LIMIT_SCALED < d
      · have hk : evalGate M d sp = GateOutcome.kill SigGovKill.DriftBreach := by
          unfold evalGate
          rw [ite_eq_right h1, ite_eq_right h2, ite_eq_left h3]
        rw [hk] at hok
        contradiction
      · by_cases h4 : sp = true
        · unfold Governable ContractiveCert
          constructor
          · exact Nat.lt_of_not_ge h2
          constructor
          · exact Nat.le_of_not_gt h3
          · exact h4
        · have hsp : sp = false := by
            cases sp <;> simp at h4 ⊢
          have hk : evalGate M d sp = GateOutcome.kill SigGovKill.SemanticProofInvalid := by
            unfold evalGate
            simp [h1, h2, h3, hsp]
          rw [hk] at hok
          contradiction

/-- **Fail-closed.** A configuration that is not provably `Governable` is never
admitted — there are no false negatives. This is the formal counterpart of the
Kani `contractivity_gate_is_fail_closed` / `adversarial_gain_is_vetoed_despite_valid_semantics`
harnesses. -/
theorem gate_vetoes_unsafe (M : GainMatrix) (d : Nat) (sp : Bool)
    (h : ¬ Governable M d sp) : evalGate M d sp ≠ GateOutcome.ok := by
  intro hok
  exact h (evalGate_cert_of_ok M d sp hok)

/-- Safe implies OK: every provably `Governable` configuration passes the gate. -/
theorem evalGate_ok_of_governable (M : GainMatrix) (d : Nat) (sp : Bool)
    (h : Governable M d sp) : evalGate M d sp = GateOutcome.ok := by
  rcases h with ⟨hcert, hd, hsp⟩
  unfold evalGate
  unfold ContractiveCert at hcert
  have h1 : ¬ CONTRACTIVITY_SCALE ≤ rowSumInf M :=
    Nat.not_le_of_gt (Nat.lt_trans hcert limit_lt_scale)
  have h2 : ¬ CONTRACTIVITY_LIMIT_SCALED ≤ rowSumInf M :=
    Nat.not_le_of_gt hcert
  have h3 : ¬ DRIFT_LIMIT_SCALED < d := Nat.not_lt_of_ge hd
  simp [h1, h2, h3, hsp]

/-! ### 4.1 Per-Discriminant Veto Proofs -/

/-- An expansive state (`‖Ψ‖₊ ≥ scale`, i.e. `ρ(Ψ) ≥ 1.0` in scaled units) is vetoed. -/
theorem expansive_killed (M : GainMatrix) (d : Nat) (sp : Bool)
    (h : CONTRACTIVITY_SCALE ≤ rowSumInf M) :
    evalGate M d sp = GateOutcome.kill SigGovKill.ExpansiveState := by
  unfold evalGate
  rw [ite_eq_left h]

/-- The contractivity band case (`1 − ε ≤ ρ < 1` in scaled units): not provably
below the `1 − ε` limit, fail-closed to `NonContractiveLambda`. -/
theorem non_contractive_killed (M : GainMatrix) (d : Nat) (sp : Bool)
    (h1 : CONTRACTIVITY_LIMIT_SCALED ≤ rowSumInf M)
    (h2 : rowSumInf M < CONTRACTIVITY_SCALE) :
    evalGate M d sp = GateOutcome.kill SigGovKill.NonContractiveLambda := by
  unfold evalGate
  have hn1 : ¬ CONTRACTIVITY_SCALE ≤ rowSumInf M := Nat.not_le_of_gt h2
  rw [ite_eq_right hn1, ite_eq_left h1]

/-- A drift breach (`drift > DRIFT_LIMIT_SCALED`) is vetoed, independently of how
well-contracted the manifold is. -/
theorem drift_killed (M : GainMatrix) (d : Nat) (sp : Bool)
    (hcert : ContractiveCert M) (h : DRIFT_LIMIT_SCALED < d) :
    evalGate M d sp = GateOutcome.kill SigGovKill.DriftBreach := by
  unfold evalGate
  unfold ContractiveCert at hcert
  have h1 : ¬ CONTRACTIVITY_SCALE ≤ rowSumInf M :=
    Nat.not_le_of_gt (Nat.lt_trans hcert limit_lt_scale)
  rw [ite_eq_right h1]
  have h2 : ¬ CONTRACTIVITY_LIMIT_SCALED ≤ rowSumInf M :=
    Nat.not_le_of_gt hcert
  rw [ite_eq_right h2, ite_eq_left h]

/-- An undischargeable semantic proof is vetoed even when the manifold is
contractive and drift is within bounds (PrismPM's process law, fail-closed). -/
theorem semantic_proof_killed (M : GainMatrix) (d : Nat)
    (hcert : ContractiveCert M) (hd : d ≤ DRIFT_LIMIT_SCALED) :
    evalGate M d false = GateOutcome.kill SigGovKill.SemanticProofInvalid := by
  unfold evalGate
  unfold ContractiveCert at hcert
  have h1 : ¬ CONTRACTIVITY_SCALE ≤ rowSumInf M :=
    Nat.not_le_of_gt (Nat.lt_trans hcert limit_lt_scale)
  rw [ite_eq_right h1]
  have h2 : ¬ CONTRACTIVITY_LIMIT_SCALED ≤ rowSumInf M :=
    Nat.not_le_of_gt hcert
  rw [ite_eq_right h2]
  have h3 : ¬ DRIFT_LIMIT_SCALED < d := Nat.not_lt_of_ge hd
  rw [ite_eq_right h3]
  rfl

/-! ### 4.2 `verifyTransition` (Pipeline Veto Gate) -/

/-- `verifyTransition` vetoes an undischargeable semantic proof. -/
theorem verify_kills_invalid_proof (M : GainMatrix) (sp : Bool) (hsp : sp = false) :
    verifyTransition M sp = GateOutcome.kill SigGovKill.SemanticProofInvalid := by
  unfold verifyTransition
  rw [hsp]
  rfl

/-- `verifyTransition` vetoes an expansive manifold even though semantics passed
(ADR-0066 "Adversarial Falsification": PrismPM compiles, PIRTM vetoes). -/
theorem verify_kills_expansive (M : GainMatrix)
    (h : CONTRACTIVITY_LIMIT_SCALED ≤ rowSumInf M) :
    verifyTransition M true = GateOutcome.kill SigGovKill.ExpansiveState := by
  unfold verifyTransition
  change (if CONTRACTIVITY_LIMIT_SCALED ≤ rowSumInf M then
            GateOutcome.kill SigGovKill.ExpansiveState else GateOutcome.ok) =
          GateOutcome.kill SigGovKill.ExpansiveState
  rw [ite_eq_left h]

/-- `verifyTransition` admits a contractive manifold with valid semantics. -/
theorem verify_ok_of_contractive (M : GainMatrix) (sp : Bool) (hsp : sp = true)
    (hcert : ContractiveCert M) :
    verifyTransition M sp = GateOutcome.ok := by
  unfold verifyTransition
  unfold ContractiveCert at hcert
  rw [hsp]
  change (if CONTRACTIVITY_LIMIT_SCALED ≤ rowSumInf M then
            GateOutcome.kill SigGovKill.ExpansiveState else GateOutcome.ok) =
          GateOutcome.ok
  rw [ite_eq_right (Nat.not_le_of_gt hcert)]

/-! ### 4.3 Contractivity Certificate Properties (Property-Based) -/

/-- The row-sum certificate is antitone: a pointwise-smaller gain matrix with a
contractive certificate stays contractive. This is the "stricter bound, still safe"
property exercised by `tests/property_contractivity_equivalence.rs` in Rust. -/
theorem contractive_antitone (A B : GainMatrix)
    (ha : A.a ≤ B.a) (hb : A.b ≤ B.b) (hc : A.c ≤ B.c) (hd : A.d ≤ B.d)
    (hBl : ContractiveCert B) : ContractiveCert A := by
  unfold ContractiveCert at *
  have hsum1 : A.a + A.b ≤ B.a + B.b := Nat.add_le_add ha hb
  have hsum2 : A.c + A.d ≤ B.c + B.d := Nat.add_le_add hc hd
  have hrow : rowSumInf A ≤ rowSumInf B := by
    unfold rowSumInf
    by_cases hxy : A.a + A.b ≤ A.c + A.d
    · rw [Nat.max_eq_right hxy]
      exact Nat.le_trans hsum2 (Nat.le_max_right (B.a + B.b) (B.c + B.d))
    · have hyx : A.c + A.d ≤ A.a + A.b := Nat.le_of_lt (Nat.lt_of_not_ge hxy)
      rw [Nat.max_eq_left hyx]
      exact Nat.le_trans hsum1 (Nat.le_max_left (B.a + B.b) (B.c + B.d))
  omega

/-- **Property test (∀-sweep).** Across *every* 2×2 fixed-point gain matrix, a
dominant diagonal entry at or above unity is never admitted by the gate. -/
theorem dominant_entry_never_admitted (a b c d : Nat)
    (h : CONTRACTIVITY_SCALE ≤ a) :
    evalGate ⟨a, b, c, d⟩ 0 true ≠ GateOutcome.ok := by
  intro hok
  have hcert := evalGate_cert_of_ok ⟨a, b, c, d⟩ 0 true hok
  rcases hcert with ⟨hcert, _, _⟩
  unfold ContractiveCert at hcert
  have hinfl : CONTRACTIVITY_SCALE ≤ rowSumInf ⟨a, b, c, d⟩ := by
    unfold rowSumInf
    exact Nat.le_trans h (Nat.le_trans (Nat.le_add_right a b) (Nat.le_max_left (a + b) (c + d)))
  have hlt : CONTRACTIVITY_LIMIT_SCALED < CONTRACTIVITY_SCALE := limit_lt_scale
  omega

/-! ## 5. Concrete Governance Instances (mirroring the Rust/Kani harness) -/

/-- The ADR-0066 adversarial `2×2` gain matrix `[[1, 0.5], [0.5, 1]]` in scaled
units (`Λ_m = 1.5`, `ρ ≥ 1 − ε`): the pipeline must veto it even though
semantics are valid. Mirrors `prism_interop_harness.rs`. -/
def adversarialGain : GainMatrix :=
  ⟨CONTRACTIVITY_SCALE, CONTRACTIVITY_SCALE / 2, CONTRACTIVITY_SCALE / 2, CONTRACTIVITY_SCALE⟩

/-- A docile, strictly contractive gain matrix `[[0.5, 0], [0, 0.5]]`:
`‖Ψ‖₊ = 0.5 < 1 − ε`, admitted. -/
def safeGain : GainMatrix :=
  ⟨CONTRACTIVITY_SCALE / 2, 0, 0, CONTRACTIVITY_SCALE / 2⟩

/-- A boundary matrix pinned exactly to the `1 − ε` band: `‖Ψ‖₊ = LIMIT`,
i.e. `ρ ≥ 1 − ε` but `< 1.0` → `NonContractiveLambda`. -/
def bandGain : GainMatrix :=
  ⟨CONTRACTIVITY_LIMIT_SCALED / 2, CONTRACTIVITY_LIMIT_SCALED / 2, 0, 0⟩

@[proof]
theorem adversarial_gain_vetoed_expansive :
    evalGate adversarialGain 0 true = GateOutcome.kill SigGovKill.ExpansiveState := by
  decide

@[proof]
theorem adversarial_gain_vetoed_despite_valid_semantics :
    evalGate adversarialGain 0 true ≠ GateOutcome.ok := by
  decide

@[proof]
theorem safe_gain_admitted :
    evalGate safeGain 0 true = GateOutcome.ok := by
  decide

@[proof]
theorem band_gain_non_contractive :
    evalGate bandGain 0 true = GateOutcome.kill SigGovKill.NonContractiveLambda := by
  decide

@[proof]
theorem drift_breach_vetoed :
    evalGate safeGain (DRIFT_LIMIT_SCALED + 1) true = GateOutcome.kill SigGovKill.DriftBreach := by
  decide

@[proof]
theorem semantic_proof_gap_vetoed :
    evalGate safeGain 0 false = GateOutcome.kill SigGovKill.SemanticProofInvalid := by
  decide

/-! ## 6. ADR-0066 Record and Governance Invariants -/

/-- ADR-0066 "PrismPM and Langlands Prism", transcribed as an `ADR` record.
Status `Accepted` per `docs/adr/accepted/0066-PrismPM and Langlands Prism.md`. -/
@[adr]
def ADR_0066 : ADR :=
  { id := "ADR-0066"
    title := "PrismPM and Langlands Prism"
    status := ADRStatus.Accepted
    context := "PrismPM is the model-to-artifact factory (the Kiln): it compiles formal .lex.tex models into hermetic artifacts and strictly prohibits unverified handwritten code. PIRTM is the prime-indexed tensor runtime (the Clay) that enforces dynamical law and refuses to compile operations that violate the spectral limit r(Λ) < 1−ε. Two adjacent governance compilers, one governing process law, the other governing dynamical law; a transition is ejected only after clearing both."
    decision := "Adopt the PrismPM/PIRTM synthesis: artifact transitions are admitted by the ACE veto gate only when PrismPM semantic proofs are dischargeable AND the lifted gain matrix is strictly contractive (r(Λ) < 1−ε) AND drift stays within its allotted bound. Operations Add and Multiply are mapped onto the prime-indexed tensor overlay as p=2 and p=3 respectively."
    consequences := [
      "Semantic and dimensional mapping: prism-calculator operations (Add, Multiply) are defined logically for zero-sorry PrismPM proofs and injected onto the prime-indexed tensor overlay (Add → p=2, Multiply → p=3).",
      "The ACE veto gate is fail-closed: any expansive state, non-contractive manifold, drift breach, or undischargeable semantic proof issues SIG_GOV_KILL and aborts the build (SIG_GOV_KILL).",
      "Universal BCS packing with fixed field order, no floats (fixed-point scaled integers only), and length-prefixed sequences yields a deterministic, symbolically model-checkable ensemble manifest wire format.",
      "Phase D resumption binds the BCS gap payload's crmf_validity_seal inside the signed request, authenticated by two distinct Ed25519 authorities (K1 ≠ K2) for anti-self-dealing and Sybil resistance."
    ]
    supersedes := none
    links := [
      ⟨"0066-PrismPM and Langlands Prism", .SpecificationDoc, "Source ADR (docs/adr/accepted/0066-PrismPM and Langlands Prism.md)"⟩
      , ⟨"packages/rust/pirtm-engine", .SourceFile, "PIRTM engine (prism gate, ensemble manifest, Phase D recovery)"⟩
      , ⟨"packages/rust/pirtm-engine/tests/prism_interop_harness.rs", .SourceFile, "Kani adversarial veto harness"⟩
    ] }

@[proof]
theorem adr0066_accepted : ADR_0066.status = ADRStatus.Accepted := by
  rfl

/-- Once Accepted, ADR-0066 cannot transition back to Proposed (immutability of
accepted decisions, `ADR.Proofs.accepted_cannot_revert_to_proposed`). -/
@[proof]
theorem adr0066_accepted_no_revision (w : Option ADRId)
    (h : ValidTransition .Accepted .Proposed w) : False :=
  accepted_cannot_revert_to_proposed w h

/-- ADR-0066 has no supersession edge to any parent: the singleton supersession
graph contains no cycles. -/
@[proof]
theorem adr0066_no_supersede_edge (parent : ADRId) :
    ¬ SupersedesRel [ADR_0066] "ADR-0066" parent := by
  rintro ⟨a, ham, haid, hasup⟩
  have haeq : a = ADR_0066 := List.mem_singleton.mp ham
  subst a
  simp [ADR_0066] at hasup

/-- **No circular supersession (ADR-0066):** `StrictAcyclic [ADR_0066]`. -/
@[proof]
theorem adr0066_acyclic : StrictAcyclic [ADR_0066] := by
  intro id h
  rcases h with ⟨parent, hrel, _⟩
  by_cases hid : id = "ADR-0066"
  · subst id
    exact adr0066_no_supersede_edge parent hrel
  · rcases hrel with ⟨a, ham, haid, hasup⟩
    have haeq : a = ADR_0066 := List.mem_singleton.mp ham
    subst a
    exact hid (by simpa [ADR_0066] using haid.symm)

/-- The singleton registry containing ADR-0066 satisfies every `ADRRegistry`
invariant: unique ids, acyclicity, supersession hygiene, no conflicts, coherent
claims. -/
def ADR_0066_Registry : ADRRegistry :=
  { adrs := [ADR_0066]
    uniqueIds := by decide
    acyclic := adr0066_acyclic
    supersedesExist := by
      intro a ha sid hs
      have haeq : a = ADR_0066 := List.mem_singleton.mp ha
      subst a
      simp [ADR_0066] at hs
    supersededStatusConsistent := by
      intro a ha sid hs
      have haeq : a = ADR_0066 := List.mem_singleton.mp ha
      subst a
      simp [ADR_0066] at hs
    noConflicts := by
      intro a ha b hb hc
      have haeq : a = ADR_0066 := List.mem_singleton.mp ha
      have hbeq : b = ADR_0066 := List.mem_singleton.mp hb
      subst haeq hbeq
      rcases hc with ⟨hne, _, _, _⟩
      exact hne rfl
    claims := []
    claimsOwnedByAccepted := by
      intro c hc
      simp at hc
    noClaimConflicts := by
      intro c₁ hc₁ c₂ hc₂ hne
      simp at hc₁
  }

/-- **Traceability:** the accepted ADR-0066 possesses a reconstructible provenance
path in its registry (`ADR.Proofs.registry_self_traceable`). -/
@[proof]
theorem adr0066_traceable : ProvenancePath [ADR_0066] "ADR-0066" "ADR-0066" := by
  exact registry_self_traceable ADR_0066_Registry ADR_0066 (by native_decide)

/-! ## 7. Consequence Entailment via the Embedded Logic (`PropTerm`/`Entails`)

The consequences of ADR-0066 are discharged as *logical consequences* of the
decision and context using the embedded propositional logic of `ADR.Core`
(`Entails`). This is the machine-checked counterpart of the human-readable
consequence list in §6: each consequence below is *derived*, never asserted.
-/

/-- The decision's contract, lifted to the embedded propositional logic:
adopt PIRTM, adopt PrismPM, and mandate the contractivity certificate. -/
def adr0066DecisionProp : PropTerm :=
  .and (.atom "adoptPIRTM") (.and (.atom "adoptPrismPM") (.atom "mandateContractivity"))

/-- Left-elimination for a single conjunctive premise. -/
theorem and_elim_left_gate {p q : PropTerm} : Entails [.and p q] p := by
  intro env hprem
  rcases hprem (.and p q) (by simp) with ⟨hp, _⟩
  exact hp

/-- Right-elimination for a single conjunctive premise. -/
theorem and_elim_right_gate {p q : PropTerm} : Entails [.and p q] q := by
  intro env hprem
  rcases hprem (.and p q) (by simp) with ⟨_, hq⟩
  exact hq

/-- **Consequence: Dynamical Law.** The contractivity mandate entails the
contractive-manifold consequence by modus ponens
(`ADR.Proofs.entailment_modus_ponens`). -/
@[proof]
theorem adr0066_contractivity_entailed :
    Entails [.atom "mandateContractivity", .implies (.atom "mandateContractivity") (.atom "contractiveManifold")]
            (.atom "contractiveManifold") :=
  entailment_modus_ponens _ _

/-- **Consequence: Dual Compilers.** Adopting PIRTM *and* adopting PrismPM entails
their conjunctive governance obligation (`ADR.Proofs.entailment_and_intro`). -/
@[proof]
theorem adr0066_dual_governance_entailed :
    Entails [.atom "adoptPIRTM", .atom "adoptPrismPM"]
            (.and (.atom "adoptPIRTM") (.atom "adoptPrismPM")) :=
  entailment_and_intro _ _

/-- **Consequence: PIRTM Commitment.** The decision conjunctively commits to
PIRTM, discharged by left-elimination on `adr0066DecisionProp`. -/
@[proof]
theorem adr0066_pirmt_commitment :
    Entails [adr0066DecisionProp] (.atom "adoptPIRTM") := by
  simpa [adr0066DecisionProp]
    using (and_elim_left_gate (p := .atom "adoptPIRTM")
      (q := .and (.atom "adoptPrismPM") (.atom "mandateContractivity")))

/-- **Consequence: Contractivity Commitment.** The decision conjunctively commits
to the contractivity certificate, discharged by nested right-elimination on
`adr0066DecisionProp`. -/
@[proof]
theorem adr0066_contractivity_commitment :
    Entails [adr0066DecisionProp] (.atom "mandateContractivity") := by
  intro env hprem
  rcases hprem adr0066DecisionProp (by simp [adr0066DecisionProp]) with ⟨_, hbc⟩
  rcases hbc with ⟨_, hc⟩
  exact hc

/-! ## 8. Intentional Failure Cases (Type System Catches Them)

These `example` blocks are *supposed* to be rejected by the type system. They are
commented out deliberately: re-enabling any of them must fail to compile, which is
the working proof that the model is not vacuous.
-/

--    example : evalGate safeGain 0 true ≠ GateOutcome.ok := by
--      decide    -- FALSE: safeGain is provably admitted — this must NOT compile.

--    example : ¬ Governable safeGain 0 true := by
--      decide    -- FALSE: safeGain is provably Governable — this must NOT compile.

end Prism
end ADR