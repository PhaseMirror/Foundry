import Core

open UAC
open HasMultiplicityNorm

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

theorem norm_preservation (s : Signature) : norm (Phi s) = norm s := by
  induction s with
  | nil => rfl
  | cons p e tail h ih =>
    simp [Phi, norm, signatureNorm]
    have ih2 : signatureNorm (Phi tail) = signatureNorm tail := ih
    rw [ih2]
    cases e with
    | ofNat n => 
      cases n with
      | zero => rfl
      | succ n => rfl
    | negSucc n => rfl

theorem zne_norm_preservation (s : Signature) (alpha : Nat) : 
  norm (Phi s) = norm s ∧ (norm (Phi s) - norm s) ≤ alpha := by
  constructor
  · exact norm_preservation s
  · rw [norm_preservation s]
    exact Nat.sub_self (norm s) ▸ Nat.zero_le alpha

structure H2ErrorWitness where
  signature : Signature
  measuredNorm : Nat
  errorBound : Nat  -- incorporates R_b and ZNE α
  r_b : Nat         -- blockade radius from physics

theorem h2_error_witness_invariant (w : H2ErrorWitness) (h_norm : norm w.signature = w.measuredNorm) :
  Phi (Phi w.signature) = w.signature ∧ 
  norm (Phi w.signature) = w.measuredNorm ∧ 
  (if norm (Phi w.signature) ≥ w.measuredNorm 
   then norm (Phi w.signature) - w.measuredNorm 
   else w.measuredNorm - norm (Phi w.signature)) ≤ w.errorBound := by
  constructor
  · exact phi_involution w.signature
  · constructor
    · rw [norm_preservation w.signature, h_norm]
    · rw [norm_preservation w.signature, h_norm]
      have h : w.measuredNorm ≥ w.measuredNorm := Nat.le_refl _
      rw [if_pos h]
      exact Nat.sub_self w.measuredNorm ▸ Nat.zero_le w.errorBound
