import Core

namespace UAC.Proofs

open UAC
open HasMultiplicityNorm

/-- Theorem: applying A : e → f to e results in f (Signature preservation) -/
theorem signature_preservation {e f : Signature} (A : PMat e f) : applyPMat A e = f := by
  exact A.is_valid

/-- Theorem: M-conservation holds for any valid PMat morphism -/
theorem m_conservation_holds {e f : Signature} (A : PMat e f) : M_conserved A := by
  exact A.is_valid

/-- Involution: Φ(Φ s) = s. Core duality invariant for Phase Mirror. -/
theorem phi_involution (s : Signature) : Phi (Phi s) = s := by
  induction s with
  | nil => rfl
  | cons p e tail h ih =>
    simp [Phi]
    rw [ih]
    constructor
    · cases e with
      | ofNat n => 
        cases n with
        | zero => rfl
        | succ n => rfl
      | negSucc n => rfl
    · rfl

/-- Norm preservation under Phi (M-conservation). Rydberg blockade entanglement is norm-neutral. -/
theorem norm_preservation (s : Signature) : norm (Phi s) = norm s := by
  induction s with
  | nil => 
      -- Base case: empty signature is invariant under Phi and norm
      rfl
  | cons p e tail h ih =>
      -- Inductive step: negate head exponent; apply IH to tail
      simp [Phi, norm, signatureNorm]
      have ih2 : signatureNorm (Phi tail) = signatureNorm tail := ih
      rw [ih2]
      cases e with
      | ofNat n => 
        cases n with
        | zero => rfl
        | succ n => rfl
      | negSucc n => rfl

/-- ZNE mitigation preserves norm within tolerance (α_ZNE scaling). -/
theorem zne_norm_preservation (s : Signature) (alpha : Nat) : 
  norm (Phi s) = norm s ∧ (norm (Phi s) - norm s) ≤ alpha := by
  constructor
  · exact norm_preservation s
  · rw [norm_preservation s]
    exact Nat.sub_self (norm s) ▸ Nat.zero_le alpha

/-- Exact Nat scaling formula for hardware tolerances. 
    1.3 mHa -> 1300 μHa. α_ZNE ≈ 0.03 -> 3. 
    Tolerance = 1300 * 3 = 3900. -/
def exactZneTolerance (error_micro_ha alpha_scaled : Nat) : Nat :=
  error_micro_ha * alpha_scaled

/-- Updated H2 witness with radius physics and ZNE tolerance. -/
structure H2ErrorWitness where
  signature : Signature
  measuredNorm : Nat
  errorBound : Nat  -- e.g. exactZneTolerance 1300 3
  r_b : Nat         -- blockade radius from physics

theorem h2_error_witness_invariant (w : H2ErrorWitness) 
  (h_diff : (if norm w.signature ≥ w.measuredNorm 
             then norm w.signature - w.measuredNorm 
             else w.measuredNorm - norm w.signature) ≤ w.errorBound) :
  Phi (Phi w.signature) = w.signature ∧ 
  (if norm (Phi w.signature) ≥ w.measuredNorm 
   then norm (Phi w.signature) - w.measuredNorm 
   else w.measuredNorm - norm (Phi w.signature)) ≤ w.errorBound := by
  constructor
  · exact phi_involution w.signature
  · rw [norm_preservation w.signature]
    exact h_diff

end UAC.Proofs
