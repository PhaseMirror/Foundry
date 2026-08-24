/-
F1 square — **the pre-Hilbert layer, brick 10** (`TestAlgebra.lean`): **the test ALGEBRA and the
integer Mellin moments** — the bounded-Lipschitz class is closed under multiplication, contains
the clamped monomials, and every test carries its certified moment sequence.

- `L2Test.mul` — **closure under products**: every certificate field is an already-proven lemma
  (`l2L`/`l2lip`/`l2fc` from brick 5, `l2bd` from brick 9). With `L2Test.add` (brick 7) the test
  class is a genuine (bounded-Lipschitz) function ALGEBRA — and pointwise multiplication is
  exactly the operation the autocorrelation cone `g ⋆ g^τ` is built from on the multiplicative
  side.
- `clamp01`/`clampTest` — the `[0,1]`-clamped identity as a test (the `qBandQ` band clamp at
  `[0,1]`: total, 1-Lipschitz, inert on the unit interval), and `oneTest` (the constant `1`).
- `powTest n` — the clamped monomials `x ↦ clamp01(x)ⁿ`, by iterated `L2Test.mul`: Lipschitz
  and bound certificates compose automatically.
- **`mellinMoment φ n := ⟨φ, powTest n⟩ = ∫₀¹ φ(x)·xⁿ dx`** — the `n`-th moment of every test,
  a certified constructive real: the Mellin data of `φ` at the integer points `s = n+1`. The
  bound `innerI_abs_le` and the Cauchy–Schwarz instance `mellinMoment_cs` make the moment
  functionals L²-bounded — the first quantitative grip on the `f ↦ f̂` direction.

WHY (the Sonine route, step 3). The genuine co-support coupling pairs a test with its transform.
The moment sequence is the transform's integer-point skeleton, realized HERE with zero new
analytic machinery — every ingredient is a composition of the layer's bricks. The full Mellin
transform (continuous `s`, the half-line domain) remains the far edge.

HONEST SCOPE. Integer moments over `[0,1]` only — NOT the Mellin transform (no continuous
parameter, no half-line, no inversion); the moment skeleton is to the transform what the
discrete band skeleton is to the Sonine space, and is fenced as such. The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.IntegralCSFull
import Multiplicity.F1.Analysis.IntegralBilinear
import Multiplicity.F1.Analysis.BandClamp

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Closure under multiplication: the test algebra.
-- ===========================================================================

/-- **The test class is closed under multiplication** — every certificate field is an
    already-proven lemma of the layer. Pointwise product is the autocorrelation-side
    operation. -/
def L2Test.mul (φ ψ : L2Test) : L2Test where
  f := fun x => Rmul (φ.f x) (ψ.f x)
  L := l2L φ ψ
  M := UOR.Bridge.F1Square.Analysis.mul φ.M ψ.M
  hLd := l2L_den φ ψ
  hLn := l2L_num φ ψ
  hMd := Qmul_den_pos φ.hMd ψ.hMd
  hMn := Int.mul_nonneg φ.hMn ψ.hMn
  hlip := l2lip φ ψ
  hfc := l2fc φ ψ
  hbd := l2bd φ ψ

-- ===========================================================================
-- The clamped identity and the constant test.
-- ===========================================================================

/-- The `[0,1]`-clamped identity: `clamp01 x = min(1, max(0, x))` (the `qBandQ` band). -/
def clamp01 (x : Real) : Real := qBandQ ⟨0, 1⟩ ⟨1, 1⟩ (by decide) (by decide) x

theorem clamp01_congr {x y : Real} (h : Req x y) : Req (clamp01 x) (clamp01 y) :=
  qBandQ_congr ⟨0, 1⟩ ⟨1, 1⟩ (by decide) (by decide) h

/-- The clamp is nonnegative. -/
theorem clamp01_nonneg (x : Real) : Rnonneg (clamp01 x) := by
  intro n
  refine Qle_trans (by decide) ?_ (qBandQ_ge ⟨0, 1⟩ ⟨1, 1⟩ (by decide) (by decide)
    (by decide) x n)
  show Qle (neg (Qbound n)) (⟨0, 1⟩ : Q)
  simp only [Qle, neg, Qbound]; push_cast; omega

/-- The clamp is `≤ 1`. -/
theorem clamp01_le_one (x : Real) : Rle (clamp01 x) (ofQ (⟨1, 1⟩ : Q) (by decide)) := by
  intro n
  refine Qle_trans (by decide) (qBandQ_le ⟨0, 1⟩ ⟨1, 1⟩ (by decide) (by decide) x n) ?_
  show Qle (⟨1, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (⟨2, n + 1⟩ : Q))
  simp only [Qle, add]; push_cast; omega

/-- `|clamp01 x| ≤ 1`. -/
theorem clamp01_abs (x : Real) : Rle (Rabs (clamp01 x)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
  Rle_trans (Rle_of_Req (Rabs_of_nonneg (clamp01_nonneg x))) (clamp01_le_one x)

/-- The clamp is inert on `[0,1]`-rationals. -/
theorem clamp01_ofQ {u : Q} (hud : 0 < u.den) (h0u : Qle (⟨0, 1⟩ : Q) u)
    (hu1 : Qle u (⟨1, 1⟩ : Q)) : Req (clamp01 (ofQ u hud)) (ofQ u hud) :=
  qBandQ_eq_of_band (Rle_ofQ_ofQ (by decide) hud h0u) (Rle_ofQ_ofQ hud (by decide) hu1)

/-- The clamped identity as a test: `1`-Lipschitz, bounded by `1`. -/
def clampTest : L2Test where
  f := clamp01
  L := ⟨1, 1⟩
  M := ⟨1, 1⟩
  hLd := by decide
  hLn := by decide
  hMd := by decide
  hMn := by decide
  hlip := fun x y =>
    Rle_trans (qBandQ_lipschitz ⟨0, 1⟩ ⟨1, 1⟩ (by decide) (by decide) x y)
      (Rle_of_Req (Req_symm (Req_trans (Rmul_comm _ _) (Rmul_one (Rabs (Rsub x y))))))
  hfc := fun _ _ h => clamp01_congr h
  hbd := fun x => clamp01_abs x

/-- The constant-`1` test. -/
def oneTest : L2Test where
  f := fun _ => one
  L := ⟨0, 1⟩
  M := ⟨1, 1⟩
  hLd := by decide
  hLn := by decide
  hMd := by decide
  hMn := by decide
  hlip := fun x y => by
    have hz : Req (Rabs (Rsub one one)) zero :=
      Req_trans (Rabs_congr (Radd_neg one)) Rabs_zero
    have hz0 : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero :=
      Req_of_seq_Qeq (fun _ => Qeq_refl _)
    have hR : Req (Rmul (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) zero :=
      Req_trans (Rmul_congr hz0 (Req_refl _))
        (Req_trans (Rmul_comm zero _) (Rmul_zero _))
    exact Rle_trans (Rle_of_Req hz) (Rle_of_Req (Req_symm hR))
  hfc := fun _ _ _ => Req_refl one
  hbd := fun _ => Rle_of_Req (Rabs_ofQ_nonneg (by decide) (by decide))

-- ===========================================================================
-- The clamped monomials and the integer Mellin moments.
-- ===========================================================================

/-- The clamped monomial tests `x ↦ clamp01(x)ⁿ`, by iterated product — the certificates
    compose automatically through `L2Test.mul`. -/
def powTest : Nat → L2Test
  | 0 => oneTest
  | n + 1 => L2Test.mul (powTest n) clampTest

/-- **The integer Mellin moments**: `mellinMoment φ n = ∫₀¹ φ(x)·clamp01(x)ⁿ dx` — the
    transform's integer-point data, a certified constructive real for every test and every
    `n`. -/
def mellinMoment (φ : L2Test) (n : Nat) : Real := innerI φ (powTest n)

/-- **The pairing is uniformly bounded**: `|⟨φ,ψ⟩| ≤ M_φ·M_ψ + (⌈L⌉+2)` — through the level-1
    dyadic sum. (The general bound behind brick 9's integral bounds, now public.) -/
theorem innerI_abs_le (φ ψ : L2Test) :
    Rle (Rabs (innerI φ ψ))
      (ofQ (add (UOR.Bridge.F1Square.Analysis.mul φ.M ψ.M)
          (⟨(((l2L φ ψ).num.toNat + 2 : Nat) : Int), 1⟩ : Q))
        (add_den_pos (Qmul_den_pos φ.hMd ψ.hMd) Nat.one_pos)) :=
  Rabs_le_of_close (Qmul_den_pos φ.hMd ψ.hMd) Nat.one_pos
    (riemannSum_abs_le (Qmul_den_pos φ.hMd ψ.hMd)
      (Int.mul_nonneg φ.hMn ψ.hMn) (l2bd φ ψ) _)
    (riemannIntegral_dyadic_dist (l2L_den φ ψ) (l2L_num φ ψ)
      (l2lip φ ψ) (l2fc φ ψ) (Nat.succ_pos 0))

/-- **The moment functionals are L²-bounded** (Cauchy–Schwarz instance):
    `(mellinMoment φ n)² ≤ ⟨φ,φ⟩·⟨xⁿ, xⁿ⟩` — the quantitative grip on the moment map. -/
theorem mellinMoment_cs (φ : L2Test) (n : Nat) :
    Rle (Rmul (mellinMoment φ n) (mellinMoment φ n))
        (Rmul (innerI φ φ) (innerI (powTest n) (powTest n))) :=
  innerI_cauchy_schwarz φ (powTest n)

/-- **The zeroth moment is the plain integral**: `mellinMoment φ 0 ≈ ∫₀¹ φ` — pointwise
    `φ·1 ≈ φ` at the shared modulus, then certificate independence back to `φ`'s own
    certificate. The moment map is anchored to the certified integral. -/
theorem mellinMoment_zero (φ : L2Test) :
    Req (mellinMoment φ 0) (riemannIntegral φ.hLd φ.hLn φ.hlip φ.hfc) := by
  have hQ : Qeq φ.L (l2L φ oneTest) := by
    show Qeq φ.L (add (UOR.Bridge.F1Square.Analysis.mul φ.M (⟨0, 1⟩ : Q))
      (UOR.Bridge.F1Square.Analysis.mul (⟨1, 1⟩ : Q) φ.L))
    simp only [Qeq, add, mul]; push_cast; ring_uor
  have hlip' := lip_weaken φ.hLd (l2L_den φ oneTest) (Qeq_le hQ) φ.hlip
  refine Req_trans (riemannIntegral_congr (l2L_den φ oneTest) (l2L_num φ oneTest)
    (l2lip φ oneTest) (l2fc φ oneTest) hlip' φ.hfc (fun x => Rmul_one (φ.f x))) ?_
  exact riemannIntegral_certif_irrel (l2L_den φ oneTest) (l2L_num φ oneTest) hlip' φ.hfc
    φ.hLd φ.hLn φ.hlip φ.hfc

end Multiplicity.UOR.Bridge.F1Square.Square
