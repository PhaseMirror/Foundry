import GRIMS.Core

/-! # Prime-Indexed Recursive Tensor Mathematics (PIRTM)

Block-diagonal prime-indexed updates, the composite global operator `U = R ∘ UΠ ∘ D`,
and the contractiveness condition from ADR-0042 §A.5. -/

namespace GRIMS

variable {K : Type*} [LinearOrderedField K]

/-- A per-prime update operator `Uₚ : Sₚ → Sₚ` with a supplied operator-norm bound. -/
structure PrimeIndexedUpdate (S : Type*) [AddGroup S] [SMul K S] [NormedSpace S K]
  (P : Type*) (Sp : P → Type*) [∀ p, AddGroup (Sp p)] [∀ p, SMul K (Sp p)]
  [∀ p, NormedSpace (Sp p) K] (d : Decomposition S P Sp) where
  Up : (p : P) → Sp p → Sp p
  opNormUp : (p : P) → K
  opNormUp_nonneg : ∀ p, 0 ≤ opNormUp p
  Up_bound : ∀ p (z : Sp p), norm (Up p z) ≤ opNormUp p * norm z
  -- Supremum of the per-prime operator norms over the deployed prime list.
  L : K
  L_nonneg : 0 ≤ L
  L_bound : ∀ p, p ∈ d.ps → opNormUp p ≤ L

/-- Block-diagonal application `(UΠ x)ₚ = Uₚ(xₚ)`. -/
def blockDiag {S : Type*} [AddGroup S] [SMul K S] [NormedSpace S K]
  {P : Type*} {Sp : P → Type*} [∀ p, AddGroup (Sp p)] [∀ p, SMul K (Sp p)]
  [∀ p, NormedSpace (Sp p) K] {d : Decomposition S P Sp}
  (u : PrimeIndexedUpdate S P Sp d) (x : (p : P) → Sp p) (p : P) : Sp p :=
  u.Up p (x p)

/-- Block-diagonal operator norm bound: `‖UΠ‖ ≤ L`. -/
theorem blockDiag_norm_le {S : Type*} [AddGroup S] [SMul K S] [NormedSpace S K]
  {P : Type*} {Sp : P → Type*} [∀ p, AddGroup (Sp p)] [∀ p, SMul K (Sp p)]
  [∀ p, NormedSpace (Sp p) K] {d : Decomposition S P Sp}
  (u : PrimeIndexedUpdate S P Sp d) (x : (p : P) → Sp p) :
    prodNorm d.ps (fun p => blockDiag u x p) ≤ u.L * prodNorm d.ps x := by
  simp only [prodNorm, blockDiag]
  apply List.sum_le_sum
  · intro p hp; exact u.Up_bound p (x p)
  · apply List.sum_le_sum
    · intro p hp; apply mul_le_mul_of_nonneg_right (u.L_bound p hp) (NormedSpace.norm_nonneg (x p))
    · rw [← List.sum_map_mul_left, mul_comm]
      simp only [prodNorm]

/-- Composite global update `U(x) = R(UΠ(D x))`. -/
def composedUpdate {S : Type*} [AddGroup S] [SMul K S] [NormedSpace S K]
  {P : Type*} {Sp : P → Type*} [∀ p, AddGroup (Sp p)] [∀ p, SMul K (Sp p)]
  [∀ p, NormedSpace (Sp p) K] {d : Decomposition S P Sp}
  (u : PrimeIndexedUpdate S P Sp d) (x : S) : S :=
  d.R (fun p => blockDiag u (d.D x) p)

/-- Global operator-norm bound `‖U‖ ≤ ‖R‖ · L · ‖D‖`. -/
theorem composed_norm_le {S : Type*} [AddGroup S] [SMul K S] [NormedSpace S K]
  {P : Type*} {Sp : P → Type*} [∀ p, AddGroup (Sp p)] [∀ p, SMul K (Sp p)]
  [∀ p, NormedSpace (Sp p) K] {d : Decomposition S P Sp}
  (u : PrimeIndexedUpdate S P Sp d) (x : S) :
    norm (composedUpdate u x) ≤ d.opNormR * u.L * d.opNormD * norm x := by
  simp only [composedUpdate, blockDiag]
  rw [d.R_bound (fun p => u.Up p (d.D x p))]
  trans d.opNormR * prodNorm d.ps (fun p => u.Up p (d.D x p)) := by apply le_of_eq; rfl
  apply mul_le_mul_of_nonneg_left (blockDiag_norm_le u (d.D x)) (NormedSpace.norm_nonneg _)
  rw [← mul_assoc]
  apply mul_le_mul_of_nonneg_left (d.D_bound x 0) (NormedSpace.norm_nonneg _)
  rw [dist, sub_zero, norm_nonneg]

/-- If `‖R‖·L·‖D‖ < 1`, the composite update is a contraction on `S`. -/
theorem composed_contractive {S : Type*} [AddGroup S] [SMul K S] [NormedSpace S K]
  {P : Type*} {Sp : P → Type*} [∀ p, AddGroup (Sp p)] [∀ p, SMul K (Sp p)]
  [∀ p, NormedSpace (Sp p) K] {d : Decomposition S P Sp}
  (u : PrimeIndexedUpdate S P Sp d) (h : d.opNormR * u.L * d.opNormD < 1)
  (x y : S) : dist (composedUpdate u x) (composedUpdate u y) ≤
    (d.opNormR * u.L * d.opNormD) * dist x y := by
  have aux := composed_norm_le u
  have hnn := by linarith [NormedSpace.norm_nonneg (x - y)]
  have main : norm (composedUpdate u x - composedUpdate u y) ≤
      d.opNormR * u.L * d.opNormD * norm (x - y) := by
    apply aux
  rw [dist, dist, ← mul_assoc]
  exact main

end GRIMS
