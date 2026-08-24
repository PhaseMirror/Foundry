/-
F1 square — **the pre-Hilbert layer, brick 113** (`ContinuousMomentNatExp.lean`): **the compact power at
the integer exponent `n` IS the clamped monomial** — `compactPow a (n·1) t ≈ (powTest n).f t = clamp01(t)ⁿ`
for every real `t ∈ [a,1]` and every `n` (`compactPow_natExpR_eq_powTest`), generalizing brick 106
(`s = 1`) to all integer exponents.

The exponent `n` as a real is `natExpR n = 1 + 1 + ⋯ + 1` (`n` ones). The identity is a clean induction:
at `0` the compact power is `1` (`compactPow_zero`), matching `(powTest 0).f = 1`; at `n+1` the power law
`compactPow_exp_add` (brick 99) splits `compactPow a (natExpR n + 1) t ≈ compactPow a (natExpR n) t ·
compactPow a 1 t`, the inductive hypothesis reads the first factor as `(powTest n).f t`, and brick 106
(`compactPow_one_eq_clamp`) reads the second as `clamp01 t = clampTest.f t` — whose product is exactly
`(powTest (n+1)).f t = clamp01(t)ⁿ⁺¹` by the `L2Test.mul` definition of `powTest`.

`natExpR n` is packaged with `natExpR_nonneg` (`≥ 0`) and `natExpR_eq_ofQ` (`≈ ofQ⟨n,1⟩`), the data the
continuous moment at exponent `n` consumes (`hs`, the rational bound `σ = ⟨n,1⟩`).

HONEST SCOPE. The integrand identity at the integer exponent `n` on `[a,1]` — the ingredient for
identifying the `a → 0` continuous moment with the integer Mellin moment beyond `s = 1`. NOT the limit
identification itself (later bricks), NOT the transform pair, NOT inversion. Step 4 is RH; crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ContinuousMomentClamp
import Multiplicity.F1.Square.ContinuousMomentAdd
import Multiplicity.F1.Square.ContinuousMomentZero

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The integer exponent `n` as a real**: `natExpR n = 1 + 1 + ⋯ + 1` (`n` ones). -/
def natExpR : Nat → Real
  | 0 => zero
  | n + 1 => Radd (natExpR n) one

/-- `natExpR n ≥ 0`. -/
theorem natExpR_nonneg : ∀ n : Nat, Rnonneg (natExpR n)
  | 0 => Rnonneg_zero
  | n + 1 => Rnonneg_Radd (natExpR_nonneg n) Rnonneg_one

/-- `natExpR n ≈ ofQ⟨n,1⟩` — the exponent is the rational `n`, so `σ = ⟨n,1⟩` bounds it exactly. -/
theorem natExpR_eq_ofQ : ∀ n : Nat, Req (natExpR n) (ofQ (⟨(n : Int), 1⟩ : Q) Nat.one_pos)
  | 0 => Req_of_seq_Qeq (fun _ => Qeq_refl _)
  | n + 1 => by
      refine Req_trans (Radd_congr (natExpR_eq_ofQ n) (Req_refl one)) ?_
      refine Req_trans (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos) ?_
      refine ofQ_congr Nat.one_pos Nat.one_pos ?_
      show Qeq (add (⟨(n : Int), 1⟩ : Q) (⟨1, 1⟩ : Q)) (⟨((n + 1 : Nat) : Int), 1⟩ : Q)
      simp only [Qeq, add]; push_cast; ring_uor

/-- **★ THE COMPACT POWER AT THE INTEGER EXPONENT IS THE CLAMPED MONOMIAL**:
    `compactPow a (natExpR n) t ≈ (powTest n).f t` for real `t ∈ [a,1]`, every `n`. Induction on `n`:
    base `compactPow_zero`, step power law (brick 99) + inductive hypothesis + brick 106. -/
theorem compactPow_natExpR_eq_powTest (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (ha1 : Qle a (⟨1, 1⟩ : Q)) (t : Real) (hlo : Rle (ofQ a had) t) (hhi : Rle t one) :
    ∀ n : Nat, Req (compactPow a han had (natExpR n) t) ((powTest n).f t)
  | 0 => compactPow_zero a han had t
  | n + 1 =>
      Req_trans (compactPow_exp_add a han had (natExpR n) one t)
        (Rmul_congr (compactPow_natExpR_eq_powTest a han had ha1 t hlo hhi n)
          (compactPow_one_eq_clamp a han had ha1 t hlo hhi))

end Multiplicity.UOR.Bridge.F1Square.Square
