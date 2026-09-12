/-
Copyright (c) 2026 Multiplicity. All rights reserved.
Released under Apache 2.0 license.
Authors: Multiplicity Foundry
-/
import Init.Omega
import Foundations.SpectralAttractor.Tags
import Foundations.SpectralAttractor.Basic
import Foundations.SpectralAttractor.Certificates

/-!
# Finite matrices over the spectral carrier

`dim × dim` matrices and vectors over the abstract ordered carrier, with
hand-rolled finite sums (`Finset` machinery is unavailable in this core).
Every summation lemma reduces to induction on one accumulator:

* `sumGo f m h` — sum of `f i` for `i < m`, carrying the bound proof;

Public surface used downstream:

* `dotVec`, `mulMV`, `quadMat`, `traceMat`, `matMulEntry`, `IsPSD`
* `diagOf` with symmetry, column-scaling, and the PSD criterion
* the locked diagonal families `hamiltonianDiag`, `amplitudeDiag`
* the proxy kernel `proxyKernel` parameterized by an abstract coupling
  family (the signature condition stays an external numerical obligation).
-/

namespace ComplexKappa.SpectralAttractor

variable {R : Type}

/-- Vectors of length `dim`. -/
@[adr] abbrev Vec (R : Type) [SpectralOrderedCarrier R] := Fin dim → R

/-- `dim × dim` matrices. -/
@[adr] abbrev Mat (R : Type) [SpectralOrderedCarrier R] := Fin dim → Fin dim → R

/-! ## Carrier helpers -/

/-- Additive unit, accessed through the parent projection so that downstream
statements never depend on numeral elaboration. -/
@[adr] def czero {R} [so : SpectralOrderedCarrier R] : R := so.toZero.zero

@[proof] theorem czero_add {R} [so : SpectralOrderedCarrier R] (x : R) :
    czero + x = x := so.zero_add x

@[proof] theorem add_czero {R} [so : SpectralOrderedCarrier R] (x : R) :
    x + czero = x := so.add_comm x czero ▸ so.zero_add x

@[proof] theorem cmul_czero_left {R} [so : SpectralOrderedCarrier R] (x : R) :
    czero * x = czero := so.zero_mul x

@[proof] theorem cadd_czero_czero {R} [so : SpectralOrderedCarrier R] :
    (czero (R := R)) + czero (R := R) = czero (R := R) :=
  so.zero_add (czero (R := R))

@[proof] theorem cmul_czero_right {R} [so : SpectralOrderedCarrier R] (x : R) :
    x * czero = czero := by
  have h := so.mul_comm x czero
  rw [h]
  exact so.zero_mul x

/-- Two-sided addition monotonicity from the one-sided class law. -/
@[proof] theorem carAdd_mono {R} [so : SpectralOrderedCarrier R] {a b c d : R}
    (h1 : so.carLe a b) (h2 : so.carLe c d) : so.carLe (a + c) (b + d) := by
  have s1 : so.carLe (c + a) (c + b) := so.add_le_add_left a b h1 c
  have s2 : so.carLe (b + c) (b + d) := so.add_le_add_left c d h2 b
  show so.carLe (a + c) (b + d)
  have e1 : a + c = c + a := so.add_comm a c
  rw [e1]
  refine so.le_trans _ _ _ s1 ?_
  have e3 : c + b = b + c := so.add_comm c b
  rw [e3]
  exact s2

/-- Product of nonnegative elements is nonnegative. -/
@[proof] theorem carMul_nonneg {R} [so : SpectralOrderedCarrier R] {a b : R}
    (ha : so.carLe czero a) (hb : so.carLe czero b) : so.carLe czero (a * b) := by
  match so.le_total czero b with
  | Or.inl hb' =>
    have hs := so.mul_le_mul_right_of_nonneg czero a b ha hb'
    show so.carLe czero (a * b)
    have hz : czero * b = czero := cmul_czero_left b
    rw [← hz]
    exact hs
  | Or.inr hb0 =>
    have hbEq : b = czero := so.le_antisymm b czero hb0 hb
    show so.carLe czero (a * b)
    rw [hbEq]
    rw [cmul_czero_right a]
    exact so.le_refl czero

/-- Middle-swap identity used to normalize quadratic forms. -/
@[proof] theorem cmul_swap_mid {R} [so : SpectralOrderedCarrier R] (x y z : R) :
    x * (y * z) = (x * z) * y := by
  have h1 : x * (y * z) = x * (z * y) :=
    congrArg (fun w : R => x * w) (so.mul_comm y z)
  have h2 : (x * z) * y = x * (z * y) := so.mul_assoc x z y
  show x * (y * z) = (x * z) * y
  rw [h1, ← h2]

/-! ## The finite accumulator -/

/-- Internal accumulator: `sumGo f m h` sums `f i` over `i < m`. -/
def sumGo {R} [so : SpectralOrderedCarrier R] (f : Vec R) :
    (m : Nat) → m ≤ dim → R
  | 0, _ => czero
  | m + 1, h =>
      sumGo f m (Nat.le_trans (Nat.le_succ m) h) +
        f ⟨m, Nat.lt_of_lt_of_le (Nat.lt_succ_self m) h⟩

@[proof] theorem sumGo_zero {R} [so : SpectralOrderedCarrier R]
    (f : Vec R) (h : 0 ≤ dim) : sumGo f 0 h = czero := rfl

@[proof] theorem sumGo_succ {R} [so : SpectralOrderedCarrier R]
    (f : Vec R) (m : Nat) (h : m + 1 ≤ dim) :
    sumGo f (m + 1) h =
      sumGo f m (Nat.le_trans (Nat.le_succ m) h) +
        f ⟨m, Nat.lt_of_lt_of_le (Nat.lt_succ_self m) h⟩ := rfl

/-- Left fold over `dim`. -/
@[adr] def finSum {R} [so : SpectralOrderedCarrier R] (f : Vec R) : R :=
  sumGo f dim (Nat.le_refl dim)

/-- Congruence of finite sums under pointwise equality. -/
@[proof] theorem sumGo_congr {R} [so : SpectralOrderedCarrier R]
    {f g : Vec R} (hc : ∀ i, f i = g i) :
    ∀ (m : Nat) (h : m ≤ dim), sumGo f m h = sumGo g m h := by
  intro m
  induction m with
  | zero => intro _; rfl
  | succ k ih =>
      intro h
      have e1 := sumGo_succ f k h
      have e2 := sumGo_succ g k h
      rw [e1, e2,
        ih (Nat.le_trans (Nat.le_succ k) h),
        hc ⟨k, Nat.lt_of_lt_of_le (Nat.lt_succ_self k) h⟩]

/-- Congruence packaged at `dim`. -/
@[proof] theorem finSum_congr {R} [so : SpectralOrderedCarrier R]
    {f g : Vec R} (h : ∀ i, f i = g i) : finSum f = finSum g :=
  sumGo_congr h dim (Nat.le_refl dim)

/-- A sum whose terms all vanish is zero. -/
@[proof] theorem sumGo_vanish {R} [so : SpectralOrderedCarrier R]
    (f : Vec R) :
    ∀ (m : Nat) (h : m ≤ dim), (∀ j : Fin dim, j.val < m → f j = czero) →
      sumGo f m h = czero := by
  intro m
  induction m with
  | zero => intro _ _; rfl
  | succ k ih =>
      intro h hv'
      have e1 := sumGo_succ f k h
      rw [e1,
        ih (Nat.le_trans (Nat.le_succ k) h)
          (fun j hj => hv' j (Nat.lt_trans hj (Nat.lt_succ_self k))),
        hv' ⟨k, Nat.lt_of_lt_of_le (Nat.lt_succ_self k) h⟩
          (Nat.lt_succ_self k)]
      exact cadd_czero_czero

/-- Pointwise nonnegativity implies nonnegativity of the finite sum. -/
@[proof] theorem sumGo_nonneg {R} [so : SpectralOrderedCarrier R]
    (f : Vec R) (hf : ∀ i, so.carLe czero (f i)) :
    ∀ (m : Nat) (h : m ≤ dim), so.carLe czero (sumGo f m h) := by
  intro m
  induction m with
  | zero => intro _; exact so.le_refl _
  | succ k ih =>
      intro h
      have e1 := sumGo_succ f k h
      rw [e1]
      have hmono := carAdd_mono
        (ih (Nat.le_trans (Nat.le_succ k) h))
        (hf ⟨k, Nat.lt_of_lt_of_le (Nat.lt_succ_self k) h⟩)
      rw [cadd_czero_czero] at hmono
      exact hmono

/-- Pointwise nonnegativity packaged at `dim`. -/
@[proof] theorem finSum_nonneg {R} [so : SpectralOrderedCarrier R]
    (f : Vec R) (h : ∀ i, so.carLe czero (f i)) : so.carLe czero (finSum f) :=
  sumGo_nonneg f h dim (Nat.le_refl dim)

/-- Collapse of a finite sum onto its unique nonzero index. -/
@[proof] theorem sumGo_single {R} [so : SpectralOrderedCarrier R]
    (f : Vec R) (i : Fin dim) (hv : ∀ j, j ≠ i → f j = czero) :
    ∀ (m : Nat) (h : m ≤ dim), i.val < m → sumGo f m h = f i := by
  intro m
  induction m with
  | zero =>
      intro h hlt
      exact absurd hlt (Nat.not_lt_zero i.val)
  | succ k ih =>
      intro h hilt
      have e1 := sumGo_succ f k h
      rw [e1]
      by_cases hki : k = i.val
      · subst hki
        -- the new term is the survivor; everything strictly below vanishes
        have hvj : ∀ j : Fin dim, j.val < i.val → f j = czero := by
          intro j hj
          refine hv j (fun e => ?_)
          rw [e] at hj
          omega
        have pref : sumGo f i.val (Nat.le_trans (Nat.le_succ i.val) h) =
            czero :=
          sumGo_vanish f _ (Nat.le_trans (Nat.le_succ i.val) h) hvj
        have heq : (⟨i.val,
            Nat.lt_of_lt_of_le (Nat.lt_succ_self i.val) h⟩ : Fin dim) = i :=
          Fin.ext rfl
        rw [pref, czero_add, heq]
      · -- the new term vanishes; recurse below
        have hz : f ⟨k, Nat.lt_of_lt_of_le (Nat.lt_succ_self k) h⟩ = czero :=
          hv ⟨k, Nat.lt_of_lt_of_le (Nat.lt_succ_self k) h⟩
            (fun e => hki (congrArg Fin.val e))
        have hilt' : i.val < k := by omega
        rw [hz, add_czero,
          ih (Nat.le_trans (Nat.le_succ k) h) hilt']

/-- Collapse packaged at `dim`. -/
@[proof] theorem finSum_single {R} [so : SpectralOrderedCarrier R]
    (f : Vec R) (i : Fin dim) (hv : ∀ j, j ≠ i → f j = czero) :
    finSum f = f i :=
  sumGo_single f i hv dim (Nat.le_refl dim) i.isLt

/-! ## Vector and matrix operations -/

/-- Inner product. -/
@[adr] def dotVec {R} [so : SpectralOrderedCarrier R] (v w : Vec R) : R :=
  finSum (fun i => v i * w i)

/-- Matrix–vector product, entrywise as a finite sum. -/
@[adr] def mulMV {R} [so : SpectralOrderedCarrier R] (M : Mat R) (v : Vec R) :
    Vec R := fun i => finSum (fun j => M i j * v j)

/-- Quadratic form `vᵀ M v`. -/
@[adr] def quadMat {R} [so : SpectralOrderedCarrier R] (M : Mat R) (v : Vec R) :
    R := dotVec v (mulMV M v)

/-- Matrix trace. -/
@[adr] def traceMat {R} [so : SpectralOrderedCarrier R] (M : Mat R) : R :=
  finSum (fun i => M i i)

/-- Matrix multiplication entry `(i, j)`: `Σₖ M i k · N k j`. -/
@[adr] def matMulEntry {R} [so : SpectralOrderedCarrier R] (M N : Mat R)
    (i j : Fin dim) : R := finSum (fun k => M i k * N k j)

/-- Positive semidefiniteness relative to the carrier's order. -/
@[adr] def IsPSD {R} [so : SpectralOrderedCarrier R] (M : Mat R) : Prop :=
  ∀ v, so.carLe czero (quadMat M v)

/-! ## Diagonal matrices -/

/-- Diagonal matrix built from a vector of entries. -/
@[adr] def diagOf {R} [so : SpectralOrderedCarrier R] (d : Vec R) : Mat R :=
  fun i j => if h : i.val = j.val then d ⟨j.val, by rw [← h]; exact i.isLt⟩
             else czero

/-- Diagonal matrices are symmetric. -/
@[proof] theorem diagOf_sym {R} [so : SpectralOrderedCarrier R] (d : Vec R)
    (i j : Fin dim) : diagOf d i j = diagOf d j i := by
  show (if h : i.val = j.val then d ⟨j.val, by rw [← h]; exact i.isLt⟩
        else czero) =
       (if h' : j.val = i.val then d ⟨i.val, by rw [← h']; exact j.isLt⟩
        else czero)
  by_cases h : i.val = j.val
  · rw [dif_pos h, dif_pos h.symm]
    have idxEq : (⟨j.val, by rw [← h]; exact i.isLt⟩ : Fin dim)
        = ⟨i.val, by rw [← h.symm]; exact j.isLt⟩ :=
      Fin.ext h.symm
    rw [idxEq]
  · rw [dif_neg h, dif_neg (fun e => h e.symm)]

private theorem diag_survivor_eq {R} [so : SpectralOrderedCarrier R]
    (d : Vec R) (k : Fin dim) :
    (if h : k.val = k.val then d ⟨k.val, by rw [← h]; exact k.isLt⟩ else czero)
      = d k := by
  rw [dif_pos rfl]

/-- Multiplying a diagonal matrix into a vector scales each coordinate. -/
@[proof] theorem mulMV_diagOf {R} [so : SpectralOrderedCarrier R] (d : Vec R)
    (v : Vec R) (k : Fin dim) :
    mulMV (diagOf d) v k = d k * v k := by
  show finSum
      (fun j => (if h : k.val = j.val then d ⟨j.val, by rw [← h]; exact k.isLt⟩
                 else czero) * v j)
      = d k * v k
  have hs := finSum_single
    (fun j => (if h : k.val = j.val then d ⟨j.val, by rw [← h]; exact k.isLt⟩
               else czero) * v j) k
    (fun j hj => by
      by_cases hke : k.val = j.val
      · exact absurd (Fin.ext hke).symm hj
      · show (if h : k.val = j.val then _ else czero) * v j = czero
        rw [dif_neg hke]
        exact cmul_czero_left (v j))
  rw [hs, diag_survivor_eq]

/-- Quadratic form of a diagonal matrix expands to a weighted square sum. -/
@[proof] theorem quadMat_diagOf {R} [so : SpectralOrderedCarrier R] (d : Vec R)
    (v : Vec R) :
    quadMat (diagOf d) v = finSum (fun i => v i * v i * d i) := by
  show finSum (fun i => v i * mulMV (diagOf d) v i)
    = finSum (fun i => v i * v i * d i)
  refine finSum_congr (fun i => ?_)
  rw [mulMV_diagOf]
  exact cmul_swap_mid (v i) (d i) (v i)

/-- PSD criterion for diagonal matrices: entrywise nonnegativity suffices. -/
@[proof] theorem IsPSD_diagOf {R} [so : SpectralOrderedCarrier R] (d : Vec R)
    (hd : ∀ i, so.carLe czero (d i)) : IsPSD (diagOf d) :=
  fun v => by
    rw [quadMat_diagOf]
    exact finSum_nonneg _ (fun i => carMul_nonneg (so.sq_nonneg (v i)) (hd i))

/-! ## Locked diagonal families -/

private theorem sub1_lt_num {i : Fin dim} (_h0 : ¬ (i.val = 0)) :
    i.val - 1 < numOrdinates := by
  have hdim9 : dim = 9 := rfl
  have hn8 : numOrdinates = 8 := rfl
  omega

/-- Mode attached to a nonzero matrix index. -/
@[adr] def idxMode (i : Fin dim) (h0 : ¬ (i.val = 0)) : ZeroMode :=
  ⟨i.val - 1, sub1_lt_num h0⟩

/-- Hamiltonian diagonal family: `(carOne, γ₁, …, γ₈)` over the carrier.
The ground entry is the unit (identity on the zero mode); every other
entry is the embedded locked ordinate. -/
@[adr] def hamiltonianDiag {R} [so : SpectralOrderedCarrier R] :
    Fin dim → R :=
  fun i => if h0 : i.val = 0 then so.carOne
           else so.fromInt (gammaScaled (idxMode i h0))

/-- Amplitude diagonal family: the envelope weights `cₙ` on the nonzero
modes and zero on the ground mode. -/
@[adr] def amplitudeDiag {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] : Fin dim → R :=
  fun i => if h0 : i.val = 0 then czero
           else c (idxMode i h0)

/-- The locked Hamiltonian is positive semidefinite. -/
@[proof] theorem IsPSD_hamiltonianDiag {R} [so : SpectralOrderedCarrier R] :
    IsPSD (diagOf (R := R) hamiltonianDiag) :=
  IsPSD_diagOf hamiltonianDiag
    (fun i => by
      show so.carLe czero (if h : i.val = 0 then _ else _)
      by_cases h0 : i.val = 0
      · rw [dif_pos h0]
        have h1 : so.carOne = so.fromInt 1 := (so.fromInt_one).symm
        rw [h1]
        exact so.fromInt_nonneg 1 (by decide)
      · rw [dif_neg h0]
        exact so.fromInt_nonneg _
          (Int.le_of_lt (gammaScaled_pos (idxMode i h0))))

/-- The amplitude family is positive semidefinite (entries are envelope
weights, which are strictly positive off the ground mode). -/
@[proof] theorem IsPSD_amplitudeDiag {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] :
    IsPSD (diagOf (R := R) amplitudeDiag) :=
  IsPSD_diagOf amplitudeDiag
    (fun i => by
      show so.carLe czero (if h : i.val = 0 then _ else _)
      by_cases h0 : i.val = 0
      · rw [dif_pos h0]
        exact so.le_refl czero
      · rw [dif_neg h0]
        exact (c_pos (idxMode i h0)).1)

/-! ## Proxy kernel -/

/-- Abstract coupling data for the indefinite proxy kernel.  The signature
condition `(1,7)` of ADR-0034-F1 is a numerical property of concrete
coupling families; it enters Lean only as hypotheses on this structure. -/
@[adr] structure ProxyCoupling (R : Type) [so : SpectralOrderedCarrier R] where
  /-- Coupling amplitudes per mode. -/
  s : ZeroMode → R
  /-- Positivity of the couplings. -/
  s_pos : ∀ n, so.carLe czero (s n) ∧ ¬ so.carLe (s n) czero

/-- Mode option attached to a matrix index: none on the ground row/column. -/
@[adr] def toModeOpt (i : Fin dim) : Option ZeroMode :=
  if h0 : i.val = 0 then none else some (idxMode i h0)

/-- Indefinite proxy kernel `α·ccᵀ − β·ssᵀ` with ground row/column zeroed.
Deliberately *not* claimed PSD: Tests exhibits an indefinite instance. -/
@[adr] def proxyKernel {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (pc : ProxyCoupling R) (α β : R) : Mat R :=
  fun i j =>
    match toModeOpt i, toModeOpt j with
    | some ni, some nj =>
        so.toAdd.add (α * (c ni * c nj))
          (so.toNeg.neg (β * (pc.s ni * pc.s nj)))
    | _, _ => czero

end ComplexKappa.SpectralAttractor
