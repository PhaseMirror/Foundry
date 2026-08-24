/-
F1 square — **the Durrmeyer operator reproduces constants** (`DurrmeyerConst.lean`), the
Mellin-inversion arc. The Bernstein–Durrmeyer operator `durrOp φ n x = (n+1)·Σ_k b_{n,k}(x)·⟨φ,b_{n,k}⟩`
carries the real coefficient of a *constant* test straight through its pairing action: for the constant
test `constTest c` (`f ≡ c`) the real-scalar pairing law pulls `c` out of every weight,
`⟨constTest c, b_{n,k}⟩ = c·⟨1, b_{n,k}⟩`, and the surviving sum is the `M_n⁽⁰⁾ = 1` normalization
(`durrOp_powTest_zero`). Hence

    `durrOp (constTest c) n x = c`   (`durrOp_constTest`),

the constant-reproduction / `M_n⁽⁰⁾`-scaling law: the Durrmeyer averaging operator fixes constants.

The per-weight identity `⟨constTest c, b_{n,k}⟩ = c·⟨1, b_{n,k}⟩` runs `innerI_symm` to move the constant
test to the right, `innerI_right_congr_on_unit` to rewrite `c ≈ c·1` on `[0,1]` (folding the constant into
`(constTest c)·1`), `innerI_constMul` (the real-scalar pairing law) to extract `c`, and `innerI_symm` back.
Pulling `c` out of the whole sum (`RsumN_Rmul_const`) and reordering (`Rmul` left-commute) exposes the bare
`durrOp 1 n x = 1`.

HONEST SCOPE. Constant reproduction only: `durrOp (constTest c) = c`, the `M_n⁽⁰⁾`-scaling of the Durrmeyer
operator. Infrastructure for the convergence reformulation (`T_n(x) = M_n⁽²⁾ − 2x·M_n⁽¹⁾ + x²`). NOT the
second central moment assembled/bounded, NOT convergence `durrOp φ n x → φ(x)`, NOT inversion, NOT
positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.DurrmeyerMomentSum
import Multiplicity.F1.Square.ConstScale
import Multiplicity.F1.Square.PairingUnitCongr
import Multiplicity.F1.Square.DurrmeyerLinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `a·(b·c) ≈ b·(a·c)` (real, left-commute) — local copy. -/
private theorem Rmul_lc (a b c : Real) : Req (Rmul a (Rmul b c)) (Rmul b (Rmul a c)) :=
  Req_trans (Req_symm (Rmul_assoc a b c))
    (Req_trans (Rmul_congr (Rmul_comm a b) (Req_refl c)) (Rmul_assoc b a c))

/-- **THE DURRMEYER OPERATOR REPRODUCES CONSTANTS** (`M_n⁽⁰⁾`-scaling): `durrOp (constTest c) n x = c`.
    Each weight `⟨constTest c, b_{n,k}⟩` factors as `c·⟨1, b_{n,k}⟩` by the real-scalar pairing law
    (`innerI_constMul`); pull `c` out of the sum (`RsumN_Rmul_const`), reorder, and collapse the bare
    `durrOp 1 n x = 1` (`durrOp_powTest_zero`), then `c·1 = c`. -/
theorem durrOp_constTest (c : Real) {mB : Q} (hMd : 0 < mB.den) (hMn : 0 ≤ mB.num)
    (hb : Rle (Rabs c) (ofQ mB hMd)) (n : Nat) (x : Real) :
    Req (durrOp (constTest c mB hMd hMn hb) n x) c := by
  show Req (Rmul (RofNat (n + 1))
      (RsumN (fun k => Rmul (bernR x n k)
        (innerI (constTest c mB hMd hMn hb) (bernBasisTest n k))) (n + 1))) c
  -- per-weight identity: `⟨constTest c, b_{n,k}⟩ ≈ c·⟨1, b_{n,k}⟩`
  have hterm : ∀ k, Req (innerI (constTest c mB hMd hMn hb) (bernBasisTest n k))
      (Rmul c (innerI (powTest 0) (bernBasisTest n k))) := by
    intro k
    refine Req_trans (innerI_symm (constTest c mB hMd hMn hb) (bernBasisTest n k)) ?_
    refine Req_trans (innerI_right_congr_on_unit (bernBasisTest n k) (constTest c mB hMd hMn hb)
      (L2Test.mul (constTest c mB hMd hMn hb) oneTest)
      (fun _ _ _ => Req_symm (Rmul_one c))) ?_
    refine Req_trans (innerI_constMul (bernBasisTest n k) oneTest c hMd hMn hb) ?_
    exact Rmul_congr (Req_refl c) (innerI_symm (bernBasisTest n k) oneTest)
  -- rewrite each summand to `c·(b_{n,k}·⟨1,b_{n,k}⟩)` and pull `c` out of the sum
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (n + 1) (fun k _ =>
        Req_trans (Rmul_congr (Req_refl (bernR x n k)) (hterm k))
          (Rmul_lc (bernR x n k) c (innerI (powTest 0) (bernBasisTest n k)))))
      (RsumN_Rmul_const c
        (fun k => Rmul (bernR x n k) (innerI (powTest 0) (bernBasisTest n k))) (n + 1)))) ?_
  -- `(n+1)·(c·S) ≈ c·((n+1)·S) = c·(durrOp 1 n x) ≈ c·1 ≈ c`
  refine Req_trans (Rmul_lc (RofNat (n + 1)) c
    (RsumN (fun k => Rmul (bernR x n k) (innerI (powTest 0) (bernBasisTest n k))) (n + 1))) ?_
  exact Req_trans (Rmul_congr (Req_refl c) (durrOp_powTest_zero n x)) (Rmul_one c)

/-- **THE DURRMEYER DEVIATION AS AN OPERATOR IMAGE**: `durrOp φ n x − φ(x) = durrOp (φ − φ(x)·1) n x`,
    where `φ(x)·1` is the constant test `constTest (φ.f x)` (bounded by `φ.M` via `φ.hbd x`). By linearity
    (`durrOp_sub`, J₅b) and constant reproduction (`durrOp_constTest`), so the pointwise deviation is the
    Durrmeyer image of the *residual* `ψ = φ − φ(x)·1`, which is Lipschitz-`L` and vanishes at `x`
    (`|ψ(t)| = |φ(t)−φ(x)| ≤ L|t−x|`) — exactly the object the convergence estimate consumes. -/
theorem durrOp_dev_eq (φ : L2Test) (n : Nat) (x : Real) :
    Req (durrOp (L2Test.sub φ (constTest (φ.f x) φ.M φ.hMd φ.hMn (φ.hbd x))) n x)
        (Rsub (durrOp φ n x) (φ.f x)) :=
  Req_trans (durrOp_sub φ (constTest (φ.f x) φ.M φ.hMd φ.hMn (φ.hbd x)) n x)
    (Rsub_congr (Req_refl _) (durrOp_constTest (φ.f x) φ.hMd φ.hMn (φ.hbd x) n x))

end Multiplicity.UOR.Bridge.F1Square.Square
