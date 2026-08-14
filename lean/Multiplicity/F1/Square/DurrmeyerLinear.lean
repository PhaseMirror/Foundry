/-
F1 square — **linearity of the Bernstein–Durrmeyer operator** (`DurrmeyerLinear.lean`), the
Mellin-inversion arc. The Durrmeyer operator

    `durrOp φ n x = (n+1)·Σ_{k=0}^n b_{n,k}(x)·⟨φ, b_{n,k}⟩`

is linear in its test argument `φ`, because the L² pairing `⟨·, b_{n,k}⟩` is additive/subtractive in
its first slot (`innerI_add_left`, `innerI_sub_left`), the Bernstein weight `b_{n,k}(x)` distributes over
the resulting sum/difference (`Rmul_distrib`, `Rmul_sub_distrib`), the finite sum splits (`RsumN_Radd`,
`RsumN_Rsub`), and the scalar `(n+1)` pulls back through:

    `durrOp (φ + ψ) n x = durrOp φ n x + durrOp ψ n x`   (`durrOp_add`),
    `durrOp (φ − ψ) n x = durrOp φ n x − durrOp ψ n x`   (`durrOp_sub`).

WHY (the Sonine route, step 3, the Mellin FRONT). Linearity of `durrOp` in `φ` is the algebraic
housekeeping the pointwise-convergence capstone (J₅) needs: it lets the deviation `durrOp φ n x − φ(x)`
be split test-by-test and re-assembled. It is a structural fact about the operator, nothing more.

HONEST SCOPE. `durrOp (φ ± ψ) = durrOp φ ± durrOp ψ`, over `Real`. Infrastructure for the convergence
step; NOT the normalization/second-moment estimate, NOT convergence `durrOp φ n x → φ(x)`, NOT inversion,
NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MomentDurrmeyer
import Multiplicity.F1Square.Square.PairingLimitI

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **THE DURRMEYER OPERATOR IS ADDITIVE IN ITS TEST**: `durrOp (φ + ψ) n x = durrOp φ n x + durrOp ψ n x`.
    Termwise the pairing is additive in the first slot (`innerI_add_left`) and the Bernstein weight
    distributes (`Rmul_distrib`); the finite sum splits (`RsumN_Radd`) and the `(n+1)` scalar pulls
    back through (`Rmul_distrib`). -/
theorem durrOp_add (φ ψ : L2Test) (n : Nat) (x : Real) :
    Req (durrOp (L2Test.add φ ψ) n x) (Radd (durrOp φ n x) (durrOp ψ n x)) := by
  show Req (Rmul (RofNat (n + 1))
      (RsumN (fun k => Rmul (bernR x n k) (innerI (L2Test.add φ ψ) (bernBasisTest n k))) (n + 1)))
      (Radd (durrOp φ n x) (durrOp ψ n x))
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (n + 1) (fun k _ =>
        Req_trans (Rmul_congr (Req_refl _) (innerI_add_left φ ψ (bernBasisTest n k)))
          (Rmul_distrib (bernR x n k)
            (innerI φ (bernBasisTest n k)) (innerI ψ (bernBasisTest n k)))))
      (RsumN_Radd (fun k => Rmul (bernR x n k) (innerI φ (bernBasisTest n k)))
        (fun k => Rmul (bernR x n k) (innerI ψ (bernBasisTest n k))) (n + 1)))) ?_
  exact Rmul_distrib (RofNat (n + 1))
    (RsumN (fun k => Rmul (bernR x n k) (innerI φ (bernBasisTest n k))) (n + 1))
    (RsumN (fun k => Rmul (bernR x n k) (innerI ψ (bernBasisTest n k))) (n + 1))

/-- **THE DURRMEYER OPERATOR IS SUBTRACTIVE IN ITS TEST**: `durrOp (φ − ψ) n x = durrOp φ n x − durrOp ψ n x`.
    Termwise the pairing subtracts in the first slot (`innerI_sub_left`) and the Bernstein weight
    distributes over the difference (`Rmul_sub_distrib`); the finite sum splits (`RsumN_Rsub`) and the
    `(n+1)` scalar pulls back through (`Rmul_sub_distrib`). -/
theorem durrOp_sub (φ ψ : L2Test) (n : Nat) (x : Real) :
    Req (durrOp (L2Test.sub φ ψ) n x) (Rsub (durrOp φ n x) (durrOp ψ n x)) := by
  show Req (Rmul (RofNat (n + 1))
      (RsumN (fun k => Rmul (bernR x n k) (innerI (L2Test.sub φ ψ) (bernBasisTest n k))) (n + 1)))
      (Rsub (durrOp φ n x) (durrOp ψ n x))
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (RsumN_congr (n + 1) (fun k _ =>
        Req_trans (Rmul_congr (Req_refl _) (innerI_sub_left φ ψ (bernBasisTest n k)))
          (Rmul_sub_distrib (bernR x n k)
            (innerI φ (bernBasisTest n k)) (innerI ψ (bernBasisTest n k)))))
      (RsumN_Rsub (fun k => Rmul (bernR x n k) (innerI φ (bernBasisTest n k)))
        (fun k => Rmul (bernR x n k) (innerI ψ (bernBasisTest n k))) (n + 1)))) ?_
  exact Rmul_sub_distrib (RofNat (n + 1))
    (RsumN (fun k => Rmul (bernR x n k) (innerI φ (bernBasisTest n k))) (n + 1))
    (RsumN (fun k => Rmul (bernR x n k) (innerI ψ (bernBasisTest n k))) (n + 1))

end Multiplicity.UOR.Bridge.F1Square.Square
