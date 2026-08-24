/-
Copyright (c) 2026 Citizen Gardens / Multiplicity Foundation.
Released under Apache 2.0 license.
Authors: Multiplicity Foundry
-/
import Init.Omega
import Multiplicity.SpectralAttractor.Tags

/-!
# Atlas coupling dominance — finite-stage kernel (AC-15/AC-16)

Self-contained, buildable transcription of the *Atlas Coupling Dominance*
program over an integer carrier. The F1 `Square` layer that originally held
`WeilPSD` / `coupledWeil_psd_iff_dominates` is not part of the current Lake
graph (its imports reference absent modules), so the minimal kernel is
re-proved here at the layer the house style trusts: kernels are
`Nat → Nat → ℤ`, truncations are natural numbers, and every sign fact
closes by kernel arithmetic.

This module currently provides the finite-sum substrate (`sumN` with its
congruence, additivity, pull-out, grid-swap, and positivity lemmas). The
kernel layer (`weilQuad`, `WeilPSD`, `gramOf`, Gate B), the coupled split,
the capstone equivalence, and the AC-15 interface bundle land in the
following sections.
-/

namespace ComplexKappa.SpectralAttractor.Atlas

/-! ## Finite sums over ℤ -/

/-- Canonical finite sum `Σ_{k < N} F k`. -/
@[adr] def sumN (F : Nat → Int) (N : Nat) : Int :=
  match N with
  | 0 => 0
  | Nat.succ m => sumN F m + F m

theorem sumN_succ_out (F : Nat → Int) (m : Nat) :
    sumN F (Nat.succ m) = sumN F m + F m := rfl

/-- Constant-zero sums vanish. -/
@[proof] theorem sumN_zero' (N : Nat) : sumN (fun _ : Nat => (0 : Int)) N = 0 := by
  induction N with
  | zero => rfl
  | succ n ih =>
    show sumN (fun _ : Nat => (0 : Int)) n + 0 = 0
    rw [ih]
    omega

/-- Pointwise-equal summands give equal sums. -/
@[proof] theorem sumN_congr {F G : Nat → Int} (N : Nat)
    (h : ∀ k, F k = G k) : sumN F N = sumN G N := by
  induction N generalizing F G with
  | zero => rfl
  | succ n ih =>
    show sumN F n + F n = sumN G n + G n
    rw [ih (fun k => h k), h n]

/-- Additivity of the summand. -/
@[proof] theorem sumN_add (F G : Nat → Int) : ∀ N : Nat,
    sumN (fun k => F k + G k) N = sumN F N + sumN G N := by
  intro N
  induction N with
  | zero => rfl
  | succ n ih =>
    rw [sumN_succ_out, sumN_succ_out, sumN_succ_out, ih]
    omega

/-- Scalar pull-out (constant factor on the right of each summand). -/
@[proof] theorem sumN_mul_right (F : Nat → Int) (t : Int) : ∀ N : Nat,
    sumN (fun k => F k * t) N = sumN F N * t := by
  intro N
  induction N with
  | zero =>
    have hl : sumN (fun k => F k * t) 0 = 0 := rfl
    have hr : sumN F 0 = 0 := rfl
    rw [hl, hr, Int.zero_mul]
  | succ n ih =>
    rw [sumN_succ_out, sumN_succ_out, ih]
    rw [Int.add_mul (sumN F n) (F n) t]

/-- Scalar pull-out (constant factor on the left of each summand). -/
@[proof] theorem sumN_mul_left (F : Nat → Int) (t : Int) : ∀ N : Nat,
    sumN (fun k => t * F k) N = t * sumN F N := by
  intro N
  induction N with
  | zero =>
    have hl : sumN (fun k => t * F k) 0 = 0 := rfl
    have hr : sumN F 0 = 0 := rfl
    rw [hl, hr, Int.mul_zero]
  | succ n ih =>
    rw [sumN_succ_out, sumN_succ_out, ih]
    rw [Int.mul_add t (sumN F n) (F n)]

/-- Negation commutes with summation. -/
@[proof] theorem sumN_neg (F : Nat → Int) : ∀ N : Nat,
    sumN (fun k => -F k) N = -(sumN F N) := by
  intro N
  induction N with
  | zero => rfl
  | succ n ih =>
    rw [sumN_succ_out, sumN_succ_out, ih]
    omega

/-- Difference of sums is the sum of differences. -/
@[proof] theorem sumN_sub (F G : Nat → Int) : ∀ N : Nat,
    sumN F N - sumN G N = sumN (fun k => F k - G k) N := by
  intro N
  induction N with
  | zero =>
    have h0 : sumN F 0 = 0 := rfl
    have h1 : sumN G 0 = 0 := rfl
    have hl : sumN (fun k => F k - G k) 0 = 0 := rfl
    rw [hl, h0, h1]
    omega
  | succ n ih =>
    rw [sumN_succ_out, sumN_succ_out, sumN_succ_out]
    omega

/-- Grid swap: `Σ_{i<a} Σ_{j<b} F i j = Σ_{j<b} Σ_{i<a} F i j`. -/
@[proof] theorem sumN_swap (F : Nat → Nat → Int) : ∀ a b : Nat,
    sumN (fun i => sumN (fun j => F i j) b) a
      = sumN (fun j => sumN (fun i => F i j) a) b := by
  intro a
  induction a with
  | zero =>
    intro b
    show 0 = _
    have hrhs : sumN (fun j => sumN (fun i => F i j) 0) b
        = sumN (fun _ : Nat => (0 : Int)) b :=
      sumN_congr b (fun j => rfl)
    rw [hrhs, sumN_zero']
  | succ n ih =>
    intro b
    show sumN (fun i => sumN (fun j => F i j) b) n
      + sumN (fun j => F n j) b = _
    have hrhs : sumN (fun j => sumN (fun i => F i j) (Nat.succ n)) b
        = sumN (fun j => sumN (fun i => F i j) n + F n j) b :=
      sumN_congr b (fun j => rfl)
    rw [hrhs, sumN_add, ih b]

/-- Nonnegativity of sums of nonnegative summands. -/
@[proof] theorem sumN_nonneg {F : Nat → Int} : ∀ N : Nat,
    (∀ k, 0 ≤ F k) → 0 ≤ sumN F N := by
  intro N
  induction N with
  | zero => intro _; exact Int.le_refl 0
  | succ n ih =>
    exact fun h => Int.add_nonneg (ih h) (h n)


private theorem mul4_reassoc (a b c d : Int) :
    a * b * (c * d) = (a * c) * (b * d) := by
  rw [Int.mul_assoc a b (c * d), Int.mul_assoc a c (b * d),
      Int.mul_left_comm b c d]

private theorem sq_nonneg_Int (x : Int) : 0 ≤ x * x := by
  rcases Int.le_total x 0 with h | h
  · have hp : 0 ≤ -x := by omega
    rw [← Int.neg_mul_neg x x]
    exact Int.mul_nonneg hp hp
  · exact Int.mul_nonneg h h

/-! ## Kernels, quadratic form, PSD -/

/-- Quadratic form of kernel `B` on test vector `c`, truncated at `N`. -/
@[adr] def weilQuad (B : Nat → Nat → Int) (c : Nat → Int) (N : Nat) : Int :=
  sumN (fun i => sumN (fun j => c i * c j * B i j) N) N

/-- Finite-truncation positive semidefiniteness. -/
@[adr] def WeilPSD (B : Nat → Nat → Int) : Prop :=
  ∀ (N : Nat) (c : Nat → Int), 0 ≤ weilQuad B c N

/-- The quadratic form is additive under pointwise subtraction of kernels. -/
@[proof] theorem weilQuad_sub (B B' : Nat → Nat → Int) (c : Nat → Int)
    (N : Nat) :
    weilQuad B c N - weilQuad B' c N
      = weilQuad (fun i j => B i j - B' i j) c N := by
  show sumN (fun i => sumN (fun j => c i * c j * B i j) N) N
    - sumN (fun i => sumN (fun j => c i * c j * B' i j) N) N
    = sumN (fun i => sumN (fun j =>
        c i * c j * (B i j - B' i j)) N) N
  have hinner : ∀ i : Nat,
      sumN (fun j => c i * c j * B i j) N
        - sumN (fun j => c i * c j * B' i j) N
        = sumN (fun j => c i * c j * (B i j - B' i j)) N := by
    intro i
    refine Eq.trans (sumN_sub (fun j => c i * c j * B i j)
      (fun j => c i * c j * B' i j) N) ?_
    exact sumN_congr N (fun j =>
      (Int.mul_sub (c i * c j) (B i j) (B' i j)).symm)
  refine Eq.trans (sumN_sub
    (fun i => sumN (fun j => c i * c j * B i j) N)
    (fun i => sumN (fun j => c i * c j * B' i j) N) N) ?_
  exact sumN_congr N (fun i => hinner i)

/-- Hilbert–Schmidt Gram of an embedding `ι` compressed to dimension `D`. -/
@[adr] def gramOf (ι : Nat → Nat → Int) (D : Nat) : Nat → Nat → Int :=
  fun i j => sumN (fun k => ι i k * ι j k) D

/-- **Gate B (free)**: a Gram of any embedding into `ℤ^D` is PSD.

Proof shape: expand the double sum through two grid swaps so column `k`
factors out, then peel perfect squares —
`quad(gram ι) c N = Σ_{k<D} (Σ_{i<N} c i · ι i k)^2 ≥ 0`. -/
@[proof] theorem WeilPSD_gramOf (ι : Nat → Nat → Int) (D : Nat) :
    WeilPSD (gramOf ι D) := by
  intro N c
  -- Step 1: push each Gram entry into an explicit inner column-sum.
  have h1 : weilQuad (gramOf ι D) c N
      = sumN (fun i => sumN (fun j =>
          sumN (fun k => c i * c j * (ι i k * ι j k)) D) N) N := by
    refine sumN_congr _ (fun i => ?_)
    refine sumN_congr _ (fun j => ?_)
    show c i * c j * sumN (fun k => ι i k * ι j k) D = _
    exact Eq.symm
      (sumN_mul_left (fun k => ι i k * ι j k) (c i * c j) D)
  -- Step 2a: swap layers j,k inside each row i; 2b: swap outer layers.
  have ha : ∀ i : Nat,
      sumN (fun j => sumN (fun k => c i * c j * (ι i k * ι j k)) D) N
        = sumN (fun k => sumN (fun j => c i * c j * (ι i k * ι j k)) N) D :=
    fun i => sumN_swap
      (fun j k => c i * c j * (ι i k * ι j k)) N D
  have h2 : sumN (fun i => sumN (fun j =>
          sumN (fun k => c i * c j * (ι i k * ι j k)) D) N) N
      = sumN (fun k => sumN (fun i => sumN (fun j =>
          c i * c j * (ι i k * ι j k)) N) N) D := by
    refine Eq.trans ?_ (sumN_swap
      (fun i k => sumN (fun j => c i * c j * (ι i k * ι j k)) N) N D)
    exact sumN_congr _ (fun i => ha i)
  rw [h1, h2]
  refine sumN_nonneg D (fun k => ?_)
  -- Column k collapses to a perfect square.
  have hin : ∀ i : Nat,
      sumN (fun j => c i * c j * (ι i k * ι j k)) N
        = (c i * ι i k) * sumN (fun j => c j * ι j k) N := by
    intro i
    have e1 : sumN (fun j => c i * c j * (ι i k * ι j k)) N
        = sumN (fun j => (c i * ι i k) * (c j * ι j k)) N :=
      sumN_congr N (fun j => mul4_reassoc (c i) (c j) (ι i k) (ι j k))
    rw [e1]
    exact sumN_mul_left (fun j => c j * ι j k) (c i * ι i k) N
  have hcol : sumN (fun i => sumN (fun j => c i * c j * (ι i k * ι j k)) N) N
      = sumN (fun i => c i * ι i k) N * sumN (fun j => c j * ι j k) N := by
    rw [sumN_congr N (fun i => hin i)]
    exact sumN_mul_right (fun i => c i * ι i k)
      (sumN (fun j => c j * ι j k) N) N
  rw [hcol]
  exact sq_nonneg_Int _


/-! ## The coupled split kernel -/

/-- Diagonal Archimedean mass matrix: `multForm arch i i = arch i`,
zero off-diagonal. -/
@[adr] def multForm (arch : Nat → Int) : Nat → Nat → Int :=
  fun i j => if i = j then arch i else 0

/-- Prime-side Gram: `Σ_{m < M} w m • v m ⊗ v m` at places `v`. -/
@[adr] def primeGram (w : Nat → Int) (v : Nat → Nat → Int) (M : Nat)
    : Nat → Nat → Int :=
  fun i j => sumN (fun m => w m * v m i * v m j) M

/-- Coupled Weil kernel at a finite stage: Archimedean block minus
prime block. -/
@[adr] def coupledWeil (arch : Nat → Int) (w : Nat → Int)
    (v : Nat → Nat → Int) (M : Nat) : Nat → Nat → Int :=
  fun i j => multForm arch i j - primeGram w v M i j

/-- The quadratic form is additive across the coupled split. -/
@[proof] theorem weilQuad_coupled (arch : Nat → Int) (w : Nat → Int)
    (v : Nat → Nat → Int) (M N : Nat) (c : Nat → Int) :
    weilQuad (coupledWeil arch w v M) c N
      = weilQuad (multForm arch) c N - weilQuad (primeGram w v M) c N :=
  Eq.symm (weilQuad_sub (multForm arch) (primeGram w v M) c N)

/-- Archimedean dominance of the prime Gram by the Archimedean block,
at every test family and truncation. -/
@[adr] def ArchDominatesPrime (arch : Nat → Int) (w : Nat → Int)
    (v : Nat → Nat → Int) (M : Nat) : Prop :=
  ∀ (N : Nat) (c : Nat → Int),
    weilQuad (primeGram w v M) c N ≤ weilQuad (multForm arch) c N

/-- **Capstone**: the coupled Weil kernel is PSD **iff** the Archimedean
block dominates the prime Gram. Pure ordered-ring bookkeeping around
`weilQuad_coupled`; all difficulty lives upstream. -/
@[proof] theorem coupledWeil_psd_iff_dominates (arch : Nat → Int)
    (w : Nat → Int) (v : Nat → Nat → Int) (M : Nat) :
    WeilPSD (coupledWeil arch w v M) ↔ ArchDominatesPrime arch w v M := by
  constructor
  · intro h N c
    have hq := h N c
    rw [weilQuad_coupled] at hq
    omega
  · intro h N c
    have hq := h N c
    rw [weilQuad_coupled]
    omega

/-! ## The Atlas coupling interface (AC-15) -/

/-- Interface bundle for an Atlas coupling at a fixed stage. Every field
except `factorization` is bookkeeping; the single non-circular
mathematical input is the factorization identity stating that the coupled
kernel *is* the Hilbert–Schmidt Gram of the Atlas-compressed scale
operators. Supplying this bundle with a proof of `factorization` is the
bridge obligation; everything downstream is free. -/
@[adr] structure AtlasCoupling where
  /-- compression dimension -/
  dim : Nat
  /-- Atlas-compressed scale-operator embedding -/
  emb : Nat → Nat → Int
  /-- Archimedean mass profile -/
  arch : Nat → Int
  /-- prime weights -/
  weight : Nat → Int
  /-- local place data -/
  place : Nat → Nat → Int
  /-- prime cutoff -/
  cutoff : Nat
  /-- the factorization identity (the one honest hypothesis) -/
  factorization :
    ∀ i j, coupledWeil arch weight place cutoff i j
             = gramOf emb dim i j

/-- Given the factorization, the coupled stage kernel is PSD — free by
Gate B. No RH, no zeros, no Li, no sign hypotheses. -/
@[proof] theorem atlas_coupled_stage_psd (K : AtlasCoupling) :
    WeilPSD (coupledWeil K.arch K.weight K.place K.cutoff) := by
  intro N c
  have hgram := WeilPSD_gramOf K.emb K.dim N c
  have hf : weilQuad (coupledWeil K.arch K.weight K.place K.cutoff) c N
      = weilQuad (gramOf K.emb K.dim) c N := by
    refine sumN_congr _ (fun i => sumN_congr _ (fun j => ?_))
    show c i * c j * coupledWeil K.arch K.weight K.place K.cutoff i j
      = c i * c j * gramOf K.emb K.dim i j
    rw [K.factorization i j]
  omega

/-- **Atlas-derived dominance** (AC-16): given the factorization, the
Archimedean block dominates the prime Gram at the bundled stage. -/
@[proof] theorem atlas_derived_dominance_stage (K : AtlasCoupling) :
    ArchDominatesPrime K.arch K.weight K.place K.cutoff :=
  (coupledWeil_psd_iff_dominates K.arch K.weight K.place K.cutoff).mp
    (atlas_coupled_stage_psd K)

/-- Pointful form of the dominance statement. -/
@[proof] theorem atlas_dominance_diag (K : AtlasCoupling) (N : Nat)
    (c : Nat → Int) :
    weilQuad (primeGram K.weight K.place K.cutoff) c N
      ≤ weilQuad (multForm K.arch) c N :=
  atlas_derived_dominance_stage K N c

end ComplexKappa.SpectralAttractor.Atlas
