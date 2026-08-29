/-
F1 square — **the pre-Hilbert layer, brick 89** (`PairingUnitZero.lean`): **A TEST VANISHING ON
`[0,1]` PAIRS TO ZERO WITH EVERYTHING, AND THE PAIRING NULLITY SURVIVES `L²` COMPLETION** — the
pairing sees only `[0,1]`.

    `∀ x ∈ [0,1], φ(x) ≈ 0`   ⟹   `⟨φ, ψ⟩ ≈ 0` for every `ψ`   (`innerI_zero_of_left_unit_zero`)

and, for an `L²`-Cauchy sequence each of whose members vanishes on `[0,1]`, the extended pairing
value vanishes too (`pairingIU_zero_of_left_unit_zero`).

This generalizes brick 81's self-version (`innerI_self_zero_of_unit_zero`) from `⟨φ,φ⟩` to `⟨φ,ψ⟩`
against an arbitrary `ψ`: the certified `L²` integral `∫₀¹ φ·ψ` samples only the rational partition
points `i/(N+1) ∈ [0,1)`, where `φ` (hence `φ·ψ`) vanishes, so every Riemann sum is zero and the
integral is zero (`riemannIntegral_zero_of_partition_zero`, brick 81). At the completion level the
extended pairing `pairingIU` is a Bishop limit of such reads, so `Rlim_zero` carries the nullity
through. Together with brick 79 (`⟨φ,φ⟩ ≈ 0 ⟺ φ` vanishes on `[0,1]`), the pairing's left null space
is *exactly* the tests vanishing on `[0,1]`, consistently across the whole pairing and its completion.

HONEST SCOPE. Left-nullity from `[0,1]`-vanishing, and its stability under `L²` completion of the
*first* argument. This is a statement about tests that already vanish on `[0,1]`; it is NOT the
`L²`-function-space limit member (still open — no completed function is constructed here, only the
pairing values), and NOT the moment problem. Nothing here touches the Weil form. Step 4 is RH. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.L2DefiniteIff
import Foundations.F1.Square.L2Complete

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **A TEST VANISHING ON `[0,1]` PAIRS TO ZERO WITH EVERYTHING**: `⟨φ, ψ⟩ = ∫₀¹ φ·ψ ≈ 0` when `φ`
    vanishes at every point of `[0,1]` — the integrand vanishes at every partition point. -/
theorem innerI_zero_of_left_unit_zero (φ ψ : L2Test)
    (hφ : ∀ x, Rle zero x → Rle x one → Req (φ.f x) zero) :
    Req (innerI φ ψ) zero := by
  refine riemannIntegral_zero_of_partition_zero (l2L_den φ ψ) (l2L_num φ ψ)
    (l2lip φ ψ) (l2fc φ ψ) ?_
  intro N i hi
  have hpt : Req (φ.f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) zero := by
    refine hφ _ ?_ ?_
    · exact Rle_ofQ_ofQ (by decide) (Nat.succ_pos N) (by simp only [Qle]; omega)
    · exact Rle_ofQ_ofQ (Nat.succ_pos N) (by decide) (by simp only [Qle]; omega)
  exact Req_trans (Rmul_congr hpt (Req_refl _))
    (Req_trans (Rmul_comm zero _) (Rmul_zero _))

/-- **THE PAIRING NULLITY SURVIVES `L²` COMPLETION**: an `L²`-Cauchy sequence each of whose members
    vanishes on `[0,1]` has vanishing extended pairing against every `ψ`. -/
theorem pairingIU_zero_of_left_unit_zero (Φ : Nat → L2Test) (h : L2CauchyU Φ) (ψ : L2Test)
    (hΦ : ∀ j : Nat, ∀ x, Rle zero x → Rle x one → Req ((Φ j).f x) zero) :
    Req (pairingIU Φ ψ h) zero :=
  Rlim_zero _ _ (fun j => innerI_zero_of_left_unit_zero (Φ (selfBnd ψ * (j + 1))) ψ
    (fun x => hΦ (selfBnd ψ * (j + 1)) x))

end Multiplicity.UOR.Bridge.F1Square.Square
