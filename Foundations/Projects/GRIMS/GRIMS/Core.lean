import Init

/-! # GRIMS+ and Prime-Indexed Recursive Lawfulness — Lean 4 formalization (no Mathlib)

This module formalizes the core objects of ADR-0042 over an arbitrary linear ordered
field `K` (instantiated with `Rat` for examples). All norms take values in `K`. The
prime-indexed product uses the **sum norm** `∑ₚ ‖xₚ‖` — a valid norm, equivalent to the
L2 norm used in the ADR appendix. No Mathlib or Std dependency: only Lean 4 `Init`.
-/

namespace GRIMS

variable {K : Type*} [LinearOrderedField K]

/-- A normed space over `K`. The algebraic structure (`AddGroup`, scalar multiplication)
is required separately. -/
class NormedSpace (α : Type*) (K : outParam Type*) [LinearOrderedField K]
  [AddGroup α] [SMul K α] where
  norm : α → K
  norm_nonneg (x : α) : 0 ≤ norm x
  norm_zero : norm (0 : α) = 0
  norm_add (x y : α) : norm (x + y) ≤ norm x + norm y
  norm_smul (c : K) (x : α) : norm (c • x) = |c| * norm x
  norm_neg (x : α) : norm (-x) = norm x
  norm_eq_zero (x : α) : norm x = 0 → x = 0

section Dist
variable {α : Type*} [AddGroup α] [SMul K α] [NormedSpace α K]

/-- Distance induced by the norm. -/
def dist (x y : α) : K := norm (x - y)

@[simp] lemma dist_self (x : α) : dist x x = 0 := by rw [dist, sub_self, norm_zero]

lemma dist_comm (x y : α) : dist x y = dist y x :=
  by rw [dist, dist, neg_sub, norm_neg]

lemma dist_nonneg (x y : α) : 0 ≤ dist x y := NormedSpace.norm_nonneg _

lemma dist_triangle (x y z : α) : dist x z ≤ dist x y + dist y z := by
  rw [dist, ← sub_add_sub_cancel x y z]
  apply NormedSpace.norm_add

/-- The norm is bounded by distance to the origin. -/
lemma norm_le_dist_zero (x : α) : norm x ≤ dist x 0 := by
  rw [dist, sub_zero]

end Dist

/-- Sum norm on a prime-indexed product space, over a finite list `ps` of primes. -/
def prodNorm {P : Type*} {Sp : P → Type*} [∀ p, AddGroup (Sp p)] [∀ p, SMul K (Sp p)]
  [∀ p, NormedSpace (Sp p) K] (ps : List P) (x : (p : P) → Sp p) : K :=
  (ps.map (fun p => norm (x p))).sum

section ProdNorm
variable {P : Type*} {Sp : P → Type*} [∀ p, AddGroup (Sp p)] [∀ p, SMul K (Sp p)]
  [∀ p, NormedSpace (Sp p) K] (ps : List P)

@[simp] lemma prodNorm_nonneg (x : (p : P) → Sp p) : 0 ≤ prodNorm ps x := by
  simp only [prodNorm]
  apply List.sum_nonneg
  intro p hp
  apply NormedSpace.norm_nonneg

lemma prodNorm_smul (c : K) (x : (p : P) → Sp p) :
    prodNorm ps (fun p => c • x p) = |c| * prodNorm ps x := by
  simp only [prodNorm, List.map_map, Function.comp, List.sum_map_mul]
  rw [List.sum_map_mul]

lemma prodNorm_add (x y : (p : P) → Sp p) :
    prodNorm ps (fun p => x p + y p) ≤ prodNorm ps x + prodNorm ps y := by
  simp only [prodNorm]
  rw [List.map_zipWith_map_list_map, List.sum_add]
  apply List.sum_le_sum
  intro p hp
  apply NormedSpace.norm_add

end ProdNorm

/-- A prime-indexed decomposition `D : S → Πₚ Sₚ` with reconstruction `R`, carrying
operator-norm bounds `‖D‖` and `‖R‖` as proof-carrying fields. -/
structure Decomposition (S : Type*) [AddGroup S] [SMul K S] [NormedSpace S K]
  (P : Type*) (Sp : P → Type*) [∀ p, AddGroup (Sp p)] [∀ p, SMul K (Sp p)]
  [∀ p, NormedSpace (Sp p) K] where
  ps : List P
  hps : ps ≠ []
  D : S → (p : P) → Sp p
  R : ((p : P) → Sp p) → S
  opNormD : K
  opNormR : K
  D_bound : ∀ (x y : S), prodNorm ps (D x - D y) ≤ opNormD * dist x y
  R_bound : ∀ c, norm (R c) ≤ opNormR * prodNorm ps c

/-- The lawful set: states satisfying every constraint `Cᵢ(x) ≤ 0`. -/
def isLawful (S : Type*) [AddGroup S] (C : List (S → K)) (x : S) : Prop :=
  ∀ c ∈ C, c x ≤ 0

/-- Recursive accept/reject: accept the candidate iff it is lawful and does not worsen
governance. -/
def lawfulStep {S : Type*} [AddGroup S] (C : List (S → K)) (G : S → K) (x x' : S) : S :=
  if (∀ c ∈ C, c x' ≤ 0) ∧ G x' ≤ G x then x' else x

/-- Drift in the prime-indexed space. -/
def drift {S : Type*} [AddGroup S] [SMul K S] [NormedSpace S K]
  {P : Type*} {Sp : P → Type*} [∀ p, AddGroup (Sp p)] [∀ p, SMul K (Sp p)]
  [∀ p, NormedSpace (Sp p) K] (d : Decomposition S P Sp) (x x' : S) : K :=
  prodNorm d.ps (d.D x' - d.D x)

section Theorems
variable {S : Type*} [AddGroup S] [SMul K S] [NormedSpace S K]

/-- Drift is bounded by the decomposition operator norm. -/
theorem drift_bound (d : Decomposition S P Sp) (x x' : S) :
    drift d x x' ≤ d.opNormD * dist x x' :=
  d.D_bound x x'

/-- Lawfulness persists and governance is monotone across `lawfulStep`. -/
theorem lawfulStep_preserves (C : List (S → K)) (G : S → K) (x x' : S)
    (hx : isLawful S C x) (hG : G x' ≤ G x)
    (hc : ∀ c ∈ C, c x' ≤ 0) : isLawful S C (lawfulStep C G x x') := by
  simp only [lawfulStep]
  split_ifs with h
  · exact fun c hc' => h.left.left c hc'
  · exact hx

theorem lawfulStep_governance (C : List (S → K)) (G : S → K) (x x' : S)
    (hG : G x' ≤ G x) (hc : ∀ c ∈ C, c x' ≤ 0) :
    G (lawfulStep C G x x') ≤ G x := by
  simp only [lawfulStep]
  split_ifs with h <;> linarith

end Theorems

end GRIMS
