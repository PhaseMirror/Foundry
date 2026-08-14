/-
F1 square — **the Durrmeyer pointwise convergence as a genuine limit object** (`DurrmeyerTendsTo.lean`),
the Mellin-inversion arc, packaging brick. The committed explicit-rate estimate `durrOp_converges`
(`|durrOp φ ((k+3)²−2) x − φ(x)| ≤ φ.L/(k+3)`) is here repackaged into the codebase's canonical limit
predicate `RTendsTo` (Bishop's `2/(k+1)+2/(n+1)` modulus, from `Analysis/Complete.lean`):

    `durrOp_tendsTo :  RTendsTo (fun m => durrOp φ ((Kₘ)·(Kₘ)−2) x) (φ.f x)`   (`x ∈ [0,1]`)

with the reindex `k := (φ.L.num.toNat + 1)·(m+1)` (so `Kₘ = (φ.L.num.toNat+1)·(m+1)+3`), which absorbs
the operator's Lipschitz constant `φ.L`: the real rate `φ.L/(Kₘ) = φ.L/((φ.L.num+1)(m+1)+3) ≤ 1/(m+1)`,
comfortably inside the `RTendsTo` modulus. The proof pushes the single real bound `|·| ≤ 1/(m+1)` down
to the two one-sided `.seq`-level bounds (`seq_diff_le`), recombines them through the rational absolute
value (`Qabs_le_of_both`), and relaxes `1/(m+1)` to `2/(m+1)`.

HONEST SCOPE. This packages the *already-proven* pointwise convergence `durrOp φ n x → φ(x)` on `[0,1]`
as an `RTendsTo` limit object — the strong pointwise Mellin inversion, delivered as a first-class limit.
It is NOT surjectivity onto function space, NOT positivity. Step 4 (the band-coupling positivity) is RH;
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.DurrmeyerConverge
import Multiplicity.F1Square.Analysis.ComplexZeta
import Multiplicity.F1Square.Analysis.Complete

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Step 1 — the reindexed real rate `|durrOp φ (Kₘ²−2) x − φ(x)| ≤ 1/(m+1)`.
-- ===========================================================================

/-- **THE REINDEXED DURRMEYER RATE**: with `k := (φ.L.num.toNat + 1)·(m+1)` the explicit convergence
    estimate `durrOp_converges` gives `|durrOp φ (Kₘ²−2) x − φ(x)| ≤ φ.L/Kₘ ≤ 1/(m+1)`
    (`Kₘ = (φ.L.num.toNat+1)·(m+1)+3`). The scaled denominator swallows `φ.L`: since
    `φ.L.num·(m+1) ≤ φ.L.den·((φ.L.num+1)(m+1)+3)`, the rational bound `φ.L·(1/Kₘ) ≤ 1/(m+1)`. -/
private theorem durrRate (φ : L2Test) (x : Real) (h0 : Rle zero x) (h1 : Rle x one) (m : Nat) :
    Rle (Rabs (Rsub (durrOp φ
        (((φ.L.num.toNat + 1) * (m + 1) + 3) * ((φ.L.num.toNat + 1) * (m + 1) + 3) - 2) x)
      (φ.f x)))
      (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) := by
  refine Rle_trans (durrOp_converges φ x h0 h1 ((φ.L.num.toNat + 1) * (m + 1))) ?_
  refine Rle_ofQ_ofQ _ (Nat.succ_pos m) ?_
  -- `Qle (mul φ.L ⟨1, (φ.L.num.toNat+1)*(m+1)+3⟩) ⟨1, m+1⟩`
  simp only [Qle, mul]
  push_cast
  have hBtoNat : (φ.L.num.toNat : Int) = φ.L.num := Int.toNat_of_nonneg φ.hLn
  have hBden1 : (1 : Int) ≤ (φ.L.den : Int) := by exact_mod_cast φ.hLd
  rw [hBtoNat]
  have hj1 : (0 : Int) ≤ (m : Int) + 1 := by omega
  -- `N·(m+1) ≤ (N+1)·(m+1)`
  have hfac : φ.L.num * ((m : Int) + 1) ≤ (φ.L.num + 1) * ((m : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right (by omega) hj1
  -- `(N+1)·(m+1) ≤ (N+1)·(m+1) + 3`
  have hplus3 : (φ.L.num + 1) * ((m : Int) + 1) ≤ (φ.L.num + 1) * ((m : Int) + 1) + 3 := by omega
  -- `(N+1)·(m+1)+3 ≤ φ.L.den·((N+1)·(m+1)+3)`
  have hPpos : (0 : Int) ≤ (φ.L.num + 1) * ((m : Int) + 1) + 3 := by
    have hp : (0 : Int) ≤ (φ.L.num + 1) * ((m : Int) + 1) := Int.mul_nonneg (by omega) hj1
    omega
  have hDmul : (φ.L.num + 1) * ((m : Int) + 1) + 3
      ≤ (φ.L.den : Int) * ((φ.L.num + 1) * ((m : Int) + 1) + 3) := by
    have := Int.mul_le_mul_of_nonneg_right hBden1 hPpos
    rw [Int.one_mul] at this; exact this
  have hchain : φ.L.num * ((m : Int) + 1)
      ≤ (φ.L.den : Int) * ((φ.L.num + 1) * ((m : Int) + 1) + 3) :=
    Int.le_trans hfac (Int.le_trans hplus3 hDmul)
  -- reconcile the explicit `* 1` / `1 *`
  have e1 : φ.L.num * 1 * ((m : Int) + 1) = φ.L.num * ((m : Int) + 1) := by ring_uor
  have e2 : (1 : Int) * ((φ.L.den : Int) * ((φ.L.num + 1) * ((m : Int) + 1) + 3))
      = (φ.L.den : Int) * ((φ.L.num + 1) * ((m : Int) + 1) + 3) := by ring_uor
  rw [e1, e2]; exact hchain

-- ===========================================================================
-- Steps 2–3 — the real rate `|Y − L| ≤ 1/(m+1)` packaged as the `RTendsTo` modulus.
-- ===========================================================================

/-- **RATE ⟹ `RTendsTo` MODULUS** (abstract): a single real bound `|Y − L| ≤ 1/(m+1)` delivers the
    `RTendsTo`-style `.seq`-level bound `|Yₙ − Lₙ| ≤ 2/(m+1) + 2/(n+1)`. Push the real bound down to the
    two one-sided `.seq` bounds (`seq_diff_le`, both directions via `Rabs`-symmetry), recombine through
    the rational absolute value (`Qabs_le_of_both`), and relax `1/(m+1)` to `2/(m+1)`. -/
private theorem tendsTo_of_rate {Y L : Real} {m : Nat}
    (hrate : Rle (Rabs (Rsub Y L)) (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m))) (n : Nat) :
    Qle (Qabs (Qsub (Y.seq n) (L.seq n))) (add (⟨2, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) := by
  -- Step 2 — one-sided `.seq` bounds, both directions.
  have hd1 : Qle (Qsub (Y.seq n) (L.seq n)) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    seq_diff_le Y L (⟨1, m + 1⟩ : Q) (Nat.succ_pos m) (Rle_of_Rabs_le hrate) n
  have hcomm : Req (Rabs (Rsub L Y)) (Rabs (Rsub Y L)) :=
    Req_trans (Rabs_congr (Req_symm (Rneg_Rsub Y L))) (Rabs_Rneg (Rsub Y L))
  have hrate' : Rle (Rabs (Rsub L Y)) (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) :=
    Rle_trans (Rle_of_Req hcomm) hrate
  have hd2 : Qle (Qsub (L.seq n) (Y.seq n)) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    seq_diff_le L Y (⟨1, m + 1⟩ : Q) (Nat.succ_pos m) (Rle_of_Rabs_le hrate') n
  -- Step 3 — recombine through `Qabs` and relax `1/(m+1) ≤ 2/(m+1)`.
  have he : Qeq (Qsub (L.seq n) (Y.seq n)) (neg (Qsub (Y.seq n) (L.seq n))) := by
    simp only [Qeq, Qsub, neg, add]; push_cast; ring_uor
  have h2 : Qle (neg (Qsub (Y.seq n) (L.seq n))) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    Qle_congr_left (Qsub_den_pos (L.den_pos n) (Y.den_pos n)) he hd2
  have hcombined : Qle (Qabs (Qsub (Y.seq n) (L.seq n))) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    Qabs_le_of_both hd1 h2
  have hm12 : Qle (⟨1, m + 1⟩ : Q) (⟨2, m + 1⟩ : Q) := by simp only [Qle]; push_cast; omega
  exact Qle_trans (add_den_pos (Nat.succ_pos m) (Nat.succ_pos n)) hcombined
    (Qadd_le_add hm12 (Qle_refl (⟨2, n + 1⟩ : Q)))

-- ===========================================================================
-- The packaged limit object.
-- ===========================================================================

/-- **★ THE DURRMEYER OPERATOR TENDS TO `φ(x)`** (packaged as an `RTendsTo` limit object): for
    `x ∈ [0,1]`, the reindexed Durrmeyer sequence

        `m ↦ durrOp φ (Kₘ·Kₘ − 2) x`,   `Kₘ = (φ.L.num.toNat + 1)·(m+1) + 3`,

    converges to `φ(x)` in the codebase's canonical limit predicate `RTendsTo` (Bishop modulus
    `2/(m+1) + 2/(n+1)`). The reindex `k := (φ.L.num.toNat + 1)·(m+1)` turns the committed rate
    `φ.L/(k+3)` into `≤ 1/(m+1)` (`durrRate`), which `tendsTo_of_rate` packages into the modulus. This
    is the strong pointwise Mellin inversion delivered as a first-class limit; NOT surjectivity, NOT
    positivity. Step 4 is RH. -/
theorem durrOp_tendsTo (φ : L2Test) (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    RTendsTo (fun m => durrOp φ
        (((φ.L.num.toNat + 1) * (m + 1) + 3) * ((φ.L.num.toNat + 1) * (m + 1) + 3) - 2) x)
      (φ.f x) := by
  intro m n
  exact tendsTo_of_rate (durrRate φ x h0 h1 m) n

end Multiplicity.UOR.Bridge.F1Square.Square
