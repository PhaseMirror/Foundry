/-
F1 square — certified integration over the constructive **Complex** API (Track-2 step 1): the
complex line integral of `gr + i·gi` over a bounded real interval `[a, a+w]`, built componentwise
from the real interval integral.

`∫_a^{a+w} (gr + i·gi) dt = ⟨∫_a^{a+w} gr, ∫_a^{a+w} gi⟩` — each component a certified real integral
(`riemannIntegralI`). This is the form the Mellin integrand `t^{s/2−1}ψ(t)` (item 3) and the
complex-valued Weil test integrals (Track 2) inhabit; the deep content (improper half-line, the
Poisson/modular seam, positivity) is downstream and unchanged.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.IntervalIntegral
import Core.F1.Analysis.ImproperIntegral
import Core.F1.Analysis.Complex

namespace UOR.Bridge.F1Square.Analysis

/-- **The complex line integral** `∫_a^{a+w} (gr + i·gi) dt` over `[a, a+w]` (`w ≥ 0`), assembled
    from the two real component integrals. Each component integrand is given with its own Lipschitz
    modulus (`Lr`, `Li`). -/
def Cintegral {gr gi : Real → Real} {Lr Li : Q}
    (hLrd : 0 < Lr.den) (hLrn : 0 ≤ Lr.num)
    (hlipr : ∀ x y, Rle (Rabs (Rsub (gr x) (gr y))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr : ∀ x y, Req x y → Req (gr x) (gr y))
    (hLid : 0 < Li.den) (hLin : 0 ≤ Li.num)
    (hlipi : ∀ x y, Rle (Rabs (Rsub (gi x) (gi y))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci : ∀ x y, Req x y → Req (gi x) (gi y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) : Complex :=
  ⟨riemannIntegralI hLrd hLrn hlipr hfcr a w ha hw hwn,
   riemannIntegralI hLid hLin hlipi hfci a w ha hw hwn⟩

/-- **`∫_a^{a+w} z = w·z`** for a complex constant `z` (componentwise `riemannIntegralI_const`). -/
theorem Cintegral_const (zr zi : Real) (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Ceq (Cintegral (gr := fun _ => zr) (gi := fun _ => zi) (Lr := (⟨0, 1⟩ : Q)) (Li := (⟨0, 1⟩ : Q))
          (by decide) (by decide) (const_lip0 zr) (fun _ _ _ => Req_refl zr)
          (by decide) (by decide) (const_lip0 zi) (fun _ _ _ => Req_refl zi) a w ha hw hwn)
        ⟨Rmul (ofQ w hw) zr, Rmul (ofQ w hw) zi⟩ :=
  ⟨Rmul_congr (Req_refl _) (riemannIntegral_const_gen zr _ _ _ _),
   Rmul_congr (Req_refl _) (riemannIntegral_const_gen zi _ _ _ _)⟩

/-- **The complex half-line integral** `∫₀^∞ (gr + i·gi) dt` — the full Mellin domain for a
    complex-valued integrand, assembled componentwise from the real `halfLineIntegral`. Each component
    carries its own Lipschitz modulus and summable-decay seam (the genuine convergence content). This
    is the object the Mellin transform of the theta relation (item 3) and the windowed Weil pairing
    (Track 2) inhabit. -/
def ChalfLineIntegral {gr gi : Real → Real} {Lr Li Kr Ki : Q}
    (hLrd : 0 < Lr.den) (hLrn : 0 ≤ Lr.num)
    (hlipr : ∀ x y, Rle (Rabs (Rsub (gr x) (gr y))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr : ∀ x y, Req x y → Req (gr x) (gr y)) (hKrd : 0 < Kr.den) (hKr0 : 0 ≤ Kr.num)
    (hbr : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
          (integralTerm hLrd hLrn hlipr hfcr m)
      ∧ Rle (integralTerm hLrd hLrn hlipr hfcr m)
          (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
    (hLid : 0 < Li.den) (hLin : 0 ≤ Li.num)
    (hlipi : ∀ x y, Rle (Rabs (Rsub (gi x) (gi y))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci : ∀ x y, Req x y → Req (gi x) (gi y)) (hKid : 0 < Ki.den) (hKi0 : 0 ≤ Ki.num)
    (hbi : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
          (integralTerm hLid hLin hlipi hfci m)
      ∧ Rle (integralTerm hLid hLin hlipi hfci m)
          (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm)))) :
    Complex :=
  ⟨halfLineIntegral hLrd hLrn hlipr hfcr hKrd hKr0 hbr,
   halfLineIntegral hLid hLin hlipi hfci hKid hKi0 hbi⟩

/-- **The complex half-line integral is additive in the integrand**
    `∫₀^∞ ((gfr+ggr) + i·(gfi+ggi)) = ∫₀^∞ (gfr + i·gfi) + ∫₀^∞ (ggr + i·ggi)` — the additive half of
    linearity for the constructive complex Mellin integral, the object the Weil pairing and the
    Mellin transform of the theta relation inhabit. Componentwise from the real `halfLineIntegral_add`
    (real and imaginary parts, each at its own shared Lipschitz constant `Lr`/`Li` and decay rate
    `Kr`/`Ki`). -/
theorem ChalfLineIntegral_add {gfr ggr gfi ggi : Real → Real} {Lr Li Kr Ki : Q}
    (hLrd : 0 < Lr.den) (hLrn : 0 ≤ Lr.num)
    (hlipr_f : ∀ x y, Rle (Rabs (Rsub (gfr x) (gfr y))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr_f : ∀ x y, Req x y → Req (gfr x) (gfr y))
    (hlipr_g : ∀ x y, Rle (Rabs (Rsub (ggr x) (ggr y))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr_g : ∀ x y, Req x y → Req (ggr x) (ggr y))
    (hlipr_fg : ∀ x y, Rle (Rabs (Rsub (Radd (gfr x) (ggr x)) (Radd (gfr y) (ggr y))))
        (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr_fg : ∀ x y, Req x y → Req (Radd (gfr x) (ggr x)) (Radd (gfr y) (ggr y)))
    (hKrd : 0 < Kr.den) (hKr0 : 0 ≤ Kr.num)
    (hbr_f : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
          (integralTerm hLrd hLrn hlipr_f hfcr_f m)
      ∧ Rle (integralTerm hLrd hLrn hlipr_f hfcr_f m)
          (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
    (hbr_g : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
          (integralTerm hLrd hLrn hlipr_g hfcr_g m)
      ∧ Rle (integralTerm hLrd hLrn hlipr_g hfcr_g m)
          (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
    (hbr_fg : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
          (integralTerm hLrd hLrn hlipr_fg hfcr_fg m)
      ∧ Rle (integralTerm hLrd hLrn hlipr_fg hfcr_fg m)
          (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
    (hLid : 0 < Li.den) (hLin : 0 ≤ Li.num)
    (hlipi_f : ∀ x y, Rle (Rabs (Rsub (gfi x) (gfi y))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci_f : ∀ x y, Req x y → Req (gfi x) (gfi y))
    (hlipi_g : ∀ x y, Rle (Rabs (Rsub (ggi x) (ggi y))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci_g : ∀ x y, Req x y → Req (ggi x) (ggi y))
    (hlipi_fg : ∀ x y, Rle (Rabs (Rsub (Radd (gfi x) (ggi x)) (Radd (gfi y) (ggi y))))
        (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci_fg : ∀ x y, Req x y → Req (Radd (gfi x) (ggi x)) (Radd (gfi y) (ggi y)))
    (hKid : 0 < Ki.den) (hKi0 : 0 ≤ Ki.num)
    (hbi_f : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
          (integralTerm hLid hLin hlipi_f hfci_f m)
      ∧ Rle (integralTerm hLid hLin hlipi_f hfci_f m)
          (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
    (hbi_g : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
          (integralTerm hLid hLin hlipi_g hfci_g m)
      ∧ Rle (integralTerm hLid hLin hlipi_g hfci_g m)
          (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
    (hbi_fg : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
          (integralTerm hLid hLin hlipi_fg hfci_fg m)
      ∧ Rle (integralTerm hLid hLin hlipi_fg hfci_fg m)
          (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm)))) :
    Ceq (ChalfLineIntegral hLrd hLrn hlipr_fg hfcr_fg hKrd hKr0 hbr_fg
            hLid hLin hlipi_fg hfci_fg hKid hKi0 hbi_fg)
        (Cadd (ChalfLineIntegral hLrd hLrn hlipr_f hfcr_f hKrd hKr0 hbr_f
                  hLid hLin hlipi_f hfci_f hKid hKi0 hbi_f)
              (ChalfLineIntegral hLrd hLrn hlipr_g hfcr_g hKrd hKr0 hbr_g
                  hLid hLin hlipi_g hfci_g hKid hKi0 hbi_g)) :=
  ⟨halfLineIntegral_add hLrd hLrn hlipr_f hfcr_f hlipr_g hfcr_g hlipr_fg hfcr_fg
      hKrd hKr0 hbr_f hbr_g hbr_fg,
   halfLineIntegral_add hLid hLin hlipi_f hfci_f hlipi_g hfci_g hlipi_fg hfci_fg
      hKid hKi0 hbi_f hbi_g hbi_fg⟩

/-- **The complex Mellin integral respects negation** `∫₀^∞ (−(gr + i·gi)) = −∫₀^∞ (gr + i·gi)` —
    completing (with `ChalfLineIntegral_add`) the additive-group linearity of the complex Mellin
    integral. Componentwise from the real `halfLineIntegral_neg`. -/
theorem ChalfLineIntegral_neg {gr gi : Real → Real} {Lr Li Kr Ki : Q}
    (hLrd : 0 < Lr.den) (hLrn : 0 ≤ Lr.num)
    (hlipr : ∀ x y, Rle (Rabs (Rsub (gr x) (gr y))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr : ∀ x y, Req x y → Req (gr x) (gr y))
    (hlipnr : ∀ x y, Rle (Rabs (Rsub (Rneg (gr x)) (Rneg (gr y)))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcnr : ∀ x y, Req x y → Req (Rneg (gr x)) (Rneg (gr y)))
    (hKrd : 0 < Kr.den) (hKr0 : 0 ≤ Kr.num)
    (hbr : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
          (integralTerm hLrd hLrn hlipr hfcr m)
      ∧ Rle (integralTerm hLrd hLrn hlipr hfcr m)
          (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
    (hbnr : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
          (integralTerm hLrd hLrn hlipnr hfcnr m)
      ∧ Rle (integralTerm hLrd hLrn hlipnr hfcnr m)
          (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
    (hLid : 0 < Li.den) (hLin : 0 ≤ Li.num)
    (hlipi : ∀ x y, Rle (Rabs (Rsub (gi x) (gi y))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci : ∀ x y, Req x y → Req (gi x) (gi y))
    (hlipni : ∀ x y, Rle (Rabs (Rsub (Rneg (gi x)) (Rneg (gi y)))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfcni : ∀ x y, Req x y → Req (Rneg (gi x)) (Rneg (gi y)))
    (hKid : 0 < Ki.den) (hKi0 : 0 ≤ Ki.num)
    (hbi : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
          (integralTerm hLid hLin hlipi hfci m)
      ∧ Rle (integralTerm hLid hLin hlipi hfci m)
          (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
    (hbni : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
          (integralTerm hLid hLin hlipni hfcni m)
      ∧ Rle (integralTerm hLid hLin hlipni hfcni m)
          (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm)))) :
    Ceq (ChalfLineIntegral hLrd hLrn hlipnr hfcnr hKrd hKr0 hbnr
            hLid hLin hlipni hfcni hKid hKi0 hbni)
        (Cneg (ChalfLineIntegral hLrd hLrn hlipr hfcr hKrd hKr0 hbr
                  hLid hLin hlipi hfci hKid hKi0 hbi)) :=
  ⟨halfLineIntegral_neg hLrd hLrn hlipr hfcr hlipnr hfcnr hKrd hKr0 hbr hbnr,
   halfLineIntegral_neg hLid hLin hlipi hfci hlipni hfcni hKid hKi0 hbi hbni⟩

/-- **The complex Mellin integral respects a constant real-rational scalar**
    `∫₀^∞ (q·(gr + i·gi)) = q·∫₀^∞ (gr + i·gi)` for `q : ℚ` — completing (with `ChalfLineIntegral_add`
    and `_neg`) the **real-rational-linear-functional** structure of the constructive complex Mellin
    integral, the form the Weil pairing's real test coefficients act through. Componentwise from the
    real `halfLineIntegral_smul`; the result is the explicit complex pair `⟨q·∫gr, q·∫gi⟩` (a *real*
    scalar multiple — the re/im-mixing complex `Cmul` scalar is a separate, downstream concern). -/
theorem ChalfLineIntegral_smul {gr gi : Real → Real} {Lr Li Kr Ki : Q} (q : Q) (hq : 0 < q.den)
    (hLrd : 0 < Lr.den) (hLrn : 0 ≤ Lr.num)
    (hlipr : ∀ x y, Rle (Rabs (Rsub (gr x) (gr y))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr : ∀ x y, Req x y → Req (gr x) (gr y))
    (hlipqr : ∀ x y, Rle (Rabs (Rsub (Rmul (ofQ q hq) (gr x)) (Rmul (ofQ q hq) (gr y))))
        (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcqr : ∀ x y, Req x y → Req (Rmul (ofQ q hq) (gr x)) (Rmul (ofQ q hq) (gr y)))
    (hKrd : 0 < Kr.den) (hKr0 : 0 ≤ Kr.num)
    (hbr : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
          (integralTerm hLrd hLrn hlipr hfcr m)
      ∧ Rle (integralTerm hLrd hLrn hlipr hfcr m)
          (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
    (hbqr : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
          (integralTerm hLrd hLrn hlipqr hfcqr m)
      ∧ Rle (integralTerm hLrd hLrn hlipqr hfcqr m)
          (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
    (hLid : 0 < Li.den) (hLin : 0 ≤ Li.num)
    (hlipi : ∀ x y, Rle (Rabs (Rsub (gi x) (gi y))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci : ∀ x y, Req x y → Req (gi x) (gi y))
    (hlipqi : ∀ x y, Rle (Rabs (Rsub (Rmul (ofQ q hq) (gi x)) (Rmul (ofQ q hq) (gi y))))
        (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfcqi : ∀ x y, Req x y → Req (Rmul (ofQ q hq) (gi x)) (Rmul (ofQ q hq) (gi y)))
    (hKid : 0 < Ki.den) (hKi0 : 0 ≤ Ki.num)
    (hbi : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
          (integralTerm hLid hLin hlipi hfci m)
      ∧ Rle (integralTerm hLid hLin hlipi hfci m)
          (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
    (hbqi : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
          (integralTerm hLid hLin hlipqi hfcqi m)
      ∧ Rle (integralTerm hLid hLin hlipqi hfcqi m)
          (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm)))) :
    Ceq (ChalfLineIntegral hLrd hLrn hlipqr hfcqr hKrd hKr0 hbqr
            hLid hLin hlipqi hfcqi hKid hKi0 hbqi)
        ⟨Rmul (ofQ q hq) (halfLineIntegral hLrd hLrn hlipr hfcr hKrd hKr0 hbr),
         Rmul (ofQ q hq) (halfLineIntegral hLid hLin hlipi hfci hKid hKi0 hbi)⟩ :=
  ⟨halfLineIntegral_smul q hq hLrd hLrn hlipr hfcr hlipqr hfcqr hKrd hKr0 hbr hbqr,
   halfLineIntegral_smul q hq hLid hLin hlipi hfci hlipqi hfcqi hKid hKi0 hbi hbqi⟩

/-- **The complex line integral respects `≈` of the integrand** (componentwise from
    `riemannIntegralI_congr`) — `∫_a^{a+w} z ≈ ∫_a^{a+w} z'` when the real and imaginary parts agree
    pointwise. -/
theorem Cintegral_congr {gr gi gr' gi' : Real → Real} {Lr Li : Q}
    (hLrd : 0 < Lr.den) (hLrn : 0 ≤ Lr.num)
    (hlipr : ∀ x y, Rle (Rabs (Rsub (gr x) (gr y))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr : ∀ x y, Req x y → Req (gr x) (gr y))
    (hlipr' : ∀ x y, Rle (Rabs (Rsub (gr' x) (gr' y))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr' : ∀ x y, Req x y → Req (gr' x) (gr' y))
    (hLid : 0 < Li.den) (hLin : 0 ≤ Li.num)
    (hlipi : ∀ x y, Rle (Rabs (Rsub (gi x) (gi y))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci : ∀ x y, Req x y → Req (gi x) (gi y))
    (hlipi' : ∀ x y, Rle (Rabs (Rsub (gi' x) (gi' y))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci' : ∀ x y, Req x y → Req (gi' x) (gi' y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hr : ∀ x, Req (gr x) (gr' x)) (hi : ∀ x, Req (gi x) (gi' x)) :
    Ceq (Cintegral hLrd hLrn hlipr hfcr hLid hLin hlipi hfci a w ha hw hwn)
        (Cintegral hLrd hLrn hlipr' hfcr' hLid hLin hlipi' hfci' a w ha hw hwn) :=
  ⟨riemannIntegralI_congr hLrd hLrn hlipr hfcr hlipr' hfcr' a w ha hw hwn hr,
   riemannIntegralI_congr hLid hLin hlipi hfci hlipi' hfci' a w ha hw hwn hi⟩

/-- **The complex Mellin integral respects `≈` of the integrand** (componentwise from
    `halfLineIntegral_congr`) — the integrand-congruence the Weil/theta complex-integrand rewrites
    need. -/
theorem ChalfLineIntegral_congr {gr gi gr' gi' : Real → Real} {Lr Li Kr Ki : Q}
    (hLrd : 0 < Lr.den) (hLrn : 0 ≤ Lr.num)
    (hlipr : ∀ x y, Rle (Rabs (Rsub (gr x) (gr y))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr : ∀ x y, Req x y → Req (gr x) (gr y))
    (hlipr' : ∀ x y, Rle (Rabs (Rsub (gr' x) (gr' y))) (Rmul (ofQ Lr hLrd) (Rabs (Rsub x y))))
    (hfcr' : ∀ x y, Req x y → Req (gr' x) (gr' y))
    (hKrd : 0 < Kr.den) (hKr0 : 0 ≤ Kr.num)
    (hbr : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
          (integralTerm hLrd hLrn hlipr hfcr m)
      ∧ Rle (integralTerm hLrd hLrn hlipr hfcr m)
          (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
    (hbr' : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
          (integralTerm hLrd hLrn hlipr' hfcr' m)
      ∧ Rle (integralTerm hLrd hLrn hlipr' hfcr' m)
          (ofQ (mul Kr (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKrd (digamma_succ_mul_pos hm))))
    (hLid : 0 < Li.den) (hLin : 0 ≤ Li.num)
    (hlipi : ∀ x y, Rle (Rabs (Rsub (gi x) (gi y))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci : ∀ x y, Req x y → Req (gi x) (gi y))
    (hlipi' : ∀ x y, Rle (Rabs (Rsub (gi' x) (gi' y))) (Rmul (ofQ Li hLid) (Rabs (Rsub x y))))
    (hfci' : ∀ x y, Req x y → Req (gi' x) (gi' y))
    (hKid : 0 < Ki.den) (hKi0 : 0 ≤ Ki.num)
    (hbi : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
          (integralTerm hLid hLin hlipi hfci m)
      ∧ Rle (integralTerm hLid hLin hlipi hfci m)
          (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
    (hbi' : ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
          (integralTerm hLid hLin hlipi' hfci' m)
      ∧ Rle (integralTerm hLid hLin hlipi' hfci' m)
          (ofQ (mul Ki (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKid (digamma_succ_mul_pos hm))))
    (hr : ∀ x, Req (gr x) (gr' x)) (hi : ∀ x, Req (gi x) (gi' x)) :
    Ceq (ChalfLineIntegral hLrd hLrn hlipr hfcr hKrd hKr0 hbr hLid hLin hlipi hfci hKid hKi0 hbi)
        (ChalfLineIntegral hLrd hLrn hlipr' hfcr' hKrd hKr0 hbr' hLid hLin hlipi' hfci' hKid hKi0 hbi') :=
  ⟨halfLineIntegral_congr hLrd hLrn hlipr hfcr hlipr' hfcr' hKrd hKr0 hbr hbr' hr,
   halfLineIntegral_congr hLid hLin hlipi hfci hlipi' hfci' hKid hKi0 hbi hbi' hi⟩

end UOR.Bridge.F1Square.Analysis
