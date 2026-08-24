/-
F1 square — **the real-to-approximant bound** (`RSeqApprox.lean`): **A REAL IS WITHIN `1/(N+1)` OF
ITS OWN `N`-TH APPROXIMANT** —

    `|x − ofQ (x.seq N)|  ≤  1/(N+1)`   (`Rabs_sub_seq_le`).

This is the statement that makes a Bishop real *usable* as a locatable object: it says the
rational data `x.seq` is not merely an internal representation but an effective approximation with
a known rate. It is the missing half of the density argument for `L2Definite` — one cannot locate a
real by comparison (there is no deciding `x ≤ 1/2`), but one can *read off* a rational within a
prescribed distance, and then locate that rational, which is decidable.

Everything is definitional unwinding plus the regularity axiom. `Rsub x (ofQ q)` reads its
arguments at `2n+1`, so at index `n` the claim is `|x_{2n+1} − x_N| ≤ 1/(N+1) + 2/(n+1)`, and
regularity already gives `≤ 1/(2n+2) + 1/(N+1)`; the slack `1/(2n+2) ≤ 2/(n+1)` closes it.

HONEST SCOPE. One inequality about the substrate, with no analysis in it. It does not by itself
discharge `DyadicApproximable` (brick 76): that still needs the clamp of `⌊q·2^m⌋` into
`[0, 2^m)` for a rational that may fall slightly outside `[0,1)`. Nothing here touches the Weil
form or the crux.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.RabsLemmas

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- The rational core: `1/(2n+2) + 1/(N+1) ≤ 1/(N+1) + 2/(n+1)`. -/
private theorem seq_slack (N n : Nat) :
    Qle (add (Qbound (2 * n + 1)) (Qbound N)) (add (⟨1, N + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) := by
  show (1 * ((N + 1 : Nat) : Int) + 1 * ((2 * n + 1 + 1 : Nat) : Int))
        * (((N + 1) * (n + 1) : Nat) : Int)
      ≤ (1 * ((n + 1 : Nat) : Int) + 2 * ((N + 1 : Nat) : Int))
        * (((2 * n + 1 + 1) * (N + 1) : Nat) : Int)
  push_cast
  have ha : (1 : Int) ≤ (N : Int) + 1 := by omega
  have hb : (1 : Int) ≤ (n : Int) + 1 := by omega
  -- with `a = N+1`, `b = n+1` the two sides are `a²b + 2ab²` and `2ab² + 4a²b`
  have eL : (1 * ((N : Int) + 1) + 1 * (2 * (n : Int) + 1 + 1))
        * (((N : Int) + 1) * ((n : Int) + 1))
      = ((N : Int) + 1) * ((N : Int) + 1) * ((n : Int) + 1)
        + 2 * (((N : Int) + 1) * (((n : Int) + 1) * ((n : Int) + 1))) := by ring_uor
  have eR : (1 * ((n : Int) + 1) + 2 * ((N : Int) + 1))
        * ((2 * (n : Int) + 1 + 1) * ((N : Int) + 1))
      = 2 * (((N : Int) + 1) * (((n : Int) + 1) * ((n : Int) + 1)))
        + 4 * (((N : Int) + 1) * ((N : Int) + 1) * ((n : Int) + 1)) := by ring_uor
  have hA : (0 : Int) ≤ ((N : Int) + 1) * ((N : Int) + 1) * ((n : Int) + 1) := by
    have h1 : (0 : Int) ≤ ((N : Int) + 1) * ((N : Int) + 1) :=
      Int.mul_nonneg (by omega) (by omega)
    exact Int.mul_nonneg h1 (by omega)
  rw [eL, eR]
  omega

/-- **A REAL IS WITHIN `1/(N+1)` OF ITS `N`-TH APPROXIMANT.** -/
theorem Rabs_sub_seq_le (x : Real) (N : Nat) :
    Rle (Rabs (Rsub x (ofQ (x.seq N) (x.den_pos N))))
      (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)) := by
  intro n
  show Qle (Qabs (add (x.seq (2 * n + 1)) (neg (x.seq N))))
    (add (⟨1, N + 1⟩ : Q) (⟨2, n + 1⟩ : Q))
  exact Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
    (x.reg (2 * n + 1) N) (seq_slack N n)

/-- The same bound, oriented as a distance from the approximant. -/
theorem Rabs_seq_sub_le (x : Real) (N : Nat) :
    Rle (Rabs (Rsub (ofQ (x.seq N) (x.den_pos N)) x))
      (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)) := by
  refine Rle_trans (Rle_of_Req ?_) (Rabs_sub_seq_le x N)
  refine Req_trans (Req_symm (Rabs_Rneg _)) (Rabs_congr ?_)
  -- `−(q − x) ≈ x − q`: both sides are `Radd`-shaped at the same depth, so pointwise is safe
  apply Req_of_seq_Qeq
  intro k
  simp only [Qeq, Rsub, Radd, Rneg, neg, add]
  push_cast
  ring_uor

end Multiplicity.UOR.Bridge.F1Square.Analysis
