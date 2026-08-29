/-
F1 square — **the pre-Hilbert layer, brick 92** (`PairingIUCongr.lean`): **THE EXTENDED PAIRING IS
WELL-DEFINED ON `[0,1]`-CLASSES AT THE COMPLETION LEVEL** — the `[0,1]`-restriction well-definedness
of bricks 89–91 survives the `L²`-completion of the first argument:

    `∀ j, Φⱼ ≈ Φ'ⱼ on [0,1]`   ⟹   `pairingIU Φ ψ h ≈ pairingIU Φ' ψ h'`   (`pairingIU_congr_on_unit`).

`pairingIU` is a Bishop limit of rescaled reads `⟨Φ_{c(j+1)}, ψ⟩`; brick 90's left congruence
(`innerI_left_congr_on_unit`) makes each read invariant under `[0,1]`-agreement, and `Rlim_congr`
carries that through the limit. So the extended pairing on `L²`-Cauchy sequences depends only on the
`[0,1]`-restrictions of the members — the `[0,1]`-quotient structure (bricks 89–91: the pairing and
its metric factor through `[0,1]`) is stable under completion, closing the `[0,1]`-restriction thread.

HONEST SCOPE. Well-definedness of the *extended pairing values* on `[0,1]`-classes of `L²`-Cauchy
sequences. This does NOT construct the `L²`-function-space limit member (still open — only the
pairing values are limits here), and it is NOT the moment problem. Nothing here touches the Weil
form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.PairingUnitCongr

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **THE EXTENDED PAIRING IS WELL-DEFINED ON `[0,1]`-CLASSES**: two `L²`-Cauchy sequences whose
    members agree on `[0,1]` have equal extended pairing against every `ψ`. -/
theorem pairingIU_congr_on_unit (Φ Φ' : Nat → L2Test) (h : L2CauchyU Φ) (h' : L2CauchyU Φ')
    (ψ : L2Test)
    (hΦ : ∀ j : Nat, ∀ x, Rle zero x → Rle x one → Req ((Φ j).f x) ((Φ' j).f x)) :
    Req (pairingIU Φ ψ h) (pairingIU Φ' ψ h') :=
  Rlim_congr _ _ (pairingIU_RReg h ψ) (pairingIU_RReg h' ψ)
    (fun j => innerI_left_congr_on_unit (Φ (selfBnd ψ * (j + 1))) (Φ' (selfBnd ψ * (j + 1))) ψ
      (fun x h0 h1 => hΦ (selfBnd ψ * (j + 1)) x h0 h1))

end Multiplicity.UOR.Bridge.F1Square.Square
