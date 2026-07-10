/-
F1 square — v0.19.0 (the genuine-pairing arc), brick W3a: **ψ(1/4), the archimedean
kernel value at the window center** — the first exact non-trivial digamma value built in
this substrate, with a certified lower bracket, as the input to Burnol's window-center
positivity certificate.

THE OPENING. The digamma series `ψ(z) = −γ + Σ_{n≥0}[1/(n+1) − 1/(n+z)]` has, at the
window center `z = 1/4`, EXACT-RATIONAL terms:
    `1/(n+1) − 1/(n+1/4) = [(n+1/4) − (n+1)] / [(n+1)(n+1/4)] = −3/[(n+1)(4n+1)]`.
So `ψ(1/4) = −γ − 3·Σ_{n≥0} 1/[(n+1)(4n+1)]` — no per-term `Rinv` needed; the core is a
sign-definite rational series with a clean telescoping tail
`3/[(i+1)(4i+1)] ≤ 3/(4i) − 3/(4(i+1))` (since `4i(i+1) ≤ (i+1)(4i+1)`), giving a
direct-sequence constructive real (the `Rgamma_h` idiom) with depth schedule `j ↦ j+2`.

THE BRACKET. `psiQuarter ≥ −4.32` (true value `≈ −4.2270`): the positive partial sums are
bounded uniformly by `366/100` (the monotone auxiliary `g(m) = S(m) + 3/(4m)` is
non-increasing, so `S(m) ≤ g(12) = S(12) + 3/48`), and `ψ(1/4) = −γ + core ≥ −0.66 − 3.66`
through `Rgamma_h_upper`. This is the value Burnol's multiplier `α(τ)` evaluates to at
`τ = 0` together with `8√2` and `−log π` (brick W3b).

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.GammaUpper
import F1Square.Analysis.RealPow

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The exact-rational term, partial sums, and telescoping comparison.
-- ===========================================================================

/-- The positive term `3/[(i+1)(4i+1)]` (the magnitude of the `i`-th digamma summand at
    `z = 1/4`). -/
private def pqT (i : Nat) : Q := ⟨3, (i + 1) * (4 * i + 1)⟩

private theorem pqT_den_pos (i : Nat) : 0 < (pqT i).den :=
  Nat.mul_pos (by omega) (by omega)

/-- The positive partial sums `S(N) = Σ_{i<N} 3/[(i+1)(4i+1)]`. -/
private def pqP : Nat → Q
  | 0 => ⟨0, 1⟩
  | (N + 1) => add (pqP N) (pqT N)

private theorem pqP_den_pos : ∀ N, 0 < (pqP N).den
  | 0 => by decide
  | (N + 1) => add_den_pos (pqP_den_pos N) (pqT_den_pos N)

/-- The telescoping comparison value `3/(4i)` (used only at `i ≥ 1`). -/
private def pqTel (i : Nat) : Q := ⟨3, 4 * i⟩

private theorem pqTel_den_pos {i : Nat} (hi : 1 ≤ i) : 0 < (pqTel i).den := by
  show 0 < 4 * i; omega

/-- **The per-term telescoping bound**: `3/[(i+1)(4i+1)] ≤ 3/(4i) − 3/(4(i+1))` for
    `i ≥ 1` (since `4i(i+1) ≤ (i+1)(4i+1)`). -/
private theorem pqT_le_teldiff {i : Nat} (hi : 1 ≤ i) :
    Qle (pqT i) (Qsub (pqTel i) (pqTel (i + 1))) := by
  show (3 : Int) * (((4 * i) * (4 * (i + 1)) : Nat) : Int) ≤
    ((3 : Int) * ((4 * (i + 1) : Nat) : Int) + -(3 : Int) * ((4 * i : Nat) : Int))
      * (((i + 1) * (4 * i + 1) : Nat) : Int)
  push_cast
  have key : ((3 : Int) * (4 * ((i : Int) + 1)) + -3 * (4 * (i : Int)))
        * (((i : Int) + 1) * (4 * (i : Int) + 1))
      = (3 : Int) * ((4 * (i : Int)) * (4 * ((i : Int) + 1))) + 12 * ((i : Int) + 1) := by
    ring_uor
  rw [key]; omega

-- ===========================================================================
-- The monotone auxiliary `g(m) = S(m) + 3/(4m)` and the uniform sum bound.
-- ===========================================================================

/-- `g(m) = S(m) + 3/(4m)`. -/
private def pqG (m : Nat) : Q := add (pqP m) (pqTel m)

private theorem pqG_den_pos {m : Nat} (hm : 1 ≤ m) : 0 < (pqG m).den :=
  add_den_pos (pqP_den_pos m) (pqTel_den_pos hm)

/-- `T(m) + tel(m+1) ≤ tel(m)` (the telescoping step, rearranged). -/
private theorem pqT_tel_le {m : Nat} (hm : 1 ≤ m) :
    Qle (add (pqT m) (pqTel (m + 1))) (pqTel m) := by
  have hadd := Qadd_le_add (pqT_le_teldiff hm) (Qle_refl (pqTel (m + 1)))
  have e3 : Qeq (add (Qsub (pqTel m) (pqTel (m + 1))) (pqTel (m + 1))) (pqTel m) := by
    simp only [Qeq, add, Qsub, neg]; push_cast; ring_uor
  refine Qle_trans ?_ hadd (Qeq_le e3)
  exact add_den_pos (Qsub_den_pos (pqTel_den_pos hm) (pqTel_den_pos (by omega)))
    (pqTel_den_pos (by omega))

/-- One step: `g(m+1) ≤ g(m)` for `m ≥ 1`. -/
private theorem pqG_step {m : Nat} (hm : 1 ≤ m) : Qle (pqG (m + 1)) (pqG m) := by
  show Qle (add (add (pqP m) (pqT m)) (pqTel (m + 1))) (add (pqP m) (pqTel m))
  have e1 : Qeq (add (add (pqP m) (pqT m)) (pqTel (m + 1)))
      (add (pqP m) (add (pqT m) (pqTel (m + 1)))) := by
    simp only [Qeq, add]; push_cast; ring_uor
  refine Qle_trans ?_ (Qeq_le e1) (Qadd_le_add (Qle_refl (pqP m)) (pqT_tel_le hm))
  exact add_den_pos (pqP_den_pos m) (add_den_pos (pqT_den_pos m) (pqTel_den_pos (by omega)))

/-- `g(a+b) ≤ g(a)` for `a ≥ 1` (monotone descent). -/
private theorem pqG_mono {a : Nat} (ha : 1 ≤ a) : ∀ b, Qle (pqG (a + b)) (pqG a)
  | 0 => Qle_refl _
  | (b + 1) => by
    have h := pqG_mono ha b
    have hstep := pqG_step (show 1 ≤ a + b by omega)
    have e : a + (b + 1) = (a + b) + 1 := by omega
    rw [e]
    exact Qle_trans (pqG_den_pos (show 1 ≤ a + b by omega)) hstep h

/-- `S` is monotone (positive terms). -/
private theorem pqP_mono {a b : Nat} (hab : a ≤ b) : Qle (pqP a) (pqP b) := by
  obtain ⟨d, rfl⟩ := Nat.le.dest hab
  clear hab
  induction d with
  | zero => exact Qle_refl _
  | succ k ih =>
    have e : a + (k + 1) = (a + k) + 1 := by omega
    rw [e]
    show Qle (pqP a) (add (pqP (a + k)) (pqT (a + k)))
    exact Qle_trans (pqP_den_pos (a + k)) ih (Qle_self_add (by show (0 : Int) ≤ 3; decide))

/-- **The uniform sum bound**: every positive partial sum is `≤ 366/100`. -/
private theorem pqP_le_366 (m : Nat) : Qle (pqP m) (⟨366, 100⟩ : Q) := by
  by_cases h12 : m ≤ 12
  · exact Qle_trans (pqP_den_pos 12) (pqP_mono h12) (by decide)
  · have hm12 : 12 ≤ m := by omega
    obtain ⟨d, hd⟩ := Nat.le.dest hm12
    have hSg : Qle (pqP m) (pqG m) := by
      show Qle (pqP m) (add (pqP m) (pqTel m))
      exact Qle_self_add (by show (0 : Int) ≤ 3; decide)
    have hgmono : Qle (pqG m) (pqG 12) := by
      rw [← hd]; exact pqG_mono (by omega) d
    have hg12 : Qle (pqG 12) (⟨366, 100⟩ : Q) := by decide
    exact Qle_trans (pqG_den_pos (by omega)) hSg
      (Qle_trans (pqG_den_pos (by omega)) hgmono hg12)

-- ===========================================================================
-- The core as a constructive real (direct-sequence), and ψ(1/4).
-- ===========================================================================

/-- The core sequence `−S(j+2)` (depth schedule `j ↦ j+2`). -/
private def pqseq (j : Nat) : Q := neg (pqP (j + 2))

private theorem pqseq_den_pos (j : Nat) : 0 < (pqseq j).den :=
  pqP_den_pos (j + 2)

/-- **The regularity tail bound**: `|S(k+2) − S(j+2)| ≤ 1/(j+1)` for `j ≤ k`. -/
private theorem pqseq_reg_le {j k : Nat} (hjk : j ≤ k) :
    Qle (Qabs (Qsub (pqseq j) (pqseq k))) (Qbound j) := by
  obtain ⟨d, hd⟩ := Nat.le.dest hjk
  have hge : Qle (pqP (j + 2)) (pqP (k + 2)) := pqP_mono (by omega)
  have hnn : (0 : Int) ≤ (Qsub (pqP (k + 2)) (pqP (j + 2))).num :=
    num_nonneg_of_Qzero_le (Qsub_nonneg_of_le hge)
  have htail : Qle (Qsub (pqP (k + 2)) (pqP (j + 2))) (pqTel (j + 2)) := by
    have hgm : Qle (pqG (k + 2)) (pqG (j + 2)) := by
      have e : k + 2 = (j + 2) + d := by omega
      rw [e]; exact pqG_mono (by omega) d
    have hSg : Qle (pqP (k + 2)) (pqG (k + 2)) := by
      show Qle (pqP (k + 2)) (add (pqP (k + 2)) (pqTel (k + 2)))
      exact Qle_self_add (by show (0 : Int) ≤ 3; decide)
    have hchain : Qle (pqP (k + 2)) (add (pqP (j + 2)) (pqTel (j + 2))) :=
      Qle_trans (pqG_den_pos (by omega)) hSg hgm
    exact Qsub_le_of_le_add (pqP_den_pos (j + 2)) (pqTel_den_pos (by omega)) hchain
  have hbnd : Qle (pqTel (j + 2)) (Qbound j) := by
    show (3 : Int) * ((j + 1 : Nat) : Int) ≤ (1 : Int) * ((4 * (j + 2) : Nat) : Int)
    push_cast; omega
  have hveq : Qeq (Qsub (pqseq j) (pqseq k)) (Qsub (pqP (k + 2)) (pqP (j + 2))) := by
    simp only [pqseq, Qeq, Qsub, add, neg]; push_cast; ring_uor
  have habs : Qle (Qabs (Qsub (pqP (k + 2)) (pqP (j + 2)))) (Qbound j) :=
    Qle_trans (pqTel_den_pos (by omega)) (Qabs_le_of_nonneg hnn htail) hbnd
  exact Qle_trans (Qabs_den_pos (Qsub_den_pos (pqP_den_pos (k + 2)) (pqP_den_pos (j + 2))))
    (Qeq_le (Qabs_Qeq hveq)) habs

private theorem pqseq_regular : IsRegular pqseq := by
  intro m n
  rcases Nat.le_total m n with h | h
  · exact Qle_trans (Qbound_den_pos m) (pqseq_reg_le h) (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · rw [Qabs_Qsub_comm]
    exact Qle_trans (Qbound_den_pos n) (pqseq_reg_le h) (Qle_add_self (by show (0 : Int) ≤ 1; decide))

/-- **The digamma core at `1/4`** `Σ_{n≥0}[1/(n+1) − 1/(n+1/4)] = −3·Σ 1/[(n+1)(4n+1)]` as
    a genuine constructive real (direct-sequence). -/
def psiQuarterCore : Real := ⟨pqseq, pqseq_regular, pqseq_den_pos⟩

/-- **The core lower bracket**: `core ≥ −3.66` (true value `≈ −3.6498`). -/
theorem psiQuarterCore_lower : Rle (ofQ (⟨-366, 100⟩ : Q) (by decide)) psiQuarterCore := by
  intro n
  show Qle (⟨-366, 100⟩ : Q) (add (neg (pqP (n + 2))) ⟨2, n + 1⟩)
  have hP := pqP_le_366 (n + 2)
  have h1 : Qle (⟨-366, 100⟩ : Q) (neg (pqP (n + 2))) := by
    show (-366 : Int) * ((pqP (n + 2)).den : Int) ≤ -(pqP (n + 2)).num * (100 : Int)
    have hPI : (pqP (n + 2)).num * (100 : Int) ≤ (366 : Int) * ((pqP (n + 2)).den : Int) := hP
    omega
  have h2 : Qle (neg (pqP (n + 2))) (add (neg (pqP (n + 2))) ⟨2, n + 1⟩) :=
    Qle_self_add (by show (0 : Int) ≤ 2; decide)
  exact Qle_trans (b := neg (pqP (n + 2))) (pqP_den_pos (n + 2)) h1 h2

/-- **ψ(1/4)** `= −γ + core` — the exact digamma value at the window center, as a
    constructive real (the same defining series as `Digamma`, specialized to `1/4` where
    the terms are exact rationals). -/
def psiQuarter : Real := Radd (Rneg Rgamma_h) psiQuarterCore

/-- **The ψ(1/4) lower bracket**: `ψ(1/4) ≥ −4.32` (true value `≈ −4.2270`), from
    `−γ ≥ −0.66` (`Rgamma_h_upper`) and `core ≥ −3.66`. -/
theorem psiQuarter_lower : Rle (ofQ (⟨-432, 100⟩ : Q) (by decide)) psiQuarter := by
  have hgamma : Rle (ofQ (neg (⟨66, 100⟩ : Q)) (by decide)) (Rneg Rgamma_h) :=
    Rneg_ofQ_le (by decide) Rgamma_h_upper
  have hsum := Radd_le_add hgamma psiQuarterCore_lower
  have hsplit : Rle (ofQ (⟨-432, 100⟩ : Q) (by decide))
      (Radd (ofQ (neg (⟨66, 100⟩ : Q)) (by decide)) (ofQ (⟨-366, 100⟩ : Q) (by decide))) := by
    refine Rle_trans (Rle_of_Req (ofQ_congr (by decide) (add_den_pos (by decide) (by decide)) ?_))
      (Rle_ofQ_add_Radd (by decide) (by decide))
    decide
  exact Rle_trans hsplit hsum

-- ===========================================================================
-- The complementary UPPER brackets (for the Riemann–Siegel center slope, where
-- `ψ(1/4)` must be bounded ABOVE — the opposite direction to the α(0) certificate).
-- ===========================================================================

/-- **The core upper bracket**: `core ≤ −3` (true value `≈ −3.6498`). Every partial sum dominates its
    first term `pqP 1 = 3` (`pqP_mono`), so `core.seq n = −S(n+2) ≤ −3`. The complement of
    `psiQuarterCore_lower`, needed where `ψ(1/4)` must be bounded from above. -/
theorem psiQuarterCore_upper : Rle psiQuarterCore (ofQ (⟨-3, 1⟩ : Q) (by decide)) := by
  intro n
  show Qle (neg (pqP (n + 2))) (add (⟨-3, 1⟩ : Q) ⟨2, n + 1⟩)
  have h3 : Qle (⟨3, 1⟩ : Q) (pqP (n + 2)) :=
    Qle_trans (pqP_den_pos 1) (by decide) (pqP_mono (by omega))
  have hA : Qle (neg (pqP (n + 2))) (⟨-3, 1⟩ : Q) := by
    show -(pqP (n + 2)).num * (1 : Int) ≤ (-3 : Int) * ((pqP (n + 2)).den : Int)
    have h3I : (3 : Int) * ((pqP (n + 2)).den : Int) ≤ (pqP (n + 2)).num * 1 := h3
    omega
  have hB : Qle (⟨-3, 1⟩ : Q) (add (⟨-3, 1⟩ : Q) ⟨2, n + 1⟩) :=
    Qle_self_add (by show (0 : Int) ≤ 2; decide)
  exact Qle_trans (b := (⟨-3, 1⟩ : Q)) (by decide) hA hB

/-- **The ψ(1/4) upper bracket**: `ψ(1/4) ≤ −3` (true value `≈ −4.2270`), from `−γ ≤ −0.54`
    (`Rgamma_h_lower`) and `core ≤ −3`. The complement of `psiQuarter_lower`; the input to the
    Riemann–Siegel center-slope obstruction (`ψ(1/4) < log π`). -/
theorem psiQuarter_upper : Rle psiQuarter (ofQ (⟨-3, 1⟩ : Q) (by decide)) := by
  have hconv : Rle (Rneg (ofQ (⟨54, 100⟩ : Q) (by decide))) (ofQ (⟨-54, 100⟩ : Q) (by decide)) :=
    fun n => Qle_self_add (by show (0 : Int) ≤ 2; decide)
  have hneg_gamma : Rle (Rneg Rgamma_h) (ofQ (⟨-54, 100⟩ : Q) (by decide)) :=
    Rle_trans (Rneg_le Rgamma_h_lower) hconv
  have hsum := Radd_le_add hneg_gamma psiQuarterCore_upper
  refine Rle_trans hsum ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (by decide) (by decide))) ?_
  exact Rle_ofQ_ofQ (by decide) (by decide) (by decide)

/-- The integer core of the `n < 6` branch (`S(n+2) ≥ S(2) = 3.3`, slack covers the gap), with the
    nonlinear `m·pn` discharged by a factored `ring_uor` key. -/
private theorem core_upper_step_lt6 (m pn pd : Int) (hpd : 0 ≤ pd) (h2I : 33 * pd ≤ pn * 10)
    (hm6 : m ≤ 6) (hm1 : 1 ≤ m) : -pn * (100 * m) ≤ (-346 * m + 200) * pd := by
  have hP : (0 : Int) ≤ 10 * m * (10 * pn - 33 * pd) :=
    Int.mul_nonneg (Int.mul_nonneg (by decide) (by omega)) (by omega)
  have hQ : (0 : Int) ≤ pd * (200 - 16 * m) := Int.mul_nonneg hpd (by omega)
  have hkey : (-346 * m + 200) * pd - (-pn * (100 * m))
      = 10 * m * (10 * pn - 33 * pd) + pd * (200 - 16 * m) := by ring_uor
  omega

/-- The integer core of the `n ≥ 6` branch (`S(n+2) ≥ S(8) ≥ 3.46`), nonlinear `m·pn` factored out. -/
private theorem core_upper_step_ge6 (m pn pd : Int) (hpd : 0 ≤ pd) (h8I : 346 * pd ≤ pn * 100)
    (hm0 : 0 ≤ m) : -pn * (100 * m) ≤ (-346 * m + 200) * pd := by
  have hP : (0 : Int) ≤ m * (100 * pn - 346 * pd) := Int.mul_nonneg hm0 (by omega)
  have hkey : (-346 * m + 200) * pd - (-pn * (100 * m))
      = m * (100 * pn - 346 * pd) + 200 * pd := by ring_uor
  omega

/-- **The sharp core upper bracket**: `core ≤ −3.46` (true value `≈ −3.6498`). For `n ≥ 6` the
    approximant `−S(n+2)` is dominated using `S(8) ≥ 3.46`; for `n < 6` the slack `2/(n+1)` covers the
    gap to `S(2) = 3.3`. The nonlinear `n·S.num` terms are discharged by factored `ring_uor` keys. -/
theorem psiQuarterCore_upper_tight : Rle psiQuarterCore (ofQ (⟨-346, 100⟩ : Q) (by decide)) := by
  intro n
  show Qle (neg (pqP (n + 2))) (add (⟨-346, 100⟩ : Q) ⟨2, n + 1⟩)
  have hpd0 : (0 : Int) ≤ ((pqP (n + 2)).den : Int) := Int.ofNat_nonneg _
  simp only [Qle, neg, add]
  push_cast
  rcases Nat.lt_or_ge n 6 with h | h
  · have h2I : 33 * ((pqP (n + 2)).den : Int) ≤ (pqP (n + 2)).num * 10 := by
      have hh : Qle (⟨33, 10⟩ : Q) (pqP (n + 2)) :=
        Qle_trans (pqP_den_pos 2) (by decide) (pqP_mono (by omega))
      have hx := hh; simp only [Qle] at hx; push_cast at hx; omega
    exact core_upper_step_lt6 ((n : Int) + 1) (pqP (n + 2)).num ((pqP (n + 2)).den : Int)
      hpd0 h2I (by omega) (by omega)
  · have h8I : 346 * ((pqP (n + 2)).den : Int) ≤ (pqP (n + 2)).num * 100 := by
      have hh : Qle (⟨346, 100⟩ : Q) (pqP (n + 2)) :=
        Qle_trans (pqP_den_pos 8) (by decide) (pqP_mono (by omega))
      have hx := hh; simp only [Qle] at hx; push_cast at hx; omega
    exact core_upper_step_ge6 ((n : Int) + 1) (pqP (n + 2)).num ((pqP (n + 2)).den : Int)
      hpd0 h8I (by omega)

/-- **The sharp ψ(1/4) upper bracket**: `ψ(1/4) ≤ −4` (true value `≈ −4.2270`), from `−γ ≤ −0.54`
    (`Rgamma_h_lower`) and `core ≤ −3.46`. Tightens `psiQuarter_upper` (`≤ −3`); the input to the
    Burnol-multiplier indefiniteness bound. -/
theorem psiQuarter_upper_tight : Rle psiQuarter (ofQ (⟨-4, 1⟩ : Q) (by decide)) := by
  have hconv : Rle (Rneg (ofQ (⟨54, 100⟩ : Q) (by decide))) (ofQ (⟨-54, 100⟩ : Q) (by decide)) :=
    fun n => Qle_self_add (by show (0 : Int) ≤ 2; decide)
  have hneg_gamma : Rle (Rneg Rgamma_h) (ofQ (⟨-54, 100⟩ : Q) (by decide)) :=
    Rle_trans (Rneg_le Rgamma_h_lower) hconv
  have hsum := Radd_le_add hneg_gamma psiQuarterCore_upper_tight
  refine Rle_trans hsum ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (by decide) (by decide))) ?_
  exact Rle_ofQ_ofQ (by decide) (by decide) (by decide)

end UOR.Bridge.F1Square.Analysis
