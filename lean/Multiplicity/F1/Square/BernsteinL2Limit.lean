/-
F1 square — **the L² density limit, packaged** (`BernsteinL2Limit.lean`), the Bernstein arc, sub-brick
L₃. Sub-brick L₂ gave the explicit-rate energy bound `‖φ − bernOpCTest φ ((k+1)²) …‖²_{L²[0,1]} ≤
(5·φ.L/(8(k+1)))²`; this brick packages it as a first-class `RTendsTo` limit:

  `RTendsTo (fun m => ⟨φ − bernOpCTest φ ((Kₘ+1)²) …, φ − …⟩) 0`,   `Kₘ = (φ.L.num.toNat+1)·(m+1)`,

i.e. the Bernstein polynomials converge to `φ` **in the L² norm**, in the codebase's canonical limit
predicate (Bishop modulus `2/(m+1) + 2/(n+1)`). The reindex `Kₘ = (φ.L.num.toNat+1)(m+1)` turns the L₂
rate `(5φ.L/(8(Kₘ+1)))²` into `≤ 1/(m+1)` (the squared denominator gives ample slack — one factor of
`Kₘ+1` dominates the numerator `25·φ.L.num²`), which the reusable rate⟹`RTendsTo` step packages into the
modulus. The energy is `≥ 0`, so `|energy − 0| = energy` and the one-sided rate suffices.

WHY (the Sonine route, step 3, the completed L² space). This is the L₂ density result delivered as a
genuine limit object — the packaged-limit companion of the durrOp strong-inversion limit (K1). The
Bernstein polynomials are a concrete L²-dense family, converging to every bounded-Lipschitz test in the
`L²[0,1]` norm as a formal limit.

HONEST SCOPE. One polynomial scheme's convergence to a bounded-Lipschitz test in the `L²[0,1]` norm,
packaged as an `RTendsTo` limit. NOT a completed L² space of *functions* (no limit member, no inversion
of an arbitrary L² element), NOT surjectivity onto function space, NOT positivity. Step 4 is RH; crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.BernsteinL2Density

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **RATE ⟹ `RTendsTo` MODULUS to `0`** (abstract): a real bound `|Y| ≤ 1/(m+1)` delivers the
    `RTendsTo`-to-`0` `.seq`-level bound `|Yₙ − 0ₙ| ≤ 2/(m+1) + 2/(n+1)`. The `L = 0` instance of the
    K1 rate⟹modulus packaging (`seq_diff_le` both directions, `Qabs_le_of_both`, relax `1/(m+1)`). -/
private theorem rate_to_seq {Y : Real} {m : Nat}
    (hrate : Rle (Rabs (Rsub Y zero)) (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m))) (n : Nat) :
    Qle (Qabs (Qsub (Y.seq n) (zero.seq n))) (add (⟨2, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) := by
  have hd1 : Qle (Qsub (Y.seq n) (zero.seq n)) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    seq_diff_le Y zero (⟨1, m + 1⟩ : Q) (Nat.succ_pos m) (Rle_of_Rabs_le hrate) n
  have hcomm : Req (Rabs (Rsub zero Y)) (Rabs (Rsub Y zero)) :=
    Req_trans (Rabs_congr (Req_symm (Rneg_Rsub Y zero))) (Rabs_Rneg (Rsub Y zero))
  have hrate' : Rle (Rabs (Rsub zero Y)) (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) :=
    Rle_trans (Rle_of_Req hcomm) hrate
  have hd2 : Qle (Qsub (zero.seq n) (Y.seq n)) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    seq_diff_le zero Y (⟨1, m + 1⟩ : Q) (Nat.succ_pos m) (Rle_of_Rabs_le hrate') n
  have he : Qeq (Qsub (zero.seq n) (Y.seq n)) (neg (Qsub (Y.seq n) (zero.seq n))) := by
    simp only [Qeq, Qsub, neg, add]; push_cast; ring_uor
  have h2 : Qle (neg (Qsub (Y.seq n) (zero.seq n))) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    Qle_congr_left (Qsub_den_pos (zero.den_pos n) (Y.den_pos n)) he hd2
  have hcombined : Qle (Qabs (Qsub (Y.seq n) (zero.seq n))) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    Qabs_le_of_both hd1 h2
  have hm12 : Qle (⟨1, m + 1⟩ : Q) (⟨2, m + 1⟩ : Q) := by simp only [Qle]; push_cast; omega
  exact Qle_trans (add_den_pos (Nat.succ_pos m) (Nat.succ_pos n)) hcombined
    (Qadd_le_add hm12 (Qle_refl (⟨2, n + 1⟩ : Q)))

/-- The reindexed energy rate: at `Kₘ = (φ.L.num.toNat+1)(m+1)` the residual energy is `≤ 1/(m+1)`.
    From L₂ (`bernOp_L2_converges`, energy `≤ (5φ.L/(8(Kₘ+1)))²`) and the rational bound
    `25·φ.L.num²·(m+1) ≤ 64·φ.L.den²·(Kₘ+1)²` — the squared denominator has one factor of `Kₘ+1` to
    spare over the linear numerator (`Kₘ+1 ≥ (φ.L.num.toNat+1)(m+1)`, and `64·φ.L.den²·(φ.L.num+1)² ≥
    25·φ.L.num²`). -/
private theorem energy_reindex_le (φ : L2Test) (m : Nat) :
    Rle (innerI
        (L2Test.sub φ (bernOpCTest φ
          (((φ.L.num.toNat + 1) * (m + 1) + 1) * ((φ.L.num.toNat + 1) * (m + 1) + 1))
          (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))))
        (L2Test.sub φ (bernOpCTest φ
          (((φ.L.num.toNat + 1) * (m + 1) + 1) * ((φ.L.num.toNat + 1) * (m + 1) + 1))
          (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)))))
      (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) := by
  refine Rle_trans (bernOp_L2_converges φ ((φ.L.num.toNat + 1) * (m + 1))) ?_
  refine Rle_ofQ_ofQ _ (Nat.succ_pos m) ?_
  simp only [Qle, mul]
  push_cast
  have hBtoNat : (φ.L.num.toNat : Int) = φ.L.num := Int.toNat_of_nonneg φ.hLn
  rw [hBtoNat]
  -- abbreviations for the chain
  have ha0 : (0 : Int) ≤ φ.L.num := φ.hLn
  have hd1 : (1 : Int) ≤ (φ.L.den : Int) := by exact_mod_cast φ.hLd
  have hP0 : (0 : Int) ≤ (m : Int) + 1 := by omega
  have hP1 : (1 : Int) ≤ (m : Int) + 1 := by omega
  have h_aa_nn : (0 : Int) ≤ φ.L.num * φ.L.num := Int.mul_nonneg ha0 ha0
  have h_aa_le : φ.L.num * φ.L.num ≤ (φ.L.num + 1) * (φ.L.num + 1) :=
    Int.mul_le_mul (by omega) (by omega) ha0 (by omega)
  have h25_64B : 25 * (φ.L.num * φ.L.num) ≤ 64 * ((φ.L.num + 1) * (φ.L.num + 1)) :=
    Int.le_trans (Int.mul_le_mul_of_nonneg_right (by omega) h_aa_nn)
      (Int.mul_le_mul_of_nonneg_left h_aa_le (by omega))
  have step1 : 25 * (φ.L.num * φ.L.num) * ((m : Int) + 1)
      ≤ 64 * ((φ.L.num + 1) * (φ.L.num + 1)) * ((m : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right h25_64B hP0
  have hP_PP : (m : Int) + 1 ≤ ((m : Int) + 1) * ((m : Int) + 1) := by
    have h := Int.mul_le_mul_of_nonneg_left hP1 hP0
    rwa [Int.mul_one] at h
  have h64B_nn : (0 : Int) ≤ 64 * ((φ.L.num + 1) * (φ.L.num + 1)) :=
    Int.mul_nonneg (by omega) (Int.mul_nonneg (by omega) (by omega))
  have step2 : 64 * ((φ.L.num + 1) * (φ.L.num + 1)) * ((m : Int) + 1)
      ≤ 64 * ((φ.L.num + 1) * (φ.L.num + 1)) * (((m : Int) + 1) * ((m : Int) + 1)) :=
    Int.mul_le_mul_of_nonneg_left hP_PP h64B_nn
  have hQ0nn : (0 : Int) ≤ (φ.L.num + 1) * ((m : Int) + 1) :=
    Int.mul_nonneg (by omega) hP0
  have hQ0p1 : (0 : Int) ≤ (φ.L.num + 1) * ((m : Int) + 1) + 1 := by have h := hQ0nn; omega
  have hQ0_le : ((φ.L.num + 1) * ((m : Int) + 1)) * ((φ.L.num + 1) * ((m : Int) + 1))
      ≤ ((φ.L.num + 1) * ((m : Int) + 1) + 1) * ((φ.L.num + 1) * ((m : Int) + 1) + 1) :=
    Int.mul_le_mul (by omega) (by omega) hQ0nn hQ0p1
  have h64_scale : 64 * (((φ.L.num + 1) * ((m : Int) + 1)) * ((φ.L.num + 1) * ((m : Int) + 1)))
      ≤ 64 * (((φ.L.num + 1) * ((m : Int) + 1) + 1) * ((φ.L.num + 1) * ((m : Int) + 1) + 1)) :=
    Int.mul_le_mul_of_nonneg_left hQ0_le (by omega)
  have hdd : (1 : Int) ≤ (φ.L.den : Int) * (φ.L.den : Int) :=
    Int.le_trans hd1 (by
      have h := Int.mul_le_mul_of_nonneg_left hd1 (show (0 : Int) ≤ (φ.L.den : Int) by omega)
      rwa [Int.mul_one] at h)
  have hX_nn : (0 : Int) ≤ ((φ.L.num + 1) * ((m : Int) + 1) + 1) * ((φ.L.num + 1) * ((m : Int) + 1) + 1) :=
    Int.mul_nonneg hQ0p1 hQ0p1
  have h64_le : (64 : Int) ≤ 64 * ((φ.L.den : Int) * (φ.L.den : Int)) := by
    have h := Int.mul_le_mul_of_nonneg_left hdd (show (0 : Int) ≤ 64 by omega)
    rwa [Int.mul_one] at h
  have h_final_scale : 64 * (((φ.L.num + 1) * ((m : Int) + 1) + 1) * ((φ.L.num + 1) * ((m : Int) + 1) + 1))
      ≤ 64 * ((φ.L.den : Int) * (φ.L.den : Int))
          * (((φ.L.num + 1) * ((m : Int) + 1) + 1) * ((φ.L.num + 1) * ((m : Int) + 1) + 1)) :=
    Int.mul_le_mul_of_nonneg_right h64_le hX_nn
  calc φ.L.num * 5 * (φ.L.num * 5) * ((m : Int) + 1)
      = 25 * (φ.L.num * φ.L.num) * ((m : Int) + 1) := by ring_uor
    _ ≤ 64 * ((φ.L.num + 1) * (φ.L.num + 1)) * ((m : Int) + 1) := step1
    _ ≤ 64 * ((φ.L.num + 1) * (φ.L.num + 1)) * (((m : Int) + 1) * ((m : Int) + 1)) := step2
    _ = 64 * (((φ.L.num + 1) * ((m : Int) + 1)) * ((φ.L.num + 1) * ((m : Int) + 1))) := by ring_uor
    _ ≤ 64 * (((φ.L.num + 1) * ((m : Int) + 1) + 1) * ((φ.L.num + 1) * ((m : Int) + 1) + 1)) := h64_scale
    _ ≤ 64 * ((φ.L.den : Int) * (φ.L.den : Int))
          * (((φ.L.num + 1) * ((m : Int) + 1) + 1) * ((φ.L.num + 1) * ((m : Int) + 1) + 1)) := h_final_scale
    _ = 1 * ((φ.L.den : Int) * (8 * ((φ.L.num + 1) * ((m : Int) + 1) + 1))
          * ((φ.L.den : Int) * (8 * ((φ.L.num + 1) * ((m : Int) + 1) + 1)))) := by ring_uor

/-- **★ THE BERNSTEIN POLYNOMIALS CONVERGE TO `φ` IN THE L² NORM** (packaged as an `RTendsTo` limit):
    the residual energy `⟨φ − bernOpCTest φ ((Kₘ+1)²) …, φ − …⟩ = ‖φ − B_{(Kₘ+1)²}φ‖²_{L²[0,1]}` tends to
    `0`, `Kₘ = (φ.L.num.toNat+1)(m+1)`. The reindex turns the L₂ rate `(5φ.L/(8(Kₘ+1)))²` into `≤ 1/(m+1)`
    (`energy_reindex_le`), which `rate_to_seq` packages into the canonical modulus; the energy is `≥ 0`, so
    `|energy − 0| = energy`. The L₂ density result as a first-class limit object — polynomial density in
    `L²[0,1]` delivered as a genuine limit. NOT a completed L² space of functions, NOT surjectivity, NOT
    positivity. Step 4 is RH. -/
theorem bernOp_L2_tendsTo (φ : L2Test) :
    RTendsTo (fun m => innerI
        (L2Test.sub φ (bernOpCTest φ
          (((φ.L.num.toNat + 1) * (m + 1) + 1) * ((φ.L.num.toNat + 1) * (m + 1) + 1))
          (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))))
        (L2Test.sub φ (bernOpCTest φ
          (((φ.L.num.toNat + 1) * (m + 1) + 1) * ((φ.L.num.toNat + 1) * (m + 1) + 1))
          (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)))))
      zero := by
  intro m n
  have hnn := innerI_self_nonneg (L2Test.sub φ (bernOpCTest φ
      (((φ.L.num.toNat + 1) * (m + 1) + 1) * ((φ.L.num.toNat + 1) * (m + 1) + 1))
      (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))))
  have hrate : Rle (Rabs (Rsub (innerI
        (L2Test.sub φ (bernOpCTest φ
          (((φ.L.num.toNat + 1) * (m + 1) + 1) * ((φ.L.num.toNat + 1) * (m + 1) + 1))
          (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))))
        (L2Test.sub φ (bernOpCTest φ
          (((φ.L.num.toNat + 1) * (m + 1) + 1) * ((φ.L.num.toNat + 1) * (m + 1) + 1))
          (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))))) zero))
      (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) :=
    Rle_trans (Rle_of_Req (Req_trans (Rabs_congr (Rsub_zero _)) (Rabs_of_nonneg hnn)))
      (energy_reindex_le φ m)
  exact rate_to_seq hrate n

end Multiplicity.UOR.Bridge.F1Square.Square
