import F1Square.Analysis.ComplexArgAdd
import F1Square.Analysis.RlogMulPos
import F1Square.Analysis.LiGrowth

/-!
# Unconditional `Clog` additivity for bounded moduli — discharging `hmod`

`Clog_add` (`ComplexArgAdd.lean`) isolates one explicit hypothesis `hmod`, the modulus-half
log-multiplicativity `log|zw|² = log|z|² + log|w|²`. This file **discharges** it in the
bounded-modulus regime (`1 ≤ |z|², |w|² ≤ B`, small radius):

* `RlogPos_cnormSq_mul` proves exactly the `hmod` proposition from elementary positivity/bound data
  on the squared moduli — via `cnormSq_mul` (`|zw|² = |z|²·|w|²`), `RlogPos_congr`, and `RlogPos_mul`.
* `Clog_add_bounded` then states `Clog(zw) = Clog z + Clog w` with **no** `hmod` hypothesis — the
  modulus seam is now a theorem, not an assumption.

The regime (squared moduli in `[1,B]`) is the substrate's small-radius artanh window; the general
case awaits relaxing the `ρ² ≤ 1/2` continuity lemmas.
-/

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 1600000 in
/-- **The `Clog_add` modulus seam, discharged** (bounded modulus): `log|zw|² = log|z|² + log|w|²`.
    `cnormSq(zw) ≈ |z|²·|w|²` (`cnormSq_mul`) carries `RlogPos` across (`RlogPos_congr`), then
    `RlogPos_mul` splits the product. Exactly the `hmod` proposition of `Clog_add`. -/
theorem RlogPos_cnormSq_mul (z w : Complex)
    (knz : Nat) (hknz : Qlt (Qbound knz) ((cnormSq z).seq knz))
    (knw : Nat) (hknw : Qlt (Qbound knw) ((cnormSq w).seq knw))
    (knzw : Nat) (hknzw : Qlt (Qbound knzw) ((cnormSq (Cmul z w)).seq knzw))
    (B : Q) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hXpos : ∀ n, 0 < ((cnormSq z).seq n).num) (hXhi : ∀ n, Qle ((cnormSq z).seq n) B)
    (hXlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq z).seq n) B))
    (hXge1 : ∀ n, Qle (⟨1, 1⟩ : Q) ((cnormSq z).seq n))
    (hYpos : ∀ n, 0 < ((cnormSq w).seq n).num) (hYhi : ∀ n, Qle ((cnormSq w).seq n) B)
    (hYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq w).seq n) B))
    (hYge1 : ∀ n, Qle (⟨1, 1⟩ : Q) ((cnormSq w).seq n))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hXYpos : ∀ n, 0 < ((Rmul (cnormSq z) (cnormSq w)).seq n).num)
    (hXYhi : ∀ n, Qle ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B))
    (hXYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B)))
    (hXYge1 : ∀ n, Qle (⟨1, 1⟩ : Q) ((Rmul (cnormSq z) (cnormSq w)).seq n))
    (hZWpos : ∀ n, 0 < ((cnormSq (Cmul z w)).seq n).num)
    (hZWhi : ∀ n, Qle ((cnormSq (Cmul z w)).seq n) (mul B B))
    (hZWlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq (Cmul z w)).seq n) (mul B B)))
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
              ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hσhalf : Qle (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
              ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩) ⟨1, 2⟩)
    (hσ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩ ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩))) :
    Req (RlogPos (cnormSq (Cmul z w)) knzw hknzw)
        (Radd (RlogPos (cnormSq z) knz hknz) (RlogPos (cnormSq w) knw hknw)) := by
  have hxy' : Qlt (Qbound 1) ((Rmul (cnormSq z) (cnormSq w)).seq 1) := ge1_pos_witness _ (hXYge1 1)
  refine Req_trans ?_ (RlogPos_mul (cnormSq z) (cnormSq w) knz hknz knw hknw 1 hxy'
    B hBd hBge hXpos hXhi hXlo hXge1 hYpos hYhi hYlo hYge1 hB2d hB2ge hXYpos hXYhi hXYlo hρ2 hρσ hσhalf hσ2)
  exact RlogPos_congr (cnormSq (Cmul z w)) (Rmul (cnormSq z) (cnormSq w)) knzw hknzw 1 hxy'
    (mul B B) hB2d hB2ge hZWpos hZWhi hZWlo hXYpos hXYhi hXYlo hσ2 (cnormSq_mul z w)

set_option maxHeartbeats 1600000 in
/-- **★ unconditional complex logarithm additivity** (bounded modulus) `Clog(zw) = Clog z + Clog w`,
    with the modulus seam `hmod` **discharged** by `RlogPos_cnormSq_mul`. The hypothesis list is the
    same `Clog_add` argument data plus elementary positivity/bound data on the squared moduli
    (`1 ≤ |z|², |w|² ≤ B`, small radius) — no `RlogPos`-multiplicativity assumption. -/
theorem Clog_add_bounded (z w : Complex)
    (knz : Nat) (hknz : Qlt (Qbound knz) ((cnormSq z).seq knz))
    (knw : Nat) (hknw : Qlt (Qbound knw) ((cnormSq w).seq knw))
    (knzw : Nat) (hknzw : Qlt (Qbound knzw) ((cnormSq (Cmul z w)).seq knzw))
    (kz : Nat) (hkz : Qlt (Qbound kz) (z.re.seq kz))
    (kw : Nat) (hkw : Qlt (Qbound kw) (w.re.seq kw))
    (kzw : Nat) (hzw : Qlt (Qbound kzw) ((Cmul z w).re.seq kzw))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2arg : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hbs : ∀ n, Qle (Qabs ((Rdiv z.im z.re kz hkz).seq n)) ρ)
    (hbt : ∀ n, Qle (Qabs ((Rdiv w.im w.re kw hkw).seq n)) ρ)
    (hbzw : ∀ n, Qle (Qabs ((Rdiv (Cmul z w).im (Cmul z w).re kzw hzw).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs (vval ((Rdiv z.im z.re kz hkz).seq n)
      ((Rdiv w.im w.re kw hkw).seq n))) ρ)
    (B : Q) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hXpos : ∀ n, 0 < ((cnormSq z).seq n).num) (hXhi : ∀ n, Qle ((cnormSq z).seq n) B)
    (hXlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq z).seq n) B))
    (hXge1 : ∀ n, Qle (⟨1, 1⟩ : Q) ((cnormSq z).seq n))
    (hYpos : ∀ n, 0 < ((cnormSq w).seq n).num) (hYhi : ∀ n, Qle ((cnormSq w).seq n) B)
    (hYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq w).seq n) B))
    (hYge1 : ∀ n, Qle (⟨1, 1⟩ : Q) ((cnormSq w).seq n))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hXYpos : ∀ n, 0 < ((Rmul (cnormSq z) (cnormSq w)).seq n).num)
    (hXYhi : ∀ n, Qle ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B))
    (hXYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B)))
    (hXYge1 : ∀ n, Qle (⟨1, 1⟩ : Q) ((Rmul (cnormSq z) (cnormSq w)).seq n))
    (hZWpos : ∀ n, 0 < ((cnormSq (Cmul z w)).seq n).num)
    (hZWhi : ∀ n, Qle ((cnormSq (Cmul z w)).seq n) (mul B B))
    (hZWlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq (Cmul z w)).seq n) (mul B B)))
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
              ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hσhalf : Qle (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
              ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩) ⟨1, 2⟩)
    (hσ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩ ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩))) :
    Ceq (Clog (Cmul z w) knzw hknzw kzw hzw ρ hρ0 hρd hlt hbzw)
        (Cadd (Clog z knz hknz kz hkz ρ hρ0 hρd hlt hbs)
              (Clog w knw hknw kw hkw ρ hρ0 hρd hlt hbt)) :=
  Clog_add z w knz hknz knw hknw knzw hknzw kz hkz kw hkw kzw hzw ρ hρ0 hρd hlt hlt16 h2ρ hhalf hρ4
    hρ2arg hρ8 hρ1 hbs hbt hbzw hbw
    (RlogPos_cnormSq_mul z w knz hknz knw hknw knzw hknzw B hBd hBge
      hXpos hXhi hXlo hXge1 hYpos hYhi hYlo hYge1 hB2d hB2ge
      hXYpos hXYhi hXYlo hXYge1 hZWpos hZWhi hZWlo hρ2 hρσ hσhalf hσ2)

end UOR.Bridge.F1Square.Analysis
