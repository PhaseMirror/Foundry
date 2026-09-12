/-
F1 square — **the convolution's Mellin transform is the head integral: `convMellinHat = ∫_t Whead`**
(`ConvMellinHatIntWhead.lean`): the moment/tail sides assembled and `Tmom` cancelled. By definition
`convMellinHat = mellinMoment(mulConv) + convTwTail`; the moment side is `∫_t Tmom`
(`mellinMoment_mulConv_dilated`) and the tail side is `∫_t (Whead − Tmom)` (`convTwTail_eq_intU`), so

    `convMellinHat = ∫_t Tmom + (∫_t Whead − ∫_t Tmom) = ∫_t Whead`.

WHY (grounding `v = ĝ`). This is the readoff the reconstruction was built for: the moment `Tmom` term
appears with opposite signs in the two branches and cancels, leaving the pure head integral. Since
`Whead.f t = g·max(t,a)ⁿ·M[f]` factors the constant `M[f] = mellinHat f`, `∫_t Whead = M[f]·∫_t (g·tⁿ)`
— the convolution theorem `M[f⋆g] = M[f]·(compact moment of g)` on the window (`a ≤ lo`), one scalar
pullout away.

HONEST SCOPE. The `Tmom`-cancellation readoff — `convMellinHat = ∫_t Whead`. It does NOT yet pull the
constant `M[f]` out of `∫_t Whead` (that is `innerI_constMul`/`riemannIntegralI` scalar pullout, the last
step), builds NO factorization `M[f⋆g]=M[f]·M[g]` in closed form, grounds NO `v = ĝ`, and —
emphatically — applies NO step-4 band-coupling positivity (`ArchDominatesPrime`), which is RH. The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ConvTwTailIntU
import Foundations.F1.Square.IntervalAddTest
import Foundations.F1.Square.IntegralDist
import Foundations.F1.Square.MellinLinear
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- `b + (a + (−b)) ≈ a` — the moment cancellation shape. -/
private theorem Radd_cancel_mid (a b : Real) : Req (Radd b (Radd a (Rneg b))) a :=
  Req_trans (Radd_congr (Req_refl b) (Radd_comm a (Rneg b)))
    (Req_trans (Req_symm (Radd_assoc b (Rneg b) a))
      (Req_trans (Radd_congr (Radd_neg b) (Req_refl a))
        (Req_trans (Radd_comm zero a) (Radd_zero a))))

/-- **`convMellinHat = ∫_t Whead`.** The moment side `mellinMoment(mulConv) = ∫_t Tmom` and the tail side
    `convTwTail = ∫_t (Whead − Tmom)` (both over the window `[lo, lo+w]`); their sum cancels the `Tmom`
    integral, leaving the head integral. `Tmom = coupOuterTestSwap f g (powTest n) …`, `Whead =
    headTest f g n …`. -/
theorem convMellinHat_eq_intWhead (f g : L2Test) (n : Nat) {Cf : Q}
    (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q)) (halo : Qle a lo) :
    Req (convMellinHat f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1)
        (riemannIntegralI (headTest f g n hCfd hCfn hfdec).hLd
          (headTest f g n hCfd hCfn hfdec).hLn (headTest f g n hCfd hCfn hfdec).hlip
          (headTest f g n hCfd hCfn hfdec).hfc lo w hlo hw hwn) := by
  -- Moment side at `Tmom`'s STANDARD certificates: `mellinMoment(mulConv) = ∫_t Tmom`, taken through
  -- `mellinConv_fubini` (whose output carries `coupOuterTestSwap`'s own witnesses) and STOPPING before
  -- `mellinMoment_mulConv_dilated`'s `mom_ptw` rewrite — so this `∫Tmom` is syntactically the tail-side
  -- one and cancels it.
  have hmomstd : Req (mellinMoment (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide)
        a han had lo w hlo hw hwn) n)
      (riemannIntegralI
        (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLd
        (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hLn
        (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hlip
        (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)).hfc
        lo w hlo hw hwn) :=
    Req_trans (Req_symm (riemannIntegralI_unit
        (l2L_den (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had lo w hlo hw hwn)
          (powTest n))
        (l2L_num (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had lo w hlo hw hwn)
          (powTest n))
        (l2lip (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had lo w hlo hw hwn)
          (powTest n))
        (l2fc (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had lo w hlo hw hwn)
          (powTest n))))
      (mellinConv_fubini f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
        lo w hlo hw hwn (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
  -- `convMellinHat = mellinMoment(mulConv) + convTwTail` (definitional); rewrite both branches.
  refine Req_trans (Radd_congr hmomstd
    (convTwTail_eq_intU f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1 halo)) ?_
  -- `∫_t (Whead − Tmom) = ∫_t Whead − ∫_t Tmom`, then cancel the (now identical) `∫Tmom`.
  refine Req_trans (Radd_congr (Req_refl _)
    (Req_trans (riemannIntegralI_addTest (headTest f g n hCfd hCfn hfdec)
        (L2Test.neg (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) a han had
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))) lo w hlo hw hwn)
      (Radd_congr (Req_refl _)
        (riemannIntegralI_negTest (coupOuterTestSwap f g (powTest n) (⟨1, 1⟩ : Q) Nat.one_pos
          (by decide) a han had (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))
          lo w hlo hw hwn)))) ?_
  exact Radd_cancel_mid _ _

end Multiplicity.UOR.Bridge.F1Square.Square
