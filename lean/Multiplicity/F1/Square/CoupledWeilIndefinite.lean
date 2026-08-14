/-
F1 square — **the indefinite-arch obstruction, kernel-checked** (`CoupledWeilIndefinite.lean`): the
kernel-checked result behind the coupled kernel's honest scope — if the archimedean multiplier has ANY negative
entry, `ArchDominatesPrime` over ALL tests is FALSE, hence the coupled kernel is NOT `WeilPSD`. So the
capstone `coupledWeil_psd_iff_dominates`'s "= RH" reading holds only under the (unbuilt) Sonine-space
test restriction — over the whole space, for the genuine indefinite arch (`α(2) < 0`,
`burnol_pairing_indefinite`), it is simply false.

The witness is the coordinate indicator `δ_k` at a negative-arch index `k`: the arch energy there is
`arch(k) < 0`, while the prime energy `Σ_m w(m)·v(m,k)²` is `≥ 0` (weights `≥ 0`), so the prime energy
exceeds the arch energy and `ArchDominatesPrime` fails at that single test.

  • `archDominatesPrime_false_of_neg_arch` — `¬ Rnonneg (arch k)` (some `k < N`) ⟹ `¬ ArchDominatesPrime`.
  • `coupledWeil_not_psd_of_neg_arch` — hence `¬ WeilPSD (coupledWeil …)` (via `coupledWeil_psd_iff_dominates`).

HONEST SCOPE. This is a NEGATIVE structural result — it does NOT close the crux; it PROVES that closing
it cannot proceed by raw whole-space dominance and MUST use the co-support (Sonine) restriction that
cancels the arch-negative band. It turns the program's standing honesty caveat ("= RH only under the
restriction") into a kernel-checked fact. Crux stays `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.CoupledWeilKernel

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The indefinite-arch obstruction**: if `arch(k)` is negative (`¬ Rnonneg`) at some `k < N`, then
    `ArchDominatesPrime` fails — the indicator `δ_k` gives arch energy `arch(k) < 0` below the
    nonnegative prime energy. -/
theorem archDominatesPrime_false_of_neg_arch (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (k N : Nat) (hkN : k < N) (hw : ∀ m, Rnonneg (w m)) (harch : ¬ Rnonneg (arch k)) :
    ¬ ArchDominatesPrime arch w v M := by
  intro h
  apply harch
  have hle : Rle (weilQuad (primeGram w v M) (indic k) N) (weilQuad (multForm arch) (indic k) N) :=
    h N (indic k)
  have hprime : Rnonneg (weilQuad (primeGram w v M) (indic k) N) :=
    WeilPSD_primeGram w v M hw N (indic k)
  have harchval : Req (weilQuad (multForm arch) (indic k) N) (arch k) := by
    refine Req_trans (weilQuad_multForm arch (indic k) N) ?_
    refine Req_trans (RsumN_indic_mul k (fun i => Rmul (indic k i) (arch i)) N hkN) ?_
    show Req (Rmul (indic k k) (arch k)) (arch k)
    rw [indic_eq_one]
    exact Req_trans (Rmul_comm one (arch k)) (Rmul_one (arch k))
  exact Rnonneg_of_Rle_zero
    (Rle_trans (Rle_zero_of_Rnonneg hprime) (Rle_trans hle (Rle_of_Req harchval)))

/-- **Hence the coupled kernel is not `WeilPSD`** when the arch multiplier has a negative entry — the
    kernel-checked reason the capstone's "= RH" needs the Sonine-space restriction. -/
theorem coupledWeil_not_psd_of_neg_arch (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (k N : Nat) (hkN : k < N) (hw : ∀ m, Rnonneg (w m)) (harch : ¬ Rnonneg (arch k)) :
    ¬ WeilPSD (coupledWeil arch w v M) := by
  intro hpsd
  exact archDominatesPrime_false_of_neg_arch arch w v M k N hkN hw harch
    ((coupledWeil_psd_iff_dominates arch w v M).mp hpsd)

end Multiplicity.UOR.Bridge.F1Square.Square
