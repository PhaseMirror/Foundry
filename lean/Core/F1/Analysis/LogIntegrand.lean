/-
F1 square — **the `∫ log` layer, part 2b: the totalized `log` integrand** (`LogIntegrand.lean`):

    `gLog c t = log(band_{[1, c+1]}(c + t))`

— a total `Real → Real` that agrees with `t ↦ log(c+t)` on `[0, 1]` (the band clamp is inert
there), built as `RlogPos` over the two-sided band clamp of part 2a, with the UNIFORM
positivity witness (index `2`, no data extracted from `t`). The two gateway data are proven
from the seq-wise band facts:

  * `gLog_congr_of` / `gLog_lip_of` — general in the base `c`, taking the small-radius and
    Lipschitz-budget certificates of `RlogPos_congr` / `Rlog_abs_lipschitz_gen` as explicit
    rational hypotheses (they are DECIDABLE per base, and provably fail for `c ≥ 5` — the
    presented-radius design caps the band at `B = c+1 ≤ 4`... wait, at `B ≤ 4`);
  * the **instances `c = 1, 2, 3`** (`gLog1_lip`/`gLog1_congr`, …) with every certificate
    discharged by `decide` — exactly the bases the `t4` slot integrals consume
    (`∫₀¹ log(c+t) dt` for `c = 1, 2, 3`).

`gLog` is `1`-Lipschitz: `Rlog_abs_lipschitz_gen` gives `|log u − log v| ≤ |u − v|` on the
band, the band clamp is `1`-Lipschitz, and the constant shift `c + ·` collapses.

HONEST SCOPE. This constructs and equips the integrand; the point values (the
log-of-rational bridge) and the evaluation `riemannIntegral_logC` are part 2c. No integral
is evaluated here; no positivity claim. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.BandClamp
import Core.F1.Analysis.LogDiffBoundGen
import Core.F1.Analysis.RlogMulPos

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The band argument and its seq-wise facts.
-- ===========================================================================

/-- `1 ≤ c+1` as rationals, general in `c`. -/
private theorem h1B (c : Nat) : Qle (⟨1, 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q) := by
  show (1 : Int) * 1 ≤ ((c + 1 : Nat) : Int) * 1
  push_cast; omega

/-- The banded argument of the integrand: `band_{[1, c+1]}(c + t)`. -/
def gLogArg (c : Nat) (t : Real) : Real :=
  qBandQ ⟨1, 1⟩ ⟨((c + 1 : Nat) : Int), 1⟩ (by decide) Nat.one_pos
    (Radd (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) t)

/-- Per-index positivity of the banded argument's numerators. -/
theorem gLogArg_pos (c : Nat) (t : Real) : ∀ n, 0 < ((gLogArg c t).seq n).num :=
  qBandQ_one_num_pos (⟨((c + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos (h1B c)
    (Radd (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) t)

/-- Per-index upper band. -/
theorem gLogArg_hi (c : Nat) (t : Real) :
    ∀ n, Qle ((gLogArg c t).seq n) (⟨((c + 1 : Nat) : Int), 1⟩ : Q) :=
  qBandQ_le ⟨1, 1⟩ (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (by decide) Nat.one_pos _

/-- Per-index lower band. -/
theorem gLogArg_ge1 (c : Nat) (t : Real) : ∀ n, Qle (⟨1, 1⟩ : Q) ((gLogArg c t).seq n) :=
  qBandQ_ge ⟨1, 1⟩ (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (by decide) Nat.one_pos (h1B c) _

/-- `1 ≤ s·B` from `1 ≤ s`, `1 ≤ B` (the `hxloB` fact the `Rlog` lemmas consume). -/
private theorem one_le_mul_of {s B : Q} (hs : Qle (⟨1, 1⟩ : Q) s) (hB : Qle (⟨1, 1⟩ : Q) B) :
    Qle (⟨1, 1⟩ : Q) (mul s B) := by
  show (1 : Int) * ((s.den * B.den : Nat) : Int) ≤ s.num * B.num * 1
  simp only [Qle] at hs hB
  push_cast at hs hB ⊢
  have hsd : (0 : Int) ≤ (s.den : Int) := Int.ofNat_nonneg _
  have hsn : (0 : Int) ≤ s.num := by omega
  have h1 : (s.den : Int) * (B.den : Int) ≤ s.num * (B.den : Int) :=
    Int.mul_le_mul_of_nonneg_right (by omega) (Int.ofNat_nonneg _)
  have h2 : s.num * (B.den : Int) ≤ s.num * B.num :=
    Int.mul_le_mul_of_nonneg_left (by omega) hsn
  omega

/-- The `hxloB` fact for the banded argument. -/
theorem gLogArg_lo (c : Nat) (t : Real) :
    ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((gLogArg c t).seq n) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)) :=
  fun n => one_le_mul_of (gLogArg_ge1 c t n) (h1B c)

/-- The uniform positivity witness at index `2` (no data from `t`). -/
theorem gLogArg_witness (c : Nat) (t : Real) :
    Qlt (Qbound (2 * (⟨1, 1⟩ : Q).den)) ((gLogArg c t).seq (2 * (⟨1, 1⟩ : Q).den)) :=
  qBandQ_witness ⟨1, 1⟩ (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (by decide) (by decide)
    Nat.one_pos (h1B c) _

-- ===========================================================================
-- THE TOTALIZED LOG INTEGRAND.
-- ===========================================================================

/-- **The totalized `log` integrand**: `gLog c t = log(band_{[1, c+1]}(c + t))` — total,
    agreeing with `log(c+t)` on `[0, 1]`. -/
def gLog (c : Nat) : Real → Real := fun t =>
  RlogPos (gLogArg c t) (2 * (⟨1, 1⟩ : Q).den) (gLogArg_witness c t)

/-- The shift collapse `(c + x) − (c + y) ≈ x − y`. -/
private theorem shift_cc (cq : Real) (x y : Real) :
    Req (Rsub (Radd cq x) (Radd cq y)) (Rsub x y) := by
  refine Req_trans (Rsub_Radd_Radd cq x cq y) ?_
  refine Req_trans (Radd_congr (Radd_neg cq) (Req_refl (Rsub x y))) ?_
  exact Req_trans (Radd_comm zero (Rsub x y)) (Radd_zero (Rsub x y))

/-- **`gLog` respects `≈`, general in the base** — the small-radius certificate
    (decidable per base, holds for `c + 1 ≤ 4`-ish radii) enters as a hypothesis. -/
theorem gLog_congr_of (c : Nat)
    (hρ : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩
      (mul ⟨(⟨((c + 1 : Nat) : Int), 1⟩ : Q).num - ((⟨((c + 1 : Nat) : Int), 1⟩ : Q).den : Int),
             (⟨((c + 1 : Nat) : Int), 1⟩ : Q).num.toNat + (⟨((c + 1 : Nat) : Int), 1⟩ : Q).den⟩
           ⟨(⟨((c + 1 : Nat) : Int), 1⟩ : Q).num - ((⟨((c + 1 : Nat) : Int), 1⟩ : Q).den : Int),
             (⟨((c + 1 : Nat) : Int), 1⟩ : Q).num.toNat + (⟨((c + 1 : Nat) : Int), 1⟩ : Q).den⟩))) :
    ∀ x y : Real, Req x y → Req (gLog c x) (gLog c y) := by
  intro x y h
  exact RlogPos_congr (gLogArg c x) (gLogArg c y) _ (gLogArg_witness c x) _ (gLogArg_witness c y)
    (⟨((c + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos (h1B c)
    (gLogArg_pos c x) (gLogArg_hi c x) (gLogArg_lo c x)
    (gLogArg_pos c y) (gLogArg_hi c y) (gLogArg_lo c y)
    hρ
    (qBandQ_congr ⟨1, 1⟩ (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (by decide) Nat.one_pos
      (Radd_congr (Req_refl _) h))

/-- **`gLog` is `1`-Lipschitz, general in the base** — the Lipschitz-budget certificates
    of `Rlog_abs_lipschitz_gen` enter as hypotheses (decidable per base). -/
theorem gLog_lip_of (c K_B K_BB : Nat)
    (hρσ : Qle (⟨(⟨((c + 1 : Nat) : Int), 1⟩ : Q).num - ((⟨((c + 1 : Nat) : Int), 1⟩ : Q).den : Int),
              (⟨((c + 1 : Nat) : Int), 1⟩ : Q).num.toNat + (⟨((c + 1 : Nat) : Int), 1⟩ : Q).den⟩ : Q)
      (⟨(mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).num
          - ((mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).den : Int),
        (mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).num.toNat
          + (mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).den⟩ : Q))
    (hKBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_B : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨(⟨((c + 1 : Nat) : Int), 1⟩ : Q).num - ((⟨((c + 1 : Nat) : Int), 1⟩ : Q).den : Int),
          (⟨((c + 1 : Nat) : Int), 1⟩ : Q).num.toNat + (⟨((c + 1 : Nat) : Int), 1⟩ : Q).den⟩
        ⟨(⟨((c + 1 : Nat) : Int), 1⟩ : Q).num - ((⟨((c + 1 : Nat) : Int), 1⟩ : Q).den : Int),
          (⟨((c + 1 : Nat) : Int), 1⟩ : Q).num.toNat + (⟨((c + 1 : Nat) : Int), 1⟩ : Q).den⟩))))
    (hKBr : K_B ≤ 2 * (((⟨((c + 1 : Nat) : Int), 1⟩ : Q).num.toNat + (⟨((c + 1 : Nat) : Int), 1⟩ : Q).den)
        * ((⟨((c + 1 : Nat) : Int), 1⟩ : Q).num.toNat + (⟨((c + 1 : Nat) : Int), 1⟩ : Q).den)
      + 4 * ((⟨((c + 1 : Nat) : Int), 1⟩ : Q).num.toNat + (⟨((c + 1 : Nat) : Int), 1⟩ : Q).den)))
    (hKBBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_BB : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul
        ⟨(mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).num
            - ((mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).den : Int),
          (mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).num.toNat
            + (mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).den⟩
        ⟨(mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).num
            - ((mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).den : Int),
          (mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).num.toNat
            + (mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).den⟩))))
    (hKBBr : K_BB ≤ 2 * (((mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).num.toNat
        + (mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).den)
        * ((mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).num.toNat
        + (mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).den)
      + 4 * ((mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).num.toNat
        + (mul (⟨((c + 1 : Nat) : Int), 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q)).den))) :
    ∀ x y : Real,
    Rle (Rabs (Rsub (gLog c x) (gLog c y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rlog_abs_lipschitz_gen (gLogArg c x) (gLogArg c y)
    _ (gLogArg_witness c x) _ (gLogArg_witness c y)
    (⟨((c + 1 : Nat) : Int), 1⟩ : Q) K_B K_BB Nat.one_pos (h1B c)
    (gLogArg_pos c x) (gLogArg_hi c x) (gLogArg_ge1 c x)
    (gLogArg_pos c y) (gLogArg_hi c y) (gLogArg_ge1 c y)
    hρσ hKBF hKBr hKBBF hKBBr) ?_
  refine Rle_trans (qBandQ_lipschitz ⟨1, 1⟩ (⟨((c + 1 : Nat) : Int), 1⟩ : Q)
    (by decide) Nat.one_pos _ _) ?_
  refine Rle_trans (Rle_of_Req (Rabs_congr
    (shift_cc (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) x y))) ?_
  exact Rle_of_Req (Req_symm (Rone_mul (Rabs (Rsub x y))))

-- ===========================================================================
-- THE INSTANCES the t4 slot consumes: c = 1, 2, 3.
-- ===========================================================================

/-- `gLog 1` respects `≈`. -/
theorem gLog1_congr : ∀ x y : Real, Req x y → Req (gLog 1 x) (gLog 1 y) :=
  gLog_congr_of 1 (by decide)

/-- **`gLog 1` is `1`-Lipschitz** (`B = 2`, budgets `K_B = 42`, `K_BB = 90`). -/
theorem gLog1_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (gLog 1 x) (gLog 1 y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) :=
  gLog_lip_of 1 42 90 (by decide) (by decide) (by decide) (by decide) (by decide)

/-- `gLog 2` respects `≈`. -/
theorem gLog2_congr : ∀ x y : Real, Req x y → Req (gLog 2 x) (gLog 2 y) :=
  gLog_congr_of 2 (by decide)

/-- **`gLog 2` is `1`-Lipschitz** (`B = 3`, budgets `K_B = 64`, `K_BB = 280`). -/
theorem gLog2_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (gLog 2 x) (gLog 2 y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) :=
  gLog_lip_of 2 64 280 (by decide) (by decide) (by decide) (by decide) (by decide)

/-- `gLog 3` respects `≈`. -/
theorem gLog3_congr : ∀ x y : Real, Req x y → Req (gLog 3 x) (gLog 3 y) :=
  gLog_congr_of 3 (by decide)

/-- **`gLog 3` is `1`-Lipschitz** (`B = 4`, budgets `K_B = 90`, `K_BB = 714`). -/
theorem gLog3_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (gLog 3 x) (gLog 3 y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) :=
  gLog_lip_of 3 90 714 (by decide) (by decide) (by decide) (by decide) (by decide)

end UOR.Bridge.F1Square.Analysis
