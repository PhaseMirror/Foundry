/-
F1 square — **the pre-Hilbert layer, brick 18** (`MellinDecay.lean`): **THE MELLIN FRONT
OPENED — the decaying test class and its certified half-line integral `∫₀^∞ φ`.**

The half-line gateway (`halfLineIntegral`) demands per-window decay data: two-sided bounds
`|∫_{m+1}^{m+2} f| ≤ K/((m+1)m)`. This brick supplies the missing bridge from POINTWISE decay
to that window data, and packages the class:

- `riemannIntegralI_abs_le_window` — the window bound: an integrand bounded by `B` on the
  affine image of `[0,1]` has `|∫_a^{a+w} f| ≤ w·B` (window-local comparison against the
  constant, whose integral evaluates through certificate independence).
- `MellinTest` — a bounded-Lipschitz test (`L2Test`) bundled with pointwise quadratic decay:
  `|f| ≤ C/(m+1)²` on every window `[m+1, m+2]`.
- `mellinTerm_bound` — the derived gateway data: the window integrals of a `MellinTest` obey
  the required `C/((m+1)m)` two-sided bounds (`(m+1)m ≤ (m+1)²` weakening).
- **`mellinIntegral φ = ∫₀^∞ φ`** — the certified full Mellin-domain integral of every
  decaying test: a constructed real (compact gateway piece plus convergent half-line tail),
  with `mellinIntegral_nonneg` for pointwise-nonnegative tests.

WHY (the Sonine route, step 3). The genuine `f, f̂` objects live over the Mellin domain
`(0,∞)`, and the layer's remaining lack "the genuine Mellin transform over the half-line"
starts exactly here: the class of tests whose half-line integrals EXIST as constructed reals.
The transform itself (the `t^{s−1}` twist) is the banked next brick — its integrand is a
product of a `MellinTest` with the power kernel, and products stay in reach of the same
window machinery.

HONEST SCOPE. The half-line integral of decaying tests; NOT the Mellin transform (no `t^{s−1}`
twist yet, no transform pair, no inversion). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.ImproperIntegral
import Multiplicity.F1Square.Analysis.IntegralLocal
import Multiplicity.F1Square.Analysis.IntegralBilinear

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The window bound: pointwise bound on the window ⟹ `|∫| ≤ w·B`.
-- ===========================================================================

/-- The zero modulus is below every admissible modulus. -/
private theorem qle_zero_L {L : Q} (hLn : 0 ≤ L.num) : Qle (⟨0, 1⟩ : Q) L := by
  show (0 : Int) * (L.den : Int) ≤ L.num * 1
  rw [Int.zero_mul, Int.mul_one]
  exact hLn

/-- **The window bound**: an integrand bounded by `B` on the affine image of `[0,1]` (i.e. on
    `[a, a+w]`) has `|∫_a^{a+w} f| ≤ w·B` — window-local comparison against the constants
    `±B`, whose interval integrals evaluate through certificate independence. -/
theorem riemannIntegralI_abs_le_window {f : Real → Real} {L : Q} (hLd : 0 < L.den)
    (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (a w B : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) (hBd : 0 < B.den)
    (hbd : ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (f (affineMap a w ha hw x))) (ofQ B hBd)) :
    Rle (Rabs (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn))
        (ofQ (mul w B) (Qmul_den_pos hw hBd)) := by
  -- the constant integrands at the shared modulus `L`
  have hlipB := lip_weaken (L := (⟨0, 1⟩ : Q)) (by decide) hLd (qle_zero_L hLn)
    (const_lip0 (ofQ B hBd))
  have hlipnB := lip_weaken (L := (⟨0, 1⟩ : Q)) (by decide) hLd (qle_zero_L hLn)
    (const_lip0 (Rneg (ofQ B hBd)))
  -- the constant interval integrals evaluate: `∫I c ≈ w·c` (certificate independence inside)
  have hconst : ∀ (c : Real) (hlipc : ∀ x y, Rle (Rabs (Rsub c c))
        (Rmul (ofQ L hLd) (Rabs (Rsub x y)))),
      Req (riemannIntegralI (f := fun _ => c) hLd hLn hlipc (fun _ _ _ => Req_refl c)
            a w ha hw hwn)
          (Rmul (ofQ w hw) c) := by
    intro c hlipc
    refine Req_trans (Rmul_congr (Req_refl _) (riemannIntegral_certif_irrel
      (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn) _ _
      (Qmul_den_pos (by decide : 0 < (⟨0, 1⟩ : Q).den) hw)
      (Int.mul_nonneg (by show (0 : Int) ≤ 0; decide) hwn)
      (affine_lip (by decide) (by show (0 : Int) ≤ 0; decide) (const_lip0 c) a w ha hw hwn)
      (fun x y h => Req_refl c))) ?_
    exact riemannIntegralI_const c a w ha hw hwn
  refine Rabs_le_of_both ?_ ?_
  · -- upper: `∫I f ≤ ∫I B = w·B`
    refine Rle_trans (riemannIntegralI_le_unit hLd hLn hlip hfc hlipB
      (fun _ _ _ => Req_refl _) a w ha hw hwn
      (fun x h0 h1 => Rle_trans (Rle_Rabs_self _) (hbd x h0 h1))) ?_
    refine Rle_trans (Rle_of_Req (hconst (ofQ B hBd) hlipB)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ hw hBd)
  · -- lower: `−(w·B) ≤ ∫I f`, flipped
    have hlo : Rle (riemannIntegralI (f := fun _ => Rneg (ofQ B hBd)) hLd hLn hlipnB
        (fun _ _ _ => Req_refl _) a w ha hw hwn)
        (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn) :=
      riemannIntegralI_le_unit hLd hLn hlipnB (fun _ _ _ => Req_refl _) hlip hfc
        a w ha hw hwn (fun x h0 h1 => Rneg_le_of_Rabs_le (hbd x h0 h1))
    have hval : Req (riemannIntegralI (f := fun _ => Rneg (ofQ B hBd)) hLd hLn hlipnB
        (fun _ _ _ => Req_refl _) a w ha hw hwn)
        (Rneg (ofQ (mul w B) (Qmul_den_pos hw hBd))) :=
      Req_trans (hconst (Rneg (ofQ B hBd)) hlipnB)
        (Req_trans (Rmul_neg_right (ofQ w hw) (ofQ B hBd))
          (Rneg_congr (Rmul_ofQ_ofQ hw hBd)))
    have h2 : Rle (Rneg (ofQ (mul w B) (Qmul_den_pos hw hBd)))
        (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn) :=
      Rle_trans (Rle_of_Req (Req_symm hval)) hlo
    refine Rle_trans (Rle_Rneg h2) (Rle_of_Req (Rneg_neg _))

-- ===========================================================================
-- The decaying test class and its half-line integral.
-- ===========================================================================

/-- A **Mellin test**: a bounded-Lipschitz test with pointwise quadratic decay
    `|f| ≤ C/(m+1)²` on every window `[m+1, m+2]` — exactly the data the half-line gateway
    converts to convergence. -/
structure MellinTest extends L2Test where
  C : Q
  hCd : 0 < C.den
  hCn : 0 ≤ C.num
  hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
    Rle (Rabs (f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
          Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) * (m + 1)⟩ : Q))
          (Qmul_den_pos hCd (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m))))

/-- **The derived gateway data**: the window integrals of a Mellin test obey the required
    `C/((m+1)m)` two-sided bounds. -/
theorem mellinTerm_bound (φ : MellinTest) : ∀ m, ∀ hm : 1 ≤ m,
    Rle (Rneg (ofQ (mul φ.C (⟨1, (m + 1) * m⟩ : Q))
          (Qmul_den_pos φ.hCd (digamma_succ_mul_pos hm))))
        (integralTerm φ.hLd φ.hLn φ.hlip φ.hfc m)
    ∧ Rle (integralTerm φ.hLd φ.hLn φ.hlip φ.hfc m)
        (ofQ (mul φ.C (⟨1, (m + 1) * m⟩ : Q))
          (Qmul_den_pos φ.hCd (digamma_succ_mul_pos hm))) := by
  intro m hm
  have habs : Rle (Rabs (integralTerm φ.hLd φ.hLn φ.hlip φ.hfc m))
      (ofQ (mul (⟨1, 1⟩ : Q) (mul φ.C (⟨1, (m + 1) * (m + 1)⟩ : Q)))
        (Qmul_den_pos (by decide)
          (Qmul_den_pos φ.hCd (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m))))) :=
    riemannIntegralI_abs_le_window φ.hLd φ.hLn φ.hlip φ.hfc
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      (mul φ.C (⟨1, (m + 1) * (m + 1)⟩ : Q)) Nat.one_pos (by decide) (by decide)
      (Qmul_den_pos φ.hCd (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m)))
      (φ.hdec m)
  have hq : Qle (mul (⟨1, 1⟩ : Q) (mul φ.C (⟨1, (m + 1) * (m + 1)⟩ : Q)))
      (mul φ.C (⟨1, (m + 1) * m⟩ : Q)) :=
    Qle_congr_left (a := mul φ.C (⟨1, (m + 1) * (m + 1)⟩ : Q))
      (Qmul_den_pos φ.hCd (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m)))
      (by simp only [Qeq, mul]; push_cast; ring_uor)
      (qmul_den_anti φ.hCn (Nat.mul_le_mul_left (m + 1) (Nat.le_succ m)))
  have habs' : Rle (Rabs (integralTerm φ.hLd φ.hLn φ.hlip φ.hfc m))
      (ofQ (mul φ.C (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos φ.hCd (digamma_succ_mul_pos hm))) :=
    Rle_trans habs (Rle_ofQ_ofQ _ _ hq)
  exact ⟨Rneg_le_of_Rabs_le habs', Rle_of_Rabs_le habs'⟩

/-- **THE CERTIFIED MELLIN-DOMAIN INTEGRAL** `∫₀^∞ φ` of a decaying test — the compact gateway
    piece plus the convergent half-line tail, a constructed real. -/
def mellinIntegral (φ : MellinTest) : Real :=
  halfLineIntegral φ.hLd φ.hLn φ.hlip φ.hfc φ.hCd φ.hCn (mellinTerm_bound φ)

/-- `∫₀^∞ φ ≥ 0` for a pointwise-nonnegative test. -/
theorem mellinIntegral_nonneg (φ : MellinTest) (hnn : ∀ x, Rnonneg (φ.f x)) :
    Rnonneg (mellinIntegral φ) :=
  halfLineIntegral_nonneg φ.hLd φ.hLn φ.hlip φ.hfc φ.hCd φ.hCn (mellinTerm_bound φ) hnn

end Multiplicity.UOR.Bridge.F1Square.Analysis
