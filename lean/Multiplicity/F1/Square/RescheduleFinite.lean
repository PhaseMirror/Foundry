/-
F1 square — **the finite reschedule of the twisted dilation covariance** (`RescheduleFinite.lean`):
summing the committed per-window covariance `twTerm_dilate_window` over `m < N` and telescoping the
`s`-scaled window tiling into a single cap integral.

The committed per-window identity gives, for each window,

    `∫_{s(m+1)}^{s(m+2)} (φ · powBandGen)  =  s^(n+1) · twTerm (dilate_s φ) n m`.

Pulling the constant `s^(n+1)` through the finite sum (`Rmul_RsumN_left`), rewriting each summand by
the per-window covariance (`RsumN_congr`, with the per-`m` band containment derived from the global
`N`-covering hypotheses via `qmul_le_left_mono`/`Qle_trans`), and telescoping the adjacent scaled
windows `[s(m+1), s(m+2)]` (`riemannIntegralI_telescope` with node sequence `c m = s(m+1)`) collapses
the tail partial-sum into the single cap integral over `[s·1, s·(N+1)]`:

    `s^(n+1) · Σ_{m<N} twTerm (dilate_s φ) n m  =  ∫_{s·1}^{s·(N+1)} (φ · powBandGen)`.

HONEST SCOPE. The finite reschedule — summing the committed per-window twisted dilation covariance
`twTerm_dilate_window` over `m < N` (constant-pull `Rmul_RsumN_left` + `RsumN_congr` with per-`m`
band containment) and telescoping the `s`-scaled window tiling (`riemannIntegralI_telescope`, node
`c m = s(m+1)`) into a single cap integral over `[s, s(N+1)]`. The band `[lo, hi]` depends on `N`
(it covers up to the `N`-th window), which is honest: `tⁿ` is unbounded so no single weight spans the
whole half-line. It builds NO half-line limit, NO boundary reconciliation, NO factorization, NO
positivity, NO determinacy, NO crux. The improper/half-line assembly is a LATER brick. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.TwTermDilateWindow
import Multiplicity.F1Square.Square.IntervalTelescope
import Multiplicity.F1Square.Square.WeilPSD
import Multiplicity.F1Square.Analysis.QOrder

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The `s`-scaled integer node `c m = s·(m+1)`, the endpoint sequence tiling the scaled cap. -/
private def capNode (s : Q) (m : Nat) : Q := mul s (⟨(m : Int) + 1, 1⟩ : Q)

/-- The numerator of an adjacent-node difference: `(s(a+1) − s(b+1)).num = s.den·s.num·(a − b)`. -/
private theorem capDiff_num (s : Q) (a b : Nat) :
    (Qsub (capNode s a) (capNode s b)).num
      = (s.den : Int) * (s.num * ((a : Int) - (b : Int))) := by
  simp only [capNode, Qsub, mul, add, neg]; push_cast; ring_uor

set_option maxHeartbeats 4000000 in
/-- **THE FINITE RESCHEDULE OF THE TWISTED DILATION COVARIANCE.** With a band `[lo, hi]` covering
    every integer window `[m+1, m+2]` and every scaled window `[s(m+1), s(m+2)]` for `m < N`
    (`hlo1`/`hlos` bound the low end, `hhiN`/`hhisN` the high end), the `s^(n+1)`-scaled tail
    partial-sum of `twTerm (dilate_s φ)` reschedules into the single integral of the ORIGINAL `φ`
    against `powBandGen` over the scaled cap `[s·1, s·(N+1)]`:

      `s^(n+1) · Σ_{m<N} twTerm (dilate_s φ) n m  =  ∫_{s·1}^{s·(N+1)} (φ · powBandGen)`. -/
theorem reschedule_finite
    (φ : L2Test) (n N : Nat) (s : Q) (hsn : 0 < s.num) (hsd : 0 < s.den)
    (lo hi : Q) (hlod : 0 < lo.den) (hhid : 0 < hi.den) (hle : Qle lo hi) (hlon : 0 ≤ lo.num)
    (hlo1 : Qle lo (⟨1, 1⟩ : Q))
    (hlos : Qle lo (mul s (⟨1, 1⟩ : Q)))
    (hhiN : Qle (⟨(N : Int) + 1, 1⟩ : Q) hi)
    (hhisN : Qle (mul s (⟨(N : Int) + 1, 1⟩ : Q)) hi) :
    Req
      (Rmul (ofQ (qpow s (n + 1)) (qpow_den_pos hsd (n + 1)))
        (RsumN (fun m => twTerm (dilateTest s hsn hsd φ) n m) N))
      (riemannIntegralI
        (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLd
        (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLn
        (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hlip
        (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hfc
        (mul s (⟨1, 1⟩ : Q))
        (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q)))
        (Qmul_den_pos hsd Nat.one_pos)
        (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
        (by
          have e : (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))).num
              = (s.den : Int) * (s.num * (N : Int)) := by
            simp only [Qsub, mul, add, neg]; push_cast; ring_uor
          rw [e]
          exact Int.mul_nonneg (Int.ofNat_nonneg _)
            (Int.mul_nonneg (Int.le_of_lt hsn) (Int.ofNat_nonneg _)))) := by
  have hs : (0 : Int) ≤ s.num := Int.le_of_lt hsn
  -- Telescope endpoint data for the node sequence `capNode s`.
  have hcden : ∀ m : Nat, 0 < (capNode s m).den := fun _ => Qmul_den_pos hsd Nat.one_pos
  have hwinN : ∀ m : Nat, 0 ≤ (Qsub (capNode s (m + 1)) (capNode s m)).num := by
    intro m
    rw [capDiff_num]
    exact Int.mul_nonneg (Int.ofNat_nonneg _) (Int.mul_nonneg hs (by push_cast; omega))
  have hWnN : ∀ M : Nat, 0 ≤ (Qsub (capNode s M) (capNode s 0)).num := by
    intro M
    rw [capDiff_num]
    exact Int.mul_nonneg (Int.ofNat_nonneg _) (Int.mul_nonneg hs (by push_cast; omega))
  have hWposN : ∀ M : Nat, 0 < (Qsub (capNode s (M + 1)) (capNode s 0)).num := by
    intro M
    rw [capDiff_num]
    exact Int.mul_pos (by exact_mod_cast hsd) (Int.mul_pos hsn (by push_cast; omega))
  have hWleN : ∀ M : Nat,
      Qle (Qsub (capNode s M) (capNode s 0)) (Qsub (capNode s (M + 1)) (capNode s 0)) := by
    intro M
    have hnum : (Qsub (capNode s M) (capNode s 0)).num
        ≤ (Qsub (capNode s (M + 1)) (capNode s 0)).num := by
      rw [capDiff_num, capDiff_num]
      refine Int.mul_le_mul_of_nonneg_left ?_ (Int.ofNat_nonneg _)
      refine Int.mul_le_mul_of_nonneg_left ?_ hs
      push_cast; omega
    show (Qsub (capNode s M) (capNode s 0)).num
          * ((Qsub (capNode s (M + 1)) (capNode s 0)).den : Int)
        ≤ (Qsub (capNode s (M + 1)) (capNode s 0)).num
          * ((Qsub (capNode s M) (capNode s 0)).den : Int)
    have hd : ((Qsub (capNode s (M + 1)) (capNode s 0)).den : Int)
        = ((Qsub (capNode s M) (capNode s 0)).den : Int) := rfl
    rw [hd]
    exact Int.mul_le_mul_of_nonneg_right hnum (Int.ofNat_nonneg _)
  have hremN : ∀ M : Nat, 0 ≤
      (Qsub (Qsub (capNode s (M + 1)) (capNode s 0))
        (Qsub (capNode s M) (capNode s 0))).num := by
    intro M
    have e : (Qsub (Qsub (capNode s (M + 1)) (capNode s 0))
          (Qsub (capNode s M) (capNode s 0))).num
        = (s.den : Int) * ((s.den : Int) * ((s.den : Int) * s.num)) := by
      simp only [capNode, Qsub, mul, add, neg]; push_cast; ring_uor
    rw [e]
    exact Int.mul_nonneg (Int.ofNat_nonneg _)
      (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.mul_nonneg (Int.ofNat_nonneg _) hs))
  -- STEP 3 (telescope): the sum of the scaled windows collapses to the cap `[s·1, s·(N+1)]`.
  have htel := riemannIntegralI_telescope
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLd
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLn
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hlip
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hfc
    (capNode s) hcden hwinN hWnN hWposN hWleN hremN N
  -- STEP 3′ (endpoint reconcile): match the telescope's `c 0 = s·(0+1)` to the stated `s·1`.
  have hrecon := riemannIntegralI_congr_Q
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLd
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLn
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hlip
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hfc
    (capNode s 0) (Qsub (capNode s N) (capNode s 0))
    (mul s (⟨1, 1⟩ : Q)) (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q)))
    (hcden 0) (Qsub_den_pos (hcden N) (hcden 0)) (hWnN N)
    (Qmul_den_pos hsd Nat.one_pos)
    (Qsub_den_pos (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos))
    (by
      have e : (Qsub (mul s (⟨(N : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))).num
          = (s.den : Int) * (s.num * (N : Int)) := by
        simp only [Qsub, mul, add, neg]; push_cast; ring_uor
      rw [e]
      exact Int.mul_nonneg (Int.ofNat_nonneg _)
        (Int.mul_nonneg (Int.le_of_lt hsn) (Int.ofNat_nonneg _)))
    (by simp only [capNode, Qeq, mul]; push_cast; ring_uor)
    (by simp only [capNode, Qeq, Qsub, mul, add, neg]; push_cast; ring_uor)
  -- Chain STEP 1 (constant-pull) · STEP 2 (per-window covariance) · STEP 3/3′.
  refine Req_trans (Rmul_RsumN_left _ _ N) (Req_trans (RsumN_congr N ?_) (Req_trans htel hrecon))
  intro i him
  -- Per-`m` band containment from the global `N`-covering hypotheses.
  have hc1 : Qle lo (⟨(i : Int) + 1, 1⟩ : Q) :=
    Qle_trans (by decide) hlo1 (by simp only [Qle]; omega)
  have hc2 : Qle (⟨(i : Int) + 2, 1⟩ : Q) hi :=
    Qle_trans Nat.one_pos (by simp only [Qle]; omega) hhiN
  have hc3 : Qle lo (mul s (⟨(i : Int) + 1, 1⟩ : Q)) :=
    Qle_trans (Qmul_den_pos hsd Nat.one_pos) hlos
      (qmul_le_left_mono hs (by simp only [Qle]; omega))
  have hc4 : Qle (mul s (⟨(i : Int) + 2, 1⟩ : Q)) hi :=
    Qle_trans (Qmul_den_pos hsd Nat.one_pos)
      (qmul_le_left_mono hs (by simp only [Qle]; omega)) hhisN
  -- STEP 2: the committed per-window covariance, reconciled to the telescope window.
  refine Req_trans
    (Req_symm (twTerm_dilate_window φ n i s hsn hsd lo hi hlod hhid hle hlon hc1 hc2 hc3 hc4)) ?_
  exact riemannIntegralI_congr_Q
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLd
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hLn
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hlip
    (L2Test.mul φ (powBandGen lo hi hlod hhid hle hlon n)).hfc
    (mul s (⟨(i : Int) + 1, 1⟩ : Q)) (mul s (⟨1, 1⟩ : Q))
    (capNode s i) (Qsub (capNode s (i + 1)) (capNode s i))
    (Qmul_den_pos hsd Nat.one_pos) (Qmul_den_pos hsd Nat.one_pos)
    (Int.mul_nonneg hs (by decide))
    (hcden i) (Qsub_den_pos (hcden (i + 1)) (hcden i)) (hwinN i)
    (by simp only [capNode]; exact Qeq_refl _)
    (by simp only [capNode, Qeq, Qsub, mul, add, neg]; push_cast; ring_uor)

end Multiplicity.UOR.Bridge.F1Square.Square
