/-
F1 square — **the realized cone slot** (`ConeSlot.lean`): the `t4` log-tent (the FIRST cone-shaped
datum with a live prime side) gets its `WeilSlot` — every interface field a genuine constructed
integral — and its Weil-functional closed form:

    `W(t4) ≈ (9/4 + t4H²) − (primes + (log4π+γ)·t4H + (t4H·log(3/2) − t4Dilog))`

with `t4H = 2·log 2`, primes from `t4PrimePart_eq`, and the dilog carried as the constructed
`t4Dilog` (no closed form exists). The archimedean tail assembles from the three shipped bricks:
the compact reciprocal half (`t4Trecip_sum`), the constructed dilog (`DilogPieces`), and the
improper remainder (`t4Improper_eq`).

The sign `W(t4) > 0` (`t4WeilValue_pos`, margin `≈ +0.05`) is certified by `M = 512` harmonic
wedges for `log 2`/`log(3/2)`/`log 3`, the standing `log 4π`/`γ` brackets, the rational dilog
lower bound `t4Dilog ≥ 1.909`, and one closing exact rational `decide`. This is the first
certified `W > 0` ON THE AUTOCORRELATION CONE with a live prime side — the sign RH demands there.

HONEST SCOPE. One realized slot and its sign; positivity for ONE cone element, not the cone
(uniform positivity on the cone = RH). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ConeTent
import Foundations.F1.Analysis.T4PoleAAssembly
import Foundations.F1.Analysis.T4ArchPieces
import Foundations.F1.Analysis.T4TailImproper
import Foundations.F1.Analysis.DilogValue
import Foundations.F1.Analysis.LambdaThreePos

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The M = 512 harmonic wedges (log 2, log 3/2, log 3 — both sides).
-- ===========================================================================

/-- `log 2` upper wedge: `hFold 512 512`. -/
def t4U2q : Q := hFold 512 512

theorem t4U2q_den : 0 < t4U2q.den := hFold_den_pos 512 (by decide) 512

/-- `log 2` lower wedge: `hFold 512 512 − 1/1024`. -/
def t4L2q : Q := Qsub t4U2q (⟨1, 1024⟩ : Q)

theorem t4L2q_den : 0 < t4L2q.den := Qsub_den_pos t4U2q_den (by decide)

theorem t4_U2 : Rle (logN 2 (by omega)) (ofQ t4U2q t4U2q_den) :=
  log2_le_hFold 512 (by decide)

theorem t4_L2 : Rle (ofQ t4L2q t4L2q_den) (logN 2 (by omega)) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ t4U2q_den (by decide)))) ?_
  refine Rsub_le_of_le_Radd ?_
  refine Rle_trans (hFold_le_log2_add 512 (by decide)) ?_
  exact Rle_trans (Rle_of_Req (Radd_comm _ _))
    (Radd_le_add (Rle_of_Req (ofQ_congr (by decide) (by decide) (by decide))) (Rle_refl _))

/-- `log 3 − log 2` upper wedge: `hFold 1024 512`. -/
def t4U32q : Q := hFold (2 * 512) 512

theorem t4U32q_den : 0 < t4U32q.den := hFold_den_pos (2 * 512) (by decide) 512

theorem t4_U32 : Rle (Rsub (logN 3 (by omega)) (logN 2 (by omega))) (ofQ t4U32q t4U32q_den) :=
  log32_le_hFold 512 (by decide)

/-- `log 3 − log 2` lower wedge: `hFold 1024 512 − 1/3072`. -/
def t4L32q : Q := Qsub t4U32q (⟨1, 6 * 512⟩ : Q)

theorem t4L32q_den : 0 < t4L32q.den := Qsub_den_pos t4U32q_den (by decide)

theorem t4_L32 : Rle (ofQ t4L32q t4L32q_den)
    (Rsub (logN 3 (by omega)) (logN 2 (by omega))) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ t4U32q_den (by decide)))) ?_
  refine Rsub_le_of_le_Radd ?_
  exact Rle_trans (hFold32_le 512 (by decide)) (Rle_of_Req (Radd_comm _ _))

/-- `log 3` upper: `U2 + U32`. -/
def t4U3q : Q := add t4U2q t4U32q

theorem t4U3q_den : 0 < t4U3q.den := add_den_pos t4U2q_den t4U32q_den

theorem t4_U3 : Rle (logN 3 (by omega)) (ofQ t4U3q t4U3q_den) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_Rsub_cancel (logN 3 (by omega))
    (logN 2 (by omega))))) ?_
  exact Rle_trans (Radd_le_add t4_U2 t4_U32) (Rle_of_Req (Radd_ofQ_ofQ t4U2q_den t4U32q_den))

/-- `log 3` lower: `L2 + L32`. -/
def t4L3q : Q := add t4L2q t4L32q

theorem t4L3q_den : 0 < t4L3q.den := add_den_pos t4L2q_den t4L32q_den

theorem t4_L3 : Rle (ofQ t4L3q t4L3q_den) (logN 3 (by omega)) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ t4L2q_den t4L32q_den))) ?_
  refine Rle_trans (Radd_le_add t4_L2 t4_L32) ?_
  exact Rle_of_Req (Radd_Rsub_cancel (logN 3 (by omega)) (logN 2 (by omega)))

-- ===========================================================================
-- Product bracket helpers.
-- ===========================================================================

/-- Product upper bound from factor uppers (`y ≥ 0`, upper of the left factor `≥ 0`). -/
private theorem mul_upper {x y : Real} {a b : Q} (had : 0 < a.den) (hbd : 0 < b.den)
    (han : 0 ≤ a.num) (hax : Rle x (ofQ a had)) (hby : Rle y (ofQ b hbd))
    (hynn : Rnonneg y) :
    Rle (Rmul x y) (ofQ (mul a b) (Qmul_den_pos had hbd)) :=
  Rle_trans (Rmul_le_Rmul_right hynn hax)
    (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ had han) hby)
      (Rle_of_Req (Rmul_ofQ_ofQ had hbd)))

/-- Product lower bound from factor lowers (both lowers `≥ 0`). -/
private theorem mul_lower {x y : Real} {a b : Q} (had : 0 < a.den) (hbd : 0 < b.den)
    (han : 0 ≤ a.num) (hbn : 0 ≤ b.num)
    (hax : Rle (ofQ a had) x) (hby : Rle (ofQ b hbd) y) :
    Rle (ofQ (mul a b) (Qmul_den_pos had hbd)) (Rmul x y) := by
  have hynn : Rnonneg y :=
    Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_ofQ hbd hbn)) hby)
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ had hbd))) ?_
  exact Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ had han) hby)
    (Rmul_le_Rmul_right hynn hax)

/-- `t4H` above: `t4H ≤ 2·U2`. -/
theorem t4H_le : Rle t4H (ofQ (mul (⟨2, 1⟩ : Q) t4U2q) (Qmul_den_pos (by decide) t4U2q_den)) := by
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos (by decide)) t4_U2) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ Nat.one_pos t4U2q_den)

/-- `t4H` below: `2·L2 ≤ t4H`. -/
theorem t4H_ge : Rle (ofQ (mul (⟨2, 1⟩ : Q) t4L2q) (Qmul_den_pos (by decide) t4L2q_den)) t4H := by
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ Nat.one_pos t4L2q_den))) ?_
  exact Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos (by decide)) t4_L2

-- ===========================================================================
-- The archimedean tail, the slot, and the closed form.
-- ===========================================================================

/-- **The `t4` archimedean tail** — the assembled constructed integrals: the compact
    reciprocal half minus (the dilog plus `t4H`·the improper remainder). -/
def t4ArchTail : Real :=
  Rsub (Radd (Radd (t4Trecip 2) (t4Trecip 3)) (t4Trecip 4))
       (Radd t4Dilog (Rmul t4H t4Improper))

/-- The archimedean constant collapses: `weilArchConst(t4) ≈ (log 4π + γ)·t4H` (`f(1) = t4H`). -/
theorem t4ArchConst_eq : Req (weilArchConst t4Test) (Rmul (Radd Rlog4pic Rgamma_h) t4H) := by
  show Req (Rmul (Radd Rlog4pic Rgamma_h) (t4F ⟨1, 1⟩)) _
  exact Rmul_congr (Req_refl _) t4F_one

/-- **The tail's value**: `t4ArchTail ≈ t4H·(log 3 − log 2) − t4Dilog`
    (`= t4H·log(3/2) − dilog ≈ −1.377`; the `log 5` telescopes cancel). -/
theorem t4ArchTail_eq : Req t4ArchTail
    (Rsub (Rmul t4H (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) t4Dilog) := by
  refine Req_trans (Rsub_congr t4Trecip_sum
    (Radd_congr (Req_refl t4Dilog) (Rmul_congr (Req_refl t4H) t4Improper_eq))) ?_
  -- `X − (D + Y) ≈ (X − Y) − D`, then `X − Y ≈ t4H·((l5−l2) − (l5−l3)) ≈ t4H·(l3−l2)`.
  refine Req_trans (Rsub_congr (Req_refl _) (Radd_comm t4Dilog _)) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Rneg_Radd _ t4Dilog)) ?_
  refine Req_trans (Req_symm (Radd_assoc _ _ _)) ?_
  refine Radd_congr ?_ (Req_refl (Rneg t4Dilog))
  refine Req_trans (Req_symm (Rmul_sub_distrib t4H _ _)) ?_
  refine Rmul_congr (Req_refl t4H) ?_
  refine Req_trans (Radd_comm _ _) ?_
  refine Req_trans (Radd_congr (Rneg_Rsub_flip (logN 5 (by omega)) (logN 3 (by omega)))
    (Req_refl _)) ?_
  exact Rsub_telescope (logN 3 (by omega)) (logN 5 (by omega)) (logN 2 (by omega))

/-- **THE REALIZED CONE SLOT**: the `t4` log-tent with every interface field a genuine
    constructed integral — poles `= t4PoleA + t4PoleB` (`≈ 9/4 + t4H²`), archimedean tail
    `= t4ArchTail` (`≈ t4H·log(3/2) − t4Dilog`). -/
def t4Slot : WeilSlot where
  test := t4Test
  poles := Radd t4PoleA t4PoleB
  archTail := t4ArchTail

/-- **THE CONE SLOT'S WEIL VALUE, IN CLOSED FORM** (the dilog carried as the constructed
    `t4Dilog` — no closed form exists for it): numerically `≈ +0.098`. -/
theorem t4WeilValue_eq :
    Req (weilValue t4Slot)
      (Rsub (Radd (ofQ (⟨9, 4⟩ : Q) (by decide)) (Rmul t4H t4H))
        (Radd
          (Radd
            (Rmul (logN 2 (by omega))
              (Radd (logN 2 (by omega))
                (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (logN 2 (by omega)))))
            (Rmul (logN 3 (by omega))
              (Radd (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
                  (logN 3 (by omega)))
                (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
                  (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
                    (logN 3 (by omega)))))))
          (Radd (Rmul (Radd Rlog4pic Rgamma_h) t4H)
            (Rsub (Rmul t4H (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) t4Dilog)))) := by
  show Req (Rsub (Radd t4PoleA t4PoleB)
    (Radd (weilPrimePart t4Test) (Radd (weilArchConst t4Test) t4ArchTail))) _
  refine Rsub_congr (Radd_congr t4PoleA_eq t4PoleB_eq) ?_
  exact Radd_congr t4PrimePart_eq (Radd_congr t4ArchConst_eq t4ArchTail_eq)

-- ===========================================================================
-- The sign: W(t4) > 0.
-- ===========================================================================

set_option maxRecDepth 1000000 in
private theorem t4L2x2_nn : 0 ≤ (mul (⟨2, 1⟩ : Q) t4L2q).num := by decide

set_option maxRecDepth 1000000 in
private theorem t4U2_nn : 0 ≤ t4U2q.num := by decide

set_option maxRecDepth 1000000 in
private theorem t4U2x2_nn : 0 ≤ (mul (⟨2, 1⟩ : Q) t4U2q).num := by decide

set_option maxRecDepth 1000000 in
private theorem t4U3_nn : 0 ≤ t4U3q.num := by decide

set_option maxRecDepth 1000000 in
private theorem t4Slo_nn : 0 ≤ (Qsub (mul (⟨2, 1⟩ : Q) t4L2q) t4U3q).num := by decide

set_option maxRecDepth 1000000 in
private theorem t4L32_nn : 0 ≤ t4L32q.num := by decide

/-- The pole-side lower rational: `9/4 + (2·L2)²`. -/
def t4PLq : Q := add (⟨9, 4⟩ : Q) (mul (mul (⟨2, 1⟩ : Q) t4L2q) (mul (⟨2, 1⟩ : Q) t4L2q))

theorem t4PLq_den : 0 < t4PLq.den :=
  add_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (by decide) t4L2q_den)
    (Qmul_den_pos (by decide) t4L2q_den))

/-- The `2L − log 3` upper rational. -/
def t4Sq : Q := Qsub (mul (⟨2, 1⟩ : Q) t4U2q) t4L3q

theorem t4Sq_den : 0 < t4Sq.den :=
  Qsub_den_pos (Qmul_den_pos (by decide) t4U2q_den) t4L3q_den

/-- The subtracted-side upper rational: primes + archConst + tail. -/
def t4BUq : Q :=
  add (add (mul t4U2q (add t4U2q (mul (⟨1, 2⟩ : Q) t4U2q)))
       (mul t4U3q (add t4Sq (mul (⟨1, 3⟩ : Q) t4Sq))))
    (add (mul (add (⟨25316, 10000⟩ : Q) (⟨578, 1000⟩ : Q)) (mul (⟨2, 1⟩ : Q) t4U2q))
      (Qsub (mul (mul (⟨2, 1⟩ : Q) t4U2q) t4U32q) (⟨1909, 1000⟩ : Q)))

theorem t4BUq_den : 0 < t4BUq.den :=
  add_den_pos
    (add_den_pos
      (Qmul_den_pos t4U2q_den (add_den_pos t4U2q_den (Qmul_den_pos (by decide) t4U2q_den)))
      (Qmul_den_pos t4U3q_den (add_den_pos t4Sq_den (Qmul_den_pos (by decide) t4Sq_den))))
    (add_den_pos
      (Qmul_den_pos (add_den_pos (by decide) (by decide)) (Qmul_den_pos (by decide) t4U2q_den))
      (Qsub_den_pos (Qmul_den_pos (Qmul_den_pos (by decide) t4U2q_den) t4U32q_den) (by decide)))

/-- The pole side is above `t4PLq`. -/
theorem t4_P_ge : Rle (ofQ t4PLq t4PLq_den)
    (Radd (ofQ (⟨9, 4⟩ : Q) (by decide)) (Rmul t4H t4H)) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ (by decide)
    (Qmul_den_pos (Qmul_den_pos (by decide) t4L2q_den) (Qmul_den_pos (by decide) t4L2q_den))))) ?_
  refine Radd_le_add (Rle_refl (ofQ (⟨9, 4⟩ : Q) (by decide))) ?_
  exact mul_lower (Qmul_den_pos (by decide) t4L2q_den) (Qmul_den_pos (by decide) t4L2q_den)
    t4L2x2_nn t4L2x2_nn t4H_ge t4H_ge

/-- `2L − log 3` bounds: above a positive rational (for non-negativity) and below `t4Sq`. -/
theorem t4_S_ge : Rle (ofQ (Qsub (mul (⟨2, 1⟩ : Q) t4L2q) t4U3q)
      (Qsub_den_pos (Qmul_den_pos (by decide) t4L2q_den) t4U3q_den))
    (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega))) (logN 3 (by omega))) := by
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ
    (Qmul_den_pos (by decide) t4L2q_den) t4U3q_den))) ?_
  exact Radd_le_add t4H_ge (Rneg_le t4_U3)

theorem t4_S_nonneg :
    Rnonneg (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega))) (logN 3 (by omega))) :=
  Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_ofQ _ t4Slo_nn)) t4_S_ge)

theorem t4_S_le : Rle (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
      (logN 3 (by omega))) (ofQ t4Sq t4Sq_den) := by
  refine Rle_trans (Radd_le_add t4H_le (Rneg_le t4_L3)) ?_
  exact Rle_of_Req (Rsub_ofQ_ofQ (Qmul_den_pos (by decide) t4U2q_den) t4L3q_den)

/-- The subtracted side is below `t4BUq`. -/
theorem t4_B_le : Rle
    (Radd
      (Radd
        (Rmul (logN 2 (by omega))
          (Radd (logN 2 (by omega))
            (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (logN 2 (by omega)))))
        (Rmul (logN 3 (by omega))
          (Radd (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
              (logN 3 (by omega)))
            (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
              (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
                (logN 3 (by omega)))))))
      (Radd (Rmul (Radd Rlog4pic Rgamma_h) t4H)
        (Rsub (Rmul t4H (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) t4Dilog)))
    (ofQ t4BUq t4BUq_den) := by
  -- primes, first term: `l2·(l2 + l2/2) ≤ U2·(U2 + U2/2)`.
  have hP1 : Rle (Rmul (logN 2 (by omega))
      (Radd (logN 2 (by omega)) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (logN 2 (by omega)))))
      (ofQ (mul t4U2q (add t4U2q (mul (⟨1, 2⟩ : Q) t4U2q)))
        (Qmul_den_pos t4U2q_den (add_den_pos t4U2q_den (Qmul_den_pos (by decide) t4U2q_den)))) := by
    refine mul_upper t4U2q_den
      (add_den_pos t4U2q_den (Qmul_den_pos (by decide) t4U2q_den)) t4U2_nn t4_U2 ?_
      (Rnonneg_Radd (Rnonneg_logN 2 (by omega))
        (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) (Rnonneg_logN 2 (by omega))))
    refine Rle_trans (Radd_le_add t4_U2 (Rle_trans (Rmul_le_Rmul_left
      (Rnonneg_ofQ (by decide) (by decide)) t4_U2)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) t4U2q_den)))) ?_
    exact Rle_of_Req (Radd_ofQ_ofQ t4U2q_den (Qmul_den_pos (by decide) t4U2q_den))
  -- primes, second term: `l3·(S + S/3) ≤ U3·(t4Sq + t4Sq/3)`.
  have hP2 : Rle (Rmul (logN 3 (by omega))
      (Radd (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega))) (logN 3 (by omega)))
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega))) (logN 3 (by omega))))))
      (ofQ (mul t4U3q (add t4Sq (mul (⟨1, 3⟩ : Q) t4Sq)))
        (Qmul_den_pos t4U3q_den (add_den_pos t4Sq_den (Qmul_den_pos (by decide) t4Sq_den)))) := by
    refine mul_upper t4U3q_den
      (add_den_pos t4Sq_den (Qmul_den_pos (by decide) t4Sq_den)) t4U3_nn t4_U3 ?_
      (Rnonneg_Radd t4_S_nonneg
        (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) t4_S_nonneg))
    refine Rle_trans (Radd_le_add t4_S_le (Rle_trans (Rmul_le_Rmul_left
      (Rnonneg_ofQ (by decide) (by decide)) t4_S_le)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) t4Sq_den)))) ?_
    exact Rle_of_Req (Radd_ofQ_ofQ t4Sq_den (Qmul_den_pos (by decide) t4Sq_den))
  -- the archimedean constant: `(log4π+γ)·t4H ≤ (2.5316 + 0.578)·(2·U2)`.
  have hC : Rle (Rmul (Radd Rlog4pic Rgamma_h) t4H)
      (ofQ (mul (add (⟨25316, 10000⟩ : Q) (⟨578, 1000⟩ : Q)) (mul (⟨2, 1⟩ : Q) t4U2q))
        (Qmul_den_pos (add_den_pos (by decide) (by decide))
          (Qmul_den_pos (by decide) t4U2q_den))) := by
    refine mul_upper (add_den_pos (by decide) (by decide))
      (Qmul_den_pos (by decide) t4U2q_den) (by decide) ?_ t4H_le t4H_nonneg
    refine Rle_trans (Radd_le_add Rlog4pic_le Rgamma_h_le_578) ?_
    exact Rle_of_Req (Radd_ofQ_ofQ (by decide) (by decide))
  -- the tail: `t4H·(l3−l2) − t4Dilog ≤ (2·U2)·U32 − 1909/1000`.
  have hT : Rle (Rsub (Rmul t4H (Rsub (logN 3 (by omega)) (logN 2 (by omega)))) t4Dilog)
      (ofQ (Qsub (mul (mul (⟨2, 1⟩ : Q) t4U2q) t4U32q) (⟨1909, 1000⟩ : Q))
        (Qsub_den_pos (Qmul_den_pos (Qmul_den_pos (by decide) t4U2q_den) t4U32q_den)
          (by decide))) := by
    have h32nn : Rnonneg (Rsub (logN 3 (by omega)) (logN 2 (by omega))) :=
      Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_ofQ t4L32q_den t4L32_nn))
        t4_L32)
    refine Rle_trans (Radd_le_add
      (mul_upper (Qmul_den_pos (by decide) t4U2q_den) t4U32q_den t4U2x2_nn t4H_le
        t4_U32 h32nn)
      (Rle_trans (Rneg_le t4Dilog_ge) (Rle_of_Req (Rneg_ofQ (⟨1909, 1000⟩ : Q) (by decide))))) ?_
    exact Rle_of_Req (Radd_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos (by decide) t4U2q_den) t4U32q_den)
      (neg_den_pos (by decide)))
  refine Rle_trans (Radd_le_add (Radd_le_add hP1 hP2) (Radd_le_add hC hT)) ?_
  refine Rle_trans (Radd_le_add
    (Rle_of_Req (Radd_ofQ_ofQ _ _)) (Rle_of_Req (Radd_ofQ_ofQ _ _))) ?_
  exact Rle_of_Req (Radd_ofQ_ofQ _ _)

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 64000000 in
/-- **`W(t4) > 0` — THE FIRST CERTIFIED POSITIVITY ON THE AUTOCORRELATION CONE with a live
    prime side** (margin `≈ +0.0558`): the sign RH demands on the cone, realized at one cone
    element. Certified through the kernel-evaluated slot fields, the `M = 512` harmonic wedges,
    the standing `log 4π`/`γ` brackets, and the rational dilog lower bound; the closing `decide`
    is exact bignum arithmetic. NOT claimed: positivity for the cone (that uniform statement is
    RH); the crux fields stay `none`. -/
theorem t4WeilValue_pos : Pos (weilValue t4Slot) := by
  refine Pos_of_Rle_ofQ (c := Qsub t4PLq t4BUq)
    (by decide) (Qsub_den_pos t4PLq_den t4BUq_den) ?_
  refine Rle_trans ?_ (Rle_of_Req (Req_symm t4WeilValue_eq))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ t4PLq_den t4BUq_den))) ?_
  exact Radd_le_add t4_P_ge (Rneg_le t4_B_le)

end Multiplicity.UOR.Bridge.F1Square.Square
