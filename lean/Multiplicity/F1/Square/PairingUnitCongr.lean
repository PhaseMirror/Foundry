/-
F1 square — **the pre-Hilbert layer, brick 90** (`PairingUnitCongr.lean`): **THE `L²` PAIRING
FACTORS THROUGH `[0,1]`-RESTRICTION** — two tests that agree on `[0,1]` pair identically with
everything:

    `∀ x ∈ [0,1], φ(x) ≈ φ'(x)`   ⟹   `⟨φ, ψ⟩ ≈ ⟨φ', ψ⟩` for every `ψ`
      (`innerI_left_congr_on_unit`).

This is the immediate corollary of brick 89 (a test vanishing on `[0,1]` pairs to zero with
everything) through bilinearity: if `φ` and `φ'` agree on `[0,1]` then `φ − φ'` vanishes there, so
`⟨φ − φ', ψ⟩ ≈ 0`, and `innerI_sub_left` splits that into `⟨φ,ψ⟩ − ⟨φ',ψ⟩ ≈ 0`. By symmetry
(`innerI_symm`) the same holds in the right argument (`innerI_right_congr_on_unit`). Together with the
definiteness of brick 81, the `L²` pairing is therefore a genuine bilinear form on the `[0,1]`
equivalence classes of tests — it depends only on the restriction to `[0,1]`, in both arguments and
consistently with the metric.

HONEST SCOPE. Well-definedness of `⟨·,·⟩` on the `[0,1]`-restriction, both arguments. This is a
structural fact about the pairing, NOT the `L²`-function-space limit member (still open) and NOT the
moment problem. Nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.PairingUnitZero

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `Req (Rsub a b) zero → Req a b` (local copy of `ZeroGeometry`'s helper). -/
private theorem Req_of_Rsub_zero {a b : Real} (h : Req (Rsub a b) zero) : Req a b := by
  have h1 : Req a (Radd (Rsub a b) b) := by
    show Req a (Radd (Radd a (Rneg b)) b)
    refine Req_trans (Req_symm (Radd_zero a)) ?_
    have hz : Req zero (Radd (Rneg b) b) :=
      Req_symm (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b))
    exact Req_trans (Radd_congr (Req_refl a) hz) (Req_symm (Radd_assoc a (Rneg b) b))
  refine Req_trans h1 ?_
  exact Req_trans (Radd_congr h (Req_refl b)) (Req_trans (Radd_comm zero b) (Radd_zero b))

/-- **THE `L²` PAIRING FACTORS THROUGH `[0,1]`-RESTRICTION (left argument)**: tests agreeing on
    `[0,1]` pair identically with any `ψ`. -/
theorem innerI_left_congr_on_unit (φ φ' ψ : L2Test)
    (h : ∀ x, Rle zero x → Rle x one → Req (φ.f x) (φ'.f x)) :
    Req (innerI φ ψ) (innerI φ' ψ) := by
  have hvanish : ∀ x, Rle zero x → Rle x one → Req ((L2Test.sub φ φ').f x) zero :=
    fun x h0 h1 => Req_trans (Rsub_congr (h x h0 h1) (Req_refl (φ'.f x))) (Radd_neg (φ'.f x))
  exact Req_of_Rsub_zero
    (Req_trans (Req_symm (innerI_sub_left φ φ' ψ))
      (innerI_zero_of_left_unit_zero (L2Test.sub φ φ') ψ hvanish))

/-- **THE `L²` PAIRING FACTORS THROUGH `[0,1]`-RESTRICTION (right argument)**, by symmetry. -/
theorem innerI_right_congr_on_unit (φ ψ ψ' : L2Test)
    (h : ∀ x, Rle zero x → Rle x one → Req (ψ.f x) (ψ'.f x)) :
    Req (innerI φ ψ) (innerI φ ψ') :=
  Req_trans (innerI_symm φ ψ)
    (Req_trans (innerI_left_congr_on_unit ψ ψ' φ h) (innerI_symm ψ' φ))

end Multiplicity.UOR.Bridge.F1Square.Square
