/-
F1 square — **the clamp-free half-line Mellin transform of the convolution EXISTS** (`ConvMellinHat.lean`):
assembling `convTwTerm_bound` into the convergent tail. For a `t`-window `⊆ (0,1]` and `f` with
order-`(n+2)` window decay, the genuine (clamp-free, per-`m` minimal clamp `S=m+2`) twisted tail terms
of the convolution's Mellin transform are summable, so

    `convTwTail f g n = ∫₁^∞ (f⋆g)(x)·xⁿ dx`   (Bishop limit of the twisted window sums),
    `convMellinHat f g n = mellinMoment(f⋆g) + convTwTail f g n = M[f⋆g](n)`,

the clamp-free half-line transform of the multiplicative convolution as a constructed real. This is the
payoff of the decay arc: `mellinHat(mulConvRTest f g S)` does NOT converge for a *fixed* clamp `S` (the
frozen tail does not decay), but the per-window-genuine values (clamp-independent by
`twTerm_mulConv_S_indep`) DO assemble into a convergent tail, because `convTwTerm_bound` puts them in the
`(C·2ⁿ)/((m+1)m)` shape `genSum_RReg` consumes.

HONEST SCOPE. The convergent half-line transform OBJECT (`convTwTail`/`convMellinHat`), plus the
two-sided per-window bound (`convTwTerm_two_sided`) feeding its regularity. It reads off NO factorization
`M[f⋆g]=M[f]·M[g]` (that is the `∫_t` reconstruction, still to come — sum the dilated-tail form over `m`,
apply the covariance per window, pull out `M[f]`, identify `∫_t g·tⁿ = M[g]`), NO positivity, NO crux.
`f`-decay is an explicit hypothesis; the `t`-window is `(0,1]`. Step 4 (band-coupling positivity) is RH;
the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ConvTwTermBound
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The two-sided per-window bound feeding the tail's regularity** — the `∧`-form of
    `convTwTerm_bound` (`Rneg_le_of_Rabs_le`/`Rle_of_Rabs_le`), exactly the shape `genSum_RReg`
    consumes at modulus `K = w·C_f·M_g·(1/a)·2ⁿ`. -/
theorem convTwTerm_two_sided (f g : L2Test) (n : Nat) {Cf : Q} (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q)) (m : Nat) (hm : 1 ≤ m) :
    Rle (Rneg (ofQ (mul (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
              (⟨1, (m + 1) * m⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hw hCfd) g.hMd)
            (Qinv_den_pos han)) Nat.one_pos) (digamma_succ_mul_pos hm))))
        (twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
          (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m)
      ∧ Rle (twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
          (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m)
        (ofQ (mul (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
              (⟨1, (m + 1) * m⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hw hCfd) g.hMd)
            (Qinv_den_pos han)) Nat.one_pos) (digamma_succ_mul_pos hm))) :=
  ⟨Rneg_le_of_Rabs_le
      (convTwTerm_bound f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1 m hm),
   Rle_of_Rabs_le
      (convTwTerm_bound f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1 m hm)⟩

/-- **The clamp-free twisted half-line tail of the convolution** `∫₁^∞ (f⋆g)(x)·xⁿ dx` — the Bishop
    limit of the genuine per-window twisted sums (`twTerm` at the minimal window-clearing clamp `m+2`),
    regular at modulus `K = w·C_f·M_g·(1/a)·2ⁿ` via `genSum_RReg` fed by `convTwTerm_two_sided`. Its mere
    existence is the convergence the whole decay arc secured. -/
def convTwTail (f g : L2Test) (n : Nat) {Cf : Q} (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q)) : Real :=
  Rlim (fun j => genSum
      (fun m => twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
        (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m)
      (digammaMidx (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))
    (genSum_RReg
      (fun m => twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
        (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m)
      (K := mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hw hCfd) g.hMd)
        (Qinv_den_pos han)) Nat.one_pos)
      (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg hwn hCfn) g.hMn)
        (Int.le_of_lt (Qinv_num_pos had))) (Int.ofNat_nonneg _))
      (fun m hm => convTwTerm_two_sided f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1 m hm))

/-- **The clamp-free half-line Mellin transform of the convolution** `M[f⋆g](n) = ∫₀^∞ (f⋆g)·xⁿ dx` —
    the compact moment (clamp `1`, inert on `[0,1]`) plus the convergent twisted tail. A constructed
    real: the clamp-free half-line transform of `⋆` exists, the object `mellinHat(mulConvRTest f g S)`
    could NOT be for a fixed `S`. -/
def convMellinHat (f g : L2Test) (n : Nat) {Cf : Q} (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q)) : Real :=
  Radd (mellinMoment (mulConvRTest f g (⟨1, 1⟩ : Q) Nat.one_pos (by decide)
          a han had lo w hlo hw hwn) n)
    (convTwTail f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1)

end Multiplicity.UOR.Bridge.F1Square.Square
