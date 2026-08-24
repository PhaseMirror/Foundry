/-
F1 square — **discharging `reg'` for the accelerated angle target** (`AngleRegDischarge.lean`).
`AngleTargetAcc.lean` repaired the certificate route by reindexing the raw partial sums through a
monotone schedule `sched`, and `atlasAngleFamily_closes_crux_acc` consumes a regularity hypothesis
`reg' : ∀ n, RReg (angleDiagTargetAcc θ n sched)`. This file discharges that `reg'` to a
**satisfiable** convergence-rate condition on the ACCELERATED increments.

Two facts are built:

- `angleDiagTarget_mono`: the raw partials `Σ_{k<m}(2−2cos(nθ_k))` are monotone non-decreasing in `m`.
  Each increment `2 − 2cos(nθ_m) = (1−cos)+(1−cos) ≥ 0` (`Rcos_le_one`, exactly the block used by
  `angleDiagTarget_nonneg`), so `P k ≤ P k + increment = P (k+1)`; compose along the chain.

- `angleDiagTargetAcc_RReg`: given a monotone schedule (`hmono`) and a **canonical-rate** tail bound on
  the accelerated increments (`htail`: `Y k − Y j ≤ 1/(j+1)` for `j ≤ k`), the accelerated target is a
  regular sequence of reals (`RReg`) — the input to Bishop's `Rlim`. This is `RReg_of_real_bound` with
  the symmetric bound `1/(j+1)+1/(k+1)`, split on `Nat.le_total`: the `j ≤ k` side is free from
  monotonicity (`Y j ≤ Y k` ⟹ `Y j − Y k ≤ 0 ≤ 1/…`), the `k ≤ j` side is `htail`. It mirrors
  `czetaRe_RReg` verbatim in shape.

WHY THE HYPOTHESIS IS STATED ON THE ACCELERATED INCREMENTS (and not a linear schedule). On the genuine
family the raw increments `2−2cos(nθ_k)` decay like `(log k)²/k²` (zero density `~ k/log k`), so raw
tails decay like `(log m)²/m`, NOT `1/m`: no fixed linear schedule `sched j = B·(j+1)` makes the
accelerated tail `≤ 1/(j+1)` — that form is VACUOUS. Stating `htail` directly on the accelerated
differences at the canonical rate `1/(j+1)` is genuinely satisfiable: any convergence modulus of the raw
series is realized by some schedule. It is a convergence-rate condition and says NOTHING about the limit
being `2λₙ` (that identity is `hid`, which is RH).

HONEST SCOPE. This discharges `reg'` to a satisfiable canonical-rate condition; it is convergence
analysis, constructs no `θ`/`sched`, and asserts nothing about `2λₙ`. It does NOT close the crux; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.AngleTargetAcc
import Multiplicity.F1.Analysis.ComplexZeta
import Multiplicity.F1.Analysis.CosSinBound
import Multiplicity.F1.Analysis.Pi

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The `m`-th raw increment `2 − 2cos(nθ_m) = (1−cos)+(1−cos)` is non-negative (`Rcos_le_one` twice,
    `Radd`/`Rsub` monotone) — the exact block whose partial sum `angleDiagTarget_nonneg` shows `≥ 0`. -/
private theorem angleDiagTarget_incr_nonneg (θ : Nat → Real) (n m : Nat) :
    Rnonneg (Rsub (Radd one one)
      (Radd (Rcos (nsmulR n (θ m))) (Rcos (nsmulR n (θ m))))) :=
  Rnonneg_Rsub_of_Rle
    (Radd_le_add (Rcos_le_one (nsmulR n (θ m))) (Rcos_le_one (nsmulR n (θ m))))

/-- `x ≤ y ⟹ x − y ≤ 0` (order level); the mirror of the raw-partial monotonicity into the `Rsub`
    sign used by the discharge's `j ≤ k` branch. -/
private theorem Rle_Rsub_zero {x y : Real} (h : Rle x y) : Rle (Rsub x y) zero :=
  Rle_trans (Radd_le_add h (Rle_refl (Rneg y))) (Rle_of_Req (Radd_neg y))

/-- **The raw partial sums are monotone non-decreasing.** `angleDiagTarget θ n j ≤ angleDiagTarget θ n k`
    whenever `j ≤ k`: each successor is the predecessor plus a non-negative block
    (`angleDiagTarget_incr_nonneg`), so `P k ≤ P k + block = P (k+1)` (`Rle_self_Radd_right`), and the
    chain composes by `Rle_trans`. Convergence-analysis structure only — no claim on the limit. -/
theorem angleDiagTarget_mono (θ : Nat → Real) (n : Nat) :
    ∀ j k, j ≤ k → Rle (angleDiagTarget θ n j) (angleDiagTarget θ n k) := by
  intro j k
  induction k with
  | zero =>
    intro h
    have hj0 : j = 0 := Nat.le_zero.mp h
    subst hj0
    exact Rle_refl _
  | succ k ih =>
    intro h
    rcases Nat.lt_or_ge j (k + 1) with hlt | hge
    · exact Rle_trans (ih (Nat.lt_succ_iff.mp hlt))
        (Rle_self_Radd_right (angleDiagTarget_incr_nonneg θ n k))
    · have hjk1 : j = k + 1 := Nat.le_antisymm h hge
      subst hjk1
      exact Rle_refl _

/-- **★ THE DISCHARGE OF `reg'`.** Given a monotone schedule `sched` (`hmono`) and the canonical-rate
    tail bound `htail` on the ACCELERATED increments — `Y k − Y j ≤ 1/(j+1)` for `j ≤ k`, where
    `Y = angleDiagTargetAcc θ n sched` — the accelerated target is a regular sequence of reals
    (`RReg`), the exact hypothesis `reg'` of `atlasAngleFamily_closes_crux_acc`.

    Proof: `RReg_of_real_bound` with the symmetric slack `1/(j+1)+1/(k+1)`, split on `Nat.le_total j k`.
    The `j ≤ k` branch is FREE from `htail`: monotonicity (`angleDiagTarget_mono` through
    `sched j ≤ sched k`) gives `Y j ≤ Y k`, so `Y j − Y k ≤ 0 ≤ 1/(j+1) ≤ 1/(j+1)+1/(k+1)`. The `k ≤ j`
    branch is `htail k j` chained to the symmetric slack. Same shape as `czetaRe_RReg`.

    This is `reg'` reduced to a SATISFIABLE canonical-rate condition on the increments — convergence
    analysis, NOT the vacuous linear-schedule form, and it asserts nothing about `2λₙ`. The crux fields
    stay `none`. -/
theorem angleDiagTargetAcc_RReg (θ : Nat → Real) (n : Nat) (sched : Nat → Nat)
    (hmono : ∀ j k, j ≤ k → sched j ≤ sched k)
    (htail : ∀ j k, j ≤ k →
        Rle (Rsub (angleDiagTargetAcc θ n sched k) (angleDiagTargetAcc θ n sched j))
            (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)))
    : RReg (angleDiagTargetAcc θ n sched) := by
  refine RReg_of_real_bound _ (fun j k => add ⟨1, j + 1⟩ ⟨1, k + 1⟩)
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (fun j k => Qle_refl _) ?_
  intro j k
  rcases Nat.le_total j k with hjk | hkj
  · -- `j ≤ k`: monotonicity gives `Y j − Y k ≤ 0`, then `0 ≤ 1/(j+1) ≤ 1/(j+1)+1/(k+1)`.
    have h1 : Rle (Rsub (angleDiagTargetAcc θ n sched j) (angleDiagTargetAcc θ n sched k)) zero :=
      Rle_Rsub_zero (angleDiagTarget_mono θ n (sched j) (sched k) (hmono j k hjk))
    have h2 : Rle (zero : Real) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) :=
      Rle_zero_of_Rnonneg (Rnonneg_ofQ (Nat.succ_pos j) (by show (0 : Int) ≤ 1; decide))
    have h3 : Rle (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))
        (ofQ (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
          (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))) :=
      Rle_ofQ_ofQ (Nat.succ_pos j) (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
        (Qle_self_add (by show (0 : Int) ≤ 1; decide))
    exact Rle_trans h1 (Rle_trans h2 h3)
  · -- `k ≤ j`: the accelerated tail, chained to the symmetric slack.
    refine Rle_trans (htail k j hkj) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos k) (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
      (Qle_add_self (by show (0 : Int) ≤ 1; decide))

/-- **reg' from a raw-convergence MODULUS — the schedule is constructed, not assumed.** If `mod` is a
    monotone reindex witnessing that the raw angle series is Cauchy at the canonical rate — every partial
    beyond index `mod j` sits within `1/(j+1)` of the `mod j`-th partial (`hconv`) — then the schedule
    `sched := mod` makes the accelerated target `RReg`. This is `angleDiagTargetAcc_RReg` with the
    accelerated tail supplied by the modulus: for `j ≤ k`, `mod j ≤ mod k` (monotone), so
    `Acc k − Acc j = P(mod k) − P(mod j) ≤ 1/(j+1)` is exactly `hconv j (mod k)`.

    It exhibits `reg'` as a consequence of MERE CONVERGENCE of the raw series — classical, unconditional
    zero-density (`Σ 1/γ² < ∞`), never RH — with the schedule EXHIBITED as the convergence modulus rather
    than posited. `hconv` says nothing about the limit's value (`2λₙ = hid`, RH) or sign; it constructs no
    `θ`. The crux fields stay `none`. -/
theorem angleDiagTargetAcc_RReg_of_modulus (θ : Nat → Real) (n : Nat) (mod : Nat → Nat)
    (hmod_mono : ∀ j k, j ≤ k → mod j ≤ mod k)
    (hconv : ∀ j m, mod j ≤ m →
        Rle (Rsub (angleDiagTarget θ n m) (angleDiagTarget θ n (mod j)))
            (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)))
    : RReg (angleDiagTargetAcc θ n mod) :=
  angleDiagTargetAcc_RReg θ n mod hmod_mono
    (fun j k hjk => hconv j (mod k) (hmod_mono j k hjk))

end Multiplicity.UOR.Bridge.F1Square.Square
