/-
F1 square — **the reconstruction's HEAD test `Whead`** (`HeadTest.lean`): the `L2Test` whose window
value is `g(t)·clamp01(t)ⁿ·M[f]` (`M[f] = mellinHat f`), one of the two objects (`Whead`, `Tmom`) that
the `∫_t` reconstruction's `U = Whead − Tmom` is built from. `Tmom` is already the existing
`coupOuterTestSwap` (moment window); this file supplies the missing `Whead`.

WHY (grounding `v = ĝ`). `covConnect_at_clampedInv` identifies the tail commute's per-`t` integrand as
`g·max(t,a)ⁿ·M[f] − g·clampedInv·mellinMoment(dilate clampedInv f)` = `Whead.f t − Tmom.f t` (on the
window, `clamp01(t)ⁿ = max(t,a)ⁿ = tⁿ` when `a ≤ lo`). `Whead` is built from existing combinators:
`L2Test.mul (L2Test.mul g (powTest n)) (constTest M[f] …)`, with the constant `M[f]` carried by a
`constTest` whose rational modulus is `mellinHatIdBnd f n Cf` (`mellinHat_id_abs_le_ofQ`).

HONEST SCOPE. One test OBJECT plus its window-value identity. It assembles NO `U` (that is
`L2Test.sub Whead Tmom` + the `hU` proof), builds NO factorization `M[f⋆g]=M[f]·M[g]`, grounds NO
`v = ĝ`, and — emphatically — applies NO step-4 band-coupling positivity (`ArchDominatesPrime`), which is
RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MellinHatIdBound
import Multiplicity.F1.Square.DilateTestRDecay
import Multiplicity.F1.Square.BernsteinClampMatch
import Multiplicity.F1.Square.ConstScale
import Multiplicity.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `qGenSum` of termwise-nonneg summands is nonneg (re-derived; the `CovCombHbound` copy is private). -/
private theorem qGenSum_num_nonneg' (g : Nat → Q) (hg : ∀ i, 0 ≤ (g i).num) :
    ∀ N, 0 ≤ (qGenSum g N).num
  | 0 => by show (0 : Int) ≤ 0; exact Int.le_refl 0
  | (N + 1) => Qadd_num_nonneg_loc (qGenSum_num_nonneg' g hg N) (hg N)

/-- The rational modulus `mellinHatIdBnd f n C` has nonnegative numerator. -/
theorem mellinHatIdBnd_num (φ : L2Test) (n : Nat) (C : Q) : 0 ≤ (mellinHatIdBnd φ n C).num :=
  Qadd_num_nonneg_loc (Qmul_num_nonneg φ.hMn (by show (0 : Int) ≤ 1; decide))
    (Qadd_num_nonneg_loc
      (qGenSum_num_nonneg' _
        (fun m => Qmul_num_nonneg (by decide) (Qmul_num_nonneg φ.hMn (powWinTest m n).hMn)) _)
      (by decide))

/-- **The reconstruction's head test** `Whead.f t = g(t)·clamp01(t)ⁿ·M[f]`, `M[f] = mellinHat f n`.
    The constant `M[f]` is carried by a `constTest` at the rational modulus `mellinHatIdBnd f n Cf`
    (`mellinHat_id_abs_le_ofQ`); `M[f]` is read at the clean-to-window decay `hdec_window_of_hfdec`. -/
def headTest (f g : L2Test) (n : Nat) {Cf : Q} (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k))))) : L2Test :=
  L2Test.mul (L2Test.mul g (powTest n))
    (constTest (mellinHat f n hCfd hCfn (hdec_window_of_hfdec f n hCfd hCfn hfdec))
      (mellinHatIdBnd f n Cf) (mellinHatIdBnd_den f n Cf) (mellinHatIdBnd_num f n Cf)
      (mellinHat_id_abs_le_ofQ f n hCfd hCfn (hdec_window_of_hfdec f n hCfd hCfn hfdec)))

/-- **The head test's window value** `Whead.f t ≈ g(t)·clamp01(t)ⁿ·M[f]` — the `L2Test.mul` structure
    (definitional) with `(powTest n).f t` rewritten as `clamp01(t)ⁿ` by `powTest_f_eq`. -/
theorem headTest_f_eq (f g : L2Test) (n : Nat) {Cf : Q} (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k))))) (t : Real) :
    Req ((headTest f g n hCfd hCfn hfdec).f t)
        (Rmul (Rmul (g.f t) (Rpow (clamp01 t) n))
          (mellinHat f n hCfd hCfn (hdec_window_of_hfdec f n hCfd hCfn hfdec))) :=
  Rmul_congr (Rmul_congr (Req_refl (g.f t)) (powTest_f_eq t n)) (Req_refl _)

end Multiplicity.UOR.Bridge.F1Square.Square
