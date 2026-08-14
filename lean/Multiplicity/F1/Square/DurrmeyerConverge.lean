/-
F1 square — **pointwise convergence of the Bernstein–Durrmeyer operator** (`DurrmeyerConverge.lean`),
the Mellin-inversion arc, sub-brick J₅ (the capstone deviation bound). The Durrmeyer operator
`durrOp φ n x = (n+1)·Σ_k b_{n,k}(x)·⟨φ, b_{n,k}⟩` approximates a Lipschitz test pointwise, and the
approximation is governed by the second central moment `T_n(x) = M_n⁽²⁾ − 2x·M_n⁽¹⁾ + x²`. The
multiplied-form deviation bound is

    `2δ·|durrOp φ n x − φ(x)| ≤ φ.L·(δ² + T_n(x))`   (`durrOp_dev_bound`, for `x ∈ [0,1]`, any `δ > 0`)

and (with the J₅a estimate `T_{p+3} ≤ 1/(p+5)`) the explicit vanishing form

    `2δ·|durrOp φ (p+3) x − φ(x)| ≤ φ.L·(δ² + 1/(p+5))`   (`durrOp_dev_bound_le`).

THE CONSTRUCTIVE OBSTACLE (the same as Bernstein's theorem). No `sqrt` for Cauchy–Schwarz, and
`|t − x| ≤ δ` is undecidable for a real `x`. The substitute is the pointwise AM–GM
`2δ|t| ≤ δ² + t²` (`amgm_2delta`): the residual `ψ = φ − φ(x)·1` is Lipschitz with `|ψ(t)| ≤ L|t−x|`,
so `2δ|ψ(t)| ≤ L·(δ² + (t−x)²)`; the right side is the value of a dominating test `G` whose Durrmeyer
image is `φ.L·(δ² + T_n)` (via `durrOp_scalar`, `durrOp_add`, `durrOp_constTest`, and the identification
of the squared deviation with `x² − 2x·(·) + (·)²` in the operator moments). The pairing domination
`|⟨ψ,b_{n,k}⟩| ≤ ⟨G,b_{n,k}⟩` (`innerI_abs_le_mono`, with `b_{n,k} ≥ 0`) transports through the
nonnegative weights `b_{n,k}(x)` and the `(n+1)` factor to `|durrOp ψ| ≤ durrOp G`.

HONEST SCOPE. The multiplied-form deviation bound and its explicit `1/(p+5)` specialization — the
pointwise convergence content `durrOp φ n x → φ(x)` up to the `1/(2δ)` division. NOT the packaged
limit object, NOT the full Mellin strong inversion, NOT positivity. Step 4 (the band-coupling
positivity) is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.DurrmeyerCentral
import Multiplicity.F1Square.Square.DurrmeyerConst
import Multiplicity.F1Square.Square.IntegralMono
import Multiplicity.F1Square.Square.BernsteinConverge
import Multiplicity.F1Square.Square.BernsteinClampMatch

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `a·(b·c) ≈ b·(a·c)` (real, left-commute) — local copy. -/
private theorem Rmul_lc (a b c : Real) : Req (Rmul a (Rmul b c)) (Rmul b (Rmul a c)) :=
  Req_trans (Req_symm (Rmul_assoc a b c))
    (Req_trans (Rmul_congr (Rmul_comm a b) (Req_refl c)) (Rmul_assoc b a c))

/-- `2·y ≈ y + y` (with `2 = RofNat 2`). -/
private theorem Rtwo_mul (y : Real) : Req (Rmul (RofNat 2) y) (Radd y y) := by
  have h2 : Req (RofNat 2) (Radd one one) :=
    Req_symm (Req_trans (Radd_ofQ_ofQ (by decide) (by decide))
      (ofQ_congr (add_den_pos (by decide) (by decide)) Nat.one_pos (by decide)))
  refine Req_trans (Rmul_congr h2 (Req_refl y)) ?_
  refine Req_trans (Rmul_distrib_right one one y) ?_
  exact Radd_congr (Rone_mul y) (Rone_mul y)

-- ===========================================================================
-- Step A — the Durrmeyer operator scales a constant-test factor.
-- ===========================================================================

/-- **THE DURRMEYER OPERATOR SCALES A CONSTANT-TEST FACTOR** (the real-scalar analogue of
    `durrOp_constTest`): `durrOp ((constTest s)·h) n x = s·durrOp h n x`. Each weight
    `⟨(constTest s)·h, b_{n,k}⟩ = s·⟨h, b_{n,k}⟩` by the real-scalar pairing law (`innerI_constMul`,
    moved into the first slot via `innerI_symm`); pull `s` out of the sum and reorder. -/
theorem durrOp_scalar (s : Real) {mB : Q} (hMd : 0 < mB.den) (hMn : 0 ≤ mB.num)
    (hb : Rle (Rabs s) (ofQ mB hMd)) (h : L2Test) (n : Nat) (x : Real) :
    Req (durrOp (L2Test.mul (constTest s mB hMd hMn hb) h) n x) (Rmul s (durrOp h n x)) := by
  show Req (Rmul (RofNat (n + 1))
      (RsumN (fun k => Rmul (bernR x n k)
        (innerI (L2Test.mul (constTest s mB hMd hMn hb) h) (bernBasisTest n k))) (n + 1)))
      (Rmul s (durrOp h n x))
  have hterm : ∀ k, Req (innerI (L2Test.mul (constTest s mB hMd hMn hb) h) (bernBasisTest n k))
      (Rmul s (innerI h (bernBasisTest n k))) := by
    intro k
    refine Req_trans (innerI_symm (L2Test.mul (constTest s mB hMd hMn hb) h) (bernBasisTest n k)) ?_
    refine Req_trans (innerI_constMul (bernBasisTest n k) h s hMd hMn hb) ?_
    exact Rmul_congr (Req_refl s) (innerI_symm (bernBasisTest n k) h)
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (n + 1) (fun k _ =>
        Req_trans (Rmul_congr (Req_refl (bernR x n k)) (hterm k))
          (Rmul_lc (bernR x n k) s (innerI h (bernBasisTest n k)))))
      (RsumN_Rmul_const s (fun k => Rmul (bernR x n k) (innerI h (bernBasisTest n k))) (n + 1)))) ?_
  exact Rmul_lc (RofNat (n + 1)) s
    (RsumN (fun k => Rmul (bernR x n k) (innerI h (bernBasisTest n k))) (n + 1))

-- ===========================================================================
-- Nonnegativity of the Bernstein basis test on all of `Real`.
-- ===========================================================================

unseal natScale in
private theorem natScale_zero_f (φ : L2Test) : natScale 0 φ = zeroL2 := rfl

unseal natScale in
private theorem natScale_succ_f (k : Nat) (φ : L2Test) :
    natScale (k + 1) φ = L2Test.add φ (natScale k φ) := rfl

/-- The `k`-fold sum preserves pointwise nonnegativity. -/
private theorem natScale_f_nonneg (φ : L2Test) (t : Real) (h : Rnonneg (φ.f t)) :
    ∀ m, Rnonneg ((natScale m φ).f t)
  | 0 => by rw [natScale_zero_f]; exact Rnonneg_zero
  | m + 1 => by
    rw [natScale_succ_f]
    exact Rnonneg_Radd h (natScale_f_nonneg φ t h m)

/-- `(powTest k).f t ≥ 0` for every real `t` (the clamp lands in `[0,1]`). -/
private theorem powTest_f_nonneg (k : Nat) (t : Real) : Rnonneg ((powTest k).f t) :=
  Rnonneg_congr (Req_symm (powTest_f_eq t k)) (Rnonneg_Rpow (clamp01_nonneg t) k)

/-- `(powMinusTest m).f t ≥ 0` for every real `t`. -/
private theorem powMinus_f_nonneg (m : Nat) (t : Real) : Rnonneg ((powMinusTest m).f t) :=
  Rnonneg_congr (Req_symm (powMinusTest_f_eq t m))
    (Rnonneg_Rpow (Rnonneg_Rsub_of_Rle (clamp01_le_one t)) m)

/-- The un-normalized basis factor is pointwise nonnegative everywhere. -/
private theorem clampProd_f_nonneg (k m : Nat) (t : Real) : Rnonneg ((clampProdTest k m).f t) :=
  Rnonneg_Rmul (powTest_f_nonneg k t) (powMinus_f_nonneg m t)

/-- **THE BERNSTEIN BASIS TEST IS POINTWISE NONNEGATIVE** (everywhere): `(bernBasisTest n k).f t ≥ 0`.
    It is `C(n,k)·clamp01ᵏ·(1−clamp01)ⁿ⁻ᵏ`, a nonnegative scalar times a product of nonnegatives. -/
theorem bernBasisTest_f_nonneg (n k : Nat) (t : Real) : Rnonneg ((bernBasisTest n k).f t) :=
  natScale_f_nonneg (clampProdTest k (n - k)) t (clampProd_f_nonneg k (n - k) t) (choose n k)

-- ===========================================================================
-- Step D — the operator dominates in absolute value.
-- ===========================================================================

/-- **THE DURRMEYER OPERATOR IS DOMINATED IN ABSOLUTE VALUE**: if `|A(t)| ≤ G(t)` on `[0,1]` then
    `|durrOp A n x| ≤ durrOp G n x` for `x ∈ [0,1]`. Per weight the pairing is dominated
    (`innerI_abs_le_mono`, with `b_{n,k} ≥ 0`); the nonnegative weight `b_{n,k}(x)` and the `(n+1)`
    factor pass through `Rabs_Rmul`, `RsumN_Rabs_le`, `RsumN_le`. -/
theorem durrOp_abs_le_dom (A G : L2Test) (n : Nat) (x : Real)
    (h0 : Rle zero x) (h1 : Rle x one)
    (hg : ∀ t, Rle zero t → Rle t one → Rle (Rabs (A.f t)) (G.f t)) :
    Rle (Rabs (durrOp A n x)) (durrOp G n x) := by
  have hxnn : Rnonneg x := Rnonneg_of_Rle_zero h0
  have h1xnn : Rnonneg (Rsub one x) := Rnonneg_Rsub_of_Rle h1
  have hterm : ∀ k, k < n + 1 →
      Rle (Rabs (Rmul (bernR x n k) (innerI A (bernBasisTest n k))))
          (Rmul (bernR x n k) (innerI G (bernBasisTest n k))) := by
    intro k _
    have hb := bernR_nonneg x hxnn h1xnn n k
    have hmono : Rle (Rabs (innerI A (bernBasisTest n k))) (innerI G (bernBasisTest n k)) :=
      innerI_abs_le_mono A (bernBasisTest n k) G hg (fun t _ _ => bernBasisTest_f_nonneg n k t)
    refine Rle_trans (Rle_of_Req (Rabs_Rmul (bernR x n k) (innerI A (bernBasisTest n k)))) ?_
    refine Rle_trans (Rle_of_Req (Rmul_congr (Rabs_of_nonneg hb) (Req_refl _))) ?_
    exact Rmul_le_Rmul_left hb hmono
  have hsum : Rle (Rabs (RsumN (fun k => Rmul (bernR x n k) (innerI A (bernBasisTest n k))) (n + 1)))
      (RsumN (fun k => Rmul (bernR x n k) (innerI G (bernBasisTest n k))) (n + 1)) :=
    Rle_trans (RsumN_Rabs_le _ (n + 1)) (RsumN_le (n + 1) hterm)
  show Rle (Rabs (Rmul (RofNat (n + 1))
        (RsumN (fun k => Rmul (bernR x n k) (innerI A (bernBasisTest n k))) (n + 1))))
       (Rmul (RofNat (n + 1))
        (RsumN (fun k => Rmul (bernR x n k) (innerI G (bernBasisTest n k))) (n + 1)))
  refine Rle_trans (Rle_of_Req (Rabs_Rmul (RofNat (n + 1)) _)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Rabs_of_nonneg (Rnonneg_RofNat (n + 1))) (Req_refl _))) ?_
  exact Rmul_le_Rmul_left (Rnonneg_RofNat (n + 1)) hsum

-- ===========================================================================
-- The pointwise squared-deviation identity.
-- ===========================================================================

/-- **THE SQUARED DEVIATION AS THE OPERATOR MONOMIALS** (pointwise, with `c = clamp01 t`):
    `(c − x)² = (1·c)·c − 2x·(1·c) + (x·x)·1`. This is exactly the pointwise value of the honest
    squared-deviation test versus the monomial combination `powTest 2 − 2x·powTest 1 + x²·powTest 0`. -/
private theorem sqdev_eq_mono (c x : Real) :
    Req (Rmul (Rsub c x) (Rsub c x))
        (Radd (Rsub (Rmul (Rmul one c) c) (Rmul (Rmul (RofNat 2) x) (Rmul one c)))
              (Rmul (Rmul x x) one)) := by
  have hP : Req (Rmul (Rmul one c) c) (Rmul c c) := Rmul_congr (Rone_mul c) (Req_refl c)
  have hR : Req (Rmul (Rmul x x) one) (Rmul x x) := Rmul_one (Rmul x x)
  have hQ : Req (Rmul (Rmul (RofNat 2) x) (Rmul one c)) (Radd (Rmul c x) (Rmul c x)) := by
    refine Req_trans (Rmul_congr (Req_refl _) (Rone_mul c)) ?_
    refine Req_trans (Rmul_assoc (RofNat 2) x c) ?_
    refine Req_trans (Rtwo_mul (Rmul x c)) ?_
    exact Radd_congr (Rmul_comm x c) (Rmul_comm x c)
  refine Req_trans (Rsub_sq_expand c x) ?_
  refine Req_trans ?_ (Req_symm (Radd_congr (Rsub_congr hP hQ) hR))
  -- `(CC + XX) − D ≈ (CC − D) + XX` with `D = CX + CX`
  refine Req_trans (Radd_assoc (Rmul c c) (Rmul x x)
    (Rneg (Radd (Rmul c x) (Rmul c x)))) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_comm (Rmul x x) (Rneg (Radd (Rmul c x) (Rmul c x))))) ?_
  exact Req_symm (Radd_assoc (Rmul c c) (Rneg (Radd (Rmul c x) (Rmul c x))) (Rmul x x))

-- ===========================================================================
-- The second central moment as an operator value.
-- ===========================================================================

/-- The Durrmeyer second central moment `T_n(x) = M_n⁽²⁾ − 2x·M_n⁽¹⁾ + x²`, written exactly as in
    `durrOp_central2_le`. -/
def durrCentral2 (n : Nat) (x : Real) : Real :=
  Radd (Rsub (durrOp (powTest 2) n x) (Rmul (Rmul (RofNat 2) x) (durrOp (powTest 1) n x)))
       (Rmul x x)


-- ===========================================================================
-- The capstone multiplied-form deviation bound.
-- ===========================================================================

/-- **★ THE DURRMEYER POINTWISE DEVIATION BOUND** (multiplied form): for `x ∈ [0,1]` and any rational
    `δ > 0`,

        `2δ·|durrOp φ n x − φ(x)| ≤ φ.L·(δ² + T_n(x))`,

    the constructive convergence estimate. `φ − φ(x)·1` is the Lipschitz residual `ψ`; its rational
    multiple `2δ·ψ` is dominated pointwise on `[0,1]` by the test `G = φ.L·(δ² + (·−x)²)` through the
    AM–GM `2δ|ψ(t)| ≤ φ.L·(δ²+(t−x)²)` (`amgm_2delta`, `φ.hlip`); `durrOp_abs_le_dom` transports the
    domination to `|durrOp (2δ·ψ)| ≤ durrOp G`, `durrOp_scalar`/`durrOp_add`/`durrOp_constTest` compute
    `durrOp G = φ.L·(δ² + T_n)` (the squared deviation matching the operator monomials via
    `sqdev_eq_mono`), and `durrOp_dev_eq` rewrites `durrOp (2δ·ψ) = 2δ·(durrOp φ − φ(x))`. -/
theorem durrOp_dev_bound (φ : L2Test) (n : Nat) (x : Real) (h0 : Rle zero x) (h1 : Rle x one)
    (δ : Q) (hδd : 0 < δ.den) (hδn : 0 < δ.num) :
    Rle (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos Nat.one_pos hδd))
              (Rabs (Rsub (durrOp φ n x) (φ.f x))))
        (Rmul (ofQ φ.L φ.hLd)
              (Radd (ofQ (mul δ δ) (Qmul_den_pos hδd hδd)) (durrCentral2 n x))) := by
  -- rational data
  have h2δd : 0 < (mul (⟨2, 1⟩ : Q) δ).den := Qmul_den_pos Nat.one_pos hδd
  have hq2δn : (0 : Int) ≤ (mul (⟨2, 1⟩ : Q) δ).num := by
    show (0 : Int) ≤ 2 * δ.num; omega
  have hMnδ2 : (0 : Int) ≤ (mul δ δ).num := by
    show (0 : Int) ≤ δ.num * δ.num; exact Int.mul_nonneg (by omega) (by omega)
  -- constant-test bounds
  have hbq2δ : Rle (Rabs (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd)) (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) :=
    Rle_of_Req (Rabs_of_nonneg (Rnonneg_ofQ h2δd hq2δn))
  have hbφL : Rle (Rabs (ofQ φ.L φ.hLd)) (ofQ φ.L φ.hLd) :=
    Rle_of_Req (Rabs_of_nonneg (Rnonneg_ofQ φ.hLd φ.hLn))
  have hbδ2 : Rle (Rabs (ofQ (mul δ δ) (Qmul_den_pos hδd hδd)))
      (ofQ (mul δ δ) (Qmul_den_pos hδd hδd)) :=
    Rle_of_Req (Rabs_of_nonneg (Rnonneg_ofQ (Qmul_den_pos hδd hδd) hMnδ2))
  have hbx : Rle (Rabs x) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    Rle_trans (Rle_of_Req (Rabs_of_nonneg (Rnonneg_of_Rle_zero h0))) h1
  have hb2x : Rle (Rabs (Rmul (RofNat 2) x)) (ofQ (⟨2, 1⟩ : Q) (by decide)) := by
    refine Rle_trans (Rle_of_Req (Rabs_of_nonneg
      (Rnonneg_Rmul (Rnonneg_RofNat 2) (Rnonneg_of_Rle_zero h0)))) ?_
    exact Rle_trans (Rmul_le_Rmul_left (Rnonneg_RofNat 2) h1) (Rle_of_Req (Rmul_one (RofNat 2)))
  have hbxx : Rle (Rabs (Rmul x x)) (ofQ (⟨1, 1⟩ : Q) (by decide)) := by
    have hxnn : Rnonneg x := Rnonneg_of_Rle_zero h0
    refine Rle_trans (Rle_of_Req (Rabs_of_nonneg (Rnonneg_Rmul hxnn hxnn))) ?_
    exact Rle_trans (Rmul_le_Rmul_left hxnn h1) (Rle_trans (Rle_of_Req (Rmul_one x)) h1)
  -- the tests
  let cx : L2Test := constTest x (⟨1, 1⟩ : Q) (by decide) (by decide) hbx
  let devTest : L2Test := L2Test.sub clampTest cx
  let sqDevTest : L2Test := L2Test.mul devTest devTest
  let dConst : L2Test :=
    constTest (ofQ (mul δ δ) (Qmul_den_pos hδd hδd)) (mul δ δ) (Qmul_den_pos hδd hδd) hMnδ2 hbδ2
  let Ginner : L2Test := L2Test.add dConst sqDevTest
  let cCoef : L2Test := constTest (ofQ φ.L φ.hLd) φ.L φ.hLd φ.hLn hbφL
  let G : L2Test := L2Test.mul cCoef Ginner
  let ψ : L2Test := L2Test.sub φ (constTest (φ.f x) φ.M φ.hMd φ.hMn (φ.hbd x))
  let c2δ : L2Test := constTest (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (mul (⟨2, 1⟩ : Q) δ) h2δd hq2δn hbq2δ
  let ψ2δ : L2Test := L2Test.mul c2δ ψ
  let twoXpow1 : L2Test :=
    L2Test.mul (constTest (Rmul (RofNat 2) x) (⟨2, 1⟩ : Q) (by decide) (by decide) hb2x) (powTest 1)
  let xsqPow0 : L2Test :=
    L2Test.mul (constTest (Rmul x x) (⟨1, 1⟩ : Q) (by decide) (by decide) hbxx) (powTest 0)
  let χ : L2Test := L2Test.add (L2Test.sub (powTest 2) twoXpow1) xsqPow0
  -- Step B: pointwise domination `|ψ2δ(t)| ≤ G(t)` on `[0,1]`.
  have hg : ∀ t, Rle zero t → Rle t one → Rle (Rabs (ψ2δ.f t)) (G.f t) := by
    intro t ht0 ht1
    have hAbsEq : Req (Rabs (ψ2δ.f t))
        (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (Rabs (Rsub (φ.f t) (φ.f x)))) :=
      Req_trans (Rabs_Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (Rsub (φ.f t) (φ.f x)))
        (Rmul_congr (Rabs_of_nonneg (Rnonneg_ofQ h2δd hq2δn)) (Req_refl _))
    have hct : Req (clamp01 t) t := clamp01_eq_self ht0 ht1
    have hstep1 : Rle (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (Rabs (Rsub (φ.f t) (φ.f x))))
        (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (Rmul (ofQ φ.L φ.hLd) (Rabs (Rsub t x)))) :=
      Rmul_le_Rmul_left (Rnonneg_ofQ h2δd hq2δn) (φ.hlip t x)
    have hstep2 : Req (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (Rmul (ofQ φ.L φ.hLd) (Rabs (Rsub t x))))
        (Rmul (ofQ φ.L φ.hLd)
          (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (Rabs (Rsub (clamp01 t) x)))) := by
      refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _)
        (Rabs_congr (Rsub_congr (Req_symm hct) (Req_refl x))))) ?_
      exact Rmul_lc (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (ofQ φ.L φ.hLd) (Rabs (Rsub (clamp01 t) x))
    have hstep3 : Rle (Rmul (ofQ φ.L φ.hLd)
          (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (Rabs (Rsub (clamp01 t) x))))
        (Rmul (ofQ φ.L φ.hLd) (Radd (ofQ (mul δ δ) (Qmul_den_pos hδd hδd))
          (Rmul (Rsub (clamp01 t) x) (Rsub (clamp01 t) x)))) :=
      Rmul_le_Rmul_left (Rnonneg_ofQ φ.hLd φ.hLn) (amgm_2delta δ hδd (Rsub (clamp01 t) x))
    exact Rle_trans (Rle_of_Req hAbsEq)
      (Rle_trans hstep1 (Rle_trans (Rle_of_Req hstep2) hstep3))
  -- Step D: `|durrOp ψ2δ| ≤ durrOp G`.
  have hD : Rle (Rabs (durrOp ψ2δ n x)) (durrOp G n x) := durrOp_abs_le_dom ψ2δ G n x h0 h1 hg
  -- Step C: `durrOp G = φ.L·(δ² + T_n)`.
  have hsqchi : Req (durrOp sqDevTest n x) (durrOp χ n x) :=
    Rmul_congr (Req_refl _) (RsumN_congr (n + 1) (fun k _ =>
      Rmul_congr (Req_refl _)
        (innerI_left_congr_on_unit sqDevTest χ (bernBasisTest n k)
          (fun t _ _ => sqdev_eq_mono (clamp01 t) x))))
  have hchi : Req (durrOp χ n x) (durrCentral2 n x) :=
    Req_trans (durrOp_add (L2Test.sub (powTest 2) twoXpow1) xsqPow0 n x)
      (Radd_congr
        (Req_trans (durrOp_sub (powTest 2) twoXpow1 n x)
          (Rsub_congr (Req_refl _)
            (durrOp_scalar (Rmul (RofNat 2) x) (by decide) (by decide) hb2x (powTest 1) n x)))
        (Req_trans (durrOp_scalar (Rmul x x) (by decide) (by decide) hbxx (powTest 0) n x)
          (Req_trans (Rmul_congr (Req_refl _) (durrOp_powTest_zero n x)) (Rmul_one (Rmul x x)))))
  have hStepC : Req (durrOp G n x)
      (Rmul (ofQ φ.L φ.hLd)
        (Radd (ofQ (mul δ δ) (Qmul_den_pos hδd hδd)) (durrCentral2 n x))) := by
    refine Req_trans (durrOp_scalar (ofQ φ.L φ.hLd) φ.hLd φ.hLn hbφL Ginner n x) ?_
    refine Rmul_congr (Req_refl _) ?_
    refine Req_trans (durrOp_add dConst sqDevTest n x) ?_
    exact Radd_congr
      (durrOp_constTest (ofQ (mul δ δ) (Qmul_den_pos hδd hδd)) (Qmul_den_pos hδd hδd) hMnδ2 hbδ2 n x)
      (Req_trans hsqchi hchi)
  -- durrOp ψ2δ = 2δ·(durrOp φ − φ(x))
  have hDevA : Req (durrOp ψ2δ n x)
      (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (Rsub (durrOp φ n x) (φ.f x))) :=
    Req_trans (durrOp_scalar (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) h2δd hq2δn hbq2δ ψ n x)
      (Rmul_congr (Req_refl _) (durrOp_dev_eq φ n x))
  have hAbs : Req (Rabs (durrOp ψ2δ n x))
      (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (Rabs (Rsub (durrOp φ n x) (φ.f x)))) :=
    Req_trans (Rabs_congr hDevA)
      (Req_trans (Rabs_Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) h2δd) (Rsub (durrOp φ n x) (φ.f x)))
        (Rmul_congr (Rabs_of_nonneg (Rnonneg_ofQ h2δd hq2δn)) (Req_refl _)))
  -- assemble
  exact Rle_trans (Rle_of_Req (Req_symm hAbs)) (Rle_trans hD (Rle_of_Req hStepC))

/-- **★ THE EXPLICIT VANISHING DEVIATION BOUND** (`n = p+3`): combining `durrOp_dev_bound` with the
    J₅a second-central-moment estimate `T_{p+3}(x) ≤ 1/(p+5)`,

        `2δ·|durrOp φ (p+3) x − φ(x)| ≤ φ.L·(δ² + 1/(p+5))`,

    the right side of which is `→ 0` under `δ = 1/(k+1)`, `p+5 ~ (k+1)²` — the pointwise convergence
    `durrOp φ (p+3) x → φ(x)` on `[0,1]`. -/
theorem durrOp_dev_bound_le (φ : L2Test) (p : Nat) (x : Real) (h0 : Rle zero x) (h1 : Rle x one)
    (δ : Q) (hδd : 0 < δ.den) (hδn : 0 < δ.num) :
    Rle (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos Nat.one_pos hδd))
              (Rabs (Rsub (durrOp φ (p + 3) x) (φ.f x))))
        (Rmul (ofQ φ.L φ.hLd)
              (Radd (ofQ (mul δ δ) (Qmul_den_pos hδd hδd))
                    (ofQ (⟨1, p + 5⟩ : Q) (Nat.succ_pos (p + 4))))) := by
  refine Rle_trans (durrOp_dev_bound φ (p + 3) x h0 h1 δ hδd hδn) ?_
  refine Rmul_le_Rmul_left (Rnonneg_ofQ φ.hLd φ.hLn) ?_
  exact Radd_le_add (Rle_refl _) (durrOp_central2_le p x h0 h1)

/-- **★ THE DURRMEYER OPERATOR CONVERGES POINTWISE** (explicit rate): along the schedule
    `n = (k+3)² − 2`, `δ = 1/(k+3)` (so the J₅a moment `T_n ≤ 1/(n+2) = δ²`),

        `|durrOp φ ((k+3)²−2) x − φ(x)| ≤ φ.L/(k+3)`   → 0,

    the pointwise convergence `durrOp φ n x → φ(x)` on `[0,1]`. Divide the explicit deviation bound
    (`durrOp_dev_bound_le`) by the weight `2δ = 2/(k+3)` (`Rle_of_Rmul_ofQ_le`); the right side
    `(k+3)/2 · φ.L · (1/(k+3)² + 1/(k+3)²) = φ.L/(k+3)` collapses by `ring_uor`. -/
theorem durrOp_converges (φ : L2Test) (x : Real) (h0 : Rle zero x) (h1 : Rle x one) (k : Nat) :
    Rle (Rabs (Rsub (durrOp φ ((k + 3) * (k + 3) - 2) x) (φ.f x)))
        (ofQ (mul φ.L (⟨1, k + 3⟩ : Q)) (Qmul_den_pos φ.hLd (Nat.succ_pos (k + 2)))) := by
  have hKK5 : 5 ≤ (k + 3) * (k + 3) := by
    have h9 := Nat.mul_le_mul (show 3 ≤ k + 3 by omega) (show 3 ≤ k + 3 by omega)
    omega
  have hp3 : (k + 3) * (k + 3) - 5 + 3 = (k + 3) * (k + 3) - 2 := by omega
  have hp5 : (k + 3) * (k + 3) - 5 + 5 = (k + 3) * (k + 3) := by omega
  have hδd : 0 < (⟨1, k + 3⟩ : Q).den := Nat.succ_pos (k + 2)
  have hδn : 0 < (⟨1, k + 3⟩ : Q).num := by show (0 : Int) < 1; decide
  have hbase := durrOp_dev_bound_le φ ((k + 3) * (k + 3) - 5) x h0 h1 (⟨1, k + 3⟩ : Q) hδd hδn
  rw [hp3] at hbase
  have hd1 : 0 < (mul (⟨1, k + 3⟩ : Q) (⟨1, k + 3⟩ : Q)).den := Qmul_den_pos hδd hδd
  have hd2 : 0 < (⟨1, (k + 3) * (k + 3) - 5 + 5⟩ : Q).den := Nat.succ_pos ((k + 3) * (k + 3) - 5 + 4)
  have hcollapse : Req
      (Rmul (ofQ φ.L φ.hLd)
        (Radd (ofQ (mul (⟨1, k + 3⟩ : Q) (⟨1, k + 3⟩ : Q)) hd1)
              (ofQ (⟨1, (k + 3) * (k + 3) - 5 + 5⟩ : Q) hd2)))
      (ofQ (mul φ.L (add (mul (⟨1, k + 3⟩ : Q) (⟨1, k + 3⟩ : Q))
              (⟨1, (k + 3) * (k + 3) - 5 + 5⟩ : Q)))
        (Qmul_den_pos φ.hLd (add_den_pos hd1 hd2))) :=
    Req_trans (Rmul_congr (Req_refl _) (Radd_ofQ_ofQ hd1 hd2))
      (Rmul_ofQ_ofQ φ.hLd (add_den_pos hd1 hd2))
  have hbound2 := Rle_trans hbase (Rle_of_Req hcollapse)
  have hcnum : (mul (⟨2, 1⟩ : Q) (⟨1, k + 3⟩ : Q)).num = ((2 : Nat) : Int) := by
    show ((2 : Int) * 1) = ((2 : Nat) : Int); decide
  have hdiv := Rle_of_Rmul_ofQ_le 2 (by decide) (Qmul_den_pos Nat.one_pos hδd) hcnum
    (Qmul_den_pos φ.hLd (add_den_pos hd1 hd2)) hbound2
  refine Rle_trans hdiv (Rle_of_Req (ofQ_congr _ (Qmul_den_pos φ.hLd (Nat.succ_pos (k + 2))) ?_))
  rw [hp5]
  simp only [Qeq, mul, add]
  push_cast
  ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
