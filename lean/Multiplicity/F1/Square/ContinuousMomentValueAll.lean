/-
F1 square — **the pre-Hilbert layer, brick 101** (`ContinuousMomentValueAll.lean`): **the `t^s`
identification at ALL rational points of `(0,1]`** — `compactPow a s (q) ≈ q^s` for every rational
`q ∈ (a, 1]` (`q ≥ a`), with NO lower cutoff. Brick 100 was capped at `q ≥ 1/4` by the `[1,4]` radius of
`RlogPos_ofQ_eq_logN`; that cap is lifted here, so the identification now holds at EVERY rational
partition point `i/(N+1) ∈ [a,1]` the certified integral samples.

The radius is lifted by the general bridge `RlogPos_eq_Rlog_gen` at `K = (A+D)²`: for the base `A/D`, the
convergence condition `1 ≤ K·(1−ρ²)` (with `ρ = (A−D)/(A+D)`, `1−ρ² = 4AD/(A+D)²`) becomes `1 ≤ 4AD`,
true for all `A, D ≥ 1`. So `RlogPos_ofQ_eq_logN_all` evaluates `log(A/D) = logN A − logN D` for every
`A ≥ D ≥ 1`, and the whole chain (`rrpowPos_ofQ_eq_all` → `gPowClamp_ofQ_eq_all` → `compactPow_ofQ_pow_all`)
follows with the `A ≤ 4D` hypothesis dropped throughout.

HONEST SCOPE. The identification now covers all rational `q ∈ (a,1]`; the general REAL-`t` identification
and the `a → 0` limit are still separate steps. No transform pair, no inversion, no positivity. Step 4 is
RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMomentFloor
import Multiplicity.F1Square.Analysis.ComplexArgAdd
import Multiplicity.F1Square.Analysis.RlogMulPos
import Multiplicity.F1Square.Analysis.LogRatCert
import Multiplicity.F1Square.Analysis.RadiusGen
import Multiplicity.F1Square.Analysis.RealPow

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

private theorem radd_sub_cancel' (X Y : Real) : Req (Rsub (Radd X Y) Y) X :=
  Req_trans (Radd_assoc X Y (Rneg Y))
    (Req_trans (Radd_congr (Req_refl X) (Radd_neg Y)) (Radd_zero X))

/-- The convergence certificate `hKF` for `RlogPos_eq_Rlog_gen`/`RlogPos_congr_gen` at `B = A/D`,
    `K = (A+D)²`: reduces to `(A+D)² ≤ (A+D)²·4AD`, i.e. `1 ≤ 4AD`. -/
private theorem hKF_gen (a d : Nat) (hd : 0 < d) (hda : d ≤ a) :
    Qle (⟨1, 1⟩ : Q) (mul (⟨((a + d) * (a + d) : Nat), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨(a : Int) - (d : Int), a + d⟩ ⟨(a : Int) - (d : Int), a + d⟩))) := by
  have ha1 : 1 ≤ a := Nat.le_trans hd hda
  show (1 : Int) * _ ≤ _ * 1
  simp only [mul, Qsub, add, neg]
  push_cast
  have hP : (0 : Int) ≤ ((a : Int) + d) * ((a : Int) + d) := Int.mul_nonneg (by omega) (by omega)
  have ha1i : (1 : Int) ≤ (a : Int) := by exact_mod_cast ha1
  have hd1i : (1 : Int) ≤ (d : Int) := by exact_mod_cast hd
  have hAD : (1 : Int) ≤ (a : Int) * (d : Int) := by
    calc (1 : Int) = 1 * 1 := by ring_uor
      _ ≤ (a : Int) * (d : Int) := Int.mul_le_mul ha1i hd1i (by omega) (by omega)
  have hMeq : (1 * (((a : Int) + d) * ((a : Int) + d)) + -(((a : Int) - d) * ((a : Int) - d)) * 1)
      = 4 * ((a : Int) * d) := by ring_uor
  have hM1 : (1 : Int) ≤ 4 * ((a : Int) * d) := by omega
  calc (1 : Int) * (1 * (1 * (((a : Int) + d) * ((a : Int) + d))))
      = ((a : Int) + d) * ((a : Int) + d) * 1 := by ring_uor
    _ ≤ ((a : Int) + d) * ((a : Int) + d) * (4 * ((a : Int) * d)) :=
        Int.mul_le_mul_of_nonneg_left hM1 hP
    _ = ((a : Int) + d) * ((a : Int) + d)
          * (1 * (((a : Int) + d) * ((a : Int) + d)) + -(((a : Int) - d) * ((a : Int) - d)) * 1) * 1 := by
        rw [hMeq]; ring_uor

/-- **The log-of-rational bridge, ALL `A ≥ D`**: `RlogPos(ofQ⟨A,D⟩) ≈ logN A − logN D` for every
    `D ≤ A` (`D ≥ 1`) — the `[1,4]` cap of `RlogPos_ofQ_eq_logN` lifted via `RlogPos_eq_Rlog_gen` at
    `K = (A+D)²`. -/
theorem RlogPos_ofQ_eq_logN_all (a d : Nat) (hd : 0 < d) (hda : d ≤ a)
    (k : Nat) (hk : Qlt (Qbound k) ((ofQ (⟨(a : Int), d⟩ : Q) hd).seq k)) :
    Req (RlogPos (ofQ (⟨(a : Int), d⟩ : Q) hd) k hk)
      (Rsub (logN a (Nat.le_trans hd hda)) (logN d hd)) := by
  have ha1 : 1 ≤ a := Nat.le_trans hd hda
  have hqge : Qle (⟨1, 1⟩ : Q) (⟨(a : Int), d⟩ : Q) := by show (1 : Int) * (d : Int) ≤ (a : Int) * 1; omega
  have hxpos : ∀ n, 0 < ((ofQ (⟨(a : Int), d⟩ : Q) hd).seq n).num := fun _ => by
    show (0 : Int) < ((a : Nat) : Int); exact_mod_cast ha1
  have hhi : ∀ n, Qle ((ofQ (⟨(a : Int), d⟩ : Q) hd).seq n) (⟨(a : Int), d⟩ : Q) := fun _ => Qle_refl _
  have hlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((ofQ (⟨(a : Int), d⟩ : Q) hd).seq n) (⟨(a : Int), d⟩ : Q)) := fun _ => by
    show (1 : Int) * ((d * d : Nat) : Int) ≤ ((a : Int) * (a : Int)) * 1
    have hsq : ((d : Int)) * (d : Int) ≤ (a : Int) * (a : Int) := by exact_mod_cast Nat.mul_le_mul hda hda
    push_cast; omega
  have hKr : (a + d) * (a + d) ≤ 2 * (((⟨(a : Int), d⟩ : Q).num.toNat + (⟨(a : Int), d⟩ : Q).den)
      * ((⟨(a : Int), d⟩ : Q).num.toNat + (⟨(a : Int), d⟩ : Q).den)
      + 4 * ((⟨(a : Int), d⟩ : Q).num.toNat + (⟨(a : Int), d⟩ : Q).den)) := by
    show (a + d) * (a + d) ≤ 2 * ((a + d) * (a + d) + 4 * (a + d)); omega
  have hA : Req (RexpReal (RlogPos (ofQ (⟨(a : Int), d⟩ : Q) hd) k hk)) (ofQ (⟨(a : Int), d⟩ : Q) hd) :=
    Req_trans
      (RexpReal_congr (RlogPos_eq_Rlog_gen (ofQ (⟨(a : Int), d⟩ : Q) hd) k hk
        (⟨(a : Int), d⟩ : Q) ((a + d) * (a + d)) hd hqge hxpos hhi hlo (hKF_gen a d hd hda) hKr))
      (Rexp_log_ratQ (⟨(a : Int), d⟩ : Q) hd hqge hxpos hhi hlo)
  have hB : Req (RexpReal (Radd (RlogPos (ofQ (⟨(a : Int), d⟩ : Q) hd) k hk) (logN d hd)))
      (RexpReal (logN a ha1)) :=
    Req_trans (RexpReal_add _ (logN d hd))
      (Req_trans (Rmul_congr hA (Rexp_logN d hd))
        (Req_trans (Rmul_ofQ_ofQ hd Nat.one_pos)
          (Req_trans (ofQ_congr (Qmul_den_pos hd Nat.one_pos) Nat.one_pos (by
              show ((a : Int) * (d : Int)) * 1 = (a : Int) * ((d * 1 : Nat) : Int); push_cast; ring_uor))
            (Req_symm (Rexp_logN a ha1)))))
  exact Req_trans (Req_symm (radd_sub_cancel' _ (logN d hd)))
    (Rsub_congr (RexpReal_inj_gen hB) (Req_refl (logN d hd)))

/-- `x^e = exp(e·(logN A − logN D))` at a rational base `⟨A,D⟩`, ALL `A ≥ D ≥ 1` (no cap). -/
theorem rrpowPos_ofQ_eq_all (A D : Nat) (hd : 0 < D) (hda : D ≤ A)
    (k : Nat) (hk : Qlt (Qbound k) ((ofQ (⟨(A : Int), D⟩ : Q) hd).seq k)) (e : Real) :
    Req (RrpowPos (ofQ (⟨(A : Int), D⟩ : Q) hd) k hk e)
        (RexpReal (Rmul e (Rsub (logN A (Nat.le_trans hd hda)) (logN D hd)))) := by
  unfold RrpowPos
  exact RexpReal_congr (Rmul_congr (Req_refl e) (RlogPos_ofQ_eq_logN_all A D hd hda k hk))

/-- The reciprocal-clamp is inert on a clean rational base `⟨A,D⟩`, ALL `A ≥ D ≥ 1` (no cap):
    `gPowClamp e (⟨A,D⟩) ≈ RrpowPos (⟨A,D⟩) e`, via `RlogPos_congr_gen` at `B = A/D`, `K = (A+D)²`. -/
theorem gPowClamp_ofQ_eq_all (A D : Nat) (hd : 0 < D) (hda : D ≤ A) (e : Real)
    (k : Nat) (hk : Qlt (Qbound k) ((ofQ (⟨(A : Int), D⟩ : Q) hd).seq k)) :
    Req (gPowClamp e (ofQ (⟨(A : Int), D⟩ : Q) hd))
        (RrpowPos (ofQ (⟨(A : Int), D⟩ : Q) hd) k hk e) := by
  have ha1 : 1 ≤ A := Nat.le_trans hd hda
  have hvge : Qle (⟨1, 1⟩ : Q) (⟨(A : Int), D⟩ : Q) := by show (1 : Int) * (D : Int) ≤ (A : Int) * 1; omega
  have hvpos : (0 : Int) < (A : Int) := by exact_mod_cast ha1
  have hvlo : Qle (⟨1, 1⟩ : Q) (mul (⟨(A : Int), D⟩ : Q) (⟨(A : Int), D⟩ : Q)) := by
    show (1 : Int) * ((D * D : Nat) : Int) ≤ ((A : Int) * (A : Int)) * 1
    have hsq : ((D : Int)) * (D : Int) ≤ (A : Int) * (A : Int) := by exact_mod_cast Nat.mul_le_mul hda hda
    push_cast; omega
  have hKr : (A + D) * (A + D) ≤ 2 * (((⟨(A : Int), D⟩ : Q).num.toNat + (⟨(A : Int), D⟩ : Q).den)
      * ((⟨(A : Int), D⟩ : Q).num.toNat + (⟨(A : Int), D⟩ : Q).den)
      + 4 * ((⟨(A : Int), D⟩ : Q).num.toNat + (⟨(A : Int), D⟩ : Q).den)) := by
    show (A + D) * (A + D) ≤ 2 * ((A + D) * (A + D) + 4 * (A + D)); omega
  unfold gPowClamp RrpowPos
  refine RexpReal_congr (Rmul_congr (Req_refl e) ?_)
  refine RlogPos_congr_gen (qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)) (ofQ (⟨(A : Int), D⟩ : Q) hd)
    1 (ge1_pos_witness (qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd))
        (qClampOne_ge1 (ofQ (⟨(A : Int), D⟩ : Q) hd) 1)) k hk
    (⟨(A : Int), D⟩ : Q) ((A + D) * (A + D)) hd hvge
    (qClampOne_pos _) (qClampOne_le hvge (fun _ => Qle_refl _)) (fun n => ?_)
    (fun _ => hvpos) (fun _ => Qle_refl _) (fun _ => hvlo)
    (hKF_gen A D hd hda) hKr
    (qClampOne_eq_of_ge (Rle_one_of_seq_ge1 (fun _ => hvge)))
  · have h1 : Qle (⟨1, 1⟩ : Q) ((qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)).seq n) := qClampOne_ge1 _ n
    have hd2 := (qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)).den_pos n
    show Qle (⟨1, 1⟩ : Q) (mul ((qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)).seq n) (⟨(A : Int), D⟩ : Q))
    simp only [Qle, mul] at h1 ⊢; push_cast at h1 ⊢
    have hDA : (D : Int) ≤ (A : Int) := by exact_mod_cast hda
    have hD0 : (0 : Int) ≤ (D : Int) := by omega
    have h1' : (((qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)).seq n).den : Int)
        ≤ ((qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)).seq n).num := by omega
    have hsnum : (0 : Int) ≤ ((qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)).seq n).num := by
      have : (1 : Int) ≤ (((qClampOne (ofQ (⟨(A : Int), D⟩ : Q) hd)).seq n).den : Int) := by
        exact_mod_cast hd2
      omega
    have key := Int.mul_le_mul h1' hDA hD0 hsnum
    omega

/-- **★ THE `t^s` IDENTIFICATION AT ALL RATIONAL POINTS OF `(a,1]`**:
    `compactPow a s (q) ≈ exp(−s·(log q_den − log q_num)) = q^s` for every rational `q ∈ (a,1]`,
    no lower cutoff. -/
theorem compactPow_ofQ_pow_all (a : Q) (han : 0 < a.num) (had : 0 < a.den) {s : Real} (hs : Rnonneg s)
    (q : Q) (hqd : 0 < q.den) (hqn : 0 < q.num) (haq : Qle a q) (hq1 : Qle q (⟨1, 1⟩ : Q)) :
    Req (compactPow a han had s (ofQ q hqd))
        (RexpReal (Rmul (Rneg s)
          (Rsub (logN q.den hqd)
                (logN q.num.toNat (by
                  have hc : (q.num.toNat : Int) = q.num := Int.toNat_of_nonneg (Int.le_of_lt hqn)
                  omega))))) := by
  have hcast : (q.num.toNat : Int) = q.num := Int.toNat_of_nonneg (Int.le_of_lt hqn)
  have hDpos : 0 < q.num.toNat := by omega
  have hDA : q.num.toNat ≤ q.den := by
    have h : q.num * 1 ≤ 1 * (q.den : Int) := by have := hq1; simp only [Qle] at this; exact this
    omega
  have hpow := compactPow_ofQ a han had hs hqd hqn haq
  refine Req_trans hpow ?_
  refine Req_trans (gPowClamp_ofQ_eq_all q.den q.num.toNat hDpos hDA (Rneg s)
    (2 * (Qinv q).den)
    (Qbound_lt_pos (by show (0 : Int) < (q.den : Int); exact_mod_cast hqd) (Qinv_den_pos hqn))) ?_
  exact rrpowPos_ofQ_eq_all q.den q.num.toNat hDpos hDA _ _ (Rneg s)

end Multiplicity.UOR.Bridge.F1Square.Square
