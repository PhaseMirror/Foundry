/-
F1 square — **the pre-Hilbert layer, brick 5** (`IntegralInner.lean`): the L² PAIRING OVER THE
CERTIFIED INTEGRAL — the first genuine function-space inner product of the Sonine route's step 3.

`L2Test` bundles a test function with everything the integration gateway demands: a rational
Lipschitz modulus `L`, a rational global bound `M`, the Lipschitz certificate, the congruence, and
the bound certificate — exactly the class the realized Weil tests (tent/bump/band constructions,
all clamped and piecewise-affine) live in. Then:

- `innerI φ ψ = ∫₀¹ φ·ψ` — the certified integral of the product, with the product certificate
  supplied by `Rmul_lipschitz` (constant `M_φ·L_ψ + M_ψ·L_φ`); a genuine constructed real, not an
  interface field.
- `innerI_self_nonneg` — `∫₀¹ φ² ≥ 0`: the L² squared norm is nonnegative (the integrand is a
  pointwise square).
- `innerI_symm_certif` — symmetry of the pairing up to the certificate: `∫ φ·ψ ≈ ∫ ψ·φ` when both
  integrals run over the SAME product certificate (the `φψ` one transports to the `ψφ` integrand
  through pointwise commutativity).

HONEST SCOPE. The pairing at a fixed product certificate. What is NOT here (banked, in order):
certificate-independence of `riemannIntegral` (the value depends only on the integrand — needs
the two-schedule limit comparison; until then, symmetry and bilinearity are stated at shared
certificates), bilinearity via `riemannIntegral_add` at a common weakened modulus, and the
integral Cauchy–Schwarz. No L² completion, no measure theory, no claim past the bounded-Lipschitz
class. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.RmulLipschitz
import Multiplicity.F1Square.Analysis.DyadicIntegral

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- A **bounded Lipschitz test function** — the function bundled with the data the certified
    integral consumes: rational Lipschitz modulus `L`, rational global bound `M`, and the three
    certificates. The realized Weil tests (clamped, piecewise-affine) all live here. -/
structure L2Test where
  f : Real → Real
  L : Q
  M : Q
  hLd : 0 < L.den
  hLn : 0 ≤ L.num
  hMd : 0 < M.den
  hMn : 0 ≤ M.num
  hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y)))
  hfc : ∀ x y, Req x y → Req (f x) (f y)
  hbd : ∀ x, Rle (Rabs (f x)) (ofQ M hMd)

/-- The product Lipschitz modulus `M_φ·L_ψ + M_ψ·L_φ` of a pair of tests. -/
def l2L (φ ψ : L2Test) : Q := add (mul φ.M ψ.L) (mul ψ.M φ.L)

theorem l2L_den (φ ψ : L2Test) : 0 < (l2L φ ψ).den :=
  add_den_pos (Qmul_den_pos φ.hMd ψ.hLd) (Qmul_den_pos ψ.hMd φ.hLd)

theorem l2L_num (φ ψ : L2Test) : 0 ≤ (l2L φ ψ).num :=
  Rmul_lip_const_nonneg φ.hLn ψ.hLn φ.hMn ψ.hMn

/-- The product integrand's Lipschitz certificate (`Rmul_lipschitz` instantiated). -/
theorem l2lip (φ ψ : L2Test) : ∀ x y,
    Rle (Rabs (Rsub (Rmul (φ.f x) (ψ.f x)) (Rmul (φ.f y) (ψ.f y))))
        (Rmul (ofQ (l2L φ ψ) (l2L_den φ ψ)) (Rabs (Rsub x y))) :=
  fun x y => Rmul_lipschitz φ.hLd ψ.hLd φ.hMd ψ.hMd φ.hLn ψ.hLn φ.hMn ψ.hMn
    φ.hlip ψ.hlip φ.hbd ψ.hbd x y

/-- The product integrand's congruence certificate. -/
theorem l2fc (φ ψ : L2Test) : ∀ x y, Req x y →
    Req (Rmul (φ.f x) (ψ.f x)) (Rmul (φ.f y) (ψ.f y)) :=
  fun x y h => Rmul_congr (φ.hfc x y h) (ψ.hfc x y h)

/-- **The L² pairing over the certified integral**: `⟨φ,ψ⟩ = ∫₀¹ φ·ψ` — a genuine constructed
    real (the Bishop limit of the dyadic Riemann sums of the product), the first function-space
    inner product of the step-3 layer. -/
def innerI (φ ψ : L2Test) : Real :=
  riemannIntegral (l2L_den φ ψ) (l2L_num φ ψ) (l2lip φ ψ) (l2fc φ ψ)

/-- **The L² squared norm is nonnegative**: `⟨φ,φ⟩ = ∫₀¹ φ² ≥ 0` — the integrand is a pointwise
    square, and the certified integral preserves nonnegativity. -/
theorem innerI_self_nonneg (φ : L2Test) : Rnonneg (innerI φ φ) :=
  riemannIntegral_nonneg (l2L_den φ φ) (l2L_num φ φ) (l2lip φ φ) (l2fc φ φ)
    (fun x => Rnonneg_Rmul_self (φ.f x))

/-- The `φψ` product certificate is also a certificate for the `ψφ` integrand (pointwise
    commutativity inside the absolute value). -/
theorem l2lip_swap (φ ψ : L2Test) : ∀ x y,
    Rle (Rabs (Rsub (Rmul (ψ.f x) (φ.f x)) (Rmul (ψ.f y) (φ.f y))))
        (Rmul (ofQ (l2L φ ψ) (l2L_den φ ψ)) (Rabs (Rsub x y))) :=
  fun x y => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
    (Rmul_comm (ψ.f x) (φ.f x)) (Rmul_comm (ψ.f y) (φ.f y))))) (l2lip φ ψ x y)

/-- The `ψφ` integrand's congruence certificate. -/
theorem l2fc_swap (φ ψ : L2Test) : ∀ x y, Req x y →
    Req (Rmul (ψ.f x) (φ.f x)) (Rmul (ψ.f y) (φ.f y)) :=
  fun x y h => Rmul_congr (ψ.hfc x y h) (φ.hfc x y h)

/-- **Symmetry of the L² pairing, up to the certificate**: `∫₀¹ φ·ψ ≈ ∫₀¹ ψ·φ` with both
    integrals over the SAME (`φψ`) product certificate — the integrand-level symmetry; the
    remaining nominal asymmetry is the certificate itself, which the banked
    certificate-independence lemma removes. -/
theorem innerI_symm_certif (φ ψ : L2Test) :
    Req (innerI φ ψ)
        (riemannIntegral (l2L_den φ ψ) (l2L_num φ ψ) (l2lip_swap φ ψ) (l2fc_swap φ ψ)) :=
  riemannIntegral_congr (l2L_den φ ψ) (l2L_num φ ψ) (l2lip φ ψ) (l2fc φ ψ)
    (l2lip_swap φ ψ) (l2fc_swap φ ψ) (fun x => Rmul_comm (φ.f x) (ψ.f x))

end Multiplicity.UOR.Bridge.F1Square.Analysis
