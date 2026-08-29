/-
F1 square — **the pre-Hilbert layer, brick 13** (`PairingLimit.lean`): **THE PAIRING EXTENDS TO
CAUCHY SEQUENCES** — the completion axis opened, sqrt-free.

For a sequence of test families `F j` that is Cauchy in the squared distance (against a fixed
`g`: `d²(F j, F k)·⟨g,g⟩ ≤ (1/(j+1) + 1/(k+1))²`), the pairings `⟨F j, g⟩` form a REGULAR
sequence of reals, so their Bishop limit exists:

- `inner_sub_sq_le` — **Cauchy–Schwarz continuity of the pairing**:
  `(⟨f,g⟩ − ⟨f',g⟩)² ≤ d²(f,f')·⟨g,g⟩` — the modulus of continuity, squared (no square root
  exists in the substrate, so the geometry runs on squares throughout).
- `pairing_RReg` — the squared Cauchy modulus converts to the canonical linear `RReg` rate
  through `Rle_of_Rsq_le` (squaring is order-reflecting on nonnegatives — the ε-shifted
  difference-of-squares argument) and the completeness bridge `RReg_of_real_bound`.
- **`pairingLim`** — the extended pairing value `lim_j ⟨F j, g⟩ : Real`, with the effective rate
  `pairingLim_dist`: `|⟨F j, g⟩ − pairingLim| ≤ 2/(j+1)`.

WHY (the Sonine route, step 3). The layer's completion lack is now split precisely: brick 11
showed Parseval holds at every finite-complete truncation; THIS brick shows the pairing data of
a Cauchy sequence converges with an effective rate — the pairing extends past finite
approximation. What is NOT constructed is the limit OBJECT (the member of the completed space):
only its pairing values exist so far, which is exactly the functional-analytic (weak-limit)
half of completeness, and the honest constructive one available without countable choice.

HONEST SCOPE. Extended pairing values along squared-Cauchy sequences at fixed truncation; no
completed space, no limit member, no strong convergence. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.Parallelogram
import Foundations.F1.Analysis.SqrtRealCmp
import Foundations.F1.Analysis.ComplexZeta
import Foundations.F1.Analysis.IntegralCertIrrel

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `|z|² ≈ z²`. -/
private theorem abs_sq (z : Real) : Req (Rmul (Rabs z) (Rabs z)) (Rmul z z) :=
  Req_trans (Req_symm (Rabs_Rmul z z)) (Rabs_of_nonneg (Rnonneg_Rmul_self z))

/-- **Cauchy–Schwarz continuity of the pairing**: `(⟨f,g⟩ − ⟨f',g⟩)² ≤ d²(f,f')·⟨g,g⟩` — the
    squared modulus of continuity, from brick 1's Cauchy–Schwarz at the difference family. -/
theorem inner_sub_sq_le (f f' g : Nat → Real) (N : Nat) :
    Rle (Rmul (Rsub (innerN f g N) (innerN f' g N))
              (Rsub (innerN f g N) (innerN f' g N)))
        (Rmul (dist2 f f' N) (innerN g g N)) := by
  have hz : Req (Rsub (innerN f g N) (innerN f' g N))
      (innerN (fun i => Rsub (f i) (f' i)) g N) :=
    Req_symm (innerN_sub_left f f' g N)
  refine Rle_trans (Rle_of_Req (Rmul_congr hz hz)) ?_
  exact cauchy_schwarz (fun i => Rsub (f i) (f' i)) g N

/-- **The pairings along a squared-Cauchy sequence are a regular sequence**: with
    `d²(F j, F k)·⟨g,g⟩ ≤ (1/(j+1) + 1/(k+1))²`, the reals `⟨F j, g⟩` satisfy `RReg` — the
    squared modulus converts to the canonical linear rate by order-reflection of squaring. -/
theorem pairing_RReg {F : Nat → Nat → Real} {g : Nat → Real} {N : Nat}
    (hFg : ∀ j k, Rle (Rmul (dist2 (F j) (F k) N) (innerN g g N))
      (ofQ (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
                (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
        (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))))) :
    RReg (fun j => innerN (F j) g N) := by
  refine RReg_of_real_bound _
    (fun j k => add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
    (fun j k => add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
    (fun j k => Qle_refl _) (fun j k => ?_)
  have hεn : 0 ≤ (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)).num :=
    Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide)
  refine Rle_trans (Rle_Rabs_self _) ?_
  refine Rle_of_Rsq_le (Rnonneg_Rabs _)
    (Rnonneg_ofQ (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k)) hεn) ?_
  refine Rle_trans (Rle_of_Req (abs_sq _)) ?_
  refine Rle_trans (inner_sub_sq_le (F j) (F k) g N) ?_
  refine Rle_trans (hFg j k) ?_
  exact Rle_of_Req (Req_symm (Rmul_ofQ_ofQ
    (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
    (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))))

/-- **THE EXTENDED PAIRING**: the Bishop limit `lim_j ⟨F j, g⟩` of the pairings along a
    squared-Cauchy sequence of test families — the pairing extends past finite approximation
    without constructing the completed space. -/
def pairingLim (F : Nat → Nat → Real) (g : Nat → Real) (N : Nat)
    (hFg : ∀ j k, Rle (Rmul (dist2 (F j) (F k) N) (innerN g g N))
      (ofQ (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
                (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
        (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))))) : Real :=
  Rlim (fun j => innerN (F j) g N) (pairing_RReg hFg)

/-- **The effective rate of the extended pairing**: `|⟨F j, g⟩ − pairingLim| ≤ 2/(j+1)` — the
    limit is approached at the canonical Bishop rate, kernel-checked. -/
theorem pairingLim_dist {F : Nat → Nat → Real} {g : Nat → Real} {N : Nat}
    (hFg : ∀ j k, Rle (Rmul (dist2 (F j) (F k) N) (innerN g g N))
      (ofQ (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
                (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
        (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))))) (j : Nat) :
    Rle (Rabs (Rsub (innerN (F j) g N) (pairingLim F g N hFg)))
        (ofQ (⟨2, j + 1⟩ : Q) (Nat.succ_pos j)) :=
  Rabs_dist_Rlim (pairing_RReg hFg) j

end Multiplicity.UOR.Bridge.F1Square.Square
