/-
F1 square — **tendsto ⟹ per-index real closeness, and its Lipschitz image** (`RTendsToClose.lean`):
two general Bishop-real primitives that convert the seq-level convergence predicate `RTendsTo` into a
per-`k` REAL closeness bound, and push that bound through a Lipschitz map.

`RTendsTo X L` is defined at the sequence level (`∀ k n, |X_k.seq n − L.seq n| ≤ 2/(k+1) + 2/(n+1)`).
`RTendsTo_imp_close` reads off the clean REAL statement it implies — that the `k`-th term is within
`2/(k+1)` of the limit as a real number: `|X_k − L| ≤ 2/(k+1)` (using the tendsto bound at the doubled
index `2n+1`, then `2/(2n+2) ≤ 2/(n+1)`). `Rlip_close` composes this with a real Lipschitz bound: the
Lipschitz image of a convergent sequence is close to the image of the limit, `|g(X_k) − g(L)| ≤
K·(2/(k+1))`.

WHY (rung 6, the non-acceleration half of the Lipschitz squeeze). The real-scale covariance capstone
needs `mellinHat (dilate_{q_k} φ) → mellinHat (dilate_c φ)` as the rationals `q_k → c`, which is
"a Lipschitz function preserves limits". That splits into (i) the Lipschitz image is CLOSE to the
image-of-limit at the scaled rate `K·2/(k+1)` — built here, no index acceleration — and (ii)
converting that per-`k` closeness back into `RTendsTo` at the canonical rate, which needs a
`K`-index reindex (`RmulK`/`Ridx`-style) and is NOT built here.

HONEST SCOPE. Two general Bishop-real convergence primitives only. It builds NO `RTendsTo` of a
Lipschitz image (the reindex half is unbuilt), NO scale continuity, NO covariance, NO factorization,
NO positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.Complete
import Foundations.F1.Analysis.RSeqApprox

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **Tendsto implies per-index real closeness**: `RTendsTo X L` gives `|X_k − L| ≤ 2/(k+1)` as a real
    number, for every `k`. The seq-level bound at the doubled index `2n+1` (`h k (2n+1)`) supplies
    `|X_k.seq(2n+1) − L.seq(2n+1)| ≤ 2/(k+1) + 2/(2n+2)`, and `2/(2n+2) ≤ 2/(n+1)` closes the `Rle`. -/
theorem RTendsTo_imp_close {X : Nat → Real} {L : Real} (h : RTendsTo X L) (k : Nat) :
    Rle (Rabs (Rsub (X k) L)) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) := by
  intro n
  exact Qle_trans (add_den_pos (Nat.succ_pos k) (Nat.succ_pos (2 * n + 1)))
    (h k (2 * n + 1))
    (Qadd_le_add (Qle_refl (⟨2, k + 1⟩ : Q))
      (by show (2 : Int) * ((n + 1 : Nat) : Int) ≤ (2 : Int) * (((2 * n + 1) + 1 : Nat) : Int)
          push_cast; omega))

/-- **The Lipschitz image of a convergent sequence is close to the image of the limit**: for a
    `K`-Lipschitz `g` (real bound) and `RTendsTo xs L`, `|g(xs_k) − g(L)| ≤ K·(2/(k+1))` for every `k`.
    Compose the Lipschitz bound at `(xs_k, L)` with `RTendsTo_imp_close`, then fold the rational product
    `K·⟨2,k+1⟩` (`Rmul_ofQ_ofQ`). The non-acceleration half of the Lipschitz limit-preservation. -/
theorem Rlip_close (g : Real → Real) (K : Q) (hKd : 0 < K.den) (hKn : 0 ≤ K.num)
    (hlip : ∀ y y', Rle (Rabs (Rsub (g y) (g y'))) (Rmul (ofQ K hKd) (Rabs (Rsub y y'))))
    {xs : Nat → Real} {L : Real} (h : RTendsTo xs L) (k : Nat) :
    Rle (Rabs (Rsub (g (xs k)) (g L)))
      (ofQ (mul K (⟨2, k + 1⟩ : Q)) (Qmul_den_pos hKd (Nat.succ_pos k))) := by
  refine Rle_trans (hlip (xs k) L) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hKd hKn) (RTendsTo_imp_close h k)) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ hKd (Nat.succ_pos k))

end Multiplicity.UOR.Bridge.F1Square.Analysis
