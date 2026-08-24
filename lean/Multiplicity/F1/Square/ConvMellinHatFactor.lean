/-
F1 square — **the convolution factorization on the window: `convMellinHat = M[f]·(moment of g)`**
(`ConvMellinHatFactor.lean`): the readoff completed. `convMellinHat = ∫_t Whead`
(`convMellinHat_eq_intWhead`) and `Whead = (g·powTest n)·constTest M[f]`, so pulling the constant
`M[f]` out of the integral (`riemannIntegralI_mulConstTest_right`) gives

    `convMellinHat f g n  =  M[f] · ∫_t (g·tⁿ) dt`   (`M[f] = mellinHat f`),

the convolution theorem `M[f⋆g] = M[f]·M[g]` on the window `[lo, lo+w] ⊆ (0,1]` (`a ≤ lo`), with `M[g]`
the compact `∫_t g·tⁿ` (`= mellinMoment g n` when the window is `[0,1]`).

WHY (grounding `v = ĝ`). This is the readoff the whole `∫_t` reconstruction was built for: the Mellin
transform of `f⋆g` FACTORS as `M[f]` times a moment of `g`. At prime powers this is what turns the
`mulConv` values into `weilPrimeGram (vFrom g)` — the genuine autocorrelation prime side the step-4
coupling positivity (`ArchDominatesPrime`) is about. The transform bridge's Wall 3 is complete.

HONEST SCOPE. The on-window factorization. It grounds `v = ĝ` at the value level here; it does NOT
assemble the coupled kernel, does NOT prove step-4 band-coupling positivity (`ArchDominatesPrime`),
which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ConvMellinHatIntWhead
import Multiplicity.F1.Square.ConstMulRight
import Multiplicity.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The convolution's Mellin transform factors on the window.** `convMellinHat f g n = M[f]·∫_t(g·tⁿ)`,
    `M[f] = mellinHat f`, the compact-window form of `M[f⋆g] = M[f]·M[g]`. Composes
    `convMellinHat_eq_intWhead` (`= ∫_t Whead`) with `riemannIntegralI_mulConstTest_right` (the constant
    `M[f]` — `Whead`'s outer-right `constTest` factor — pulls out of the integral). -/
theorem convMellinHat_eq_MfMoment (f g : L2Test) (n : Nat) {Cf : Q}
    (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q)) (halo : Qle a lo) :
    Req (convMellinHat f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1)
        (Rmul (mellinHat f n hCfd hCfn (hdec_window_of_hfdec f n hCfd hCfn hfdec))
          (riemannIntegralI (L2Test.mul g (powTest n)).hLd (L2Test.mul g (powTest n)).hLn
            (L2Test.mul g (powTest n)).hlip (L2Test.mul g (powTest n)).hfc lo w hlo hw hwn)) :=
  Req_trans (convMellinHat_eq_intWhead f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1 halo)
    (riemannIntegralI_mulConstTest_right
      (mellinHat f n hCfd hCfn (hdec_window_of_hfdec f n hCfd hCfn hfdec))
      (mellinHatIdBnd_den f n Cf) (mellinHatIdBnd_num f n Cf)
      (mellinHat_id_abs_le_ofQ f n hCfd hCfn (hdec_window_of_hfdec f n hCfd hCfn hfdec))
      (L2Test.mul g (powTest n)) lo w hlo hw hwn)

end Multiplicity.UOR.Bridge.F1Square.Square
