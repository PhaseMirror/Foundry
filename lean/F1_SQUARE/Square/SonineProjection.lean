/-
F1 square — v0.22.0 Track 2, the crux frontier: **the Sonine projection — Weil positivity recovered
on the complement of the negative-multiplier band.**

THE FRONTIER, NAMED. The natural finite routes to the crux are foreclosed: component isolation is
RH-equivalent (neither `arith(n)` nor `arch(n)` is unconditionally positive — `arch(1) < 0`); pointwise
single-place positivity is REFUTED (`BurnolAlphaTwo.burnol_multiplier_indefinite`: `α(0) > 0`, `α(2) < 0`);
free algebraic sum-of-squares is RH-equivalent (`WeilPSD.realizesDiag_genuine_iff`: an SOS for `2λₙ` IS
RH). What is LEFT STANDING is not a component and not a pointwise value but a **projection**: the
positivity of the *whole* Weil pairing recovered on the Sonine complement — the Connes–Consani / Burnol
resolution.

THE CONSTRUCTION (extrapolated from the proven `α`-indefiniteness and the Atlas signature geometry).
The Weil pairing on autocorrelations is the spectral (multiplier) form `Σ_τ α(τ)·|g(τ)|²` with `α`
Burnol's archimedean multiplier — PROVEN indefinite (`α(0) > 0`, `α(2) < 0`). Diagonalized on the
spectral indices it is `multForm α`, `(multForm α)(i,j) = δ_{ij}·α(i)`. Then:

- **The whole form is positive iff there is no negative band** (`multForm_psd_iff`): `WeilPSD (multForm α)
  ⟺ α(i) ≥ 0 ∀i`. For Burnol's `α` the right side is FALSE (`α(2) < 0`), so the bare pairing is
  indefinite (`burnol_pairing_indefinite`) — the single-place obstruction, in form-positivity terms.
- **Positivity is recovered, UNCONDITIONALLY, on the Sonine complement** (`multForm_psd_on_complement`):
  if a test family `c` vanishes on the negative band (`c(i) = 0` wherever `α(i) < 0`), then
  `Σ c_i c_j (multForm α)(i,j) = Σ_i c_i² α(i) ≥ 0` — a THEOREM, no RH. `burnol_pairing_psd_on_sonine`
  is the Burnol instance: with `c(1) = 0` (projecting out the `α(2) < 0` band index), the pairing is
  `≥ 0` using `α(0) > 0` on the complement.

WHAT IS UNCONDITIONAL vs WHAT IS RH. The Sonine-complement positivity (`...on_complement`,
`...on_sonine`) is unconditional — a genuine theorem. The FULL positivity (over *all* test families,
including those with energy in the negative band) is `WeilPSD (multForm α)` = `α ≥ 0 ∀i` (the bare
multiplier nonneg), which is FALSE pointwise; the genuine RH content is that the negative band's
contribution is cancelled by the coupling of `f` and its transform `f̂` (the Sonine *space* constraint,
which couples the two and is NOT captured by the bare support condition here). This file builds the
projection MECHANISM and the unconditional complement-positivity; the band-coupling that would extend it
to the whole space is RH, and stays open — the crux fields stay `none`.

(Faithfulness boundary: the genuine Connes–Consani Sonine space is the `f, f̂` co-support condition, an
infinite-dimensional coupling; `c(i) = 0 on the band` is its spectral-support skeleton, which is what
the discrete, integration-free substrate carries. The unconditional positivity proved here is the
band-complement positivity, not the full Sonine-space theorem.)

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.GaugeTower
import F1Square.Analysis.BurnolAlphaTwo

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- The multiplier (Weil spectral) form and the sifting collapse to its diagonal.
-- ===========================================================================

/-- The discrete **Weil multiplier form** `Σ_τ α(τ)·|g(τ)|²`, diagonalized on the spectral indices:
    `(multForm α)(i,j) = δ_{ij}·α(i)`. With `α` Burnol's archimedean multiplier this is the spectral
    form of the Weil pairing on autocorrelations. -/
def multForm (α : Nat → Real) : Nat → Nat → Real :=
  fun i j => if i = j then α i else zero

/-- `(multForm α)(n,n) = α(n)` — the diagonal is the multiplier. -/
theorem multForm_diag (α : Nat → Real) (n : Nat) : multForm α n n = α n := if_pos rfl

/-- **Sifting**: `Σ_{j<N} c(j)·(δ_{ij}·v) ≈ c(i)·v` for `i < N` — only the `j = i` term survives. -/
theorem RsumN_sift (i : Nat) (c : Nat → Real) (v : Real) :
    ∀ N, i < N → Req (RsumN (fun j => Rmul (c j) (if i = j then v else zero)) N) (Rmul (c i) v) := by
  intro N
  induction N with
  | zero => intro h; exact absurd h (Nat.not_lt_zero i)
  | succ m ih =>
    intro h
    by_cases him : i = m
    · subst him
      show Req (Radd (RsumN (fun j => Rmul (c j) (if i = j then v else zero)) i)
        (Rmul (c i) (if i = i then v else zero))) (Rmul (c i) v)
      rw [if_pos rfl]
      have hearlier : Req (RsumN (fun j => Rmul (c j) (if i = j then v else zero)) i) zero :=
        RsumN_zero i (fun j hj => by
          rw [if_neg (by omega : ¬ i = j)]; exact Rmul_zero (c j))
      exact Req_trans (Radd_congr hearlier (Req_refl (Rmul (c i) v)))
        (Req_trans (Radd_comm zero (Rmul (c i) v)) (Radd_zero (Rmul (c i) v)))
    · have hlt : i < m := by omega
      show Req (Radd (RsumN (fun j => Rmul (c j) (if i = j then v else zero)) m)
        (Rmul (c m) (if i = m then v else zero))) (Rmul (c i) v)
      rw [if_neg him]
      exact Req_trans (Radd_congr (ih hlt) (Rmul_zero (c m))) (Radd_zero (Rmul (c i) v))

/-- **The multiplier form collapses to its diagonal**: `Σ_{i,j<N} c_i c_j (multForm α)(i,j) ≈
    Σ_{i<N} c_i·(c_i·α(i))` — the off-diagonal vanishes (sifting), leaving the spectral square sum. -/
theorem weilQuad_multForm (α c : Nat → Real) (N : Nat) :
    Req (weilQuad (multForm α) c N) (RsumN (fun i => Rmul (c i) (Rmul (c i) (α i))) N) := by
  unfold weilQuad
  refine RsumN_congr N (fun i hi => ?_)
  refine Req_trans (Req_symm (Rmul_RsumN_left (c i) (fun j => Rmul (c j) (multForm α i j)) N)) ?_
  exact Rmul_congr (Req_refl (c i)) (RsumN_sift i c (α i) N hi)

-- ===========================================================================
-- The dichotomy: whole-form positivity = no negative band; complement positivity is unconditional.
-- ===========================================================================

/-- **The whole multiplier form is positive iff the multiplier has no negative band**:
    `WeilPSD (multForm α) ⟺ α(i) ≥ 0 ∀i`. Forward: a PSD form has nonnegative diagonal
    (`WeilPSD_diag`), and the diagonal is `α`. Backward: every `α(i) ≥ 0` makes the diagonal sum of
    squares `Σ c_i² α(i)` nonnegative (`multForm_psd_on_complement` with no projection). -/
theorem multForm_psd_iff (α : Nat → Real) :
    WeilPSD (multForm α) ↔ ∀ i, Rnonneg (α i) := by
  constructor
  · intro h i
    have hd := WeilPSD_diag h i
    rwa [multForm_diag α i] at hd
  · intro h N c
    refine Rnonneg_congr (Req_symm (weilQuad_multForm α c N)) ?_
    refine Rnonneg_RsumN N (fun i _ => ?_)
    exact Rnonneg_congr (Rmul_assoc (c i) (c i) (α i))
      (Rnonneg_Rmul (Rnonneg_Rmul_self (c i)) (h i))

/-- **POSITIVITY ON THE SONINE COMPLEMENT, UNCONDITIONALLY**: if the test family `c` vanishes on the
    negative band — at every `i < N`, either `α(i) ≥ 0` or `c(i) = 0` — then the multiplier-form
    quadratic is `≥ 0`. The form collapses to `Σ_{i<N} c_i² α(i)`, and each term is `≥ 0` (its factor
    `α(i)` is nonneg, or `c(i) = 0` kills it). This is the Weil pairing recovered on the Sonine
    complement: a genuine theorem, NO RH. -/
theorem multForm_psd_on_complement (α c : Nat → Real) (N : Nat)
    (h : ∀ i, i < N → Rnonneg (α i) ∨ Req (c i) zero) :
    Rnonneg (weilQuad (multForm α) c N) := by
  refine Rnonneg_congr (Req_symm (weilQuad_multForm α c N)) ?_
  refine Rnonneg_RsumN N (fun i hi => ?_)
  rcases h i hi with hα | hc0
  · exact Rnonneg_congr (Rmul_assoc (c i) (c i) (α i))
      (Rnonneg_Rmul (Rnonneg_Rmul_self (c i)) hα)
  · refine Rnonneg_congr (Req_symm ?_) Rnonneg_zero
    exact Req_trans (Rmul_congr hc0 (Req_refl _))
      (Req_trans (Rmul_comm zero (Rmul (c i) (α i))) (Rmul_zero (Rmul (c i) (α i))))

-- ===========================================================================
-- The Burnol instance: the bare pairing is indefinite, positive on the Sonine complement.
-- ===========================================================================

/-- Burnol's archimedean multiplier as a discrete spectral sequence: index `0` is the window-center
    sample `α(0) > 0` (in the Sonine complement), index `1` is the off-center sample `α(2) < 0` (the
    negative band), `0` beyond. The two PROVEN values (`burnolAlphaZero_pos`, `burnolAlphaTwo_neg`). -/
def burnolMult : Nat → Real
  | 0 => burnolAlphaZero
  | 1 => burnolAlphaTwo
  | _ => zero

/-- **THE BARE WEIL PAIRING IS INDEFINITE** (form-positivity terms): `multForm burnolMult` is not
    `WeilPSD`, because its negative band `α(2) < 0` (index `1`) is a negative diagonal entry. This is
    the single-place obstruction (`burnol_multiplier_indefinite`) read as failure of full
    form-positivity — exactly why a projection, not a pointwise bound, is needed. -/
theorem burnol_pairing_indefinite : ¬ WeilPSD (multForm burnolMult) := by
  apply not_WeilPSD_of_neg_diag 1
  rw [multForm_diag burnolMult 1]
  exact burnolAlphaTwo_neg

/-- **THE WEIL PAIRING, RECOVERED ON THE SONINE COMPLEMENT** (Burnol instance, unconditional): a test
    family `c` projected off the negative band (`c(1) = 0`, removing the `α(2) < 0` index) gives a
    nonnegative pairing, for every truncation `N` — using `α(0) > 0` on the complement. Positivity is
    recovered by the PROJECTION, with no RH input. The crux (extending it to test families with energy
    in the band, via the genuine Sonine `f↔f̂` coupling) stays open. -/
theorem burnol_pairing_psd_on_sonine (c : Nat → Real) (N : Nat) (hband : Req (c 1) zero) :
    Rnonneg (weilQuad (multForm burnolMult) c N) := by
  refine multForm_psd_on_complement burnolMult c N (fun i _ => ?_)
  rcases i with _ | _ | k
  · exact Or.inl (Rnonneg_of_Pos burnolAlphaZero_pos)
  · exact Or.inr hband
  · exact Or.inl Rnonneg_zero

-- ===========================================================================
-- BURNOL'S CORRECTION (the sharpest UNCONDITIONAL Weil-positivity mechanism, discretized).
-- Deep-research-verified (Burnol, arXiv math/0101068, Thm): α(τ) → +∞ at ±∞, so the negative
-- band is bounded and ∃ a correction making the multiplier pointwise ≥ 0, with the correction
-- vanishing on the support window — hence Z(k) ≥ 0 for test functions supported in the window,
-- UNCONDITIONALLY. This is the sharpest positivity that is a theorem (not RH-equivalent).
-- ===========================================================================

/-- **THE CORRECTION MECHANISM (Burnol), discretized and UNCONDITIONAL**: if a correction `corr`
    makes the multiplier pointwise nonnegative (`α(i) + corr(i) ≥ 0 ∀i`) and vanishes on the support
    of the test family `c` (the window — `corr(i) = 0` wherever `c(i) ≠ 0`), then the Weil
    multiplier-form pairing is `≥ 0`. The form collapses to `Σ c_i² α(i)`; on the window `α(i) = α(i) +
    corr(i) = β(i) ≥ 0`, off it `c(i) = 0`, so every term is nonneg. This is Burnol's
    `Aε·cos(ετ) + α(τ) ≥ 0 ∀τ` with `cos(ετ)` integrating to zero on `[1/c,c]` — the sharpest
    UNCONDITIONAL Weil-positivity theorem (the support-restricted one), in the discrete substrate.
    No RH; the crux fields stay `none`. -/
theorem multForm_psd_via_correction (α corr c : Nat → Real) (N : Nat)
    (hnn : ∀ i, Rnonneg (Radd (α i) (corr i)))
    (hwin : ∀ i, i < N → Req (corr i) zero ∨ Req (c i) zero) :
    Rnonneg (weilQuad (multForm α) c N) := by
  refine Rnonneg_congr (Req_symm (weilQuad_multForm α c N)) ?_
  refine Rnonneg_RsumN N (fun i hi => ?_)
  rcases hwin i hi with hcorr0 | hc0
  · -- corr i = 0 ⟹ α i = α i + corr i = β i ≥ 0
    have hαβ : Req (α i) (Radd (α i) (corr i)) :=
      Req_symm (Req_trans (Radd_congr (Req_refl _) hcorr0) (Radd_zero (α i)))
    exact Rnonneg_congr (Rmul_assoc (c i) (c i) (α i))
      (Rnonneg_Rmul (Rnonneg_Rmul_self (c i)) (Rnonneg_congr (Req_symm hαβ) (hnn i)))
  · refine Rnonneg_congr (Req_symm ?_) Rnonneg_zero
    exact Req_trans (Rmul_congr hc0 (Req_refl _))
      (Req_trans (Rmul_comm zero (Rmul (c i) (α i))) (Rmul_zero (Rmul (c i) (α i))))

/-- Burnol's discrete correction for the proven samples: `0` on the window (index `0`), and
    `−α(2)` on the negative-band index (`1`) — the amount that exactly cancels the `α(2) < 0` band. -/
def burnolCorr : Nat → Real
  | 1 => Rneg burnolAlphaTwo
  | _ => zero

/-- **THE BURNOL-CORRECTED MULTIPLIER IS POINTWISE NONNEGATIVE** — `α(i) + corr(i) ≥ 0 ∀i`: at the
    window center `α(0) > 0` (correction `0`); at the negative band `α(2) + (−α(2)) = 0`; `0` beyond.
    The discrete analog of `Aε·cos(ετ) + α(τ) ≥ 0 ∀τ`: the correction lifts the bounded negative band
    to `0`, leaving the multiplier nonnegative everywhere. UNCONDITIONAL. -/
theorem burnol_corrected_nonneg : ∀ i, Rnonneg (Radd (burnolMult i) (burnolCorr i)) := by
  intro i
  rcases i with _ | _ | k
  · exact Rnonneg_congr (Req_symm (Radd_zero burnolAlphaZero)) (Rnonneg_of_Pos burnolAlphaZero_pos)
  · exact Rnonneg_congr (Req_symm (Radd_neg burnolAlphaTwo)) Rnonneg_zero
  · exact Rnonneg_congr (Req_symm (Radd_zero zero)) Rnonneg_zero

/-- **THE WEIL PAIRING IS POSITIVE ON THE WINDOW, VIA THE BURNOL CORRECTION** (unconditional): for a
    test family supported on the window (`c(1) = 0`, off the negative band), the bare-`α` pairing is
    `≥ 0` — recovered through the pointwise-nonnegative corrected multiplier (`burnol_corrected_nonneg`),
    which agrees with `α` on the window. This is the sharpest unconditional positivity (Burnol's
    support-restricted theorem) on the built object, via the correction rather than bare projection.
    Crux `none`. -/
theorem burnol_pairing_psd_via_correction (c : Nat → Real) (N : Nat) (hband : Req (c 1) zero) :
    Rnonneg (weilQuad (multForm burnolMult) c N) := by
  refine multForm_psd_via_correction burnolMult burnolCorr c N burnol_corrected_nonneg (fun i _ => ?_)
  rcases i with _ | _ | k
  · exact Or.inl (Req_refl _)
  · exact Or.inr hband
  · exact Or.inl (Req_refl _)

/-- **THE SONINE DICHOTOMY, on the built object**: the bare Weil pairing is NOT positive
    (`burnol_pairing_indefinite`, the negative band is real), but positivity IS recovered on the
    Sonine complement (`burnol_pairing_psd_on_sonine`, unconditional). So what closes the crux is
    neither a component nor a pointwise value: it is the projection — and the open content is the
    coupling that would carry the band-complement positivity to the whole space (RH). The crux fields
    stay `none`. -/
theorem burnol_sonine_dichotomy :
    (¬ WeilPSD (multForm burnolMult))
    ∧ (∀ (c : Nat → Real) (N : Nat), Req (c 1) zero →
        Rnonneg (weilQuad (multForm burnolMult) c N)) :=
  ⟨burnol_pairing_indefinite, burnol_pairing_psd_on_sonine⟩

end UOR.Bridge.F1Square.Square
