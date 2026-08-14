/-
F1 square — **the pre-Hilbert layer, brick 32** (`DeepMember.lean`): **THE NONZERO `K = 2`
CO-SUPPORT MEMBER** — a genuine nonzero `[0,1]`-supported test whose transform vanishes at
BOTH integer points `0, 1`, so the skeleton's unconditional positivity
(`weil_psd_on_cosupport`, brick 29) fires on genuinely NONZERO `f, f̂` data.

The member is `x(1−x)(1−5x+5x²)`, realized in EXPANDED form as the linear combination
`c − 6c² + 10c³ − 5c⁴` of clamped-power tests (`deepBump`), so that:

- the moments split by the pairing's BILINEARITY (`innerI_add_left`/`innerI_neg_left`) into
  the certified engine values `(1/2, 1/3, 1/4, 1/5, 1/6)` of bricks 23–31, which cancel:
  `∫p = 1/2 − 2 + 5/2 − 1 = 0` and `∫xp = 1/3 − 3/2 + 2 − 5/6 = 0`
  (`deepBump_moment_zero`/`_one`) — no product expansion, no shared-modulus juggling;
- unit support follows from `p(1) = 0`: at every window point the clamp saturates and the
  coefficient tree collapses to `(1 + 10) − (6 + 5) = 0` (`deepBump_supp`);
- apartness is witnessed at `x = 1/10`: `p(1/10) = 99/2000 > 0`
  (`deepBump_value_tenth`/`deepBump_apart`).

`deepBump_hatVanishes` places it in `HatVanishes · 2` through the brick-22 moment bridge, and
**`weil_psd_nonzero_instance`** is the capstone: the discrete Weil multiplier form is
nonnegative on `momSeq deepBump` at every truncation — the band hypothesis discharged by a
CONSTRUCTED transform's vanishing at a certified NONZERO test. No RH.

HONEST SCOPE. One nonzero member at `K = 2`; deeper `K` needs higher-degree engines; the
positivity delivered remains the skeleton's diagonal multiplier form on moment data — not
the Weil functional on the test space, and not positivity beyond the complement (step 4,
= RH). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.BandBridge
import Multiplicity.F1Square.Square.MomentQuintic

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The member: c − 6c² + 10c³ − 5c⁴ from the test algebra.
-- ===========================================================================

/-- The quartic power test `clamp⁴`. -/
def quadT : L2Test := L2Test.mul cubeT clampTest

/-- `2c³`. -/
def d2T : L2Test := L2Test.add cubeT cubeT

/-- `10c³`. -/
def c10T : L2Test :=
  L2Test.add d2T (L2Test.add d2T (L2Test.add d2T (L2Test.add d2T d2T)))

/-- `2c²`. -/
def s2T : L2Test := L2Test.add sqT sqT

/-- `6c²`. -/
def s6T : L2Test := L2Test.add s2T (L2Test.add s2T s2T)

/-- `5c⁴`. -/
def q5T : L2Test :=
  L2Test.add quadT (L2Test.add quadT (L2Test.add quadT (L2Test.add quadT quadT)))

/-- **The deep bump**: `x(1−x)(1−5x+5x²) = x − 6x² + 10x³ − 5x⁴` on `[0,1]`, vanishing
    beyond — in expanded linear form `(c + 10c³) − (6c² + 5c⁴)`. -/
def deepBump : L2Test :=
  L2Test.add (L2Test.add clampTest c10T) (L2Test.neg (L2Test.add s6T q5T))

-- ===========================================================================
-- The elementary pairings against the monomial directions.
-- ===========================================================================

private theorem e1_0 : Req (innerI clampTest (powTest 0)) (ofQ (⟨1, 2⟩ : Q) (by decide)) :=
  mellinMoment_clamp_zero

private theorem e1_1 : Req (innerI clampTest (powTest 1)) (ofQ (⟨1, 3⟩ : Q) (by decide)) :=
  mellinMoment_clamp_one

private theorem e2_0 : Req (innerI sqT (powTest 0)) (ofQ (⟨1, 3⟩ : Q) (by decide)) := by
  have hdist : ∀ x, Req (Rmul (sqT.f x) ((powTest 0).f x)) (clampSq x) :=
    fun x => Rmul_one (sqT.f x)
  have hlipS : ∀ x y, Rle (Rabs (Rsub (clampSq x) (clampSq y)))
      (Rmul (ofQ (l2L sqT (powTest 0)) (l2L_den sqT (powTest 0))) (Rabs (Rsub x y))) :=
    fun x y => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x))
      (Req_symm (hdist y))))) (l2lip sqT (powTest 0) x y)
  have hfcS : ∀ x y : Real, Req x y → Req (clampSq x) (clampSq y) :=
    fun _ _ h => Rmul_congr (clamp01_congr h) (clamp01_congr h)
  refine Req_trans (riemannIntegral_congr (g := clampSq)
    (l2L_den sqT (powTest 0)) (l2L_num sqT (powTest 0))
    (l2lip sqT (powTest 0)) (l2fc sqT (powTest 0)) hlipS hfcS hdist) ?_
  exact riemannIntegral_clampSq_gen (l2L_den sqT (powTest 0)) (l2L_num sqT (powTest 0))
    hlipS hfcS

private theorem e2_1 : Req (innerI sqT (powTest 1)) (ofQ (⟨1, 4⟩ : Q) (by decide)) := by
  have hdist : ∀ x, Req (Rmul (sqT.f x) ((powTest 1).f x)) (clampCube x) := fun x =>
    Rmul_congr (Req_refl (sqT.f x))
      (Req_trans (Rmul_comm one (clamp01 x)) (Rmul_one (clamp01 x)))
  have hlipS : ∀ x y, Rle (Rabs (Rsub (clampCube x) (clampCube y)))
      (Rmul (ofQ (l2L sqT (powTest 1)) (l2L_den sqT (powTest 1))) (Rabs (Rsub x y))) :=
    fun x y => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x))
      (Req_symm (hdist y))))) (l2lip sqT (powTest 1) x y)
  have hfcS : ∀ x y : Real, Req x y → Req (clampCube x) (clampCube y) :=
    fun _ _ h => Rmul_congr (Rmul_congr (clamp01_congr h) (clamp01_congr h))
      (clamp01_congr h)
  refine Req_trans (riemannIntegral_congr (g := clampCube)
    (l2L_den sqT (powTest 1)) (l2L_num sqT (powTest 1))
    (l2lip sqT (powTest 1)) (l2fc sqT (powTest 1)) hlipS hfcS hdist) ?_
  exact riemannIntegral_clampCube_gen (l2L_den sqT (powTest 1)) (l2L_num sqT (powTest 1))
    hlipS hfcS

private theorem e3_0 : Req (innerI cubeT (powTest 0)) (ofQ (⟨1, 4⟩ : Q) (by decide)) := by
  have hdist : ∀ x, Req (Rmul (cubeT.f x) ((powTest 0).f x)) (clampCube x) :=
    fun x => Rmul_one (cubeT.f x)
  have hlipS : ∀ x y, Rle (Rabs (Rsub (clampCube x) (clampCube y)))
      (Rmul (ofQ (l2L cubeT (powTest 0)) (l2L_den cubeT (powTest 0))) (Rabs (Rsub x y))) :=
    fun x y => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x))
      (Req_symm (hdist y))))) (l2lip cubeT (powTest 0) x y)
  have hfcS : ∀ x y : Real, Req x y → Req (clampCube x) (clampCube y) :=
    fun _ _ h => Rmul_congr (Rmul_congr (clamp01_congr h) (clamp01_congr h))
      (clamp01_congr h)
  refine Req_trans (riemannIntegral_congr (g := clampCube)
    (l2L_den cubeT (powTest 0)) (l2L_num cubeT (powTest 0))
    (l2lip cubeT (powTest 0)) (l2fc cubeT (powTest 0)) hlipS hfcS hdist) ?_
  exact riemannIntegral_clampCube_gen (l2L_den cubeT (powTest 0)) (l2L_num cubeT (powTest 0))
    hlipS hfcS

private theorem e3_1 : Req (innerI cubeT (powTest 1)) (ofQ (⟨1, 5⟩ : Q) (by decide)) := by
  have hdist : ∀ x, Req (Rmul (cubeT.f x) ((powTest 1).f x)) (clampQuad x) := fun x =>
    Rmul_congr (Req_refl (cubeT.f x))
      (Req_trans (Rmul_comm one (clamp01 x)) (Rmul_one (clamp01 x)))
  have hlipS : ∀ x y, Rle (Rabs (Rsub (clampQuad x) (clampQuad y)))
      (Rmul (ofQ (l2L cubeT (powTest 1)) (l2L_den cubeT (powTest 1))) (Rabs (Rsub x y))) :=
    fun x y => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x))
      (Req_symm (hdist y))))) (l2lip cubeT (powTest 1) x y)
  have hfcS : ∀ x y : Real, Req x y → Req (clampQuad x) (clampQuad y) :=
    fun _ _ h => Rmul_congr (Rmul_congr (Rmul_congr (clamp01_congr h) (clamp01_congr h))
      (clamp01_congr h)) (clamp01_congr h)
  refine Req_trans (riemannIntegral_congr (g := clampQuad)
    (l2L_den cubeT (powTest 1)) (l2L_num cubeT (powTest 1))
    (l2lip cubeT (powTest 1)) (l2fc cubeT (powTest 1)) hlipS hfcS hdist) ?_
  exact riemannIntegral_clampQuad_gen (l2L_den cubeT (powTest 1)) (l2L_num cubeT (powTest 1))
    hlipS hfcS

private theorem e4_0 : Req (innerI quadT (powTest 0)) (ofQ (⟨1, 5⟩ : Q) (by decide)) := by
  have hdist : ∀ x, Req (Rmul (quadT.f x) ((powTest 0).f x)) (clampQuad x) :=
    fun x => Rmul_one (quadT.f x)
  have hlipS : ∀ x y, Rle (Rabs (Rsub (clampQuad x) (clampQuad y)))
      (Rmul (ofQ (l2L quadT (powTest 0)) (l2L_den quadT (powTest 0))) (Rabs (Rsub x y))) :=
    fun x y => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x))
      (Req_symm (hdist y))))) (l2lip quadT (powTest 0) x y)
  have hfcS : ∀ x y : Real, Req x y → Req (clampQuad x) (clampQuad y) :=
    fun _ _ h => Rmul_congr (Rmul_congr (Rmul_congr (clamp01_congr h) (clamp01_congr h))
      (clamp01_congr h)) (clamp01_congr h)
  refine Req_trans (riemannIntegral_congr (g := clampQuad)
    (l2L_den quadT (powTest 0)) (l2L_num quadT (powTest 0))
    (l2lip quadT (powTest 0)) (l2fc quadT (powTest 0)) hlipS hfcS hdist) ?_
  exact riemannIntegral_clampQuad_gen (l2L_den quadT (powTest 0)) (l2L_num quadT (powTest 0))
    hlipS hfcS

private theorem e4_1 : Req (innerI quadT (powTest 1)) (ofQ (⟨1, 6⟩ : Q) (by decide)) := by
  have hdist : ∀ x, Req (Rmul (quadT.f x) ((powTest 1).f x)) (clampQuint x) := fun x =>
    Rmul_congr (Req_refl (quadT.f x))
      (Req_trans (Rmul_comm one (clamp01 x)) (Rmul_one (clamp01 x)))
  have hlipS : ∀ x y, Rle (Rabs (Rsub (clampQuint x) (clampQuint y)))
      (Rmul (ofQ (l2L quadT (powTest 1)) (l2L_den quadT (powTest 1))) (Rabs (Rsub x y))) :=
    fun x y => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x))
      (Req_symm (hdist y))))) (l2lip quadT (powTest 1) x y)
  have hfcS : ∀ x y : Real, Req x y → Req (clampQuint x) (clampQuint y) :=
    fun _ _ h => Rmul_congr (Rmul_congr (Rmul_congr (Rmul_congr (clamp01_congr h)
      (clamp01_congr h)) (clamp01_congr h)) (clamp01_congr h)) (clamp01_congr h)
  refine Req_trans (riemannIntegral_congr (g := clampQuint)
    (l2L_den quadT (powTest 1)) (l2L_num quadT (powTest 1))
    (l2lip quadT (powTest 1)) (l2fc quadT (powTest 1)) hlipS hfcS hdist) ?_
  exact riemannIntegral_clampQuint_gen (l2L_den quadT (powTest 1)) (l2L_num quadT (powTest 1))
    hlipS hfcS

-- ===========================================================================
-- The vanishing moments (bilinearity against the engine values).
-- ===========================================================================

/-- Split-and-collapse helper: `⟨A+B, ψ⟩ ≈ v` from the two component values and the closed
    rational identity. -/
private theorem pair_add {A B ψ : L2Test} {a b v : Q}
    (had : 0 < a.den) (hbd : 0 < b.den) (hvd : 0 < v.den)
    (hA : Req (innerI A ψ) (ofQ a had)) (hB : Req (innerI B ψ) (ofQ b hbd))
    (hq : Qeq (add a b) v) :
    Req (innerI (L2Test.add A B) ψ) (ofQ v hvd) :=
  Req_trans (innerI_add_left A B ψ)
    (Req_trans (Radd_congr hA hB)
      (Req_trans (Radd_ofQ_ofQ had hbd) (Req_of_seq_Qeq (fun _ => hq))))

/-- **The deep bump's zeroth moment vanishes**: `∫₀¹ (x − 6x² + 10x³ − 5x⁴) = 0`. -/
theorem deepBump_moment_zero : Req (mellinMoment deepBump 0) zero := by
  have hd2 : Req (innerI d2T (powTest 0)) (ofQ (⟨1, 2⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e3_0 e3_0 (by decide)
  have hd4 : Req (innerI (L2Test.add d2T d2T) (powTest 0)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hd2 hd2 (by decide)
  have hd6 : Req (innerI (L2Test.add d2T (L2Test.add d2T d2T)) (powTest 0))
      (ofQ (⟨3, 2⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hd2 hd4 (by decide)
  have hd8 : Req (innerI (L2Test.add d2T (L2Test.add d2T (L2Test.add d2T d2T))) (powTest 0))
      (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hd2 hd6 (by decide)
  have hc10 : Req (innerI c10T (powTest 0)) (ofQ (⟨5, 2⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hd2 hd8 (by decide)
  have hs2 : Req (innerI s2T (powTest 0)) (ofQ (⟨2, 3⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e2_0 e2_0 (by decide)
  have hs4 : Req (innerI (L2Test.add s2T s2T) (powTest 0)) (ofQ (⟨4, 3⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hs2 hs2 (by decide)
  have hs6 : Req (innerI s6T (powTest 0)) (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hs2 hs4 (by decide)
  have hq2 : Req (innerI (L2Test.add quadT quadT) (powTest 0))
      (ofQ (⟨2, 5⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e4_0 e4_0 (by decide)
  have hq3 : Req (innerI (L2Test.add quadT (L2Test.add quadT quadT)) (powTest 0))
      (ofQ (⟨3, 5⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e4_0 hq2 (by decide)
  have hq4 : Req (innerI (L2Test.add quadT (L2Test.add quadT (L2Test.add quadT quadT)))
      (powTest 0)) (ofQ (⟨4, 5⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e4_0 hq3 (by decide)
  have hq5 : Req (innerI q5T (powTest 0)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e4_0 hq4 (by decide)
  have hL : Req (innerI (L2Test.add clampTest c10T) (powTest 0))
      (ofQ (⟨3, 1⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e1_0 hc10 (by decide)
  have hSQ : Req (innerI (L2Test.add s6T q5T) (powTest 0))
      (ofQ (⟨3, 1⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hs6 hq5 (by decide)
  have hN : Req (innerI (L2Test.neg (L2Test.add s6T q5T)) (powTest 0))
      (ofQ (neg (⟨3, 1⟩ : Q)) (by decide)) :=
    Req_trans (innerI_neg_left (L2Test.add s6T q5T) (powTest 0))
      (Req_trans (Rneg_congr hSQ) (Rneg_ofQ (⟨3, 1⟩ : Q) (by decide)))
  refine Req_trans (innerI_add_left (L2Test.add clampTest c10T)
    (L2Test.neg (L2Test.add s6T q5T)) (powTest 0)) ?_
  refine Req_trans (Radd_congr hL hN) ?_
  refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (add (⟨3, 1⟩ : Q) (neg (⟨3, 1⟩ : Q))) (⟨0, 1⟩ : Q)
    decide)

/-- **The deep bump's first moment vanishes**: `∫₀¹ x·(x − 6x² + 10x³ − 5x⁴) = 0`. -/
theorem deepBump_moment_one : Req (mellinMoment deepBump 1) zero := by
  have hd2 : Req (innerI d2T (powTest 1)) (ofQ (⟨2, 5⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e3_1 e3_1 (by decide)
  have hd4 : Req (innerI (L2Test.add d2T d2T) (powTest 1)) (ofQ (⟨4, 5⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hd2 hd2 (by decide)
  have hd6 : Req (innerI (L2Test.add d2T (L2Test.add d2T d2T)) (powTest 1))
      (ofQ (⟨6, 5⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hd2 hd4 (by decide)
  have hd8 : Req (innerI (L2Test.add d2T (L2Test.add d2T (L2Test.add d2T d2T))) (powTest 1))
      (ofQ (⟨8, 5⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hd2 hd6 (by decide)
  have hc10 : Req (innerI c10T (powTest 1)) (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hd2 hd8 (by decide)
  have hs2 : Req (innerI s2T (powTest 1)) (ofQ (⟨1, 2⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e2_1 e2_1 (by decide)
  have hs4 : Req (innerI (L2Test.add s2T s2T) (powTest 1)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hs2 hs2 (by decide)
  have hs6 : Req (innerI s6T (powTest 1)) (ofQ (⟨3, 2⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hs2 hs4 (by decide)
  have hq2 : Req (innerI (L2Test.add quadT quadT) (powTest 1))
      (ofQ (⟨1, 3⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e4_1 e4_1 (by decide)
  have hq3 : Req (innerI (L2Test.add quadT (L2Test.add quadT quadT)) (powTest 1))
      (ofQ (⟨1, 2⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e4_1 hq2 (by decide)
  have hq4 : Req (innerI (L2Test.add quadT (L2Test.add quadT (L2Test.add quadT quadT)))
      (powTest 1)) (ofQ (⟨2, 3⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e4_1 hq3 (by decide)
  have hq5 : Req (innerI q5T (powTest 1)) (ofQ (⟨5, 6⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e4_1 hq4 (by decide)
  have hL : Req (innerI (L2Test.add clampTest c10T) (powTest 1))
      (ofQ (⟨7, 3⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) e1_1 hc10 (by decide)
  have hSQ : Req (innerI (L2Test.add s6T q5T) (powTest 1))
      (ofQ (⟨7, 3⟩ : Q) (by decide)) :=
    pair_add (by decide) (by decide) (by decide) hs6 hq5 (by decide)
  have hN : Req (innerI (L2Test.neg (L2Test.add s6T q5T)) (powTest 1))
      (ofQ (neg (⟨7, 3⟩ : Q)) (by decide)) :=
    Req_trans (innerI_neg_left (L2Test.add s6T q5T) (powTest 1))
      (Req_trans (Rneg_congr hSQ) (Rneg_ofQ (⟨7, 3⟩ : Q) (by decide)))
  refine Req_trans (innerI_add_left (L2Test.add clampTest c10T)
    (L2Test.neg (L2Test.add s6T q5T)) (powTest 1)) ?_
  refine Req_trans (Radd_congr hL hN) ?_
  refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (add (⟨7, 3⟩ : Q) (neg (⟨7, 3⟩ : Q))) (⟨0, 1⟩ : Q)
    decide)

-- ===========================================================================
-- Unit support and apartness.
-- ===========================================================================

/-- Pointwise collapse helper: `(A+B)(t) ≈ v` from component values. -/
private theorem val_add {u w v : Q} {a b : Real}
    (hud : 0 < u.den) (hwd : 0 < w.den) (hvd : 0 < v.den)
    (ha : Req a (ofQ u hud)) (hb : Req b (ofQ w hwd)) (hq : Qeq (add u w) v) :
    Req (Radd a b) (ofQ v hvd) :=
  Req_trans (Radd_congr ha hb)
    (Req_trans (Radd_ofQ_ofQ hud hwd) (Req_of_seq_Qeq (fun _ => hq)))

/-- **The deep bump is `[0,1]`-supported**: `p(1) = 1 − 6 + 10 − 5 = 0`, so the saturated
    clamp kills the value at every window point. -/
theorem deepBump_supp : UnitSupported deepBump := by
  intro m x h0 h1
  have hsat := clamp01_sat (affine_window_ge_one m h0)
  have h2 : Req (sqT.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) one :=
    Req_trans (Rmul_congr hsat hsat) (Rmul_one one)
  have h3 : Req (cubeT.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) one :=
    Req_trans (Rmul_congr h2 hsat) (Rmul_one one)
  have h4 : Req (quadT.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) one :=
    Req_trans (Rmul_congr h3 hsat) (Rmul_one one)
  have hd2 : Req (d2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h3 h3 (by decide)
  have hd4 : Req (Radd (d2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (d2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))) (ofQ (⟨4, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hd2 hd2 (by decide)
  have hd6 : Req (Radd (d2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (Radd (d2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q)
      (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)) (d2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q)
      (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))) (ofQ (⟨6, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hd2 hd4 (by decide)
  have hd8 : Req (Radd (d2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (Radd (d2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q)
      (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)) (Radd (d2T.f (affineMap
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
      (d2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))))
      (ofQ (⟨8, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hd2 hd6 (by decide)
  have hc10 : Req (c10T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨10, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hd2 hd8 (by decide)
  have hs2 : Req (s2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h2 h2 (by decide)
  have hs4 : Req (Radd (s2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (s2T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))) (ofQ (⟨4, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hs2 hs2 (by decide)
  have hs6 : Req (s6T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨6, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hs2 hs4 (by decide)
  have hq2 : Req (Radd (quadT.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (quadT.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))) (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h4 h4 (by decide)
  have hq3 : Req (Radd (quadT.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (Radd (quadT.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q)
      (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)) (quadT.f (affineMap
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))))
      (ofQ (⟨3, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h4 hq2 (by decide)
  have hq4 : Req (Radd (quadT.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (Radd (quadT.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q)
      (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)) (Radd (quadT.f (affineMap
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))
      (quadT.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide)
      x))))) (ofQ (⟨4, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h4 hq3 (by decide)
  have hq5 : Req (q5T.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨5, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h4 hq4 (by decide)
  have hL : Req ((L2Test.add clampTest c10T).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q)
      (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)) (ofQ (⟨11, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hsat hc10 (by decide)
  have hSQ : Req ((L2Test.add s6T q5T).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨11, 1⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hs6 hq5 (by decide)
  have hN : Req ((L2Test.neg (L2Test.add s6T q5T)).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q)
      (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)) (ofQ (neg (⟨11, 1⟩ : Q)) (by decide)) :=
    Req_trans (Rneg_congr hSQ) (Rneg_ofQ (⟨11, 1⟩ : Q) (by decide))
  refine Req_trans (Radd_congr hL hN) ?_
  refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (add (⟨11, 1⟩ : Q) (neg (⟨11, 1⟩ : Q))) (⟨0, 1⟩ : Q)
    decide)

/-- **The member is not the zero function**: `deepBump(1/10) ≈ 99/2000`
    (`p(1/10) = (1000 − 600 + 100 − 5)/10000`). -/
theorem deepBump_value_tenth :
    Req (deepBump.f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ (⟨99, 2000⟩ : Q) (by decide)) := by
  have hc : Req (clamp01 (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ (⟨1, 10⟩ : Q) (by decide)) :=
    clamp01_ofQ (by decide) (by decide) (by decide)
  have h2 : Req (sqT.f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ (⟨1, 100⟩ : Q) (by decide)) :=
    Req_trans (Rmul_congr hc hc)
      (Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (Req_of_seq_Qeq (fun _ => by
        show Qeq (mul (⟨1, 10⟩ : Q) (⟨1, 10⟩ : Q)) (⟨1, 100⟩ : Q); decide)))
  have h3 : Req (cubeT.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨1, 1000⟩ : Q) (by decide)) :=
    Req_trans (Rmul_congr h2 hc)
      (Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (Req_of_seq_Qeq (fun _ => by
        show Qeq (mul (⟨1, 100⟩ : Q) (⟨1, 10⟩ : Q)) (⟨1, 1000⟩ : Q); decide)))
  have h4 : Req (quadT.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨1, 10000⟩ : Q) (by decide)) :=
    Req_trans (Rmul_congr h3 hc)
      (Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (Req_of_seq_Qeq (fun _ => by
        show Qeq (mul (⟨1, 1000⟩ : Q) (⟨1, 10⟩ : Q)) (⟨1, 10000⟩ : Q); decide)))
  have hd2 : Req (d2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨2, 1000⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h3 h3 (by decide)
  have hd4 : Req (Radd (d2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (d2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))) (ofQ (⟨4, 1000⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hd2 hd2 (by decide)
  have hd6 : Req (Radd (d2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (Radd (d2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
        (d2T.f (ofQ (⟨1, 10⟩ : Q) (by decide))))) (ofQ (⟨6, 1000⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hd2 hd4 (by decide)
  have hd8 : Req (Radd (d2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (Radd (d2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
        (Radd (d2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
          (d2T.f (ofQ (⟨1, 10⟩ : Q) (by decide))))))
      (ofQ (⟨8, 1000⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hd2 hd6 (by decide)
  have hc10 : Req (c10T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨10, 1000⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hd2 hd8 (by decide)
  have hs2 : Req (s2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨2, 100⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h2 h2 (by decide)
  have hs4 : Req (Radd (s2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (s2T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))) (ofQ (⟨4, 100⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hs2 hs2 (by decide)
  have hs6 : Req (s6T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨6, 100⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hs2 hs4 (by decide)
  have hq2 : Req (Radd (quadT.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (quadT.f (ofQ (⟨1, 10⟩ : Q) (by decide)))) (ofQ (⟨2, 10000⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h4 h4 (by decide)
  have hq3 : Req (Radd (quadT.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (Radd (quadT.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
        (quadT.f (ofQ (⟨1, 10⟩ : Q) (by decide))))) (ofQ (⟨3, 10000⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h4 hq2 (by decide)
  have hq4 : Req (Radd (quadT.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (Radd (quadT.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
        (Radd (quadT.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
          (quadT.f (ofQ (⟨1, 10⟩ : Q) (by decide))))))
      (ofQ (⟨4, 10000⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h4 hq3 (by decide)
  have hq5 : Req (q5T.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨5, 10000⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) h4 hq4 (by decide)
  have hL : Req ((L2Test.add clampTest c10T).f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨11, 100⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hc hc10 (by decide)
  have hSQ : Req ((L2Test.add s6T q5T).f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨605, 10000⟩ : Q) (by decide)) :=
    val_add (by decide) (by decide) (by decide) hs6 hq5 (by decide)
  have hN : Req ((L2Test.neg (L2Test.add s6T q5T)).f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (neg (⟨605, 10000⟩ : Q)) (by decide)) :=
    Req_trans (Rneg_congr hSQ) (Rneg_ofQ (⟨605, 10000⟩ : Q) (by decide))
  refine Req_trans (Radd_congr hL hN) ?_
  refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (add (⟨11, 100⟩ : Q) (neg (⟨605, 10000⟩ : Q))) (⟨99, 2000⟩ : Q)
    decide)

/-- **Apartness**: `Pos (deepBump(1/10))` — the `K = 2` member is strictly apart from the
    zero function at a witnessed point. -/
theorem deepBump_apart : Pos (deepBump.f (ofQ (⟨1, 10⟩ : Q) (by decide))) :=
  Pos_congr (Req_symm deepBump_value_tenth) ⟨21, by decide⟩

-- ===========================================================================
-- Membership at K = 2 and the capstone.
-- ===========================================================================

/-- **THE NONZERO `K = 2` CO-SUPPORT MEMBER**: the deep bump's transform vanishes at both
    integer points `0` and `1`. -/
theorem deepBump_hatVanishes :
    HatVanishes deepBump 2 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp deepBump deepBump_supp) :=
  hatVanishes_of_moments deepBump 2 deepBump_supp (fun n hn => by
    match n with
    | 0 => exact deepBump_moment_zero
    | 1 => exact deepBump_moment_one
    | (k + 2) => exact absurd hn (by omega))

/-- **THE CAPSTONE**: the skeleton's unconditional complement-positivity fires on the moment
    sequence of a certified NONZERO test whose constructed transform vanishes on the band —
    genuinely nonzero `f, f̂` data in the Sonine complement. No RH. -/
theorem weil_psd_nonzero_instance (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult) (momSeq deepBump) N) :=
  weil_psd_on_cosupport deepBump deepBump_supp deepBump_hatVanishes N

end Multiplicity.UOR.Bridge.F1Square.Square
