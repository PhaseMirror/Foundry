/-
F1 square — **the convolution's twisted tail is its own limit at any faster schedule**
(`ConvTwTailSchedule.lean`): `convTwTail` is defined as the Bishop limit of the genuine per-window
twisted sums on the canonical `digammaMidx K_conv` schedule (`K_conv = w·Cf·M_g·(1/a)·2ⁿ`). This brick
records that ANY integer schedule `R` cofinal-above that canonical one yields the SAME limit:

    `Rlim (genSum (convolution twisted terms) ∘ R) = convTwTail f g n`.

WHY THIS MATTERS. The `∫_t` reconstruction of `M[f⋆g]=M[f]·M[g]` closes the tail commute with
`Rlim_eval_real_rate` on `convTwTail`'s own limit, and the per-`t` closeness `dilTail_partial_close`
needs the evaluation schedule to dominate the dilated tail's canonical schedule `digammaMidx (Cf·2ⁿ)`.
Since `K_conv` and `Cf·2ⁿ` are not comparable in general (`K_conv = (w·M_g·(1/a))·(Cf·2ⁿ)` and the
prefactor can be `< 1`), this bump lets the reconstruction evaluate on a common dominating schedule
without changing the value.

The two schedules agree within `1/(j+1)` at every index (`genSum_close`, fed by `convTwTerm_two_sided`),
so their limits coincide (`Rlim_approx_eq`) — the exact analog of `improper_schedule_eq` for the
convolution's clamp-free tail.

HONEST SCOPE. Schedule-independence of `convTwTail` only. It builds NO limit-inside-the-integral, NO
`Ttail` test, NO covariance, NO factorization `M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ConvMellinHat
import Multiplicity.F1Square.Square.ImproperScheduleIndep

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **`convTwTail` is its own limit at any faster schedule.** For any integer schedule `R` with
    `digammaMidx K_conv j ≤ R j` (`K_conv = w·Cf·M_g·(1/a)·2ⁿ`), the Bishop limit of the convolution's
    twisted window sums on `R` equals `convTwTail f g n`. Via `Rlim_approx_eq` on the `1/(j+1)`
    schedule-closeness (`genSum_close`, fed by `convTwTerm_two_sided`). -/
theorem convTwTail_eq_fast_schedule (f g : L2Test) (n : Nat) {Cf : Q}
    (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q))
    (R : Nat → Nat)
    (hgrow : ∀ j, digammaMidx
      (mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j ≤ R j)
    (hRegR : RReg (fun j => genSum
      (fun m => twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
        (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m) (R j))) :
    Req (Rlim (fun j => genSum
          (fun m => twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
            (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m) (R j)) hRegR)
        (convTwTail f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1) :=
  Rlim_approx_eq _ _ hRegR
    (genSum_RReg
      (fun m => twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
        (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m)
      (K := mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hw hCfd) g.hMd)
        (Qinv_den_pos han)) Nat.one_pos)
      (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg hwn hCfn) g.hMn)
        (Int.le_of_lt (Qinv_num_pos had))) (Int.ofNat_nonneg _))
      (fun m hm => convTwTerm_two_sided f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1 m hm))
    (fun j => genSum_close
      (fun m => twTerm (mulConvRTest f g (⟨(m : Int) + 2, 1⟩ : Q) Nat.one_pos
        (by show (0 : Int) ≤ (m : Int) + 2; omega) a han had lo w hlo hw hwn) n m)
      (K := mul (mul (mul (mul w Cf) g.M) (Qinv a)) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hw hCfd) g.hMd)
        (Qinv_den_pos han)) Nat.one_pos)
      (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg hwn hCfn) g.hMn)
        (Int.le_of_lt (Qinv_num_pos had))) (Int.ofNat_nonneg _))
      (fun m hm => convTwTerm_two_sided f g n hCfd hCfn hfdec a han had ha1 lo w hlo hw hwn hw1 m hm)
      R hgrow j)

end Multiplicity.UOR.Bridge.F1Square.Square
