/-
F1 square — **the multiplied-form deviation bound** (`BernsteinDevBound.lean`), the Bernstein arc,
sub-brick H₆. Bernstein's absolute central moment (`bernR_abs_moment`, sub-brick F) is stated with the
central deviation `|k − nx|`, while the operator's pointwise deviation (`bernOp_deviation`, sub-brick G)
carries the sample deviation `|k/n − x|`; the two differ by the factor `n`. Rescaling and applying the
AM-GM moment bound, and clamping `x(1−x) ≤ 1/4`, gives the deviation sum a **rational** bound:

    `2δn · Σ_k |k/n − x|·b_{n,k}(x) ≤ δ² + n/4`   (`bernOp_devsum_bound`, on `[0,1]`, any `δ > 0`).

Kept in multiplied form (`2δn·(…) ≤ …`) so the reciprocal `1/(2δn)` is only formed later at a concrete
schedule — where it is a fixed power of two — instead of symbolically here.

WHY (the Sonine route, step 3, the Mellin FRONT). The determinacy residual is bounded pointwise by
`M_φ·L·(deviation sum)` (sub-brick H₅), so this rational bound on the deviation sum is what makes the
energy `⟨φ,φ⟩` bound a vanishing rational under the schedule `δ = 2^m`, `n = 4^m` — the last analytic
input the determinacy squeeze consumes.

HONEST SCOPE. The multiplied-form deviation-sum bound and the unconditional `x(1−x) ≤ 1/4`, over `Real`.
Infrastructure for determinacy; NOT yet the energy bound, NOT `⟨φ,φ⟩ ≈ 0`, NOT determinacy, NOT
inversion, NOT positivity. Step 4 is RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.BernsteinDeviation

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `1/2` as a real. -/
private def half : Real := ofQ (⟨1, 2⟩ : Q) (by decide)

/-- `a − (b − c) ≈ (c + a) − b` (structural, no `ring_uor` over the multi-fraction `Qeq`). -/
private theorem sub_sub_rearrange (a b c : Real) :
    Req (Rsub a (Rsub b c)) (Rsub (Radd c a) b) := by
  show Req (Radd a (Rneg (Radd b (Rneg c)))) (Radd (Radd c a) (Rneg b))
  refine Req_trans (Radd_congr (Req_refl a)
    (Req_trans (Rneg_Radd b (Rneg c)) (Radd_congr (Req_refl (Rneg b)) (Rneg_Rneg c)))) ?_
  refine Req_trans (Req_symm (Radd_assoc a (Rneg b) c)) ?_
  refine Req_trans (Radd_congr (Radd_comm a (Rneg b)) (Req_refl c)) ?_
  refine Req_trans (Radd_assoc (Rneg b) a c) ?_
  refine Req_trans (Radd_comm (Rneg b) (Radd a c)) ?_
  exact Radd_congr (Radd_comm a c) (Req_refl (Rneg b))

/-- **`x(1 − x) ≤ 1/4`** for every real `x` — from `(x − 1/2)² ≥ 0`, expanded (`Rsub_sq_expand`) into
    `1/4 − x(1 − x) = (x − 1/2)² ≥ 0`. -/
theorem quarter_bound (x : Real) :
    Rle (Rmul x (Rsub one x)) (ofQ (⟨1, 4⟩ : Q) (by decide)) := by
  have hsq : Req (Rmul half half) (ofQ (⟨1, 4⟩ : Q) (by decide)) :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide))
      (ofQ_congr (Qmul_den_pos (by decide) (by decide)) (by decide)
        (by show Qeq (mul (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q)) (⟨1, 4⟩ : Q); simp only [Qeq, mul]; decide))
  have hone : Req (Radd half half) one :=
    Req_trans (Radd_ofQ_ofQ (by decide) (by decide))
      (ofQ_congr (add_den_pos (by decide) (by decide)) (by decide)
        (by show Qeq (add (⟨1, 2⟩ : Q) (⟨1, 2⟩ : Q)) (⟨1, 1⟩ : Q); simp only [Qeq, add]; decide))
  have hcross : Req (Radd (Rmul x half) (Rmul x half)) x :=
    Req_trans (Req_symm (Rmul_distrib x half half))
      (Req_trans (Rmul_congr (Req_refl x) hone) (Rmul_one x))
  have hlhs : Req (Rmul (Rsub x half) (Rsub x half))
      (Rsub (Radd (Rmul x x) (ofQ (⟨1, 4⟩ : Q) (by decide))) x) :=
    Req_trans (Rsub_sq_expand x half)
      (Rsub_congr (Radd_congr (Req_refl (Rmul x x)) hsq) hcross)
  have hxx : Req (Rmul x (Rsub one x)) (Rsub x (Rmul x x)) :=
    Req_trans (Rmul_sub_distrib x one x) (Rsub_congr (Rmul_one x) (Req_refl (Rmul x x)))
  have hrhs : Req (Rsub (ofQ (⟨1, 4⟩ : Q) (by decide)) (Rmul x (Rsub one x)))
      (Rsub (Radd (Rmul x x) (ofQ (⟨1, 4⟩ : Q) (by decide))) x) :=
    Req_trans (Rsub_congr (Req_refl _) hxx)
      (sub_sub_rearrange (ofQ (⟨1, 4⟩ : Q) (by decide)) x (Rmul x x))
  exact Rle_of_Rnonneg_Rsub (Rnonneg_congr (Req_trans hlhs (Req_symm hrhs))
    (Rnonneg_Rmul_self (Rsub x half)))

/-- Per-term: `n·(k/n − x) ≈ k − n·x`. -/
private theorem ratPt_scale (n k : Nat) (hn : 0 < n) (x : Real) :
    Req (Rmul (RofNat n) (Rsub (ratPt k n hn) x)) (Rsub (RofNat k) (Rmul (RofNat n) x)) := by
  refine Req_trans (Rmul_sub_distrib (RofNat n) (ratPt k n hn) x) ?_
  refine Rsub_congr ?_ (Req_refl _)
  show Req (Rmul (ofQ (⟨(n : Int), 1⟩ : Q) Nat.one_pos) (ofQ (⟨(k : Int), n⟩ : Q) hn))
      (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos)
  refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos hn) ?_
  exact ofQ_congr (Qmul_den_pos Nat.one_pos hn) Nat.one_pos
    (by show Qeq (mul (⟨(n : Int), 1⟩ : Q) (⟨(k : Int), n⟩ : Q)) (⟨(k : Int), 1⟩ : Q)
        simp only [Qeq, mul]; push_cast; ring_uor)

/-- Per-term: `n·(|k/n − x|·b) ≈ |k − nx|·b`. -/
private theorem dev_term_scale (n k : Nat) (hn : 0 < n) (x : Real) :
    Req (Rmul (RofNat n) (Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)))
        (Rmul (Rabs (Rsub (RofNat k) (Rmul (RofNat n) x))) (bernR x n k)) := by
  refine Req_trans (Req_symm (Rmul_assoc (RofNat n)
    (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k))) ?_
  refine Rmul_congr ?_ (Req_refl _)
  refine Req_trans (Req_symm (Req_trans (Rabs_Rmul (RofNat n) (Rsub (ratPt k n hn) x))
    (Rmul_congr (Rabs_of_nonneg (Rnonneg_RofNat n)) (Req_refl _)))) ?_
  exact Rabs_congr (ratPt_scale n k hn x)

/-- **The deviation sum rescales**: `n·Σ_k |k/n − x|·b = Σ_k |k − nx|·b` — the sample-deviation sum is
    `1/n` times Bernstein's central-deviation sum. -/
theorem devsum_rescale (n : Nat) (hn : 0 < n) (x : Real) :
    Req (Rmul (RofNat n)
          (RsumN (fun k => Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)) (n + 1)))
        (RsumN (fun k => Rmul (Rabs (Rsub (RofNat k) (Rmul (RofNat n) x))) (bernR x n k)) (n + 1)) :=
  Req_trans (Req_symm (RsumN_Rmul_const (RofNat n)
      (fun k => Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)) (n + 1)))
    (RsumN_congr (n + 1) (fun k _ => dev_term_scale n k hn x))

/-- `n·x·(1−x) ≤ n/4` on `[0,1]` — `quarter_bound` scaled by `n ≥ 0`. -/
private theorem nx_bound (n : Nat) (x : Real) :
    Rle (Rmul (Rmul (RofNat n) x) (Rsub one x)) (ofQ (⟨(n : Int), 4⟩ : Q) (by show (0:Nat) < 4; decide)) := by
  refine Rle_trans (Rle_of_Req (Rmul_assoc (RofNat n) x (Rsub one x))) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_RofNat n) (quarter_bound x)) ?_
  refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos (by decide)) ?_)
  exact ofQ_congr (Qmul_den_pos Nat.one_pos (by decide)) (by show (0:Nat) < 4; decide)
    (by show Qeq (mul (⟨(n : Int), 1⟩ : Q) (⟨1, 4⟩ : Q)) (⟨(n : Int), 4⟩ : Q)
        simp only [Qeq, mul]; push_cast; ring_uor)

/-- **★ THE MULTIPLIED-FORM DEVIATION BOUND**: `2δn·Σ_k |k/n − x|·b_{n,k}(x) ≤ δ² + n/4` on `[0,1]`,
    for any `δ > 0`. Rescale the sum (`devsum_rescale`), apply Bernstein's AM-GM moment bound
    (`bernR_abs_moment`), and clamp `x(1−x) ≤ 1/4` (`nx_bound`). -/
theorem bernOp_devsum_bound (n : Nat) (hn : 0 < n) {x : Real} (h0 : Rle zero x) (h1 : Rle x one)
    (δ : Q) (hδd : 0 < δ.den) :
    Rle (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
                (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos))
              (RsumN (fun k => Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)) (n + 1)))
        (ofQ (add (mul δ δ) (⟨(n : Int), 4⟩ : Q))
          (add_den_pos (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide))) := by
  have hx : Rnonneg x := Rnonneg_of_Rle_zero h0
  have h1x : Rnonneg (Rsub one x) := Rnonneg_Rsub_of_Rle h1
  -- rewrite `2δn·devsum` as `2δ·(n·devsum) = 2δ·absMomSum`
  have hlhs : Req (Rmul (ofQ (mul (mul (⟨2, 1⟩ : Q) δ) (⟨(n : Int), 1⟩ : Q))
                (Qmul_den_pos (Qmul_den_pos (by decide) hδd) Nat.one_pos))
              (RsumN (fun k => Rmul (Rabs (Rsub (ratPt k n hn) x)) (bernR x n k)) (n + 1)))
      (Rmul (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos (by decide) hδd))
        (RsumN (fun k => Rmul (Rabs (Rsub (RofNat k) (Rmul (RofNat n) x))) (bernR x n k)) (n + 1))) := by
    refine Req_trans (Rmul_congr (Req_symm (Rmul_ofQ_ofQ (Qmul_den_pos (by decide) hδd) Nat.one_pos))
      (Req_refl _)) ?_
    refine Req_trans (Rmul_assoc (ofQ (mul (⟨2, 1⟩ : Q) δ) (Qmul_den_pos (by decide) hδd))
      (RofNat n) _) ?_
    exact Rmul_congr (Req_refl _) (devsum_rescale n hn x)
  -- Bernstein AM-GM + the `1/4` clamp
  refine Rle_trans (Rle_of_Req hlhs) (Rle_trans (bernR_abs_moment x hx h1x n δ hδd) ?_)
  refine Rle_trans (Radd_le_add (Rle_refl _) (nx_bound n x)) ?_
  exact Rle_of_Req (Radd_ofQ_ofQ (Qmul_den_pos hδd hδd) (by show (0:Nat) < 4; decide))

end Multiplicity.UOR.Bridge.F1Square.Square
