/-
Copyright (c) 2026 Multiplicity. All rights reserved.
Released under Apache 2.0 license.
Authors: Multiplicity Foundry
-/
import Init.Omega
import Foundations.SpectralAttractor.Tags
import Foundations.SpectralAttractor.Basic
import Foundations.SpectralAttractor.Certificates
import Foundations.SpectralAttractor.Matrices

/-!
# Completely positive trace-preserving maps

Kraus-family predicates and the concrete dephasing channel of ADR-0034-F1
§4.2: the projector pair `{Π_ground, Π_excited}` on the nine-dimensional
test space.  Both operations are diagonal; trace preservation is proved
entrywise from `ground ⊕ excited = 1`.
-/

namespace ComplexKappa.SpectralAttractor

variable {R : Type}

/-! ## Channel sums over an arbitrary number of channels -/

/-- Internal accumulator over `nch` channels. -/
def chanGo {R} [so : SpectralOrderedCarrier R] {nch : Nat} (f : Fin nch → R) :
    (m : Nat) → m ≤ nch → R
  | 0, _ => czero
  | m + 1, h =>
      chanGo f m (Nat.le_trans (Nat.le_succ m) h) +
        f ⟨m, Nat.lt_of_lt_of_le (Nat.lt_succ_self m) h⟩

@[proof] theorem chanGo_succ {R} [so : SpectralOrderedCarrier R] {nch : Nat}
    (f : Fin nch → R) (m : Nat) (h : m + 1 ≤ nch) :
    chanGo f (m + 1) h =
      chanGo f m (Nat.le_trans (Nat.le_succ m) h) +
        f ⟨m, Nat.lt_of_lt_of_le (Nat.lt_succ_self m) h⟩ := rfl

/-- Finite channel sum. -/
@[adr] def finSumChan {R} [so : SpectralOrderedCarrier R] {nch : Nat}
    (f : Fin nch → R) : R :=
  chanGo f nch (Nat.le_refl nch)

/-- A two-channel sum is the pair sum. -/
@[proof] theorem finSumChan_pair {R} [so : SpectralOrderedCarrier R]
    (f : Fin 2 → R) :
    finSumChan f =
      f ⟨0, (by omega : (0:Nat) < 2)⟩ + f ⟨1, (by omega : (1:Nat) < 2)⟩ := by
  have e := chanGo_succ f 1 (by omega : ((1:Nat) + 1) ≤ 2)
  have e0 : chanGo f 1 (by omega : ((0:Nat) + 1) ≤ 2)
      = czero + f ⟨0, (by omega : (0:Nat) < 2)⟩ := rfl
  show chanGo f 2 (Nat.le_refl 2) = _
  rw [e, e0, czero_add]

/-! ## Kraus families -/

/-- A Kraus family with `nch` operation matrices. -/
@[adr] structure KrausFamily (R : Type) [so : SpectralOrderedCarrier R]
    (nch : Nat) where
  /-- The operation matrices. -/
  ops : Fin nch → Mat R

/-- Transpose-entry product `(AᵀB)_ij = Σₖ A_ki B_kj`. -/
@[adr] def adjMulEntry {R} [so : SpectralOrderedCarrier R] (A B : Mat R)
    (i j : Fin dim) : R :=
  finSum (fun k => A k i * B k j)

/-- Entry of the transpose-square of a diagonal matrix: `δ_ij · d_i²`. -/
private theorem adjMulEntry_diagOf {R} [so : SpectralOrderedCarrier R]
    (d : Vec R) (i j : Fin dim) :
    adjMulEntry (diagOf d) (diagOf d) i j =
      (if _h : i.val = j.val then d i * d i else czero) := by
  show finSum (fun k => diagOf d k i * diagOf d k j) = _
  have hv : ∀ k : Fin dim, k ≠ i → diagOf d k i * diagOf d k j = czero := by
    intro k hk
    show diagOf d k i * diagOf d k j = czero
    have hzi : diagOf d k i = czero := by
      show (if h : k.val = i.val then d ⟨i.val, by rw [← h]; exact k.isLt⟩
            else czero (R := R)) = czero (R := R)
      have hne : ¬ (k.val = i.val) := fun e => hk (Fin.ext e)
      rw [dif_neg hne]
    rw [hzi, cmul_czero_left (R := R)]
  have hs := finSum_single (fun k => diagOf d k i * diagOf d k j) i hv
  rw [hs]
  show diagOf d i i * diagOf d i j = _
  have hself : diagOf d i i = d i := by
    show (if h : i.val = i.val then d ⟨i.val, by rw [← h]; exact i.isLt⟩
          else czero (R := R)) = _
    rw [dif_pos rfl]
  rw [hself]
  by_cases hij : i.val = j.val
  · have hr : diagOf d i j = d i := by
      show (if h : i.val = j.val then d ⟨j.val, by rw [← h]; exact i.isLt⟩
            else czero (R := R)) = _
      have hje : (⟨j.val, by rw [← hij]; exact i.isLt⟩ : Fin dim) = i :=
        Fin.ext hij.symm
      rw [dif_pos hij]
      exact congrArg d hje
    rw [hr, dif_pos hij]
  · have hz : diagOf d i j = czero (R := R) := by
      show (if h : i.val = j.val then d ⟨j.val, by rw [← h]; exact i.isLt⟩
            else czero (R := R)) = czero (R := R)
      rw [dif_neg hij]
    rw [hz, cmul_czero_right (d i), dif_neg hij]

/-- Pair of diagonal transpose-squares, combined entrywise. -/
private theorem adjPair {R} [so : SpectralOrderedCarrier R]
    (d e : Vec R) (i j : Fin dim) :
    adjMulEntry (diagOf d) (diagOf d) i j +
        adjMulEntry (diagOf e) (diagOf e) i j =
      (if _h : i.val = j.val then d i * d i + e i * e i else czero) := by
  rw [adjMulEntry_diagOf d i j, adjMulEntry_diagOf e i j]
  by_cases hij : i.val = j.val
  · rw [dif_pos hij, dif_pos hij, dif_pos hij]
  · rw [dif_neg hij, dif_neg hij, dif_neg hij]
    exact cadd_czero_czero

/-- Trace preservation: `Σ_c (Aᵀ_c A_c)_ij = δ_ij` entrywise. -/
@[adr] def TracePreserving {R} [so : SpectralOrderedCarrier R] {nch : Nat}
    (F : KrausFamily R nch) : Prop :=
  ∀ i j, finSumChan (fun c => adjMulEntry (F.ops c) (F.ops c) i j)
          = (if _h : i.val = j.val then so.carOne else czero)

/-- Complete positivity (algebraic form): every Kraus operator is PSD. -/
@[adr] def KrausPositive {R} [so : SpectralOrderedCarrier R] {nch : Nat}
    (F : KrausFamily R nch) : Prop :=
  ∀ (c : Fin nch) (v : Vec R), so.carLe czero (quadMat (F.ops c) v)

/-! ## The dephasing channel -/

/-- Ground-state indicator vector. -/
@[adr] def groundVec {R} [so : SpectralOrderedCarrier R] : Fin dim → R :=
  fun i => if _h : i.val = 0 then so.carOne else czero

/-- Excited-indicator vector (complement of the ground mode). -/
@[adr] def excitedVec {R} [so : SpectralOrderedCarrier R] : Fin dim → R :=
  fun i => if _h : i.val = 0 then czero else so.carOne

/-- The dephasing Kraus pair: projectors onto the ground and excited
complementary subspaces. -/
@[adr] def dephasingOps {R} [so : SpectralOrderedCarrier R] :
    Fin 2 → Mat R :=
  fun c => match c.val with
    | 0 => diagOf (R := R) groundVec
    | _ + 1 => diagOf (R := R) excitedVec

private theorem ground_zero {R : Type} [so : SpectralOrderedCarrier R]
    (i : Fin dim) (hi0 : ¬ (i.val = 0)) : groundVec (R := R) i = czero := by
  show (if h : i.val = 0 then _ else _) = _
  rw [dif_neg hi0]

private theorem ground_one {R : Type} [so : SpectralOrderedCarrier R]
    (i : Fin dim) (hi0 : i.val = 0) : groundVec (R := R) i = so.carOne := by
  show (if h : i.val = 0 then _ else _) = _
  rw [dif_pos hi0]

private theorem excited_zero {R : Type} [so : SpectralOrderedCarrier R]
    (i : Fin dim) (hi0 : i.val = 0) : excitedVec (R := R) i = czero := by
  show (if h : i.val = 0 then _ else _) = _
  rw [dif_pos hi0]

private theorem excited_one {R : Type} [so : SpectralOrderedCarrier R]
    (i : Fin dim) (hi0 : ¬ (i.val = 0)) : excitedVec (R := R) i = so.carOne := by
  show (if h : i.val = 0 then _ else _) = _
  rw [dif_neg hi0]

/-- The dephasing family preserves the trace. -/
@[proof] theorem dephasing_tracePreserving {R : Type}
    [so : SpectralOrderedCarrier R] :
    TracePreserving (nch := 2) (R := R) ⟨dephasingOps⟩ := by
  intro i j
  have key := finSumChan_pair
    (fun c => adjMulEntry (dephasingOps (R := R) c) (dephasingOps (R := R) c) i j)
  show finSumChan (fun c => adjMulEntry (dephasingOps (R := R) c)
      (dephasingOps (R := R) c) i j) = _
  rw [key]
  show adjMulEntry (diagOf (R := R) groundVec) (diagOf (R := R) groundVec) i j +
      adjMulEntry (diagOf (R := R) excitedVec) (diagOf (R := R) excitedVec) i j = _
  rw [adjPair groundVec excitedVec i j]
  by_cases hij : i.val = j.val
  · rw [dif_pos hij, dif_pos hij]
    by_cases hi0 : i.val = 0
    · rw [ground_one i hi0, excited_zero i hi0,
        so.carOne_mul so.carOne, cmul_czero_left (czero (R := R)), add_czero]
    · rw [ground_zero i hi0, excited_one i hi0,
        cmul_czero_left (czero (R := R)), czero_add,
        so.carOne_mul so.carOne]
  · rw [dif_neg hij, dif_neg hij]

/-- Unit nonnegativity helper. -/
private theorem carOne_nonneg {R : Type} [so : SpectralOrderedCarrier R] :
    so.carLe czero so.carOne := by
  have h1 : so.carOne = so.fromInt 1 := (so.fromInt_one).symm
  rw [h1]
  exact so.fromInt_nonneg 1 (by decide)

/-- The dephasing family is completely positive (algebraic form). -/
@[proof] theorem dephasing_KrausPositive {R : Type}
    [so : SpectralOrderedCarrier R] :
    KrausPositive (nch := 2) (R := R) ⟨dephasingOps⟩ := by
  intro c
  match c with
  | ⟨0, _⟩ =>
    intro v
    show so.carLe czero (quadMat (diagOf (R := R) groundVec) v)
    rw [quadMat_diagOf]
    refine finSum_nonneg _ (fun i => ?_)
    show so.carLe czero (v i * v i * (if h : i.val = 0 then _ else _))
    by_cases hi0 : i.val = 0
    · rw [dif_pos hi0]
      exact carMul_nonneg (so.sq_nonneg (v i)) carOne_nonneg
    · rw [dif_neg hi0, cmul_czero_right]
      exact so.le_refl czero
  | ⟨_ + 1, _⟩ =>
    intro v
    show so.carLe czero (quadMat (diagOf (R := R) excitedVec) v)
    rw [quadMat_diagOf]
    refine finSum_nonneg _ (fun i => ?_)
    show so.carLe czero (v i * v i * (if h : i.val = 0 then _ else _))
    by_cases hi0 : i.val = 0
    · rw [dif_pos hi0, cmul_czero_right]
      exact so.le_refl czero
    · rw [dif_neg hi0]
      exact carMul_nonneg (so.sq_nonneg (v i)) carOne_nonneg

end ComplexKappa.SpectralAttractor
