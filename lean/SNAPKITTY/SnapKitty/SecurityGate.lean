/-
  Security Invariant: Fail-Closed Gate for RSA Mitigation
  ------------------------------------------------------
  This formalizes the governance requirement from ADR-111: any primitive
  identified as RSA (id = 0) is prohibited while the operator channel is in
  `GovernanceReview` mode. The ACE guardian (`crates/ace`) must verify
  `is_lawful_operation` before executing any operator word; on failure it
  raises `SIG_GOV_KILL` (Fail-Closed), per
  `docs/SOVEREIGN_SYNTHESIS_DEFENSIVE_PUBLICATION.md`.

  NOTE: the original sketch `rsa_governance_fail_closed` is not provable as
  written — `decide (is_lawful_operation s)` on a `match` returning `False`
  vs non-`False` does not `simp`, and `False.elim` has no target. The theorem
  below is provable and states the invariant directly on the predicate.
-/

namespace Multiplicity.Security

inductive SecurityMode where
  | Normal
  | GovernanceReview
  deriving DecidableEq, Repr

/-- Current state of the operator channel. -/
structure SecurityState where
  mode : SecurityMode
  primitive_id : Nat -- 0: RSA, 1: PrimeIndexed
  deriving DecidableEq, Repr

/--
  The core predicate for lawful operations.
  Any primitive identified as RSA (id = 0) results in a violation if the mode
  is `GovernanceReview`.
-/
def is_lawful_operation (s : SecurityState) : Prop :=
  match s.mode, s.primitive_id with
  | SecurityMode.GovernanceReview, 0 => False -- Fail-Closed: RSA primitive detected
  | SecurityMode.Normal, 0           => True  -- Legacy allowance
  | _, 1                             => True  -- PrimeIndexed is always lawful
  | _, _                             => True  -- Fallback default

/--
  The contractivity validator gate. Formal mirror of the Rust
  `validate_contraction_gate` in `crates/ace`.
-/
def validate_contraction_gate (s : SecurityState) : Bool :=
  decide (is_lawful_operation s)

/--
  The Fail-Closed invariant, stated directly on the predicate: no operation is
  lawful when the mode is `GovernanceReview` and the primitive is RSA.
-/
theorem rsa_governance_fail_closed
    (s : SecurityState)
    (h_mode : s.mode = SecurityMode.GovernanceReview)
    (h_rsa : s.primitive_id = 0) :
    ¬ is_lawful_operation s := by
  intro h_lawful
  rw [is_lawful_operation] at h_lawful
  rw [h_mode, h_rsa] at h_lawful
  exact h_lawful

/--
  The gate agrees with the predicate: it returns `false` exactly when the
  operation is unlawful (i.e. Review + RSA).
-/
theorem gate_iff_not_lawful (s : SecurityState) :
    validate_contraction_gate s = false ↔ ¬ is_lawful_operation s := by
  simp [validate_contraction_gate, decide_eq_false_iff, decide_eq_true_iff]

/--
  PrimeIndexed (id = 1) is always lawful, in any mode.
-/
theorem prime_indexed_always_lawful (s : SecurityState) (h : s.primitive_id = 1) :
    is_lawful_operation s := by
  rw [is_lawful_operation, h]

end Multiplicity.Security
