/-
F1 square — the frontier construction: **the archimedean kernel `Re ψ(1/4 + iτ/2)` ASSEMBLED as a
constructive real at a frontier point**, and the consequence — the Riemann–Siegel angle is
non-monotone TWO-SIDEDLY.

`DigammaWindow.lean` built the `τ`-parameterized kernel TERM `windowTerm n s = 1/(n+1) −
(n+1/4)/((n+1/4)² + s)` (`s = τ²/4`) and its monotonicity, and recorded — honestly — that the
multiplier `α(τ)` is indefinite and that the assembled kernel was not yet built. THIS FILE builds the
assembled kernel at the concrete frontier point `τ = 10` (`s = 25`), the first value of `Re ψ` along
the critical line away from the center `ψ(1/4)`.

THE DECOMPOSITION. The window term splits EXACTLY into the center term and a positive correction:
    `windowTerm n 25 = windowTerm n 0 + cₙ`,   `cₙ = s/((n+1/4)((n+1/4)²+s)) = 1600/((4n+1)((4n+1)²+400)) ≥ 0`,
and `windowTerm n 0 = −3/[(n+1)(4n+1)]` is exactly `ψ(1/4)`'s summand (`DigammaWindow.windowTerm_zero`).
So `Re ψ(1/4 + 5i) = −γ + Σ windowTerm n 25 = ψ(1/4) + Σ cₙ`. We build `Σ cₙ` (`corrCore`) as a
genuine constructive real — a manifestly POSITIVE convergent series — and set
`psiLineRe5 := ψ(1/4) + corrCore`.

THE TELESCOPING (regularity, from scratch). `cₙ ≤ tel(n) − tel(n+1)` with `tel(n) = 100/(4n+1)`,
for ALL `n` — the comparison reduces to `(4n−1)² + 380 ≥ 0` (a manifest square). So the partial
sums are Cauchy with the depth schedule `j ↦ 25(j+1)` (`tail ≤ tel(25(j+1)) = 100/(100j+101) ≤
1/(j+1)`), giving a regular sequence in the Bishop sense.

THE CONSEQUENCE. `Re ψ(1/4 + 5i) ≥ −4.32 + Σ_{n<12} cₙ ≥ −4.32 + 5.6 = 1.28 > log π`, so the
Riemann–Siegel center slope `θ′(0) = ½(ψ(1/4) − log π) < 0` (`RiemannSiegel.rsCenterSlope_neg`) is
matched by a POSITIVE slope out at `τ = 10`: `θ′(10) = ½(Re ψ(1/4+5i) − log π) > 0`. The angle
DECREASES through the center and INCREASES out on the line — non-monotone, two-sided, an axiom-clean
theorem. This is exactly the bounded-negative-band structure Burnol / Connes–Consani must work
around; it is the obstruction, sharpened, NOT a route through it. Crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.PsiQuarter
import F1Square.Analysis.DigammaWindow
import F1Square.Analysis.RiemannSiegel
import F1Square.Analysis.LogPiLower

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The positive correction term cₙ = s/((n+1/4)((n+1/4)²+s)) at s = 25 (τ = 10),
-- in exact-rational form 1600/((4n+1)((4n+1)²+400)), and its telescoping bound.
-- ===========================================================================

/-- The positive correction `cₙ = 1600/[(4n+1)((4n+1)²+400)]` — the gain of `Re ψ(1/4+iτ/2)` over
    `ψ(1/4)` at `s = τ²/4 = 25`, summand by summand. -/
private def corrT (n : Nat) : Q := ⟨1600, (4 * n + 1) * ((4 * n + 1) * (4 * n + 1) + 400)⟩

private theorem corrT_den_pos (n : Nat) : 0 < (corrT n).den :=
  Nat.mul_pos (by omega) (by omega)

/-- The telescoping comparison value `tel(n) = 100/(4n+1)`. -/
private def corrTel (n : Nat) : Q := ⟨100, 4 * n + 1⟩

private theorem corrTel_den_pos (n : Nat) : 0 < (corrTel n).den := by
  show 0 < 4 * n + 1; omega

/-- The positive partial sums `S(N) = Σ_{i<N} cᵢ`. -/
private def corrP : Nat → Q
  | 0 => ⟨0, 1⟩
  | (N + 1) => add (corrP N) (corrT N)

private theorem corrP_den_pos : ∀ N, 0 < (corrP N).den
  | 0 => by decide
  | (N + 1) => add_den_pos (corrP_den_pos N) (corrT_den_pos N)

/-- **The per-term telescoping bound** `cₙ ≤ tel(n) − tel(n+1)` for ALL `n` — the comparison reduces
    to `(4n−1)² + 380 ≥ 0`, a manifest square (with `K = 100`). -/
private theorem corrT_le_teldiff (n : Nat) :
    Qle (corrT n) (Qsub (corrTel n) (corrTel (n + 1))) := by
  simp only [corrT, corrTel, Qsub, Qle, add, neg]
  push_cast
  have key :
      (100 * (4 * ((n : Int) + 1) + 1) + -100 * (4 * (n : Int) + 1))
        * ((4 * (n : Int) + 1) * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 400))
      = 1600 * ((4 * (n : Int) + 1) * (4 * ((n : Int) + 1) + 1))
        + 400 * (4 * (n : Int) + 1) * ((4 * (n : Int) - 1) * (4 * (n : Int) - 1) + 380) := by
    ring_uor
  rw [key]
  have hnn : (0 : Int) ≤ 400 * (4 * (n : Int) + 1)
      * ((4 * (n : Int) - 1) * (4 * (n : Int) - 1) + 380) := by
    refine Int.mul_nonneg (Int.mul_nonneg (by decide) (by omega)) ?_
    have hsq : (0 : Int) ≤ (4 * (n : Int) - 1) * (4 * (n : Int) - 1) := by
      rcases Int.le_total 0 (4 * (n : Int) - 1) with h | h
      · exact Int.mul_nonneg h h
      · have h' : (0 : Int) ≤ -(4 * (n : Int) - 1) := by omega
        have hh : (0 : Int) ≤ (-(4 * (n : Int) - 1)) * (-(4 * (n : Int) - 1)) := Int.mul_nonneg h' h'
        simpa using hh
    omega
  omega

-- ===========================================================================
-- The monotone auxiliary g(m) = S(m) + tel(m), and the tail bound.
-- ===========================================================================

/-- `g(m) = S(m) + tel(m)`. -/
private def corrG (m : Nat) : Q := add (corrP m) (corrTel m)

private theorem corrG_den_pos (m : Nat) : 0 < (corrG m).den :=
  add_den_pos (corrP_den_pos m) (corrTel_den_pos m)

/-- `cₘ + tel(m+1) ≤ tel(m)` (the telescoping step, rearranged). -/
private theorem corrT_tel_le (m : Nat) :
    Qle (add (corrT m) (corrTel (m + 1))) (corrTel m) := by
  have hadd := Qadd_le_add (corrT_le_teldiff m) (Qle_refl (corrTel (m + 1)))
  have e3 : Qeq (add (Qsub (corrTel m) (corrTel (m + 1))) (corrTel (m + 1))) (corrTel m) := by
    simp only [Qeq, add, Qsub, neg]; push_cast; ring_uor
  refine Qle_trans ?_ hadd (Qeq_le e3)
  exact add_den_pos (Qsub_den_pos (corrTel_den_pos m) (corrTel_den_pos (m + 1)))
    (corrTel_den_pos (m + 1))

/-- One step: `g(m+1) ≤ g(m)`. -/
private theorem corrG_step (m : Nat) : Qle (corrG (m + 1)) (corrG m) := by
  show Qle (add (add (corrP m) (corrT m)) (corrTel (m + 1))) (add (corrP m) (corrTel m))
  have e1 : Qeq (add (add (corrP m) (corrT m)) (corrTel (m + 1)))
      (add (corrP m) (add (corrT m) (corrTel (m + 1)))) := by
    simp only [Qeq, add]; push_cast; ring_uor
  refine Qle_trans ?_ (Qeq_le e1) (Qadd_le_add (Qle_refl (corrP m)) (corrT_tel_le m))
  exact add_den_pos (corrP_den_pos m) (add_den_pos (corrT_den_pos m) (corrTel_den_pos (m + 1)))

/-- `g(a+b) ≤ g(a)` (monotone descent, from `m = 0`). -/
private theorem corrG_mono : ∀ a b, Qle (corrG (a + b)) (corrG a)
  | _, 0 => Qle_refl _
  | a, (b + 1) => by
    have h := corrG_mono a b
    have hstep := corrG_step (a + b)
    have e : a + (b + 1) = (a + b) + 1 := by omega
    rw [e]
    exact Qle_trans (corrG_den_pos (a + b)) hstep h

/-- `S` is monotone (positive terms). -/
private theorem corrP_mono {a b : Nat} (hab : a ≤ b) : Qle (corrP a) (corrP b) := by
  obtain ⟨d, rfl⟩ := Nat.le.dest hab
  clear hab
  induction d with
  | zero => exact Qle_refl _
  | succ k ih =>
    have e : a + (k + 1) = (a + k) + 1 := by omega
    rw [e]
    show Qle (corrP a) (add (corrP (a + k)) (corrT (a + k)))
    exact Qle_trans (corrP_den_pos (a + k)) ih (Qle_self_add (by show (0 : Int) ≤ 1600; decide))

-- ===========================================================================
-- The correction series as a constructive real (depth schedule j ↦ 25(j+1)).
-- ===========================================================================

/-- The correction sequence `S(25(j+1))` (depth schedule `j ↦ 25(j+1)`). -/
private def corrseq (j : Nat) : Q := corrP (25 * (j + 1))

private theorem corrseq_den_pos (j : Nat) : 0 < (corrseq j).den :=
  corrP_den_pos (25 * (j + 1))

/-- **The regularity tail bound** `|S(25(k+1)) − S(25(j+1))| ≤ 1/(j+1)` for `j ≤ k`. -/
private theorem corrseq_reg_le {j k : Nat} (hjk : j ≤ k) :
    Qle (Qabs (Qsub (corrseq j) (corrseq k))) (Qbound j) := by
  rw [Qabs_Qsub_comm]
  obtain ⟨d, hd⟩ := Nat.le.dest hjk
  have hge : Qle (corrP (25 * (j + 1))) (corrP (25 * (k + 1))) := corrP_mono (by omega)
  have hnn : (0 : Int) ≤ (Qsub (corrP (25 * (k + 1))) (corrP (25 * (j + 1)))).num :=
    num_nonneg_of_Qzero_le (Qsub_nonneg_of_le hge)
  have htail : Qle (Qsub (corrP (25 * (k + 1))) (corrP (25 * (j + 1)))) (corrTel (25 * (j + 1))) := by
    have hgm : Qle (corrG (25 * (k + 1))) (corrG (25 * (j + 1))) := by
      have e : 25 * (k + 1) = 25 * (j + 1) + 25 * d := by omega
      rw [e]; exact corrG_mono (25 * (j + 1)) (25 * d)
    have hSg : Qle (corrP (25 * (k + 1))) (corrG (25 * (k + 1))) := by
      show Qle (corrP (25 * (k + 1))) (add (corrP (25 * (k + 1))) (corrTel (25 * (k + 1))))
      exact Qle_self_add (by show (0 : Int) ≤ 100; decide)
    have hchain : Qle (corrP (25 * (k + 1))) (add (corrP (25 * (j + 1))) (corrTel (25 * (j + 1)))) :=
      Qle_trans (corrG_den_pos (25 * (k + 1))) hSg hgm
    exact Qsub_le_of_le_add (corrP_den_pos (25 * (j + 1))) (corrTel_den_pos (25 * (j + 1))) hchain
  have hbnd : Qle (corrTel (25 * (j + 1))) (Qbound j) := by
    show (100 : Int) * ((j + 1 : Nat) : Int) ≤ (1 : Int) * ((4 * (25 * (j + 1)) + 1 : Nat) : Int)
    push_cast; omega
  -- `corrseq k ≡ corrP (25(k+1))` definitionally, so `habs` already has the goal's type.
  exact Qle_trans (corrTel_den_pos (25 * (j + 1))) (Qabs_le_of_nonneg hnn htail) hbnd

private theorem corrseq_regular : IsRegular corrseq := by
  intro m n
  rcases Nat.le_total m n with h | h
  · exact Qle_trans (Qbound_den_pos m) (corrseq_reg_le h) (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · rw [Qabs_Qsub_comm]
    exact Qle_trans (Qbound_den_pos n) (corrseq_reg_le h) (Qle_add_self (by show (0 : Int) ≤ 1; decide))

/-- **The correction series** `Σ_{n≥0} cₙ = Σ 1600/[(4n+1)((4n+1)²+400)]` as a genuine constructive
    real — the gain of `Re ψ(1/4 + 5i)` over `ψ(1/4)`. Manifestly positive (sum of positives). -/
def corrCore : Real := ⟨corrseq, corrseq_regular, corrseq_den_pos⟩

/-- **`corrCore ≥ S(12)`**: the limit dominates the 12-term partial sum (the depth schedule starts at
    `25 > 12`, so every approximant `S(25(j+1))` already dominates `S(12)` by monotonicity). -/
theorem corrCore_ge_twelve : Rle (ofQ (corrP 12) (corrP_den_pos 12)) corrCore := by
  intro j
  show Qle (corrP 12) (add (corrP (25 * (j + 1))) ⟨2, j + 1⟩)
  exact Qle_trans (corrP_den_pos (25 * (j + 1))) (corrP_mono (by omega))
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- **`S(12) ≥ 5.6`**: the 12-term partial sum, certified (true value `≈ 5.7534`). -/
theorem corrP_twelve_lower : Rle (ofQ (⟨56, 10⟩ : Q) (by decide)) (ofQ (corrP 12) (corrP_den_pos 12)) :=
  Rle_ofQ_ofQ (by decide) (corrP_den_pos 12) (by decide)

/-- **`corrCore ≥ 5.6`**, the certified lower bracket of the correction series. -/
theorem corrCore_lower : Rle (ofQ (⟨56, 10⟩ : Q) (by decide)) corrCore :=
  Rle_trans corrP_twelve_lower corrCore_ge_twelve

-- ===========================================================================
-- The assembled archimedean kernel Re ψ(1/4 + 5i) and its lower bracket.
-- ===========================================================================

/-- **`Re ψ(1/4 + 5i)`** — the archimedean kernel at the frontier point `τ = 10` (`s = τ²/4 = 25`),
    `= ψ(1/4) + Σ cₙ`. The first assembled value of `Re ψ` along the critical line off-center. -/
def psiLineRe5 : Real := Radd psiQuarter corrCore

/-- **The faithfulness bridge**: the correction term `cₙ` IS the gain of the `DigammaWindow` kernel
    term over its center value, `windowTerm n 25 1 = windowTerm n 0 1 + cₙ` — i.e. `psiLineRe5` is
    built from exactly `DigammaWindow`'s `Re ψ` summands at `s = 25`. -/
theorem corrT_eq_windowTerm_gain (n : Nat) :
    Qeq (corrT n) (Qsub (windowTerm n 25 1) (windowTerm n 0 1)) := by
  simp only [corrT, windowTerm, windowKernel, Qsub, Qeq, add, neg]; push_cast; ring_uor

/-- **The lower bracket `Re ψ(1/4 + 5i) ≥ 1.28`** (true value `≈ 1.61`), from `ψ(1/4) ≥ −4.32`
    (`psiQuarter_lower`) and `Σ cₙ ≥ 5.6` (`corrCore_lower`). Comfortably above `log π ≈ 1.1447` —
    the climb of the archimedean kernel out along the critical line. -/
theorem psiLineRe5_lower : Rle (ofQ (⟨128, 100⟩ : Q) (by decide)) psiLineRe5 := by
  have hsum := Radd_le_add psiQuarter_lower corrCore_lower
  refine Rle_trans ?_ hsum
  refine Rle_trans (Rle_of_Req (ofQ_congr (by decide)
    (add_den_pos (by decide) (by decide)) ?_)) (Rle_ofQ_add_Radd (by decide) (by decide))
  decide

-- ===========================================================================
-- The capstone: the Riemann–Siegel angle is non-monotone, two-sided.
-- ===========================================================================

/-- **`θ′(10) > 0` — the Riemann–Siegel angle INCREASES out at `τ = 10`.** `Re ψ(1/4 + 5i) − log π >
    0`, from `Re ψ(1/4 + 5i) ≥ 1.28` (`psiLineRe5_lower`) and `log π ≤ 1.1453` (`Rlogπc_le`): the
    line slope discriminant `≥ 1.28 − 1.15 = 0.13 > 0`. (Same `log π = Rlogπc` as the center slope.) -/
theorem rsLineSlope10_pos : Pos (Rsub psiLineRe5 Rlogπc) := by
  have hlogle : Rle Rlogπc (ofQ (⟨115, 100⟩ : Q) (by decide)) :=
    Rle_trans Rlogπc_le (Rle_ofQ_ofQ _ (by decide) (by decide))
  have hstep : Rle (Rsub (ofQ (⟨128, 100⟩ : Q) (by decide)) (ofQ (⟨115, 100⟩ : Q) (by decide)))
      (Rsub psiLineRe5 Rlogπc) :=
    Rsub_le_sub psiLineRe5_lower hlogle
  refine Pos_of_Rle_ofQ (c := (⟨13, 100⟩ : Q)) (by decide) (by decide) (Rle_trans ?_ hstep)
  intro n
  show Qle (⟨13, 100⟩ : Q) (add (add (⟨128, 100⟩ : Q) (neg (⟨115, 100⟩ : Q))) ⟨2, n + 1⟩)
  simp only [Qle, add, neg]
  push_cast
  omega

/-- **THE RIEMANN–SIEGEL ANGLE IS NON-MONOTONE — TWO-SIDED, an axiom-clean theorem.** For the same
    angle `θ(t) = arg Γ(1/4 + i t/2) − (t/2)·log π` (one `log π = Rlogπc`):
    * `θ′(0) < 0` — the center slope is negative (`rsCenterSlope_neg`); `θ` DECREASES through the
      symmetry point `t = 0`;
    * `θ′(10) > 0` — out at `τ = 10` the line slope is positive (`rsLineSlope10_pos`); `θ` INCREASES.
    The slope changes sign, so `θ` is genuinely non-monotone — the bounded-negative-band structure
    Burnol / Connes–Consani must work around. The obstruction, completed as a two-sided theorem from
    the FIRST assembled value of the archimedean kernel `Re ψ(1/4 + iτ/2)` off-center (`psiLineRe5`,
    `= ψ(1/4) + Σ cₙ`). This sharpens the barrier; it does NOT cross it. The crux fields stay `none`. -/
theorem rsAngle_non_monotone : Pos (Rneg rsCenterSlope) ∧ Pos (Rsub psiLineRe5 Rlogπc) :=
  ⟨rsCenterSlope_neg, rsLineSlope10_pos⟩

-- ===========================================================================
-- The PARAMETERIZED kernel Re ψ(1/4 + iτ/2) over rational s = τ²/4 ∈ [0, 25],
-- and the MONOTONE CLIMB (θ′ increasing — θ convex on the window, the analytic
-- heart `DigammaWindow` records, now a theorem about the assembled kernel).
-- ===========================================================================

/-- The correction term `cₙ(s) = s/((n+1/4)((n+1/4)²+s))` at `s = sn/sd`, exact rational
    `64·sn / [(4n+1)((4n+1)²·sd + 16·sn)]` (`= corrT` at `s = 25`, i.e. `sn = 25, sd = 1`). -/
private def corrTP (sn sd n : Nat) : Q :=
  ⟨64 * sn, (4 * n + 1) * ((4 * n + 1) * (4 * n + 1) * sd + 16 * sn)⟩

private theorem corrTP_den_pos {sn sd : Nat} (hsd : 1 ≤ sd) (n : Nat) : 0 < (corrTP sn sd n).den := by
  show 0 < (4 * n + 1) * ((4 * n + 1) * (4 * n + 1) * sd + 16 * sn)
  have h1 : 0 < (4 * n + 1) * (4 * n + 1) * sd :=
    Nat.mul_pos (Nat.mul_pos (by omega) (by omega)) hsd
  exact Nat.mul_pos (by omega) (by omega)

/-- **`cₙ` is monotone increasing in `s`**: `s = sn/sd ≤ s' = sn'/sd'` (`sn·sd' ≤ sn'·sd`) ⟹
    `cₙ(s) ≤ cₙ(s')` — the reduction is exactly `sn·sd' ≤ sn'·sd` (divide by `(4n+1)³`). -/
private theorem corrTP_mono {sn sd sn' sd' n : Nat} (hmono : sn * sd' ≤ sn' * sd) :
    Qle (corrTP sn sd n) (corrTP sn' sd' n) := by
  simp only [corrTP, Qle]
  push_cast
  have key :
      64 * (sn' : Int) * ((4 * (n : Int) + 1)
          * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * (sd : Int) + 16 * (sn : Int)))
      = 64 * (sn : Int) * ((4 * (n : Int) + 1)
          * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * (sd' : Int) + 16 * (sn' : Int)))
        + 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * (4 * (n : Int) + 1))
          * ((sn' : Int) * (sd : Int) - (sn : Int) * (sd' : Int)) := by ring_uor
  rw [key]
  have hnn : (0 : Int) ≤ 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * (4 * (n : Int) + 1))
      * ((sn' : Int) * (sd : Int) - (sn : Int) * (sd' : Int)) := by
    refine Int.mul_nonneg (Int.mul_nonneg (by decide) ?_) ?_
    · have h : (0 : Int) ≤ 4 * (n : Int) + 1 := by omega
      exact Int.mul_nonneg (Int.mul_nonneg h h) h
    · have : (sn : Int) * (sd' : Int) ≤ (sn' : Int) * (sd : Int) := by exact_mod_cast hmono
      omega
  omega

/-- **`cₙ(s) ≤ cₙ(25) = corrT n`** for `s ≤ 25` — the reduction is exactly `sn ≤ 25·sd` (divide by
    `(4n+1)³`). Proved directly (avoiding `corrTP 25 1 ≟ corrT` defeq reduction). -/
private theorem corrTP_le_corrT {sn sd : Nat} (hs : sn ≤ 25 * sd) (n : Nat) :
    Qle (corrTP sn sd n) (corrT n) := by
  simp only [corrTP, corrT, Qle]
  push_cast
  have key :
      1600 * ((4 * (n : Int) + 1)
          * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * (sd : Int) + 16 * (sn : Int)))
      = 64 * (sn : Int) * ((4 * (n : Int) + 1)
          * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 400))
        + 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * (4 * (n : Int) + 1))
          * (25 * (sd : Int) - (sn : Int)) := by ring_uor
  rw [key]
  have hnn : (0 : Int) ≤ 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * (4 * (n : Int) + 1))
      * (25 * (sd : Int) - (sn : Int)) := by
    refine Int.mul_nonneg (Int.mul_nonneg (by decide) ?_) ?_
    · have h : (0 : Int) ≤ 4 * (n : Int) + 1 := by omega
      exact Int.mul_nonneg (Int.mul_nonneg h h) h
    · have : (sn : Int) ≤ 25 * (sd : Int) := by exact_mod_cast hs
      omega
  omega

/-- `cₙ(s) ≤ tel(n) − tel(n+1)` for `s ≤ 25` — chain `cₙ(s) ≤ corrT n` through the `s = 25`
    telescoping `corrT_le_teldiff`. -/
private theorem corrTP_le_teldiff {sn sd : Nat} (hs : sn ≤ 25 * sd) (n : Nat) :
    Qle (corrTP sn sd n) (Qsub (corrTel n) (corrTel (n + 1))) :=
  Qle_trans (corrT_den_pos n) (corrTP_le_corrT hs n) (corrT_le_teldiff n)

private def corrPP (sn sd : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (N + 1) => add (corrPP sn sd N) (corrTP sn sd N)

private theorem corrPP_den_pos {sn sd : Nat} (hsd : 1 ≤ sd) : ∀ N, 0 < (corrPP sn sd N).den
  | 0 => Nat.one_pos
  | (N + 1) => add_den_pos (corrPP_den_pos hsd N) (corrTP_den_pos hsd N)

private def corrGP (sn sd m : Nat) : Q := add (corrPP sn sd m) (corrTel m)

private theorem corrGP_den_pos {sn sd : Nat} (hsd : 1 ≤ sd) (m : Nat) : 0 < (corrGP sn sd m).den :=
  add_den_pos (corrPP_den_pos hsd m) (corrTel_den_pos m)

private theorem corrTP_tel_le {sn sd : Nat} (hs : sn ≤ 25 * sd) (m : Nat) :
    Qle (add (corrTP sn sd m) (corrTel (m + 1))) (corrTel m) := by
  have hadd := Qadd_le_add (corrTP_le_teldiff hs m) (Qle_refl (corrTel (m + 1)))
  have e3 : Qeq (add (Qsub (corrTel m) (corrTel (m + 1))) (corrTel (m + 1))) (corrTel m) := by
    simp only [Qeq, add, Qsub, neg]; push_cast; ring_uor
  refine Qle_trans ?_ hadd (Qeq_le e3)
  exact add_den_pos (Qsub_den_pos (corrTel_den_pos m) (corrTel_den_pos (m + 1)))
    (corrTel_den_pos (m + 1))

private theorem corrGP_step {sn sd : Nat} (hsd : 1 ≤ sd) (hs : sn ≤ 25 * sd) (m : Nat) :
    Qle (corrGP sn sd (m + 1)) (corrGP sn sd m) := by
  show Qle (add (add (corrPP sn sd m) (corrTP sn sd m)) (corrTel (m + 1)))
    (add (corrPP sn sd m) (corrTel m))
  have e1 : Qeq (add (add (corrPP sn sd m) (corrTP sn sd m)) (corrTel (m + 1)))
      (add (corrPP sn sd m) (add (corrTP sn sd m) (corrTel (m + 1)))) := by
    simp only [Qeq, add]; push_cast; ring_uor
  refine Qle_trans ?_ (Qeq_le e1) (Qadd_le_add (Qle_refl (corrPP sn sd m)) (corrTP_tel_le hs m))
  exact add_den_pos (corrPP_den_pos hsd m)
    (add_den_pos (corrTP_den_pos hsd m) (corrTel_den_pos (m + 1)))

private theorem corrGP_mono {sn sd : Nat} (hs : sn ≤ 25 * sd) (hsd : 1 ≤ sd) :
    ∀ a b, Qle (corrGP sn sd (a + b)) (corrGP sn sd a)
  | _, 0 => Qle_refl _
  | a, (b + 1) => by
    have h := corrGP_mono hs hsd a b
    have hstep := corrGP_step hsd hs (a + b)
    have e : a + (b + 1) = (a + b) + 1 := by omega
    rw [e]
    exact Qle_trans (corrGP_den_pos hsd (a + b)) hstep h

private theorem corrPP_mono_N {sn sd : Nat} (hsd : 1 ≤ sd) {a b : Nat} (hab : a ≤ b) :
    Qle (corrPP sn sd a) (corrPP sn sd b) := by
  obtain ⟨d, rfl⟩ := Nat.le.dest hab
  clear hab
  induction d with
  | zero => exact Qle_refl _
  | succ k ih =>
    have e : a + (k + 1) = (a + k) + 1 := by omega
    rw [e]
    show Qle (corrPP sn sd a) (add (corrPP sn sd (a + k)) (corrTP sn sd (a + k)))
    exact Qle_trans (corrPP_den_pos hsd (a + k)) ih
      (Qle_self_add (by show (0 : Int) ≤ 64 * (sn : Int); omega))

/-- **Partial sums are monotone in `s`** (termwise `corrTP_mono`). -/
private theorem corrPP_mono_s {sn sd sn' sd' : Nat} (hmono : sn * sd' ≤ sn' * sd) :
    ∀ N, Qle (corrPP sn sd N) (corrPP sn' sd' N)
  | 0 => Qle_refl _
  | (N + 1) => by
    show Qle (add (corrPP sn sd N) (corrTP sn sd N)) (add (corrPP sn' sd' N) (corrTP sn' sd' N))
    exact Qadd_le_add (corrPP_mono_s hmono N) (corrTP_mono hmono)

private def corrseqP (sn sd : Nat) (j : Nat) : Q := corrPP sn sd (25 * (j + 1))

private theorem corrseqP_den_pos {sn sd : Nat} (hsd : 1 ≤ sd) (j : Nat) : 0 < (corrseqP sn sd j).den :=
  corrPP_den_pos hsd (25 * (j + 1))

private theorem corrseqP_reg_le {sn sd : Nat} (hsd : 1 ≤ sd) (hs : sn ≤ 25 * sd) {j k : Nat}
    (hjk : j ≤ k) : Qle (Qabs (Qsub (corrseqP sn sd j) (corrseqP sn sd k))) (Qbound j) := by
  rw [Qabs_Qsub_comm]
  obtain ⟨d, hd⟩ := Nat.le.dest hjk
  have hge : Qle (corrPP sn sd (25 * (j + 1))) (corrPP sn sd (25 * (k + 1))) :=
    corrPP_mono_N hsd (by omega)
  have hnn : (0 : Int) ≤ (Qsub (corrPP sn sd (25 * (k + 1))) (corrPP sn sd (25 * (j + 1)))).num :=
    num_nonneg_of_Qzero_le (Qsub_nonneg_of_le hge)
  have htail : Qle (Qsub (corrPP sn sd (25 * (k + 1))) (corrPP sn sd (25 * (j + 1))))
      (corrTel (25 * (j + 1))) := by
    have hgm : Qle (corrGP sn sd (25 * (k + 1))) (corrGP sn sd (25 * (j + 1))) := by
      have e : 25 * (k + 1) = 25 * (j + 1) + 25 * d := by omega
      rw [e]; exact corrGP_mono hs hsd (25 * (j + 1)) (25 * d)
    have hSg : Qle (corrPP sn sd (25 * (k + 1))) (corrGP sn sd (25 * (k + 1))) := by
      show Qle (corrPP sn sd (25 * (k + 1)))
        (add (corrPP sn sd (25 * (k + 1))) (corrTel (25 * (k + 1))))
      exact Qle_self_add (by show (0 : Int) ≤ 100; decide)
    have hchain : Qle (corrPP sn sd (25 * (k + 1)))
        (add (corrPP sn sd (25 * (j + 1))) (corrTel (25 * (j + 1)))) :=
      Qle_trans (corrGP_den_pos hsd (25 * (k + 1))) hSg hgm
    exact Qsub_le_of_le_add (corrPP_den_pos hsd (25 * (j + 1))) (corrTel_den_pos (25 * (j + 1))) hchain
  have hbnd : Qle (corrTel (25 * (j + 1))) (Qbound j) := by
    show (100 : Int) * ((j + 1 : Nat) : Int) ≤ (1 : Int) * ((4 * (25 * (j + 1)) + 1 : Nat) : Int)
    push_cast; omega
  exact Qle_trans (corrTel_den_pos (25 * (j + 1))) (Qabs_le_of_nonneg hnn htail) hbnd

private theorem corrseqP_regular {sn sd : Nat} (hsd : 1 ≤ sd) (hs : sn ≤ 25 * sd) :
    IsRegular (corrseqP sn sd) := by
  intro m n
  rcases Nat.le_total m n with h | h
  · exact Qle_trans (Qbound_den_pos m) (corrseqP_reg_le hsd hs h)
      (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · rw [Qabs_Qsub_comm]
    exact Qle_trans (Qbound_den_pos n) (corrseqP_reg_le hsd hs h)
      (Qle_add_self (by show (0 : Int) ≤ 1; decide))

/-- **The parameterized correction series** `Σ cₙ(s)` for `s = sn/sd ∈ [0, 25]` — the gain of
    `Re ψ(1/4 + iτ/2)` over `ψ(1/4)`, as a genuine constructive real. -/
def corrCoreP (sn sd : Nat) (hsd : 1 ≤ sd) (hs : sn ≤ 25 * sd) : Real :=
  ⟨corrseqP sn sd, corrseqP_regular hsd hs, corrseqP_den_pos hsd⟩

/-- **THE MONOTONE CLIMB (correction level)**: `s ≤ s' ⟹ Σ cₙ(s) ≤ Σ cₙ(s')` — termwise
    (`corrPP_mono_s`), at the assembled-real level (common depth schedule). -/
theorem corrCoreP_mono {sn sd sn' sd' : Nat} (hsd : 1 ≤ sd) (hsd' : 1 ≤ sd')
    (hs : sn ≤ 25 * sd) (hs' : sn' ≤ 25 * sd') (hmono : sn * sd' ≤ sn' * sd) :
    Rle (corrCoreP sn sd hsd hs) (corrCoreP sn' sd' hsd' hs') := by
  intro j
  show Qle (corrPP sn sd (25 * (j + 1))) (add (corrPP sn' sd' (25 * (j + 1))) ⟨2, j + 1⟩)
  exact Qle_trans (corrPP_den_pos hsd' (25 * (j + 1))) (corrPP_mono_s hmono (25 * (j + 1)))
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- **The parameterized archimedean kernel** `Re ψ(1/4 + iτ/2) = ψ(1/4) + Σ cₙ(s)`, `s = τ²/4 ∈ [0,25]`. -/
def psiLineReP (sn sd : Nat) (hsd : 1 ≤ sd) (hs : sn ≤ 25 * sd) : Real :=
  Radd psiQuarter (corrCoreP sn sd hsd hs)

/-- **THE MONOTONE CLIMB — `Re ψ(1/4 + iτ/2)` increases in `τ`** (for `τ² ≤ 100`, `s ≤ 25`): the
    analytic heart `DigammaWindow` records, now a theorem about the ASSEMBLED kernel. With the
    center slope `θ′(0) < 0` and `θ′(10) > 0` (`rsAngle_non_monotone`), this says `θ′ = ½(Re ψ − log π)`
    is monotone increasing — `θ` is CONVEX on the window, with a UNIQUE minimum, so the negative band
    of `α` is a single bounded interval. The obstruction's exact shape, made a theorem; crux `none`. -/
theorem psiLineReP_mono {sn sd sn' sd' : Nat} (hsd : 1 ≤ sd) (hsd' : 1 ≤ sd')
    (hs : sn ≤ 25 * sd) (hs' : sn' ≤ 25 * sd') (hmono : sn * sd' ≤ sn' * sd) :
    Rle (psiLineReP sn sd hsd hs) (psiLineReP sn' sd' hsd' hs') :=
  Radd_le_add (Rle_refl psiQuarter) (corrCoreP_mono hsd hsd' hs hs' hmono)

-- ===========================================================================
-- θ′ > 0 on the whole UPPER BAND: the climb from a sharper point at s = 16 gives
-- θ′(s) > 0 for ALL s ∈ [16, 25], not just at the single point s = 25 (τ = 10).
-- ===========================================================================

/-- **`corrCoreP sn sd ≥ S(N)`** for any partial-sum cutoff `N ≤ 25` — the depth schedule starts at
    `25 ≥ N`, so every approximant dominates `S(N)` by `corrPP_mono_N`. -/
theorem corrCoreP_ge_partial {sn sd : Nat} (hsd : 1 ≤ sd) (hs : sn ≤ 25 * sd) {N : Nat} (hN : N ≤ 25) :
    Rle (ofQ (corrPP sn sd N) (corrPP_den_pos hsd N)) (corrCoreP sn sd hsd hs) := by
  intro j
  show Qle (corrPP sn sd N) (add (corrPP sn sd (25 * (j + 1))) ⟨2, j + 1⟩)
  exact Qle_trans (corrPP_den_pos hsd (25 * (j + 1))) (corrPP_mono_N hsd (by omega))
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- **`Re ψ(1/4 + 4i) ≥ 1.18`** (`s = 16`, `τ = 8`; true value `≈ 1.236`): from `ψ(1/4) ≥ −4.32`
    and `Σ cₙ(16) ≥ 5.5` (the certified 12-term partial sum). Above `log π ≈ 1.1447`, so `θ′(8) > 0`. -/
theorem psiLineReP_16_lower :
    Rle (ofQ (⟨118, 100⟩ : Q) (by decide)) (psiLineReP 16 1 (by omega) (by omega)) := by
  have hcorr : Rle (ofQ (⟨55, 10⟩ : Q) (by decide)) (corrCoreP 16 1 (by omega) (by omega)) :=
    Rle_trans (Rle_ofQ_ofQ (by decide) (corrPP_den_pos (by omega) 12) (by decide))
      (corrCoreP_ge_partial (by omega) (by omega) (by decide))
  have hsum := Radd_le_add psiQuarter_lower hcorr
  refine Rle_trans ?_ hsum
  refine Rle_trans (Rle_of_Req (ofQ_congr (by decide)
    (add_den_pos (by decide) (by decide)) ?_)) (Rle_ofQ_add_Radd (by decide) (by decide))
  decide

/-- **`θ′(8) > 0`** — the line slope is already positive at `τ = 8` (`s = 16`), inside the window. -/
theorem rsLineSlope16_pos : Pos (Rsub (psiLineReP 16 1 (by omega) (by omega)) Rlogπc) := by
  have hlogle : Rle Rlogπc (ofQ (⟨115, 100⟩ : Q) (by decide)) :=
    Rle_trans Rlogπc_le (Rle_ofQ_ofQ _ (by decide) (by decide))
  have hstep : Rle (Rsub (ofQ (⟨118, 100⟩ : Q) (by decide)) (ofQ (⟨115, 100⟩ : Q) (by decide)))
      (Rsub (psiLineReP 16 1 (by omega) (by omega)) Rlogπc) :=
    Rsub_le_sub psiLineReP_16_lower hlogle
  refine Pos_of_Rle_ofQ (c := (⟨3, 100⟩ : Q)) (by decide) (by decide) (Rle_trans ?_ hstep)
  intro n
  show Qle (⟨3, 100⟩ : Q) (add (add (⟨118, 100⟩ : Q) (neg (⟨115, 100⟩ : Q))) ⟨2, n + 1⟩)
  simp only [Qle, add, neg]
  push_cast
  omega

/-- **THE ANGLE STRICTLY INCREASES ON THE UPPER BAND**: for every rational `s = τ²/4 ∈ [16, 25]`,
    `θ′ > 0` (`Re ψ(1/4 + i√s) > log π`). The monotone climb (`psiLineReP_mono`) carries the single
    positive point `θ′(8) > 0` (`rsLineSlope16_pos`) to the whole interval `s ≥ 16` — so the
    Riemann–Siegel angle's unique minimum lies at `τ < 8`, and beyond it `θ` rises monotonically.
    A genuine interval of positivity, not a single point; crux fields stay `none`. -/
theorem rsAngle_increasing_on_band {sn sd : Nat} (hsd : 1 ≤ sd) (hs : sn ≤ 25 * sd)
    (hband : 16 * sd ≤ sn) : Pos (Rsub (psiLineReP sn sd hsd hs) Rlogπc) :=
  Pos_mono
    (Rsub_le_sub (psiLineReP_mono (by omega) hsd (by omega) hs (by omega)) (Rle_refl Rlogπc))
    rsLineSlope16_pos

-- ===========================================================================
-- Faithfulness at the center: the assembled kernel reduces to ψ(1/4) at s = 0
-- (the assembled-level analog of DigammaWindow.windowTerm_zero).
-- ===========================================================================

private theorem corrTP_zero_num (n : Nat) : (corrTP 0 1 n).num = 0 := by simp [corrTP]

/-- At `s = 0` every correction term vanishes, so every partial sum has numerator `0`. -/
private theorem corrPP_zero_num : ∀ N, (corrPP 0 1 N).num = 0
  | 0 => rfl
  | (N + 1) => by
    show (corrPP 0 1 N).num * ((corrTP 0 1 N).den : Int)
        + (corrTP 0 1 N).num * ((corrPP 0 1 N).den : Int) = 0
    rw [corrPP_zero_num N, corrTP_zero_num N]; simp

private theorem corrPP_zero_Qeq (N : Nat) : Qeq (corrPP 0 1 N) (⟨0, 1⟩ : Q) := by
  simp [Qeq, corrPP_zero_num N]

/-- **The correction series vanishes at `s = 0`**: `Σ cₙ(0) = 0` (every partial sum is `Qeq 0`). -/
theorem corrCoreP_zero : Req (corrCoreP 0 1 (by omega) (by omega)) zero :=
  Req_of_seq_Qeq (fun j => corrPP_zero_Qeq (25 * (j + 1)))

/-- **THE KERNEL AT THE CENTER IS `ψ(1/4)`**: `Re ψ(1/4 + i·0) = ψ(1/4)` — the parameterized
    assembled kernel reduces, at `s = 0` (`τ = 0`), to exactly the window-center value, the
    assembled-level analog of `DigammaWindow.windowTerm_zero`. With `psiLineRe5` (`= psiLineReP 25 1`)
    at the far end, the construction is verified-correct at both endpoints of the window. -/
theorem psiLineReP_zero : Req (psiLineReP 0 1 (by omega) (by omega)) psiQuarter :=
  Req_trans (Radd_congr (Req_refl psiQuarter) corrCoreP_zero) (Radd_zero psiQuarter)

-- ===========================================================================
-- A TIGHT upper bound `Σ cₙ(1) ≤ 4.22` (s = 1), via the sharper K=s=1 telescoping
-- tel'(n) = 16/((4n+1)²+16) (valid for n ≥ 2). Bounds Re ψ(1/4 + i) from above —
-- the kernel-value input to the Burnol multiplier indefiniteness `α(2) < 0`.
-- ===========================================================================

private theorem le_add_right_of_nonneg {a b : Int} (h : 0 ≤ b) : a ≤ a + b := by omega

private theorem sq_nonneg_int (a : Int) : 0 ≤ a * a := by
  rcases Int.le_total 0 a with h | h
  · exact Int.mul_nonneg h h
  · have h' : (0 : Int) ≤ -a := by omega
    have := Int.mul_nonneg h' h'; simpa using this

private theorem quad_nonneg_ge2 {n : Int} (hn : 2 ≤ n) : 0 ≤ 16 * n * n - 8 * n - 35 := by
  have h0 : (0 : Int) ≤ n * (n - 2) := Int.mul_nonneg (by omega) (by omega)
  have hk : 16 * n * n - 8 * n - 35 = 16 * (n * (n - 2)) + 24 * n - 35 := by ring_uor
  rw [hk]; omega

private def corrTel1 (n : Nat) : Q := ⟨16, (4 * n + 1) * (4 * n + 1) + 16⟩

private theorem corrTel1_den_pos (n : Nat) : 0 < (corrTel1 n).den := by
  show 0 < (4 * n + 1) * (4 * n + 1) + 16; omega

/-- `cₙ(1) ≤ tel'(n) − tel'(n+1)` for `n ≥ 2` — the cleared inequality is `16n² − 8n − 35 ≥ 0`. -/
private theorem corrTP1_le_teldiff1 {n : Nat} (hn : 2 ≤ n) :
    Qle (corrTP 1 1 n) (Qsub (corrTel1 n) (corrTel1 (n + 1))) := by
  simp only [corrTP, corrTel1, Qsub, Qle, add, neg]
  push_cast
  have key :
      (16 * ((4 * ((n : Int) + 1) + 1) * (4 * ((n : Int) + 1) + 1) + 16)
          + -16 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16))
        * ((4 * (n : Int) + 1) * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) * 1 + 16))
      = 64 * (((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
          * ((4 * ((n : Int) + 1) + 1) * (4 * ((n : Int) + 1) + 1) + 16))
        + 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
          * (16 * (n : Int) * (n : Int) - 8 * (n : Int) - 35) := by ring_uor
  rw [key]
  have hnn : (0 : Int) ≤ 64 * ((4 * (n : Int) + 1) * (4 * (n : Int) + 1) + 16)
      * (16 * (n : Int) * (n : Int) - 8 * (n : Int) - 35) :=
    Int.mul_nonneg (Int.mul_nonneg (by decide)
      (by have := sq_nonneg_int (4 * (n : Int) + 1); omega)) (quad_nonneg_ge2 (by exact_mod_cast hn))
  exact le_add_right_of_nonneg hnn

private def corrGP1 (m : Nat) : Q := add (corrPP 1 1 m) (corrTel1 m)

private theorem corrGP1_den_pos (m : Nat) : 0 < (corrGP1 m).den :=
  add_den_pos (corrPP_den_pos (by omega) m) (corrTel1_den_pos m)

private theorem corrTP1_tel1_le {m : Nat} (hm : 2 ≤ m) :
    Qle (add (corrTP 1 1 m) (corrTel1 (m + 1))) (corrTel1 m) := by
  have hadd := Qadd_le_add (corrTP1_le_teldiff1 hm) (Qle_refl (corrTel1 (m + 1)))
  have e3 : Qeq (add (Qsub (corrTel1 m) (corrTel1 (m + 1))) (corrTel1 (m + 1))) (corrTel1 m) := by
    simp only [Qeq, add, Qsub, neg]; push_cast; ring_uor
  refine Qle_trans ?_ hadd (Qeq_le e3)
  exact add_den_pos (Qsub_den_pos (corrTel1_den_pos m) (corrTel1_den_pos (m + 1)))
    (corrTel1_den_pos (m + 1))

private theorem corrGP1_step {m : Nat} (hm : 2 ≤ m) : Qle (corrGP1 (m + 1)) (corrGP1 m) := by
  show Qle (add (add (corrPP 1 1 m) (corrTP 1 1 m)) (corrTel1 (m + 1)))
    (add (corrPP 1 1 m) (corrTel1 m))
  have e1 : Qeq (add (add (corrPP 1 1 m) (corrTP 1 1 m)) (corrTel1 (m + 1)))
      (add (corrPP 1 1 m) (add (corrTP 1 1 m) (corrTel1 (m + 1)))) := by
    simp only [Qeq, add]; push_cast; ring_uor
  refine Qle_trans ?_ (Qeq_le e1) (Qadd_le_add (Qle_refl (corrPP 1 1 m)) (corrTP1_tel1_le hm))
  exact add_den_pos (corrPP_den_pos (by omega) m)
    (add_den_pos (corrTP_den_pos (by omega) m) (corrTel1_den_pos (m + 1)))

private theorem corrGP1_mono {a : Nat} (ha : 2 ≤ a) : ∀ b, Qle (corrGP1 (a + b)) (corrGP1 a)
  | 0 => Qle_refl _
  | (b + 1) => by
    have h := corrGP1_mono ha b
    have hstep := corrGP1_step (show 2 ≤ a + b by omega)
    have e : a + (b + 1) = (a + b) + 1 := by omega
    rw [e]
    exact Qle_trans (corrGP1_den_pos (a + b)) hstep h

private theorem corrPP1_tail {a b : Nat} (ha : 2 ≤ a) (hab : a ≤ b) :
    Qle (corrPP 1 1 b) (add (corrPP 1 1 a) (corrTel1 a)) := by
  obtain ⟨d, hd⟩ := Nat.le.dest hab
  have hgm : Qle (corrGP1 b) (corrGP1 a) := by rw [← hd]; exact corrGP1_mono ha d
  have hSg : Qle (corrPP 1 1 b) (corrGP1 b) := by
    show Qle (corrPP 1 1 b) (add (corrPP 1 1 b) (corrTel1 b))
    exact Qle_self_add (by show (0 : Int) ≤ 16; decide)
  exact Qle_trans (corrGP1_den_pos b) hSg hgm

/-- **`Σ cₙ(1) ≤ 4.22`** (true value `≈ 4.21`): the tail past the 12-term partial sum is bounded by
    `tel'(12) = 16/2417 ≈ 0.0066` (the `K=s=1` telescoping), so `corrCoreP 1 1 ≤ S(12) + tel'(12) ≤
    4.22`. The upper input for `Re ψ(1/4 + i) = ψ(1/4) + Σ cₙ(1) ≤ −4 + 4.22 = 0.22`. -/
theorem corrCoreP_one_upper :
    Rle (corrCoreP 1 1 (by omega) (by omega)) (ofQ (⟨422, 100⟩ : Q) (by decide)) := by
  intro j
  show Qle (corrPP 1 1 (25 * (j + 1))) (add (⟨422, 100⟩ : Q) ⟨2, j + 1⟩)
  have htail : Qle (corrPP 1 1 (25 * (j + 1))) (add (corrPP 1 1 12) (corrTel1 12)) :=
    corrPP1_tail (by omega) (by omega)
  have hval : Qle (add (corrPP 1 1 12) (corrTel1 12)) (⟨422, 100⟩ : Q) := by decide
  exact Qle_trans (corrGP1_den_pos 12) htail
    (Qle_trans (by decide) hval (Qle_self_add (by show (0 : Int) ≤ 2; decide)))

/-- **`Re ψ(1/4 + i) ≤ 0.22`** (true value `≈ −0.017`): the assembled kernel at `τ = 2` (`s = 1`),
    from `ψ(1/4) ≤ −4` (`psiQuarter_upper_tight`) and `Σ cₙ(1) ≤ 4.22` (`corrCoreP_one_upper`). -/
theorem psiLineReP_one_upper :
    Rle (psiLineReP 1 1 (by omega) (by omega)) (ofQ (⟨22, 100⟩ : Q) (by decide)) := by
  have hsum := Radd_le_add psiQuarter_upper_tight corrCoreP_one_upper
  refine Rle_trans hsum ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (by decide) (by decide))) ?_
  exact Rle_ofQ_ofQ (by decide) (by decide) (by decide)

/-- **`h₊(2) < 0` — Burnol's archimedean multiplier part is negative at `τ = 2`** (`Re ψ(1/4 + i) <
    log π`): `Re ψ(1/4 + i) ≤ 0.22 < 1 ≤ log π`, so `h₊(2) = Re ψ(1/4 + i) − log π ≤ 0.22 − 1 = −0.78`.
    This is the kernel-sign content of the Burnol multiplier `α(τ) = 8√2·cos(τ log2)/(1+4τ²) +
    h₊(τ)`: the archimedean part `h₊` is strictly negative inside the band, which (with the bounded
    oscillating cosine term) is *why* `α` dips below zero — the indefiniteness Burnol / Connes–Consani
    must work around. The full pointwise `α(2) < 0` additionally needs the multiplier-coefficient bound
    `8√2 ≤ 12` (`√2 ≤ 3/2`), which requires the `exp∘RlogPos = id` inverse not yet in this substrate.
    Crux fields stay `none`. -/
theorem archKernel_at_two_below_logpi :
    Pos (Rsub Rlogπc (psiLineReP 1 1 (by omega) (by omega))) := by
  refine Pos_of_Rle_ofQ (c := (⟨78, 100⟩ : Q)) (by decide) (by decide) ?_
  refine Rle_trans ?_ (Rsub_le_sub Rlogpi_ge_one psiLineReP_one_upper)
  intro n
  show Qle (⟨78, 100⟩ : Q) (add (add (⟨1, 1⟩ : Q) (neg (⟨22, 100⟩ : Q))) ⟨2, n + 1⟩)
  simp only [Qle, add, neg]; push_cast; omega

end UOR.Bridge.F1Square.Analysis
