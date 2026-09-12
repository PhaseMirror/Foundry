/-
F1 square — **uniform convergence of the Bernstein operator-as-test** (`BernsteinUniform.lean`), the
Bernstein arc, sub-brick L₁. The operator test `bernOpCTest φ n` (H₄, an honest `L2Test` agreeing with
`B_n(φ)` on `[0,1]`) converges to `φ` *uniformly on `[0,1]`* with a rational rate:

  `|φ(x) − (bernOpCTest φ ((k+1)²) …).f x| ≤ 5·φ.L / (8(k+1))`   for every `x ∈ [0,1]`.

The rate is INDEPENDENT of `x` — a genuine constructive Weierstrass approximation theorem for the
bounded-Lipschitz class, with `bernOpCTest φ n` a polynomial on `[0,1]`. Assembly, from bricks in hand:

- `bernOpCTest_pointwise_dev` (H₅): `|φ(x) − B_n(x)| ≤ φ.L · Σ_k |k/n − x|·b_{n,k}(x)` on `[0,1]`;
- `bernOp_devsum_bound` (H₆): `2δn · Σ_k |k/n − x|·b_{n,k}(x) ≤ δ² + n/4` on `[0,1]`, any `δ > 0`;
- at `δ = k+1`, `n = (k+1)²` the deviation sum is `≤ (5/4)(k+1)² / (2(k+1)³) = 5/(8(k+1))` (division by
  `Rle_of_Rmul_ofQ_le`), so scaling by `φ.L` gives the uniform rate.

WHY (the Sonine route, step 3, the completed L² space). Uniform convergence of the Bernstein
polynomials is the constructive Weierstrass theorem; its L² corollary (next sub-brick) is that the
polynomials are DENSE in `L²[0,1]` — the first handle on the completed function space the Mellin front
left open. This is the *approximation* companion of moment determinacy (the injectivity half).

HONEST SCOPE. Uniform (sup-norm) convergence of one polynomial approximation scheme to a
bounded-Lipschitz test on `[0,1]`, over `Real`, with an explicit rational rate. NOT L² density (next
sub-brick), NOT surjectivity onto function space, NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.BernsteinDeviationTransfer
import Foundations.F1.Square.BernsteinDevBound
import Foundations.F1.Square.MomentDeterminacy

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **UNIFORM (WEIERSTRASS) CONVERGENCE**: on `[0,1]`, the Bernstein operator-as-test converges to `φ`
    with an `x`-independent rational rate, `|φ(x) − (bernOpCTest φ ((k+1)²) …).f x| ≤ 5·φ.L / (8(k+1))`.
    Combine the pointwise deviation transfer (H₅) with the AM-GM deviation-sum bound (H₆) at the
    schedule `δ = k+1`, `n = (k+1)²`, and divide the sum out (`Rle_of_Rmul_ofQ_le`). -/
theorem bernOp_uniform_converges (φ : L2Test) {x : Real} (h0 : Rle zero x) (h1 : Rle x one) (k : Nat) :
    Rle (Rabs (Rsub (φ.f x)
          ((bernOpCTest φ ((k + 1) * (k + 1))
            (Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k))).f x)))
        (ofQ (mul φ.L (⟨5, 8 * (k + 1)⟩ : Q))
          (Qmul_den_pos φ.hLd (Nat.mul_pos (by decide) (Nat.succ_pos k)))) := by
  have hkk : 0 < (k + 1) * (k + 1) := Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k)
  -- H₅: pointwise deviation, |φ − B_n| ≤ φ.L · devsum
  have hdev := bernOpCTest_pointwise_dev φ ((k + 1) * (k + 1)) hkk h0 h1
  -- H₆: multiplied AM-GM bound at δ = k+1
  have hδd : 0 < (⟨(k + 1 : Int), 1⟩ : Q).den := Nat.one_pos
  have hdb := bernOp_devsum_bound ((k + 1) * (k + 1)) hkk h0 h1 (⟨(k + 1 : Int), 1⟩ : Q) hδd
  -- divide the deviation sum out: devsum ≤ 5/(8(k+1))
  have hR : 0 < 2 * (k + 1) * ((k + 1) * (k + 1)) :=
    Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos k)) hkk
  have hcnum : (mul (mul (⟨2, 1⟩ : Q) (⟨(k + 1 : Int), 1⟩ : Q)) (⟨((k + 1) * (k + 1) : Int), 1⟩ : Q)).num
      = ((2 * (k + 1) * ((k + 1) * (k + 1)) : Nat) : Int) := by
    simp only [mul]; push_cast; ring_uor
  have hBd : 0 < (add (mul (⟨(k + 1 : Int), 1⟩ : Q) (⟨(k + 1 : Int), 1⟩ : Q))
      (⟨((k + 1) * (k + 1) : Int), 4⟩ : Q)).den :=
    add_den_pos (Qmul_den_pos hδd hδd) (by show (0 : Nat) < 4; decide)
  have hcd : 0 < (mul (mul (⟨2, 1⟩ : Q) (⟨(k + 1 : Int), 1⟩ : Q))
      (⟨((k + 1) * (k + 1) : Int), 1⟩ : Q)).den :=
    Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos
  have hdiv := Rle_of_Rmul_ofQ_le (2 * (k + 1) * ((k + 1) * (k + 1))) hR hcd hcnum hBd hdb
  -- the divided bound equals 5/(8(k+1))
  have h8d : 0 < (⟨5, 8 * (k + 1)⟩ : Q).den := Nat.mul_pos (by decide) (Nat.succ_pos k)
  have hqeq : Qeq (mul (⟨((mul (mul (⟨2, 1⟩ : Q) (⟨(k + 1 : Int), 1⟩ : Q))
        (⟨((k + 1) * (k + 1) : Int), 1⟩ : Q)).den : Int), 2 * (k + 1) * ((k + 1) * (k + 1))⟩ : Q)
      (add (mul (⟨(k + 1 : Int), 1⟩ : Q) (⟨(k + 1 : Int), 1⟩ : Q))
        (⟨((k + 1) * (k + 1) : Int), 4⟩ : Q)))
      (⟨5, 8 * (k + 1)⟩ : Q) := by
    simp only [Qeq, mul, add]; push_cast; ring_uor
  have hSbound := Rle_trans hdiv (Rle_of_Req (ofQ_congr _ h8d hqeq))
  -- scale by φ.L ≥ 0 and collapse the ofQ product
  refine Rle_trans hdev (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ φ.hLd φ.hLn) hSbound)
    (Rle_of_Req (Rmul_ofQ_ofQ φ.hLd h8d)))

end Multiplicity.UOR.Bridge.F1Square.Square
