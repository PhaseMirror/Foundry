/-
F1 square — **the positivity STRUCTURE of the UOR Atlas** (`AtlasPositivityStructure.lean`): two
kernel-level facts that formalize *what is positive in the Atlas and how its shape relates to the RH
form* — the crux-closing strategy's "understanding the positivity of the UOR Atlas", made theorems
rather than prose. NEITHER asserts the RH-equivalent core (`∀n>0, Pos (genuineLamSeq n)`), so the crux
fields stay `none`.

1. **The conserved positivity balance** `posMass − reflMass = T·O = 24`. The Atlas signature `(10,14)`
   counts eigen-DIRECTIONS; weighting them by eigenvalue gives the Atlas's own conserved invariant
   (`uor-atlas.md §5`): positive mass `10·1 + 7·2 + 2·7 = 38`, reflection mass `1·14 = 14`, and
   `38 − 14 = 24 = atlasTrace = T·O`. This refines `atlasTrace_eq`/`atlasM_signature` into the
   positive-vs-reflection split the Atlas balances at its zero-state.

2. **The difference-of-PSD decomposition** `atlasM = multForm posEig − multForm reflEig`, with BOTH
   parts `WeilPSD`. So the Atlas spectral form is a *difference of two positive-semidefinite forms* —
   the SAME structural shape as the crux's coupled kernel `coupledWeil arch w v M = multForm arch −
   primeGram w v M` (`CoupledWeilKernel.lean`). And `atlasM` is *not* `WeilPSD` (`atlasM_indefinite`):
   the Atlas is the finite, computable instance of the exact phenomenon the crux inhabits — "a
   difference of PSD forms need not be PSD", whose PSD-ness on the genuine data IS RH.

HONEST SCOPE. Structural facts about the Atlas's positivity (a decide-level mass balance, and a
diagonal decomposition into two PSD parts). This does NOT connect the definite parts to `2λₙ` (the §9
"decline to identify" — that connection is RH and is NOT made here), does NOT assert `ArchDominatesPrime`
or `WeilPSD` of any genuine form. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.AtlasSpectrum
import Multiplicity.F1.Square.SonineProjection

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- 1. The conserved positivity balance: posMass − reflMass = T·O = 24.
-- ===========================================================================

/-- The **positive eigenvalue-mass** `Σ_{i<24, λᵢ>0} λᵢ` — each positive eigendirection weighted by its
    eigenvalue. -/
def atlasPosMass : Int :=
  (((List.range 24).filter (fun i => decide (0 < atlasEig i))).map atlasEig).foldl (· + ·) 0

/-- The **reflection mass** `Σ_{i<24, λᵢ<0} (−λᵢ)` — the magnitude carried by the `−1` reflection
    eigenspace. -/
def atlasReflMass : Int :=
  (((List.range 24).filter (fun i => decide (atlasEig i < 0))).map (fun i => - atlasEig i)).foldl (· + ·) 0

/-- **Positive mass = 38** (`10·1 + 7·2 + 2·7`). Computed. -/
theorem atlasPosMass_eq : atlasPosMass = 38 := by decide

/-- **Reflection mass = 14** (`1·14`). Computed. -/
theorem atlasReflMass_eq : atlasReflMass = 14 := by decide

/-- **THE CONSERVED POSITIVITY BALANCE**: `posMass − reflMass = 24 = atlasTrace = T·O`. The Atlas
    balances its positive eigenvalue-mass against its reflection mass to exactly the carrier dimension
    `T·O` — the positivity invariant of the zero-state (`uor-atlas.md §5`), now a theorem. -/
theorem atlasPositivity_balance :
    atlasPosMass - atlasReflMass = atlasTrace ∧ atlasTrace = atlasT * atlasO := by decide

-- ===========================================================================
-- 2. The difference-of-PSD decomposition atlasM = multForm posEig − multForm reflEig.
-- ===========================================================================

/-- The **positive part** of the atlas eigenvalue at carrier `i`: `max(λᵢ, 0)` as a real. -/
def atlasPosEig (i : Nat) : Real :=
  ofQ ⟨if 0 ≤ atlasEig i then atlasEig i else 0, 1⟩ Nat.one_pos

/-- The **reflection part** of the atlas eigenvalue at carrier `i`: `max(−λᵢ, 0)` as a real. -/
def atlasReflEig (i : Nat) : Real :=
  ofQ ⟨if 0 ≤ atlasEig i then 0 else - atlasEig i, 1⟩ Nat.one_pos

/-- The positive part is non-negative. -/
theorem atlasPosEig_nonneg (i : Nat) : Rnonneg (atlasPosEig i) :=
  Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ if 0 ≤ atlasEig i then atlasEig i else 0; split <;> omega)

/-- The reflection part is non-negative. -/
theorem atlasReflEig_nonneg (i : Nat) : Rnonneg (atlasReflEig i) :=
  Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ if 0 ≤ atlasEig i then 0 else - atlasEig i; split <;> omega)

/-- **The positive part is a PSD form** — a non-negative diagonal (`multForm_psd_iff`). -/
theorem atlasPos_psd : WeilPSD (multForm atlasPosEig) :=
  (multForm_psd_iff atlasPosEig).mpr atlasPosEig_nonneg

/-- **The reflection part is a PSD form** — a non-negative diagonal (`multForm_psd_iff`). -/
theorem atlasRefl_psd : WeilPSD (multForm atlasReflEig) :=
  (multForm_psd_iff atlasReflEig).mpr atlasReflEig_nonneg

/-- Integer subtraction at denominator 1: `(a/1) − (b/1) ≈ (a−b)/1`. -/
private theorem ofQ1_sub (a b : Int) :
    Req (Rsub (ofQ ⟨a, 1⟩ Nat.one_pos) (ofQ ⟨b, 1⟩ Nat.one_pos))
        (ofQ ⟨a - b, 1⟩ Nat.one_pos) := by
  apply Req_of_seq_Qeq; intro n
  simp only [Rsub, Radd, Rneg, ofQ, add, neg, Qeq]; push_cast; ring_uor

/-- **THE ATLAS SPECTRAL FORM IS A DIFFERENCE OF TWO PSD FORMS**:
    `atlasM = multForm posEig − multForm reflEig` (pointwise), each part `WeilPSD`. On the diagonal the
    positive/reflection split is `λᵢ = max(λᵢ,0) − max(−λᵢ,0)`; off-diagonal both sides are `0`. This is
    the SAME shape as the crux's coupled kernel `coupledWeil = multForm arch − primeGram` — and by
    `atlasM_indefinite` the difference is NOT PSD, so the Atlas is the finite computable instance of the
    "difference of PSD forms need not be PSD" phenomenon whose PSD-ness on the genuine data is RH. -/
theorem atlasM_eq_pos_sub_refl (i j : Nat) :
    Req (atlasM i j) (Rsub (multForm atlasPosEig i j) (multForm atlasReflEig i j)) := by
  by_cases h : i = j
  · subst h
    -- diagonal: ofQ⟨λᵢ,1⟩ = (ofQ⟨p,1⟩) − (ofQ⟨r,1⟩), with p − r = λᵢ
    have hint : (if 0 ≤ atlasEig i then atlasEig i else 0)
        - (if 0 ≤ atlasEig i then 0 else - atlasEig i) = atlasEig i := by split <;> omega
    have ha : atlasM i i = ofQ ⟨atlasEig i, 1⟩ Nat.one_pos := if_pos rfl
    have hp : multForm atlasPosEig i i = atlasPosEig i := if_pos rfl
    have hr : multForm atlasReflEig i i = atlasReflEig i := if_pos rfl
    rw [ha, hp, hr]
    show Req (ofQ ⟨atlasEig i, 1⟩ Nat.one_pos)
             (Rsub (ofQ ⟨if 0 ≤ atlasEig i then atlasEig i else 0, 1⟩ Nat.one_pos)
                   (ofQ ⟨if 0 ≤ atlasEig i then 0 else - atlasEig i, 1⟩ Nat.one_pos))
    refine Req_symm (Req_trans (ofQ1_sub _ _) ?_)
    exact ofQ_congr Nat.one_pos Nat.one_pos (by simp only [Qeq]; omega)
  · -- off-diagonal: both sides vanish
    have e1 : atlasM i j = zero := if_neg h
    have e2 : multForm atlasPosEig i j = zero := if_neg h
    have e3 : multForm atlasReflEig i j = zero := if_neg h
    rw [e1, e2, e3]
    exact Req_symm (Req_trans (Radd_congr (Req_refl zero) Rneg_zero) (Radd_zero zero))

/-- **The difference `posEig − reflEig` is NOT PSD** — its diagonal entry at the `−1` reflection index
    `10` is `0 − 1 = −1 < 0` (transported from `atlasM_neg_entry` across `atlasM_eq_pos_sub_refl`). -/
theorem atlasM_diff_not_psd :
    ¬ WeilPSD (fun i j => Rsub (multForm atlasPosEig i j) (multForm atlasReflEig i j)) :=
  not_WeilPSD_of_neg_diag 10
    (Pos_congr (Rneg_congr (atlasM_eq_pos_sub_refl 10 10)) atlasM_neg_entry)

/-- **THE ATLAS IS THE FINITE KERNEL WITNESS THAT "A DIFFERENCE OF PSD FORMS NEED NOT BE PSD"** —
    `multForm posEig` and `multForm reflEig` are each `WeilPSD`, yet their difference (`= atlasM`) is
    NOT. This is exactly the crux's phenomenon (`coupledWeil = multForm arch − primeGram`, a difference
    of PSD forms whose PSD-ness on the genuine data is RH), here realized concretely and decidably at the
    Atlas: the Atlas is the computable instance, the genuine coupling the RH instance. It exhibits WHY
    the crux is not automatic — it does NOT close it. Crux fields stay `none`. -/
theorem atlas_diff_of_psd_not_psd :
    WeilPSD (multForm atlasPosEig) ∧ WeilPSD (multForm atlasReflEig)
    ∧ ¬ WeilPSD (fun i j => Rsub (multForm atlasPosEig i j) (multForm atlasReflEig i j)) :=
  ⟨atlasPos_psd, atlasRefl_psd, atlasM_diff_not_psd⟩

end Multiplicity.UOR.Bridge.F1Square.Square
