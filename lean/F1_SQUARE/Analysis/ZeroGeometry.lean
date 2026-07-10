/-
F1 square — v0.20.0 stage F, **Lever 1: the Li/zero geometry** — the constructive bridge between a
zero's POSITION (relative to the critical line) and the GROWTH of its Li contribution, the precise
link that feeds Voros's dichotomy (`Voros.lean`) and the de la Vallée-Poussin zero-free region.

Each Riemann zero `ρ` contributes `1 − (1−1/ρ)ⁿ` to the Li coefficient `λₙ = Σ_ρ (1−(1−1/ρ)ⁿ)`. The
modulus of `(1−1/ρ)ⁿ` is `r(ρ)ⁿ` with `r(ρ) = |1−1/ρ| = |ρ−1|/|ρ|`, so the GROWTH of the term is
governed entirely by the squared ratio `|ρ−1|²/|ρ|²`. THE GENUINE CONSTRUCTIVE NUGGET — proved here,
unconditionally and without `sqrt` (working with the squared moduli):

    |ρ−1|² − |ρ|²  =  1 − 2·Re ρ.

The `Im ρ` terms cancel exactly, so the sign of the difference — hence whether the Li term is
bounded, decaying, or growing — is decided ENTIRELY by which side of the critical line `Re ρ = ½`
the zero lies on:

  • `Re ρ = ½`  (on the critical line, RH)      ⟹  `|ρ−1|² = |ρ|²`  (ratio 1: BOUNDED — Voros's
                                                    tempered regime, the home of `λₙ > 0 ∀n`);
  • `Re ρ < ½`  (left of the line)               ⟹  `|ρ−1|² > |ρ|²`  (ratio > 1: a term of modulus
                                                    `r(ρ)ⁿ → ∞` — the EXPONENTIAL OSCILLATION seed,
                                                    Voros's ¬RH regime);
  • `Re ρ > ½`  (right of the line)              ⟹  `|ρ−1|² < |ρ|²`  (ratio < 1: decaying).

WHAT THIS DOES AND DOES NOT DO. This is the exact per-zero mechanism behind the Voros dichotomy: a
single off-line zero seeds an exponentially growing Li term. It is fully constructive. It does NOT
prove WHERE the zeros are (that is RH), nor that the SUM `λₙ` (with its cancellations) inherits a
single term's growth (Voros's saddle-point analysis — [CLASSICAL], interface). The de la
Vallée-Poussin zero-free band (`DVPBand`) pins zeros into `δ < Re ρ < 1−δ` for some `δ > 0`, but
`δ > 0` does NOT collapse the band to the line — that residual gap IS the open analytic content.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.Complex
import F1Square.Analysis.RealPow

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The squared moduli `|ρ|²` and `|ρ−1|²` (no `sqrt` — the growth dichotomy lives in the squares).
-- ===========================================================================

/-- The squared modulus `|z|² = (Re z)² + (Im z)²`. -/
def cnormSq (z : Complex) : Real := Radd (Rmul z.re z.re) (Rmul z.im z.im)

/-- The squared modulus of `z − 1`, `|z−1|² = (Re z − 1)² + (Im z)²` — the numerator of the Li
    growth ratio `|1−1/ρ|² = |ρ−1|²/|ρ|²`. -/
def csubOneNormSq (z : Complex) : Real :=
  Radd (Rmul (Rsub z.re one) (Rsub z.re one)) (Rmul z.im z.im)

-- Generic ADDITIVE identities, proved by the abelian-group lemmas (`Radd_assoc`/`Radd_comm`/
-- `Radd_neg`/`Rneg_Radd`/…).  `Req_of_seq_Qeq` is NOT usable here: it needs both sides to share the
-- additive TREE SHAPE (Bishop `Radd` reindexes by depth), and these lemmas re-shape the tree — so
-- the rearrangements must go through the genuine group laws. Multiplicative subterms are threaded as
-- whole variables and the lemmas applied by substitution.

/-- `x − (y − z) ≈ (x − y) + z`. -/
private theorem addA (x y z : Real) : Req (Rsub x (Rsub y z)) (Radd (Rsub x y) z) := by
  show Req (Radd x (Rneg (Radd y (Rneg z)))) (Radd (Radd x (Rneg y)) z)
  have h1 : Req (Rneg (Radd y (Rneg z))) (Radd (Rneg y) z) :=
    Req_trans (Rneg_Radd y (Rneg z)) (Radd_congr (Req_refl _) (Rneg_neg z))
  exact Req_trans (Radd_congr (Req_refl x) h1) (Req_symm (Radd_assoc x (Rneg y) z))

/-- `(x − a) − a ≈ x − (a + a)`. -/
private theorem addB (x a : Real) : Req (Rsub (Rsub x a) a) (Rsub x (Radd a a)) := by
  show Req (Radd (Radd x (Rneg a)) (Rneg a)) (Radd x (Rneg (Radd a a)))
  exact Req_trans (Radd_assoc x (Rneg a) (Rneg a))
    (Radd_congr (Req_refl x) (Req_symm (Rneg_Radd a a)))

/-- `(p + w) − (q + w) ≈ p − q` (the shared summand cancels). -/
private theorem addC (p q w : Real) : Req (Rsub (Radd p w) (Radd q w)) (Rsub p q) := by
  show Req (Radd (Radd p w) (Rneg (Radd q w))) (Radd p (Rneg q))
  have h1 : Req (Rneg (Radd q w)) (Radd (Rneg w) (Rneg q)) :=
    Req_trans (Rneg_Radd q w) (Radd_comm (Rneg q) (Rneg w))
  refine Req_trans (Radd_congr (Req_refl _) h1) ?_
  refine Req_trans (Radd_assoc p w (Radd (Rneg w) (Rneg q))) ?_
  refine Req_trans (Radd_congr (Req_refl p) (Req_symm (Radd_assoc w (Rneg w) (Rneg q)))) ?_
  refine Req_trans (Radd_congr (Req_refl p) (Radd_congr (Radd_neg w) (Req_refl _))) ?_
  exact Radd_congr (Req_refl p) (Req_trans (Radd_comm zero (Rneg q)) (Radd_zero (Rneg q)))

/-- `((p − w) + c) − p ≈ c − w`. -/
private theorem addD (p w c : Real) : Req (Rsub (Radd (Rsub p w) c) p) (Rsub c w) := by
  show Req (Radd (Radd (Radd p (Rneg w)) c) (Rneg p)) (Radd c (Rneg w))
  refine Req_trans (Radd_congr (Radd_assoc p (Rneg w) c) (Req_refl (Rneg p))) ?_
  refine Req_trans (Radd_assoc p (Radd (Rneg w) c) (Rneg p)) ?_
  refine Req_trans (Radd_congr (Req_refl p) (Radd_comm (Radd (Rneg w) c) (Rneg p))) ?_
  refine Req_trans (Req_symm (Radd_assoc p (Rneg p) (Radd (Rneg w) c))) ?_
  refine Req_trans (Radd_congr (Radd_neg p) (Req_refl _)) ?_
  refine Req_trans (Radd_comm zero (Radd (Rneg w) c)) ?_
  exact Req_trans (Radd_zero (Radd (Rneg w) c)) (Radd_comm (Rneg w) c)

/-- `(p − r) + (p − r) ≈ (p + p) − (r + r)`. -/
private theorem addE (p r : Real) : Req (Radd (Rsub p r) (Rsub p r)) (Rsub (Radd p p) (Radd r r)) := by
  show Req (Radd (Radd p (Rneg r)) (Radd p (Rneg r))) (Radd (Radd p p) (Rneg (Radd r r)))
  refine Req_trans (Radd_assoc p (Rneg r) (Radd p (Rneg r))) ?_
  refine Req_trans (Radd_congr (Req_refl p) (Req_symm (Radd_assoc (Rneg r) p (Rneg r)))) ?_
  refine Req_trans (Radd_congr (Req_refl p)
    (Radd_congr (Radd_comm (Rneg r) p) (Req_refl (Rneg r)))) ?_
  refine Req_trans (Radd_congr (Req_refl p) (Radd_assoc p (Rneg r) (Rneg r))) ?_
  refine Req_trans (Req_symm (Radd_assoc p p (Radd (Rneg r) (Rneg r)))) ?_
  exact Radd_congr (Req_refl (Radd p p)) (Req_symm (Rneg_Radd r r))

/-- `p − ((p − w) + c) ≈ w − c`. -/
private theorem addF (p w c : Real) : Req (Rsub p (Radd (Rsub p w) c)) (Rsub w c) := by
  show Req (Radd p (Rneg (Radd (Radd p (Rneg w)) c))) (Radd w (Rneg c))
  have h1 : Req (Rneg (Radd (Radd p (Rneg w)) c)) (Radd (Radd (Rneg p) w) (Rneg c)) := by
    refine Req_trans (Rneg_Radd (Radd p (Rneg w)) c) (Radd_congr ?_ (Req_refl (Rneg c)))
    exact Req_trans (Rneg_Radd p (Rneg w)) (Radd_congr (Req_refl (Rneg p)) (Rneg_neg w))
  refine Req_trans (Radd_congr (Req_refl p) h1) ?_
  refine Req_trans (Radd_congr (Req_refl p) (Radd_assoc (Rneg p) w (Rneg c))) ?_
  refine Req_trans (Req_symm (Radd_assoc p (Rneg p) (Radd w (Rneg c)))) ?_
  refine Req_trans (Radd_congr (Radd_neg p) (Req_refl _)) ?_
  exact Req_trans (Radd_comm zero (Radd w (Rneg c))) (Radd_zero (Radd w (Rneg c)))

/-- `(a−1)² = (a² − 2a) + 1` on `Real` (the multiplicative expansion; the additive regrouping runs
    through the generic `addA`/`addB`, threading `a·a` as a whole atom). -/
private theorem sub_one_sq_expand (a : Real) :
    Req (Rmul (Rsub a one) (Rsub a one)) (Radd (Rsub (Rmul a a) (Radd a a)) one) := by
  have hd1 : Req (Rmul (Rsub a one) (Rsub a one))
      (Rsub (Rmul a (Rsub a one)) (Rmul one (Rsub a one))) :=
    Rmul_sub_distrib_right a one (Rsub a one)
  have hd2 : Req (Rmul a (Rsub a one)) (Rsub (Rmul a a) a) :=
    Req_trans (Rmul_sub_distrib a a one) (Rsub_congr (Req_refl _) (Rmul_one a))
  have hd3 : Req (Rmul one (Rsub a one)) (Rsub a one) :=
    Req_trans (Rmul_comm one (Rsub a one)) (Rmul_one (Rsub a one))
  -- (a·(a−1)) − (1·(a−1)) ≈ ((a²−a) − (a−1)) ≈ ((a²−a)−a)+1 ≈ (a²−(a+a))+1
  refine Req_trans hd1 (Req_trans (Rsub_congr hd2 hd3) ?_)
  refine Req_trans (addA (Rsub (Rmul a a) a) a one) ?_
  exact Radd_congr (addB (Rmul a a) a) (Req_refl one)

/-- A small additive helper: `Req (Rsub a b) zero → Req a b`. -/
theorem Req_of_Rsub_zero {a b : Real} (h : Req (Rsub a b) zero) : Req a b := by
  have h1 : Req a (Radd (Rsub a b) b) := by
    show Req a (Radd (Radd a (Rneg b)) b)
    refine Req_trans (Req_symm (Radd_zero a)) ?_
    have hz : Req zero (Radd (Rneg b) b) :=
      Req_symm (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b))
    exact Req_trans (Radd_congr (Req_refl a) hz) (Req_symm (Radd_assoc a (Rneg b) b))
  refine Req_trans h1 ?_
  exact Req_trans (Radd_congr h (Req_refl b)) (Req_trans (Radd_comm zero b) (Radd_zero b))

/-- `½ + ½ = 1`. -/
theorem half_add_half : Req (Radd half half) one := by
  apply Req_of_seq_Qeq; intro n
  simp only [Radd, half, one, ofQ, add, Qeq]; push_cast

-- ===========================================================================
-- **THE LI GROWTH-RATIO IDENTITY** and its three positional consequences.
-- ===========================================================================

/-- **The Li growth-ratio identity** `|z−1|² − |z|² ≈ 1 − 2·Re z` — the `Im z` terms cancel, so the
    sign is fixed by `Re z` alone. The constructive heart of Lever 1. -/
theorem liRatio_diff_eq (z : Complex) :
    Req (Rsub (csubOneNormSq z) (cnormSq z)) (Rsub one (Radd z.re z.re)) := by
  unfold csubOneNormSq cnormSq
  -- cancel the shared `im²` (addC), expand `(re−1)²` (sub_one_sq_expand), regroup (addD)
  refine Req_trans (addC (Rmul (Rsub z.re one) (Rsub z.re one)) (Rmul z.re z.re)
    (Rmul z.im z.im)) ?_
  refine Req_trans (Rsub_congr (sub_one_sq_expand z.re) (Req_refl (Rmul z.re z.re))) ?_
  exact addD (Rmul z.re z.re) (Radd z.re z.re) one

/-- **On the critical line** `Re z = ½`: the Li ratio is exactly `1` (`|z−1|² = |z|²`). The bounded
    term — Voros's tempered regime. -/
theorem liRatio_on_line (z : Complex) (h : Req z.re half) :
    Req (csubOneNormSq z) (cnormSq z) := by
  refine Req_of_Rsub_zero (Req_trans (liRatio_diff_eq z) ?_)
  refine Req_trans (Rsub_congr (Req_refl one) (Radd_congr h h)) ?_
  exact Req_trans (Rsub_congr (Req_refl one) half_add_half) (Radd_neg one)

/-- **Left of the critical line** `Re z < ½`: the Li ratio EXCEEDS `1` (`|z−1|² > |z|²`) — a term of
    modulus `r(ρ)ⁿ → ∞`, the exponential-oscillation seed (Voros's ¬RH regime). -/
theorem liRatio_left_of_line (z : Complex) (h : Pos (Rsub half z.re)) :
    Pos (Rsub (csubOneNormSq z) (cnormSq z)) := by
  -- (½−re)+(½−re) ≈ (½+½)−(re+re) ≈ 1−(re+re) ≈ |z−1|²−|z|²
  have hdbl : Req (Radd (Rsub half z.re) (Rsub half z.re)) (Rsub one (Radd z.re z.re)) :=
    Req_trans (addE half z.re) (Rsub_congr half_add_half (Req_refl (Radd z.re z.re)))
  have hpos2 : Pos (Radd (Rsub half z.re) (Rsub half z.re)) :=
    Pos_mono (Rle_self_Radd_right (Rnonneg_of_Pos h)) h
  exact Pos_congr (Req_trans hdbl (Req_symm (liRatio_diff_eq z))) hpos2

/-- **Right of the critical line** `Re z > ½`: the Li ratio is BELOW `1` (`|z|² > |z−1|²`) — a
    decaying term. -/
theorem liRatio_right_of_line (z : Complex) (h : Pos (Rsub z.re half)) :
    Pos (Rsub (cnormSq z) (csubOneNormSq z)) := by
  -- |z|²−|z−1|² ≈ (re+re)−1 ≈ (re+re)−(½+½) ≈ (re−½)+(re−½)
  have hL : Req (Rsub (cnormSq z) (csubOneNormSq z)) (Rsub (Radd z.re z.re) one) := by
    unfold cnormSq csubOneNormSq
    refine Req_trans (addC (Rmul z.re z.re) (Rmul (Rsub z.re one) (Rsub z.re one))
      (Rmul z.im z.im)) ?_
    refine Req_trans (Rsub_congr (Req_refl (Rmul z.re z.re)) (sub_one_sq_expand z.re)) ?_
    exact addF (Rmul z.re z.re) (Radd z.re z.re) one
  have hR : Req (Radd (Rsub z.re half) (Rsub z.re half)) (Rsub (Radd z.re z.re) one) :=
    Req_trans (addE z.re half) (Rsub_congr (Req_refl (Radd z.re z.re)) half_add_half)
  have hpos2 : Pos (Radd (Rsub z.re half) (Rsub z.re half)) :=
    Pos_mono (Rle_self_Radd_right (Rnonneg_of_Pos h)) h
  exact Pos_congr (Req_trans hR (Req_symm hL)) hpos2

-- ===========================================================================
-- The conditional asymptotic frame: zeros, the dVP band, and the gap to RH.
-- ===========================================================================

/-- A complex number is **on the critical line** iff `Re = ½`. -/
def OnCriticalLine (z : Complex) : Prop := Req z.re half

/-- **The Riemann Hypothesis face for an abstract zero set** `isZero`: every zero is on the critical
    line. (`isZero` models the genuine zero set, which is the open analytic object.) -/
def AllZerosOnLine (isZero : Complex → Prop) : Prop := ∀ z, isZero z → OnCriticalLine z

/-- **The de la Vallée-Poussin zero-free band** of half-width `δ`: every zero has `δ < Re < 1−δ`.
    The genuine dVP theorem (`ζ ≠ 0` for `Re σ ≥ 1 − c/log(|t|+2)`), with the functional-equation
    reflection, carves exactly such a band; that theorem is [CLASSICAL] and stays interface — what is
    mechanizable is the band's CONSEQUENCE for the Li ratios (below). -/
def DVPBand (isZero : Complex → Prop) (δ : Real) : Prop :=
  ∀ z, isZero z → Pos (Rsub z.re δ) ∧ Pos (Rsub (Rsub one δ) z.re)

/-- **CONDITIONAL TEMPERED RATIOS (the RH face)**: if every zero is on the critical line, then every
    zero's Li growth ratio is exactly `1` — `|ρ−1|² = |ρ|²` — the bounded, tempered seed (so `λₙ` has
    the polynomial envelope, no exponential term). This is the FORWARD constructive content of the
    conditional asymptotic: `RH ⟹ tempered`. -/
theorem allOnLine_ratios_one (isZero : Complex → Prop) (h : AllZerosOnLine isZero) :
    ∀ z, isZero z → Req (csubOneNormSq z) (cnormSq z) :=
  fun z hz => liRatio_on_line z (h z hz)

/-- **THE GAP, stated honestly**: the dVP band of half-width `δ` does NOT by itself force a zero onto
    the critical line. A zero strictly inside the band yet left of the line (`δ < Re z`, `Re z < ½`)
    simultaneously WITNESSES band membership AND a Li ratio strictly above `1` (`|z−1|² > |z|²`, a
    growing term) — the two coexist, so `DVPBand δ` for `δ > 0` is strictly weaker than
    `AllZerosOnLine`. Closing that residual gap (band ⟹ line) is RH itself. -/
theorem dvp_band_admits_off_line (z : Complex) (δ : Real)
    (hband : Pos (Rsub z.re δ) ∧ Pos (Rsub (Rsub one δ) z.re))
    (hleft : Pos (Rsub half z.re)) :
    (Pos (Rsub z.re δ) ∧ Pos (Rsub (Rsub one δ) z.re))
      ∧ Pos (Rsub (csubOneNormSq z) (cnormSq z)) :=
  ⟨hband, liRatio_left_of_line z hleft⟩

end UOR.Bridge.F1Square.Analysis
