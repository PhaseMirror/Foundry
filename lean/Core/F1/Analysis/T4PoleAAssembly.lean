/-
F1 square — **the `t4PoleA` assembly, part 1** (`T4PoleAAssembly.lean`). Toward
`t4PoleA ≈ 9/4`: the first exact piece value and the `Gn 3` telescope.

    `t4A12 ≈ 1`  —  `∫₁² (2log2 − log x) dx = 2log2 − (Gn 2 − Gn 1) = 2log2 − (2log2 − 1) = 1`,
    the logs cancelling *inside a single piece* (`Gn 2`'s log term IS the cone height `t4H`,
    definitionally);

    `t4A23 + t4A34 ≈ (t4H + t4H) − (Gn 4 − Gn 2)` — the middle pieces telescope, so
    `Gn 3` (the only `log 3` carrier) drops out of the assembly without ever being
    expanded.

What remains for `≈ 9/4`: expand `Gn 4 − Gn 2` through `logN 4 ≈ 2·logN 2`
(`logN_mul_gen`), fold in `t4Ah`/`t4Aq`, and cancel the `log 2` coefficient
(`6 − 8 + 3/2 + 1/2 = 0`).

HONEST SCOPE. Exact identities between constructed integrals and `Gn` data; no slot
field, no positivity. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.T4PoleAPieces

namespace UOR.Bridge.F1Square.Analysis

/-- `a − (a − b) ≈ b` (the double-subtraction collapse). -/
private theorem ta_sub_sub_self (a b : Real) : Req (Rsub a (Rsub a b)) b := by
  refine Req_trans (Radd_congr (Req_refl a) (Rneg_Radd a (Rneg b))) ?_
  refine Req_trans (Radd_congr (Req_refl a)
    (Radd_congr (Req_refl (Rneg a)) (Rneg_neg b))) ?_
  refine Req_trans (Req_symm (Radd_assoc a (Rneg a) b)) ?_
  refine Req_trans (Radd_congr (Radd_neg a) (Req_refl b)) ?_
  exact Req_trans (Radd_comm zero b) (Radd_zero b)

/-- **`t4A12 ≈ 1` — the first exact piece value**: `∫₁² (2log2 − log x) dx = 1`. The
    cone height is `Gn 2`'s own log term, so the logs cancel inside the piece. -/
theorem t4A12_val : Req t4A12 one := by
  refine Req_trans t4A12_eq ?_
  -- `Gn 1 ≈ −1`, and `−(−1) ≈ 1`
  refine Req_trans (Rsub_congr (Req_refl t4H)
    (Radd_congr (Req_refl (Gn 2 (by omega)))
      (Req_trans (Rneg_congr Gn_one) (Rneg_neg one)))) ?_
  -- `t4H − (Gn 2 + 1) ≈ (t4H − Gn 2) − 1`
  refine Req_trans (Rsub_Radd_eq t4H (Gn 2 (by omega)) one) ?_
  -- `t4H − Gn 2 = t4H − (t4H − 2) ≈ 2`
  refine Req_trans (Rsub_congr
    (ta_sub_sub_self t4H (ofQ (⟨((2 : Nat) : Int), 1⟩ : Q) Nat.one_pos))
    (Req_refl one)) ?_
  -- `2 − 1 ≈ 1`
  refine Req_trans (Rsub_ofQ_ofQ Nat.one_pos (by decide)) ?_
  exact ofQ_congr (Qsub_den_pos Nat.one_pos (by decide)) (by decide) (by decide)

/-- **The middle-piece telescope**: `t4A23 + t4A34 ≈ (t4H + t4H) − (Gn 4 − Gn 2)` —
    `Gn 3`, the only `log 3` carrier in the assembly, drops out here and is never
    expanded. -/
theorem t4A2334_val : Req (Radd t4A23 t4A34)
    (Rsub (Radd t4H t4H) (Rsub (Gn 4 (by omega)) (Gn 2 (by omega)))) := by
  refine Req_trans (Radd_congr t4A23_eq t4A34_eq) ?_
  refine Req_trans (Req_symm (Rsub_Radd_Radd t4H t4H
    (Rsub (Gn 3 (by omega)) (Gn 2 (by omega)))
    (Rsub (Gn 4 (by omega)) (Gn 3 (by omega))))) ?_
  refine Rsub_congr (Req_refl (Radd t4H t4H)) ?_
  refine Req_trans (Radd_comm (Rsub (Gn 3 (by omega)) (Gn 2 (by omega)))
    (Rsub (Gn 4 (by omega)) (Gn 3 (by omega)))) ?_
  exact Rsub_telescope (Gn 4 (by omega)) (Gn 3 (by omega)) (Gn 2 (by omega))


-- ===========================================================================
-- Part 2: the normal-form kit and `t4PoleA ≈ 9/4`.
-- ===========================================================================

/-- `(−a) − (−b) ≈ −(a − b)` (private copy). -/
private theorem ta_neg_sub (a b : Real) : Req (Rsub (Rneg a) (Rneg b)) (Rneg (Rsub a b)) := by
  apply Req_of_seq_Qeq; intro n
  simp only [Qeq, Rsub, Radd, Rneg, neg, add]; push_cast; ring_uor

/-- `a·z + b·z ≈ (a+b)·z` (rational scalars). -/
private theorem ta_smul_add {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) (z : Real) :
    Req (Radd (Rmul (ofQ a ha) z) (Rmul (ofQ b hb) z))
      (Rmul (ofQ (add a b) (add_den_pos ha hb)) z) := by
  refine Req_trans (Radd_congr (Rmul_comm _ z) (Rmul_comm _ z)) ?_
  refine Req_trans (Req_symm (Rmul_distrib z (ofQ a ha) (ofQ b hb))) ?_
  refine Req_trans (Rmul_comm z _) ?_
  exact Rmul_congr (Radd_ofQ_ofQ ha hb) (Req_refl z)

/-- `a·z − b·z ≈ (a−b)·z` (rational scalars). -/
private theorem ta_smul_sub {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) (z : Real) :
    Req (Rsub (Rmul (ofQ a ha) z) (Rmul (ofQ b hb) z))
      (Rmul (ofQ (Qsub a b) (add_den_pos ha hb)) z) := by
  refine Req_trans (Req_symm (Rmul_sub_distrib_right (ofQ a ha) (ofQ b hb) z)) ?_
  exact Rmul_congr (Rsub_ofQ_ofQ ha hb) (Req_refl z)

/-- `(x − a) − (y − b) ≈ (x − y) − (a − b)`. -/
private theorem ta_sub_pair (x a y b : Real) :
    Req (Rsub (Rsub x a) (Rsub y b)) (Rsub (Rsub x y) (Rsub a b)) :=
  Req_trans (Rsub_Radd_Radd x (Rneg a) y (Rneg b))
    (Radd_congr (Req_refl (Rsub x y)) (ta_neg_sub a b))

/-- `x − (y − b) ≈ (x − y) + b`. -/
private theorem ta_sub_sub (x y b : Real) :
    Req (Rsub x (Rsub y b)) (Radd (Rsub x y) b) := by
  refine Req_trans (Radd_congr (Req_refl x) (Rneg_Radd y (Rneg b))) ?_
  refine Req_trans (Radd_congr (Req_refl x)
    (Radd_congr (Req_refl (Rneg y)) (Rneg_neg b))) ?_
  exact Req_symm (Radd_assoc x (Rneg y) b)

/-- NF addition: `(a·z + q) + (b·z + r) ≈ (a+b)·z + (q+r)`. -/
private theorem ta_nf_add {a q b r : Q} (ha : 0 < a.den) (hq : 0 < q.den)
    (hb : 0 < b.den) (hr : 0 < r.den) (z : Real) :
    Req (Radd (Radd (Rmul (ofQ a ha) z) (ofQ q hq)) (Radd (Rmul (ofQ b hb) z) (ofQ r hr)))
      (Radd (Rmul (ofQ (add a b) (add_den_pos ha hb)) z)
        (ofQ (add q r) (add_den_pos hq hr))) :=
  Req_trans (Radd_swap (Rmul (ofQ a ha) z) (ofQ q hq) (Rmul (ofQ b hb) z) (ofQ r hr))
    (Radd_congr (ta_smul_add ha hb z) (Radd_ofQ_ofQ hq hr))

/-- NF scaling: `w·(a·z + q) ≈ (wa)·z + wq`. -/
private theorem ta_nf_smul {w a q : Q} (hw : 0 < w.den) (ha : 0 < a.den) (hq : 0 < q.den)
    (z : Real) :
    Req (Rmul (ofQ w hw) (Radd (Rmul (ofQ a ha) z) (ofQ q hq)))
      (Radd (Rmul (ofQ (mul w a) (Qmul_den_pos hw ha)) z)
        (ofQ (mul w q) (Qmul_den_pos hw hq))) := by
  refine Req_trans (Rmul_distrib (ofQ w hw) (Rmul (ofQ a ha) z) (ofQ q hq)) ?_
  refine Radd_congr ?_ (Rmul_ofQ_ofQ hw hq)
  refine Req_trans (Req_symm (Rmul_assoc (ofQ w hw) (ofQ a ha) z)) ?_
  exact Rmul_congr (Rmul_ofQ_ofQ hw ha) (Req_refl z)

/-- **`Gn 2 − Gn 1 ≈ 2·log2 − 1`** (NF form). -/
theorem gn21_nf : Req (Rsub (Gn 2 (by omega)) (Gn 1 (by omega)))
    (Radd (Rmul (ofQ (⟨((2 : Nat) : Int), 1⟩ : Q) Nat.one_pos) (logN 2 (by omega)))
      (ofQ (⟨-1, 1⟩ : Q) (by decide))) := by
  refine Req_trans (Radd_congr (Req_refl (Gn 2 (by omega)))
    (Req_trans (Rneg_congr Gn_one) (Rneg_neg one))) ?_
  refine Req_trans (Radd_assoc
    (Rmul (ofQ (⟨((2 : Nat) : Int), 1⟩ : Q) Nat.one_pos) (logN 2 (by omega)))
    (Rneg (ofQ (⟨((2 : Nat) : Int), 1⟩ : Q) Nat.one_pos)) one) ?_
  refine Radd_congr (Req_refl _) ?_
  refine Req_trans (Radd_congr (Rneg_ofQ _ Nat.one_pos) (Req_refl one)) ?_
  refine Req_trans (Radd_ofQ_ofQ Nat.one_pos (by decide)) ?_
  exact ofQ_congr (add_den_pos Nat.one_pos (by decide)) (by decide) (by decide)

/-- **`Gn 4 − Gn 2 ≈ 6·log2 + (−2)`** (NF form, via `logN 4 ≈ 2·logN 2`). -/
theorem gn42_nf : Req (Rsub (Gn 4 (by omega)) (Gn 2 (by omega)))
    (Radd (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
      (ofQ (⟨-2, 1⟩ : Q) (by decide))) := by
  refine Req_trans (Rsub_congr (Rsub_congr
    (Req_trans (Rmul_congr (Req_refl (ofQ (⟨((4 : Nat) : Int), 1⟩ : Q) Nat.one_pos))
      (Req_symm (logN_mul_gen 2 2 (by omega) (by omega))))
      (Rmul_distrib _ (logN 2 (by omega)) (logN 2 (by omega))))
    (Req_refl _)) (Req_refl (Gn 2 (by omega)))) ?_
  refine Req_trans (ta_sub_pair _ _ _ _) ?_
  refine Req_trans (Rsub_congr
    (Req_trans (Rsub_congr (ta_smul_add Nat.one_pos Nat.one_pos _) (Req_refl _))
      (Req_trans (ta_smul_sub (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos _)
        (Rmul_congr (ofQ_congr (b := (⟨6, 1⟩ : Q))
          (add_den_pos (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos)
          (by decide) (by decide)) (Req_refl _))))
    (Req_trans (Rsub_ofQ_ofQ Nat.one_pos Nat.one_pos)
      (ofQ_congr (b := (⟨2, 1⟩ : Q)) (add_den_pos Nat.one_pos Nat.one_pos)
        (by decide) (by decide)))) ?_
  refine Radd_congr (Req_refl _) ?_
  exact Req_trans (Rneg_ofQ _ (by decide)) (ofQ_congr (by decide) (by decide) (by decide))

/-- **`t4A23 + t4A34 ≈ (−2)·log2 + 2`** (NF form). -/
theorem a2334_nf : Req (Radd t4A23 t4A34)
    (Radd (Rmul (ofQ (⟨-2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
      (ofQ (⟨2, 1⟩ : Q) (by decide))) := by
  refine Req_trans t4A2334_val ?_
  refine Req_trans (Rsub_congr
    (Req_trans (ta_smul_add Nat.one_pos Nat.one_pos _)
      (Rmul_congr (ofQ_congr (b := (⟨4, 1⟩ : Q)) (add_den_pos Nat.one_pos Nat.one_pos)
        (by decide) (by decide)) (Req_refl _))) gn42_nf) ?_
  refine Req_trans (Rsub_Radd_eq _ _ _) ?_
  refine Req_trans (Rsub_congr (Req_trans (ta_smul_sub (by decide) (by decide) _)
    (Rmul_congr (ofQ_congr (b := (⟨-2, 1⟩ : Q)) (by decide) (by decide) (by decide))
      (Req_refl _))) (Req_refl _)) ?_
  refine Radd_congr (Req_refl _) ?_
  exact Req_trans (Rneg_ofQ _ (by decide)) (ofQ_congr (by decide) (by decide) (by decide))

/-- **`t4Ah ≈ (3/2)·log2 + (−1/2)`** (NF form). -/
theorem ah_nf : Req t4Ah
    (Radd (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (logN 2 (by omega)))
      (ofQ (⟨-1, 2⟩ : Q) (by decide))) := by
  refine Req_trans t4Ah_eq ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (Radd_congr (Req_symm (Rone_mul (logN 2 (by omega)))) gn21_nf)
      (Req_trans (Req_symm (Radd_assoc _ _ _))
        (Radd_congr (Req_trans
          (ta_smul_add (a := (⟨1, 1⟩ : Q)) (by decide) Nat.one_pos _)
          (Rmul_congr (ofQ_congr (b := (⟨3, 1⟩ : Q)) (add_den_pos (by decide) Nat.one_pos)
            (by decide) (by decide)) (Req_refl _))) (Req_refl _))))) ?_
  refine Req_trans (ta_nf_smul (by decide) (by decide) (by decide) _) ?_
  exact Radd_congr (Rmul_congr (ofQ_congr (Qmul_den_pos (by decide) (by decide))
    (by decide) (by decide)) (Req_refl _))
    (ofQ_congr (Qmul_den_pos (by decide) (by decide)) (by decide) (by decide))

/-- **`t4Aq ≈ (1/2)·log2 + (−1/4)`** (NF form). -/
theorem aq_nf : Req t4Aq
    (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (logN 2 (by omega)))
      (ofQ (⟨-1, 4⟩ : Q) (by decide))) := by
  refine Req_trans t4Aq_eq ?_
  refine Req_trans (Rmul_congr (Req_refl _) gn21_nf) ?_
  refine Req_trans (ta_nf_smul (by decide) Nat.one_pos (by decide) _) ?_
  exact Radd_congr (Rmul_congr (ofQ_congr (Qmul_den_pos (by decide) Nat.one_pos)
    (by decide) (by decide)) (Req_refl _))
    (ofQ_congr (Qmul_den_pos (by decide) (by decide)) (by decide) (by decide))

/-- **★ `t4PoleA ≈ 9/4`** — the cone tent's `∫ f` pole component, EXACT: the `log 2`
    coefficient cancels (`−2 + 3/2 + 1/2 = 0`) and the rationals total `9/4`
    (`1 + 2 − 1/2 − 1/4`). -/
theorem t4PoleA_eq : Req t4PoleA (ofQ (⟨9, 4⟩ : Q) (by decide)) := by
  show Req (Radd (Radd (Radd t4A12 t4A23) (Radd t4A34 t4Ah)) t4Aq) _
  refine Req_trans (Radd_congr (Req_trans (Radd_assoc t4A12 t4A23 (Radd t4A34 t4Ah))
    (Radd_congr (Req_refl t4A12) (Req_symm (Radd_assoc t4A23 t4A34 t4Ah))))
    (Req_refl t4Aq)) ?_
  refine Req_trans (Radd_congr (Radd_congr t4A12_val
    (Req_trans (Radd_congr a2334_nf ah_nf)
      (ta_nf_add (by decide) (by decide) (by decide) (by decide) _))) aq_nf) ?_
  -- `one + NF` folds into the rational slot
  refine Req_trans (Radd_congr (Req_trans (Radd_comm one _)
    (Req_trans (Radd_assoc _ _ one)
      (Radd_congr (Req_refl _) (Radd_ofQ_ofQ (add_den_pos (by decide) (by decide)) (by decide)))))
    (Req_refl _)) ?_
  refine Req_trans (ta_nf_add (add_den_pos (by decide) (by decide))
    (add_den_pos (add_den_pos (by decide) (by decide)) (by decide)) (by decide) (by decide) _) ?_
  -- the log2 coefficient is 0; the rational slot is 9/4
  refine Req_trans (Radd_congr (Req_trans (Rmul_congr
    (ofQ_congr (add_den_pos (add_den_pos (by decide) (by decide)) (by decide))
      (by decide) (show Qeq _ (⟨0, 1⟩ : Q) by decide)) (Req_refl _))
    (Req_trans (Rmul_comm _ _) (Rmul_zero _))) (Req_refl _)) ?_
  refine Req_trans (Radd_comm zero _) ?_
  refine Req_trans (Radd_zero _) ?_
  exact ofQ_congr (add_den_pos (add_den_pos (add_den_pos (by decide) (by decide)) (by decide))
    (by decide)) (by decide) (by decide)

end UOR.Bridge.F1Square.Analysis
