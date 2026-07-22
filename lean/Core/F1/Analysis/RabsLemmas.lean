/-
F1 square — **`Rabs` triangle inequality and its finite-sum form**, foundational reals API.

`Rabs` (`RMax.lean`) carries only congruence and non-negativity; the triangle inequality
`|a+b| ≤ |a|+|b|` and its sum form `|Σ F| ≤ Σ|F|` were missing. They are the basic estimates every
absolute-value bound needs — in particular the dyadic Riemann-sum refinement convergence
(`RiemannSum.lean`, the certified-integration gateway) and the Weil-pairing bounds (Track 2).

Both lift the rational facts (`Qabs_add_le`) through the `Rabs x = ⟨n ↦ |xₙ|⟩` definition, with the
`Rle` regularity slack `⟨2,n+1⟩` absorbed by `Qle_self_add`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RMax
import Core.F1.Analysis.RSum

namespace UOR.Bridge.F1Square.Analysis

/-- **Triangle inequality** `|a + b| ≤ |a| + |b|`. -/
theorem Rabs_Radd (a b : Real) : Rle (Rabs (Radd a b)) (Radd (Rabs a) (Rabs b)) := by
  intro n
  show Qle (Qabs (add (a.seq (2 * n + 1)) (b.seq (2 * n + 1))))
    (add (add (Qabs (a.seq (2 * n + 1))) (Qabs (b.seq (2 * n + 1)))) (⟨2, n + 1⟩ : Q))
  exact Qle_trans
    (add_den_pos (Qabs_den_pos (a.den_pos (2 * n + 1))) (Qabs_den_pos (b.den_pos (2 * n + 1))))
    (Qabs_add_le (a.seq (2 * n + 1)) (b.seq (2 * n + 1)))
    (Qle_self_add (show (0 : Int) ≤ 2 by decide))

/-- `|0| = 0`. -/
theorem Rabs_zero : Req (Rabs zero) zero := Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- **`|x| ≤ B ⟹ x ≤ B`** (one side of the two-sided characterization), via `a ≤ |a|`. -/
theorem Rle_of_Rabs_le {x B : Real} (h : Rle (Rabs x) B) : Rle x B := fun n =>
  Qle_trans (Qabs_den_pos (x.den_pos n)) (Qle_self_Qabs (x.seq n)) (h n)

/-- **`|−x| = |x|`.** -/
theorem Rabs_Rneg (x : Real) : Req (Rabs (Rneg x)) (Rabs x) :=
  Req_of_seq_Qeq (fun n => by
    show Qeq (Qabs (neg (x.seq n))) (Qabs (x.seq n)); rw [Qabs_neg]; exact Qeq_refl _)

/-- **`|x| ≤ B ⟹ −B ≤ x`** (the other side), via `|−x| = |x|` and `Rle_of_Rabs_le`. -/
theorem Rneg_le_of_Rabs_le {x B : Real} (h : Rle (Rabs x) B) : Rle (Rneg B) x :=
  Rle_trans (Rle_Rneg (Rle_of_Rabs_le (Rle_trans (Rle_of_Req (Rabs_Rneg x)) h)))
    (Rle_of_Req (Rneg_neg x))

/-- **`|q| = q` for a non-negative rational** (embedded): `Rabs (ofQ q) = ofQ q` when `q.num ≥ 0`. -/
theorem Rabs_ofQ_nonneg {q : Q} (hq : 0 < q.den) (hn : 0 ≤ q.num) :
    Req (Rabs (ofQ q hq)) (ofQ q hq) :=
  Req_of_seq_Qeq (fun _ => Qabs_of_nonneg hn)

/-- **`|q·z| = q·|z|` for a non-negative rational scalar** `q` (embedded). The `Rmul` reindex
    `Ridx (ofQ q) z` and `Ridx (ofQ q) (Rabs z)` coincide (`xBound (Rabs z) = xBound z`), so this is
    pointwise: `|q·z_r| = |q|·|z_r| = q·|z_r|` (`Qabs_mul`, `Qabs_of_nonneg`). The scalar law the
    affine change of variables (general-interval integral) needs. -/
theorem Rabs_Rmul_ofQ_nonneg {q : Q} (hq : 0 < q.den) (hn : 0 ≤ q.num) (z : Real) :
    Req (Rabs (Rmul (ofQ q hq) z)) (Rmul (ofQ q hq) (Rabs z)) :=
  Req_of_seq_Qeq (fun n => by
    show Qeq (Qabs (mul q (z.seq (Ridx (ofQ q hq) z n))))
             (mul q (Qabs (z.seq (Ridx (ofQ q hq) (Rabs z) n))))
    rw [Qabs_mul]
    exact Qmul_congr (Qabs_of_nonneg hn) (Qeq_refl _))

/-- **`x ≤ |x|`** — the embedding side of the absolute value (lifts `a ≤ |a|` pointwise). -/
theorem Rle_Rabs_self (x : Real) : Rle x (Rabs x) := fun n =>
  Qle_trans (Qabs_den_pos (x.den_pos n)) (Qle_self_Qabs (x.seq n))
    (Qle_self_add (show (0 : Int) ≤ 2 by decide))

/-- **`|ofQ q| = ofQ |q|`** — the absolute value commutes with the rational embedding (pointwise). -/
theorem Rabs_ofQ {q : Q} (hq : 0 < q.den) :
    Req (Rabs (ofQ q hq)) (ofQ (Qabs q) (Qabs_den_pos hq)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- **`|x·y| = |x|·|y|`** — full multiplicativity of the absolute value. The `Rmul` reindex
    `Ridx x y` and `Ridx (Rabs x) (Rabs y)` coincide (`xBound (Rabs ·) = xBound ·`, since
    `Int.natAbs (Int.ofNat k) = k`), so this is the pointwise `Qabs_mul`. -/
theorem Rabs_Rmul (x y : Real) : Req (Rabs (Rmul x y)) (Rmul (Rabs x) (Rabs y)) :=
  Req_of_seq_Qeq (fun n => by
    show Qeq (Qabs (mul (x.seq (Ridx x y n)) (y.seq (Ridx x y n))))
             (mul (Qabs (x.seq (Ridx (Rabs x) (Rabs y) n)))
                  (Qabs (y.seq (Ridx (Rabs x) (Rabs y) n))))
    rw [Qabs_mul]
    exact Qmul_congr (Qeq_refl _) (Qeq_refl _))

/-- **The finite-sum triangle inequality** `|Σ_{i<N} F i| ≤ Σ_{i<N} |F i|`. -/
theorem RsumN_Rabs_le (F : Nat → Real) :
    ∀ N, Rle (Rabs (RsumN F N)) (RsumN (fun i => Rabs (F i)) N)
  | 0 => Rle_of_Req Rabs_zero
  | (N + 1) =>
      Rle_trans (Rabs_Radd (RsumN F N) (F N))
        (Radd_le_add (RsumN_Rabs_le F N) (Rle_refl (Rabs (F N))))

end UOR.Bridge.F1Square.Analysis
