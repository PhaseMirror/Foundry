/-
F1 square — **the pre-Hilbert layer, brick 20** (`MellinHat.lean`): **THE MELLIN TRANSFORM AT
INTEGER POINTS** — the twisted tail converges and `f̂(n) = ∫₀^∞ φ(t)·tⁿ dt` exists as a
constructed real.

The twist `tⁿ` grows, so the twisted integrand is built per window from the algebra: on window
`[m+1, m+2]` it is the product test `φ · powWinTest m n` (brick 19), whose window integral is
`twTerm`. Convergence trades decay for growth:

- `tw_collapse` — the exponent-generic estimate `C·(m+2)ⁿ/(m+1)^{n+2} ≤ C·2ⁿ/((m+1)m)`, from
  the Nat core `(m+2)ⁿ·(m+1)·m ≤ 2ⁿ·(m+1)^{n+2}` (`(m+2)ⁿ ≤ (2(m+1))ⁿ` and two spare `(m+1)`
  factors), the power atoms generalized before the ring normalizer.
- `twTerm_bound` — for a test with exponent-`(n+2)` window decay, the twisted window integrals
  obey the gateway's `K/((m+1)m)` shape with `K := C·2ⁿ` (the window bound of brick 18 against
  the product's pointwise bound, `powWinTest_M_le` feeding the power factor).
- **`twTail`** — the twisted half-line tail `∫₁^∞ φ(t)·tⁿ dt` as a Bishop limit
  (`genSum_RReg` at modulus `C·2ⁿ`), and **`mellinHat φ n = mellinMoment φ n + twTail`** —
  the transform at the integer point `n`: compact piece (brick 10's moment, the `[0,1]` twist)
  plus convergent twisted tail. The first constructed value of the `f ↦ f̂` direction.

HONEST SCOPE. The transform at integer points for exponent-decaying tests, window-clamped
twist (equal to `tⁿ` on each window by brick 19's inertness); no continuous parameter, no
transform pair, no inversion, no coupling. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.WindowPower
import Foundations.F1.Analysis.MellinDecay
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Left multiplication by a nonnegative rational is monotone (the public mirror of the
    `DilogPhi`-private lemma). -/
theorem qmul_le_left_mono {s p q : Q} (hs : 0 ≤ s.num) (h : Qle p q) :
    Qle (mul s p) (mul s q) := by
  simp only [Qle, mul] at h ⊢
  push_cast
  have e1 : (s.num * p.num) * ((s.den : Int) * (q.den : Int))
      = (s.num * (s.den : Int)) * (p.num * (q.den : Int)) := by ring_uor
  have e2 : (s.num * q.num) * ((s.den : Int) * (p.den : Int))
      = (s.num * (s.den : Int)) * (q.num * (p.den : Int)) := by ring_uor
  rw [e1, e2]
  exact Int.mul_le_mul_of_nonneg_left h (Int.mul_nonneg hs (Int.ofNat_nonneg s.den))

/-- The Nat core of the twisted decay: `(m+2)ⁿ·(m+1)·m ≤ 2ⁿ·(m+1)^{n+2}`. -/
private theorem pow_window_core (m n : Nat) :
    (m + 2) ^ n * ((m + 1) * m) ≤ 2 ^ n * (m + 1) ^ (n + 2) := by
  have h1 : (m + 2) ^ n ≤ 2 ^ n * (m + 1) ^ n := by
    calc (m + 2) ^ n ≤ (2 * (m + 1)) ^ n := Nat.pow_le_pow_left (by omega) n
    _ = 2 ^ n * (m + 1) ^ n := Nat.mul_pow 2 (m + 1) n
  have h2 : (m + 1) * m ≤ (m + 1) * (m + 1) := Nat.mul_le_mul_left _ (by omega)
  have h3 : (m + 1) ^ n * ((m + 1) * (m + 1)) = (m + 1) ^ (n + 2) := by
    rw [Nat.pow_succ, Nat.pow_succ, Nat.mul_assoc]
  calc (m + 2) ^ n * ((m + 1) * m)
      ≤ (2 ^ n * (m + 1) ^ n) * ((m + 1) * (m + 1)) := Nat.mul_le_mul h1 h2
    _ = 2 ^ n * ((m + 1) ^ n * ((m + 1) * (m + 1))) := Nat.mul_assoc _ _ _
    _ = 2 ^ n * (m + 1) ^ (n + 2) := by rw [h3]

/-- **The exponent-generic collapse**: `C·(m+2)ⁿ/(m+1)^{n+2} ≤ (C·2ⁿ)/((m+1)m)`. -/
private theorem tw_collapse {C : Q} (_hCd : 0 < C.den) (hCn : 0 ≤ C.num) (m n : Nat) :
    Qle (mul (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) (⟨(((m + 2) ^ n : Nat) : Int), 1⟩ : Q))
        (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q)) := by
  show ((C.num * 1) * (((m + 2) ^ n : Nat) : Int))
        * ((((C.den * 1) * ((m + 1) * m) : Nat)) : Int)
      ≤ ((C.num * ((2 ^ n : Nat) : Int)) * 1)
        * ((((C.den * ((m + 1) ^ (n + 2))) * 1 : Nat)) : Int)
  push_cast
  generalize hA : ((m : Int) + 2) ^ n = A
  generalize hB : ((m : Int) + 1) ^ (n + 2) = B
  generalize hT : (2 : Int) ^ n = T
  have hcoreZ : A * (((m : Int) + 1) * (m : Int)) ≤ T * B := by
    rw [← hA, ← hB, ← hT]
    exact_mod_cast pow_window_core m n
  have e1 : C.num * 1 * A * ((C.den : Int) * 1 * (((m : Int) + 1) * (m : Int)))
      = (C.num * (C.den : Int)) * (A * (((m : Int) + 1) * (m : Int))) := by ring_uor
  have e2 : C.num * T * 1 * ((C.den : Int) * B * 1)
      = (C.num * (C.den : Int)) * (T * B) := by ring_uor
  rw [e1, e2]
  exact Int.mul_le_mul_of_nonneg_left hcoreZ
    (Int.mul_nonneg hCn (Int.ofNat_nonneg C.den))

/-- **The twisted window integral** `∫_{m+1}^{m+2} φ(t)·tⁿ dt` — the interval integral of the
    algebra product `φ · powWinTest m n` (certificates automatic; equal to `φ·tⁿ` on the
    window by brick 19's inertness). -/
def twTerm (φ : L2Test) (n m : Nat) : Real :=
  riemannIntegralI (l2L_den φ (powWinTest m n)) (l2L_num φ (powWinTest m n))
    (l2lip φ (powWinTest m n)) (l2fc φ (powWinTest m n))
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)

/-- **The twisted gateway data**: for a test with exponent-`(n+2)` window decay, the twisted
    window integrals obey the two-sided `(C·2ⁿ)/((m+1)m)` bounds. -/
theorem twTerm_bound (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    ∀ m, ∀ hm : 1 ≤ m,
      Rle (Rneg (ofQ (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q))
            (Qmul_den_pos (Qmul_den_pos hCd Nat.one_pos) (digamma_succ_mul_pos hm))))
          (twTerm φ n m)
      ∧ Rle (twTerm φ n m)
          (ofQ (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q))
            (Qmul_den_pos (Qmul_den_pos hCd Nat.one_pos) (digamma_succ_mul_pos hm))) := by
  intro m hm
  have hpt : ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((fun t => Rmul (φ.f t) ((powWinTest m n).f t))
          (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) ((powWinTest m n).M))
          (Qmul_den_pos (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))
            (powWinTest m n).hMd)) := by
    intro x h0 h1
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _)
      (Rnonneg_ofQ (powWinTest m n).hMd (powWinTest m n).hMn)
      (hdec m x h0 h1) ((powWinTest m n).hbd _)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ _ _)
  have habs : Rle (Rabs (twTerm φ n m))
      (ofQ (mul (⟨1, 1⟩ : Q)
          (mul (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) ((powWinTest m n).M)))
        (Qmul_den_pos (by decide)
          (Qmul_den_pos (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))
            (powWinTest m n).hMd))) :=
    riemannIntegralI_abs_le_window (l2L_den φ (powWinTest m n)) (l2L_num φ (powWinTest m n))
      (l2lip φ (powWinTest m n)) (l2fc φ (powWinTest m n))
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      (mul (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) ((powWinTest m n).M))
      Nat.one_pos (by decide) (by decide)
      (Qmul_den_pos (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))
        (powWinTest m n).hMd)
      hpt
  have hq : Qle (mul (⟨1, 1⟩ : Q)
        (mul (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) ((powWinTest m n).M)))
      (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q)) := by
    refine Qle_congr_left
      (a := mul (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) ((powWinTest m n).M))
      (Qmul_den_pos (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))
        (powWinTest m n).hMd)
      (by simp only [Qeq, mul]; push_cast; ring_uor) ?_
    refine Qle_trans (Qmul_den_pos
      (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))) Nat.one_pos) ?_
      (tw_collapse hCd hCn m n)
    exact qmul_le_left_mono
      (Int.mul_nonneg hCn (by show (0 : Int) ≤ 1; decide))
      (powWinTest_M_le m n)
  have habs2 : Rle (Rabs (twTerm φ n m))
      (ofQ (mul (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos hCd Nat.one_pos) (digamma_succ_mul_pos hm))) :=
    Rle_trans habs (Rle_ofQ_ofQ _ _ hq)
  exact ⟨Rneg_le_of_Rabs_le habs2, Rle_of_Rabs_le habs2⟩

/-- **The twisted half-line tail** `∫₁^∞ φ(t)·tⁿ dt` — the Bishop limit of the twisted window
    sums, regular at the modulus `C·2ⁿ`. -/
def twTail (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) : Real :=
  Rlim (fun j => genSum (fun m => twTerm φ n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))
    (genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos)
      (Int.mul_nonneg hCn (Int.ofNat_nonneg _)) (twTerm_bound φ n hCd hCn hdec))

/-- **THE MELLIN TRANSFORM AT THE INTEGER POINT `n`**: `f̂(n) = ∫₀^∞ φ(t)·tⁿ dt` — the compact
    piece is brick 10's moment (the `[0,1]` twist), the tail is the convergent twisted sum. A
    constructed real: the first value of the `f ↦ f̂` direction. -/
def mellinHat (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) : Real :=
  Radd (mellinMoment φ n) (twTail φ n hCd hCn hdec)

-- ===========================================================================
-- The first evaluation: compactly supported tests.
-- ===========================================================================

/-- A test vanishing on the half-line windows satisfies the decay hypothesis at `C = 0`. -/
theorem hdec_of_supp (φ : L2Test) (n : Nat)
    (hsupp : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Req (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
        Nat.one_pos (by decide) x)) zero) :
    ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul (⟨0, 1⟩ : Q) (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos (by decide) (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) := by
  intro m x h0 h1
  refine Rle_trans (Rle_of_Req (Req_trans (Rabs_congr (hsupp m x h0 h1)) Rabs_zero)) ?_
  exact Rle_zero_of_Rnonneg (Rnonneg_ofQ _ (by show (0 : Int) ≤ 0 * 1; decide))

/-- **THE TRANSFORM OF A COMPACTLY SUPPORTED TEST IS ITS MOMENT SEQUENCE**: if `φ` vanishes on
    `[1, ∞)` (at every window point), then `f̂(n) ≈ mellinMoment φ n` — the twisted tail
    vanishes term by term, and the constructed transform collapses to brick 10's moments. The
    first evaluation of `mellinHat`, welding the compact and half-line Mellin objects. -/
theorem mellinHat_compact (φ : L2Test) (n : Nat)
    (hsupp : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Req (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
        Nat.one_pos (by decide) x)) zero) :
    Req (mellinHat φ n (by decide) (by show (0 : Int) ≤ 0; decide)
          (hdec_of_supp φ n hsupp))
        (mellinMoment φ n) := by
  have htw : ∀ m, Req (twTerm φ n m) zero := by
    intro m
    have hpt : ∀ x, Rle zero x → Rle x one →
        Rle (Rabs ((fun t => Rmul (φ.f t) ((powWinTest m n).f t))
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
          (ofQ (⟨0, 1⟩ : Q) (by decide)) := by
      intro x h0 h1
      refine Rle_of_Req (Req_trans (Rabs_congr (Req_trans
        (Rmul_congr (hsupp m x h0 h1) (Req_refl _))
        (Req_trans (Rmul_comm zero _) (Rmul_zero _)))) Rabs_zero)
    have habs : Rle (Rabs (twTerm φ n m))
        (ofQ (mul (⟨1, 1⟩ : Q) (⟨0, 1⟩ : Q))
          (Qmul_den_pos (by decide) (by decide))) :=
      riemannIntegralI_abs_le_window (l2L_den φ (powWinTest m n))
        (l2L_num φ (powWinTest m n)) (l2lip φ (powWinTest m n)) (l2fc φ (powWinTest m n))
        (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) (⟨0, 1⟩ : Q)
        Nat.one_pos (by decide) (by decide) (by decide) hpt
    have hz : Req (ofQ (mul (⟨1, 1⟩ : Q) (⟨0, 1⟩ : Q))
        (Qmul_den_pos (by decide) (by decide))) zero :=
      Req_of_seq_Qeq (fun n => by
        show Qeq (mul (⟨1, 1⟩ : Q) (⟨0, 1⟩ : Q)) (⟨0, 1⟩ : Q)
        decide)
    have hup : Rle (twTerm φ n m) zero :=
      Rle_trans (Rle_of_Rabs_le habs) (Rle_of_Req hz)
    have hlo : Rle zero (twTerm φ n m) := by
      have h1 := Rneg_le_of_Rabs_le habs
      refine Rle_trans (Rle_of_Req (Req_symm (Req_trans (Rneg_congr hz)
        (Req_trans (Req_symm (Radd_zero (Rneg zero)))
          (Req_trans (Radd_comm (Rneg zero) zero) (Radd_neg zero)))))) h1
    exact Rle_antisymm hup hlo
  have hgs : ∀ M, Req (genSum (fun m => twTerm φ n m) M) zero := by
    intro M
    induction M with
    | zero => exact Req_refl zero
    | succ k ih => exact Req_trans (Radd_congr ih (htw k)) (Radd_zero zero)
  have htail : Req (twTail φ n (by decide) (by show (0 : Int) ≤ 0; decide)
      (hdec_of_supp φ n hsupp)) zero :=
    Rlim_zero _ _ (fun j => hgs _)
  exact Req_trans (Radd_congr (Req_refl _) htail) (Radd_zero _)

end Multiplicity.UOR.Bridge.F1Square.Square
