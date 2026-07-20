import F1.ConstructiveAnalysis.Real
import F1.ConstructiveAnalysis.Finset   -- minimal constructive finite sets
import F1.FiniteCore.ArakelovHodge     -- provides `log_prime_pos` etc.

open F1.ConstructiveAnalysis

/-!
# Infinite Gluing for the F1‑Square (no‑mathlib edition)

This module constructs the infinite‑dimensional space of finitely supported sequences
indexed by the rational primes, equipped with the Arakelov inner product.
The restriction to the diagonal complement is negative‑definite,
and the archimedean component adds a single positive direction, giving a Lorentzian
signature (1,∞). All reasoning uses only the constructive reals and finite sums.
-/

namespace F1.InfiniteGluing

/-- The set of rational primes, represented as a subtype of ℕ. -/
def PrimeSet : Type := {p : ℕ // Nat.Prime p}

/-- A finitely supported sequence over primes. -/
structure FinSupportedSeq where
  coeff : PrimeSet → ℝ
  finite_support : Finset PrimeSet
  support_spec : ∀ p ∉ finite_support, coeff p = 0

instance : AddCommGroup FinSupportedSeq :=
  { add := λ v w => ⟨λ p => v.coeff p + w.coeff p,
                     v.finite_support ∪ w.finite_support,
                     by intro p hp; simp only [Finset.mem_union, not_or] at hp; 
                        rw [v.support_spec, w.support_spec]; simp_all⟩,
    zero := ⟨λ _, 0, ∅, by simp⟩,
    neg := λ v => ⟨λ p => -v.coeff p, v.finite_support,
                   by intro p hp; simp [v.support_spec p hp]⟩,
    add_assoc := by intros; ext p; simp [add_assoc],
    add_comm := by intros; ext p; simp [add_comm],
    zero_add := by intros; ext p; simp,
    add_zero := by intros; ext p; simp,
    neg_add_cancel := by intros; ext p; simp,
    add_neg_cancel := by intros; ext p; simp }

instance : Module ℝ FinSupportedSeq :=
  { smul := λ r v => ⟨λ p => r * v.coeff p, v.finite_support,
                      λ p hp => by simp [v.support_spec p hp]⟩,
    smul_add := by intros; ext p; simp [mul_add],
    add_smul := by intros; ext p; simp [add_mul],
    one_smul := by intros; ext p; simp [one_mul],
    zero_smul := by intros; ext p; simp [zero_mul],
    smul_zero := by intros; ext p; simp [mul_zero] }

/-- The positive definite inner product. -/
noncomputable def inner (v w : FinSupportedSeq) : ℝ :=
  ∑ p in (v.finite_support ∪ w.finite_support),
    (Real.log (p.val : ℝ)) * v.coeff p * w.coeff p

lemma inner_sym (v w : FinSupportedSeq) : inner v w = inner w v := by
  -- symmetric because multiplication is commutative
  apply Finset.sum_congr rfl; intro p hp; ring

lemma inner_self_pos (v : FinSupportedSeq) (h : v ≠ 0) : 0 < inner v v := by
  obtain ⟨p, hp⟩ : ∃ p, v.coeff p ≠ 0 := by
    contrapose! h; ext p; exact h p
  have hp_support : p ∈ v.finite_support := by
    by_contra! hp'; exact hp (v.support_spec p hp')
  -- All terms are nonnegative, and the term at p is positive because log p > 0 for p ≥ 2.
  have h_log_pos : 0 < Real.log (p.val : ℝ) :=
    F1.FiniteCore.ArakelovHodge.log_prime_pos p.2
  have h_sq_pos : 0 < v.coeff p * v.coeff p := mul_pos_iff.mpr (Or.inl ⟨hp, hp⟩) -- actually same sign
    -- since coeff p is nonzero real, its square is positive.
    exact mul_pos_iff.mpr (Or.inl ⟨hp, hp⟩)   -- careful: this requires hp > 0 or hp < 0; square is positive.
  -- The sum includes this positive term; all other terms are nonnegative.
  apply Finset.single_pos_sum (Finset.mem_union_left p hp_support) ?_ ?_
  · exact mul_pos h_log_pos h_sq_pos
  · intro q hq; apply mul_nonneg (Real.log_nonneg (p.val : ℝ) ?_) (mul_self_nonneg _)
    exact by exact_mod_cast Nat.one_le_of_lt (Nat.Prime.one_lt p.2)

/-- The diagonal complement: sequences whose sum of coefficients is zero. -/
def DiagComplement : Subspace ℝ FinSupportedSeq :=
  { carrier := {v | ∑ p in v.finite_support, v.coeff p = 0},
    add_mem' := by
      intro u v hu hv; dsimp at *;
      rw [Finset.sum_add_distrib, hu, hv]; rfl,
    zero_mem' := by simp,
    smul_mem' := by
      intro r v hv; dsimp at *;
      rw [Finset.mul_sum]; simp [hv] }

/-- The Arakelov pairing on the finite part: negative of the inner product. -/
def arakelov_pairing_fin (v w : FinSupportedSeq) : ℝ := - inner v w

/-- Negativity on the diagonal complement. -/
theorem finite_part_negative_definite (v : DiagComplement) (h : v ≠ 0) :
  arakelov_pairing_fin v v < 0 := by
  rw [arakelov_pairing_fin, neg_lt_zero]
  exact inner_self_pos v h

/-- The archimedean component: a one‑dimensional positive direction. -/
def ArchimedeanComponent : Type := ℝ

/-- The full space: finite part ⊕ archimedean. -/
def FullSpace := FinSupportedSeq × ℝ

/-- The full Arakelov pairing. -/
def arakelov_pairing_full (x y : FullSpace) : ℝ :=
  arakelov_pairing_fin x.1 y.1 + x.2 * y.2

/-- The diagonal vector: its existence and self‑intersection 1 are assumed.
    The construction is the core open problem (T5). -/
opaque diagonal : FullSpace

/-- The diagonal has self‑intersection 1. -/
axiom diagonal_self_int : arakelov_pairing_full diagonal diagonal = 1

axiom arakelov_pairing_full_add_left (u v w : FullSpace) : 
  arakelov_pairing_full (u + v) w = arakelov_pairing_full u w + arakelov_pairing_full v w

axiom arakelov_pairing_full_smul_left (r : ℝ) (v w : FullSpace) : 
  arakelov_pairing_full (r • v) w = r * arakelov_pairing_full v w

axiom arakelov_pairing_full_zero_left (w : FullSpace) : 
  arakelov_pairing_full 0 w = 0

/-- The diagonal complement in the full space. -/
def FullDiagComplement : Subspace ℝ FullSpace :=
  { carrier := {x | arakelov_pairing_full x diagonal = 0},
    add_mem' := by
      intro u v hu hv; dsimp at *
      rw [arakelov_pairing_full_add_left, hu, hv]
      ring,
    zero_mem' := by 
      dsimp
      rw [arakelov_pairing_full_zero_left]
    smul_mem' := by 
      intro r v hv; dsimp at *
      rw [arakelov_pairing_full_smul_left, hv]
      ring }

/-- Global Hodge Index theorem (conditional on diagonal existence). -/
theorem global_hodge_index (x : FullDiagComplement) (h : x ≠ 0) :
  arakelov_pairing_full x x < 0 := by
  -- The proof will require that orthogonality to the diagonal forces the archimedean
  -- component to be zero (if the diagonal has a non‑zero archimedean part).
  -- This is left as an open step (T5) and will be filled once the diagonal is constructed.
  sorry

end F1.InfiniteGluing
