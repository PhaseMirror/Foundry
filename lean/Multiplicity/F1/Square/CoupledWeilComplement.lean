/-
F1 square — **the complement projection does not rescue the coupled kernel** (`CoupledWeilComplement.lean`):
the kernel-checked answer, for the off-diagonal coupled kernel, to the program doc's central question —
does the unconditional complement-positivity of the DIAGONAL multiplier form extend? It does NOT.

`multForm_psd_on_complement` (SonineProjection.lean) is UNCONDITIONAL: a test `c` vanishing on the
archimedean negative band gives `weilQuad (multForm arch) c N ≥ 0`, no RH — the Sonine-support skeleton.
But the coupled kernel SUBTRACTS the prime Gram, and the prime Gram is itself PSD (for `w ≥ 0`), so on
the complement the coupled form is

    `weilQuad (coupledWeil arch w v M) c N = (arch complement energy ≥ 0) − (prime energy ≥ 0)`

— a difference of two nonnegative quantities, sign UNDETERMINED. The complement projection kills the
archimedean negative band but leaves the subtracted prime energy untouched; positivity there still
requires the prime energy to be dominated by the (now nonnegative) arch energy. This is the doc's
SECOND dichotomy branch, kernel-checked: the skeleton's unconditional positivity does not carry to the
whole (coupled) form — that carrying is step 4 = RH.

THE LAWS (all genuine, kernel-checked):
  • `coupledWeil_complement_signed` — on the complement (and `w ≥ 0`) the coupled form is `A − P` with
    `A = weilQuad (multForm arch) c N ≥ 0` and `P = weilQuad (primeGram w v M) c N ≥ 0` (both nonneg;
    the split holds; sign of the difference undetermined).
  • `coupledWeil_complement_lower` — hence the coupled form on the complement is bounded below by
    `−P` (NOT by `0`): `Rle (Rneg P) (weilQuad (coupledWeil …) c N)` — the genuine negative gap the
    subtracted prime leaves.
  • `coupledWeil_complement_psd_iff` — on the complement, coupled positivity ⟺ the prime energy is
    dominated by the (nonnegative) arch energy: `Rnonneg (weilQuad (coupledWeil …) c N) ⟺ P ≤ A`.

HONEST SCOPE. Pure sign/algebra on the assembled object; abstract over interface data `arch, w, v`
(`w ≥ 0`; the von Mangoldt case is unconditional). NOTHING asserts the coupled form is positive OR
indefinite at any genuine data — these laws only exhibit the two nonnegative pieces and locate the
residual (prime dominance) that the complement projection does not discharge. Crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.CoupledWeilMono

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **On the complement the coupled form is `A − P`, both nonnegative**: for a test `c` vanishing on
    the archimedean negative band (`∀ i < N, arch i ≥ 0 ∨ c i = 0`) and nonnegative weights, the arch
    energy `A ≥ 0` (`multForm_psd_on_complement`), the prime energy `P ≥ 0` (`WeilPSD_primeGram`), and
    the coupled form is their difference — sign undetermined. -/
theorem coupledWeil_complement_signed (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (c : Nat → Real) (N : Nat)
    (hc : ∀ i, i < N → Rnonneg (arch i) ∨ Req (c i) zero) (hw : ∀ m, Rnonneg (w m)) :
    Rnonneg (weilQuad (multForm arch) c N)
      ∧ Rnonneg (weilQuad (primeGram w v M) c N)
      ∧ Req (weilQuad (coupledWeil arch w v M) c N)
            (Rsub (weilQuad (multForm arch) c N) (weilQuad (primeGram w v M) c N)) :=
  ⟨multForm_psd_on_complement arch c N hc,
   WeilPSD_primeGram w v M hw N c,
   coupledWeil_quad_split arch w v M c N⟩

/-- **The complement gives only a `−P` lower bound, not `0`**: on the complement the coupled form is
    `≥ −(prime energy)` — the genuine negative gap the subtracted prime leaves. (`A − P ≥ −P` since
    `A ≥ 0`; the complement projection does NOT force positivity.) -/
theorem coupledWeil_complement_lower (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (c : Nat → Real) (N : Nat)
    (hc : ∀ i, i < N → Rnonneg (arch i) ∨ Req (c i) zero) :
    Rle (Rneg (weilQuad (primeGram w v M) c N)) (weilQuad (coupledWeil arch w v M) c N) := by
  have hA : Rnonneg (weilQuad (multForm arch) c N) := multForm_psd_on_complement arch c N hc
  refine Rle_trans (Rle_self_Radd_left hA)
    (Rle_of_Req (Req_symm (coupledWeil_quad_split arch w v M c N)))

/-- **On the complement, positivity ⟺ prime dominated by the (nonnegative) arch energy**: the residual
    content the complement projection does not discharge — `Rnonneg (weilQuad (coupledWeil …) c N) ⟺
    weilQuad (primeGram …) c N ≤ weilQuad (multForm arch) c N`, and by `coupledWeil_complement_signed`
    the right side is a nonnegative quantity dominating the (nonnegative) prime energy. -/
theorem coupledWeil_complement_psd_iff (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (c : Nat → Real) (N : Nat) :
    Rnonneg (weilQuad (coupledWeil arch w v M) c N)
      ↔ Rle (weilQuad (primeGram w v M) c N) (weilQuad (multForm arch) c N) :=
  coupledWeil_quad_nonneg_iff arch w v M c N

end Multiplicity.UOR.Bridge.F1Square.Square
