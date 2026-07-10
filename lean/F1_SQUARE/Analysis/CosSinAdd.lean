/-
F1 square — **the trigonometric Cauchy product** toward `cos² + sin² = 1` (and hence `|cos|,|sin| ≤ 1`,
the keystone for the `Czeta` modulus). This file builds the per-term algebra of the alternating series:
`altTerm q off i · altTerm q off' j ≈ (−q²)^{i+j} / ((2i+off)!·(2j+off')!)`, the trig analogue of the
exponential product term. Combined with `alternating_binomial` (`Σ_k (−1)^k C(2m,k) = 0`) it gives the
per-degree Pythagorean coefficient vanishing.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.Binomial
import F1Square.Analysis.CosSin
import F1Square.Analysis.ROrder

namespace UOR.Bridge.F1Square.Analysis

/-- Four-factor rearrangement `(a·b)·(c·d) ≈ (a·c)·(b·d)`. -/
theorem Qmul4_rearrange (a b c d : Q) : Qeq (mul (mul a b) (mul c d)) (mul (mul a c) (mul b d)) := by
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **The trig product term**: `((−q²)ⁱ/(2i+off)!) · ((−q²)ʲ/(2j+off')!) ≈ (−q²)^{i+j}/((2i+off)!·(2j+off')!)`. -/
theorem altTerm_mul {q : Q} (hqd : 0 < q.den) (off off' i j : Nat) :
    Qeq (mul (altTerm q off i) (altTerm q off' j))
      (mul (qpow (neg (mul q q)) (i + j)) ⟨1, fct (2 * i + off) * fct (2 * j + off')⟩) := by
  have hN : 0 < (neg (mul q q)).den := Nat.mul_pos hqd hqd
  have h1 : Qeq (mul (altTerm q off i) (altTerm q off' j))
      (mul (mul (qpow (neg (mul q q)) i) (qpow (neg (mul q q)) j))
        (mul (⟨1, fct (2 * i + off)⟩ : Q) ⟨1, fct (2 * j + off')⟩)) :=
    Qmul4_rearrange (qpow (neg (mul q q)) i) ⟨1, fct (2 * i + off)⟩
      (qpow (neg (mul q q)) j) ⟨1, fct (2 * j + off')⟩
  refine Qeq_trans ?_ h1 ?_
  · exact Qmul_den_pos (Qmul_den_pos (qpow_den_pos hN i) (qpow_den_pos hN j))
      (Qmul_den_pos (fct_pos _) (fct_pos _))
  · exact Qmul_congr (Qeq_symm (qpow_add (neg (mul q q)) hN i j)) (Qeq_refl _)

/-- **Convolution factoring**: the degree-`d` self-convolution of the `off`-shifted alternating series
    factors as `(−q²)^d · Σ_{i≤d} 1/((2i+off)!·(2(d−i)+off)!)`. -/
theorem altConv_factor {q : Q} (hqd : 0 < q.den) (off d : Nat) :
    Qeq (Fsum (fun i => mul (altTerm q off i) (altTerm q off (d - i))) d)
      (mul (qpow (neg (mul q q)) d)
        (Fsum (fun i => (⟨1, fct (2 * i + off) * fct (2 * (d - i) + off)⟩ : Q)) d)) := by
  have hN : 0 < (neg (mul q q)).den := Nat.mul_pos hqd hqd
  have hfd : ∀ i, 0 < ((⟨1, fct (2 * i + off) * fct (2 * (d - i) + off)⟩ : Q)).den :=
    fun i => Nat.mul_pos (fct_pos _) (fct_pos _)
  have hstep : Qeq (Fsum (fun i => mul (altTerm q off i) (altTerm q off (d - i))) d)
      (Fsum (fun i => mul (qpow (neg (mul q q)) d)
        (⟨1, fct (2 * i + off) * fct (2 * (d - i) + off)⟩ : Q)) d) :=
    Fsum_congr_le (fun i hi => by
      have h := altTerm_mul hqd off off i (d - i)
      rw [show i + (d - i) = d from by omega] at h
      exact h)
  exact Qeq_trans (Fsum_den_pos (fun i => Qmul_den_pos (qpow_den_pos hN d) (hfd i)) d) hstep
    (Fsum_mul_left (qpow_den_pos hN d) hfd d)

/-- `(x+y)+z ≈ (x+z)+y`. -/
theorem Qadd_perm (x y z : Q) : Qeq (add (add x y) z) (add (add x z) y) := by
  simp only [Qeq, add]; push_cast; ring_uor

/-- `((e+o)+x)+y ≈ (e+y)+(o+x)`. -/
theorem Qadd_perm4 (e o x y : Q) : Qeq (add (add (add e o) x) y) (add (add e y) (add o x)) := by
  simp only [Qeq, add]; push_cast; ring_uor

/-- **Parity split**: `Σ_{i=0}^{2m+2} aᵢ ≈ (Σ_{j=0}^{m+1} a_{2j}) + (Σ_{j=0}^{m} a_{2j+1})`. -/
theorem Fsum_parity_split (a : Nat → Q) (ha : ∀ i, 0 < (a i).den) :
    ∀ m, Qeq (Fsum a (2 * m + 2))
      (add (Fsum (fun j => a (2 * j)) (m + 1)) (Fsum (fun j => a (2 * j + 1)) m))
  | 0 => Qadd_perm (a 0) (a 1) (a 2)
  | (m + 1) => by
      show Qeq (add (add (Fsum a (2 * m + 2)) (a (2 * m + 2 + 1))) (a (2 * m + 2 + 2)))
        (add (add (Fsum (fun j => a (2 * j)) (m + 1)) (a (2 * m + 2 + 2)))
          (add (Fsum (fun j => a (2 * j + 1)) m) (a (2 * m + 2 + 1))))
      exact Qeq_trans
        (add_den_pos (add_den_pos (add_den_pos (Fsum_den_pos (fun j => ha (2 * j)) (m + 1))
          (Fsum_den_pos (fun j => ha (2 * j + 1)) m)) (ha (2 * m + 2 + 1))) (ha (2 * m + 2 + 2)))
        (Qadd_congr (Qadd_congr (Fsum_parity_split a ha m) (Qeq_refl (a (2 * m + 2 + 1))))
          (Qeq_refl (a (2 * m + 2 + 2))))
        (Qadd_perm4 (Fsum (fun j => a (2 * j)) (m + 1)) (Fsum (fun j => a (2 * j + 1)) m)
          (a (2 * m + 2 + 1)) (a (2 * m + 2 + 2)))

/-- Integer running sum (the numerator sum for a constant-denominator `Fsum`). -/
def NFsum (f : Nat → Int) : Nat → Int
  | 0 => f 0
  | (k + 1) => NFsum f k + f (k + 1)

/-- `⟨a,D⟩ + ⟨b,D⟩ ≈ ⟨a+b,D⟩`. -/
theorem Qadd_same_den (a b : Int) (D : Nat) : Qeq (add (⟨a, D⟩ : Q) ⟨b, D⟩) ⟨a + b, D⟩ := by
  simp only [Qeq, add]; push_cast; ring_uor

/-- A constant-denominator finite sum collapses to a single fraction. -/
theorem Fsum_const_den (f : Nat → Int) (D : Nat) (hD : 0 < D) :
    ∀ k, Qeq (Fsum (fun i => (⟨f i, D⟩ : Q)) k) ⟨NFsum f k, D⟩
  | 0 => Qeq_refl _
  | (k + 1) =>
      Qeq_trans (add_den_pos (show 0 < (⟨NFsum f k, D⟩ : Q).den from hD) hD)
        (Qadd_congr (Fsum_const_den f D hD k) (Qeq_refl (⟨f (k + 1), D⟩ : Q)))
        (Qadd_same_den (NFsum f k) (f (k + 1)) D)

/-- `(−1)^{2k} = 1`. -/
theorem qpow_neg_one_even : ∀ k, qpow (⟨-1, 1⟩ : Q) (2 * k) = ⟨1, 1⟩
  | 0 => rfl
  | (k + 1) => by
      rw [show 2 * (k + 1) = 2 * k + 1 + 1 from by omega, qpow_succ, qpow_succ, qpow_neg_one_even k]
      rfl

/-- `(−1)^{2k+1} = −1`. -/
theorem qpow_neg_one_odd (k : Nat) : qpow (⟨-1, 1⟩ : Q) (2 * k + 1) = ⟨-1, 1⟩ := by
  rw [qpow_succ, qpow_neg_one_even k]; rfl

/-- `NFsum` distributes over negation. -/
theorem NFsum_neg (f : Nat → Int) : ∀ k, NFsum (fun j => -(f j)) k = -(NFsum f k)
  | 0 => rfl
  | (k + 1) => by
      show NFsum (fun j => -(f j)) k + -(f (k + 1)) = -(NFsum f k + f (k + 1))
      rw [NFsum_neg f k]; omega

/-- The alternating-binomial summand at an even index `2j` equals `+C(2m+2,2j)`. -/
theorem binTerm_even (m j : Nat) (hj : j ≤ m + 1) :
    Qeq (binTerm ⟨1, 1⟩ ⟨-1, 1⟩ (2 * m + 2) (2 * j)) ⟨(choose (2 * m + 2) (2 * j) : Int), 1⟩ := by
  show Qeq (mul ⟨(choose (2 * m + 2) (2 * j) : Int), 1⟩
      (mul (qpow (⟨1, 1⟩ : Q) (2 * j)) (qpow (⟨-1, 1⟩ : Q) ((2 * m + 2) - (2 * j)))))
    ⟨(choose (2 * m + 2) (2 * j) : Int), 1⟩
  rw [qpow_one_eq, show (2 * m + 2) - (2 * j) = 2 * (m + 1 - j) from by omega, qpow_neg_one_even]
  simp only [Qeq, mul]; push_cast; ring_uor

/-- The alternating-binomial summand at an odd index `2j+1` equals `−C(2m+2,2j+1)`. -/
theorem binTerm_odd (m j : Nat) (hj : j ≤ m) :
    Qeq (binTerm ⟨1, 1⟩ ⟨-1, 1⟩ (2 * m + 2) (2 * j + 1))
      ⟨-(choose (2 * m + 2) (2 * j + 1) : Int), 1⟩ := by
  show Qeq (mul ⟨(choose (2 * m + 2) (2 * j + 1) : Int), 1⟩
      (mul (qpow (⟨1, 1⟩ : Q) (2 * j + 1)) (qpow (⟨-1, 1⟩ : Q) ((2 * m + 2) - (2 * j + 1)))))
    ⟨-(choose (2 * m + 2) (2 * j + 1) : Int), 1⟩
  rw [qpow_one_eq, show (2 * m + 2) - (2 * j + 1) = 2 * (m - j) + 1 from by omega, qpow_neg_one_odd]
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **The even/odd binomial-sum equality** `Σ_{i≤m+1} C(2m+2,2i) = Σ_{i≤m} C(2m+2,2i+1)`, the
    combinatorial heart of `cos² + sin² = 1`. Proof: split the alternating-binomial sum
    `Σ_k (−1)^k C(2m+2,k) = 0` by parity (`Fsum_parity_split`); the even part is `+Σ C(·,2i)`, the
    odd part is `−Σ C(·,2i+1)`, so the two are equal. -/
theorem binom_even_odd_eq (m : Nat) :
    NFsum (fun j => (choose (2 * m + 2) (2 * j) : Int)) (m + 1)
      = NFsum (fun j => (choose (2 * m + 2) (2 * j + 1) : Int)) m := by
  have ha : ∀ i, 0 < (binTerm (⟨1, 1⟩ : Q) ⟨-1, 1⟩ (2 * m + 2) i).den :=
    fun i => binTerm_den_pos (by decide) (by decide) (2 * m + 2) i
  have hsplit := Fsum_parity_split (binTerm (⟨1, 1⟩ : Q) ⟨-1, 1⟩ (2 * m + 2)) ha m
  have hzero : Qeq (Fsum (binTerm (⟨1, 1⟩ : Q) ⟨-1, 1⟩ (2 * m + 2)) (2 * m + 2)) ⟨0, 1⟩ :=
    alternating_binomial (2 * m + 1)
  have heven : Qeq (Fsum (fun j => binTerm (⟨1, 1⟩ : Q) ⟨-1, 1⟩ (2 * m + 2) (2 * j)) (m + 1))
      ⟨NFsum (fun j => (choose (2 * m + 2) (2 * j) : Int)) (m + 1), 1⟩ :=
    Qeq_trans (Fsum_den_pos (f := fun j => (⟨(choose (2 * m + 2) (2 * j) : Int), 1⟩ : Q))
        (fun _ => Nat.one_pos) (m + 1))
      (Fsum_congr_le (fun j hj => binTerm_even m j hj))
      (Fsum_const_den (fun j => (choose (2 * m + 2) (2 * j) : Int)) 1 Nat.one_pos (m + 1))
  have hodd : Qeq (Fsum (fun j => binTerm (⟨1, 1⟩ : Q) ⟨-1, 1⟩ (2 * m + 2) (2 * j + 1)) m)
      ⟨NFsum (fun j => -(choose (2 * m + 2) (2 * j + 1) : Int)) m, 1⟩ :=
    Qeq_trans (Fsum_den_pos (f := fun j => (⟨-(choose (2 * m + 2) (2 * j + 1) : Int), 1⟩ : Q))
        (fun _ => Nat.one_pos) m)
      (Fsum_congr_le (fun j hj => binTerm_odd m j hj))
      (Fsum_const_den (fun j => -(choose (2 * m + 2) (2 * j + 1) : Int)) 1 Nat.one_pos m)
  -- add even + odd ≈ 0
  have hsum0 : Qeq (add ⟨NFsum (fun j => (choose (2 * m + 2) (2 * j) : Int)) (m + 1), 1⟩
      ⟨NFsum (fun j => -(choose (2 * m + 2) (2 * j + 1) : Int)) m, 1⟩) ⟨0, 1⟩ :=
    Qeq_trans (add_den_pos (Fsum_den_pos (fun j => ha (2 * j)) (m + 1))
        (Fsum_den_pos (fun j => ha (2 * j + 1)) m))
      (Qeq_symm (Qadd_congr heven hodd))
      (Qeq_trans (Fsum_den_pos ha (2 * m + 2)) (Qeq_symm hsplit) hzero)
  have hSeq : Qeq (⟨NFsum (fun j => (choose (2 * m + 2) (2 * j) : Int)) (m + 1)
      + NFsum (fun j => -(choose (2 * m + 2) (2 * j + 1) : Int)) m, 1⟩ : Q) ⟨0, 1⟩ :=
    Qeq_trans (add_den_pos Nat.one_pos Nat.one_pos) (Qeq_symm (Qadd_same_den _ _ 1)) hsum0
  have hS : NFsum (fun j => (choose (2 * m + 2) (2 * j) : Int)) (m + 1)
      + NFsum (fun j => -(choose (2 * m + 2) (2 * j + 1) : Int)) m = 0 := by
    have h := hSeq; unfold Qeq at h; simpa using h
  rw [NFsum_neg] at hS; omega

/-- A `cos²` factorial term equals `C(2m+2,2i)/(2m+2)!`. -/
theorem cosFct_term (m i : Nat) (hi : i ≤ m + 1) :
    Qeq (⟨1, fct (2 * i) * fct (2 * ((m + 1) - i))⟩ : Q)
      ⟨(choose (2 * m + 2) (2 * i) : Int), fct (2 * m + 2)⟩ := by
  have hfac := choose_mul_fct_mul_fct (n := 2 * m + 2) (k := 2 * i) (by omega)
  rw [show (2 * m + 2) - (2 * i) = 2 * ((m + 1) - i) from by omega] at hfac
  have hN : fct (2 * m + 2) = choose (2 * m + 2) (2 * i) * (fct (2 * i) * fct (2 * ((m + 1) - i))) := by
    rw [← hfac, Nat.mul_assoc]
  show (1 : Int) * ((fct (2 * m + 2) : Nat) : Int)
     = ((choose (2 * m + 2) (2 * i) : Nat) : Int) * ((fct (2 * i) * fct (2 * ((m + 1) - i)) : Nat) : Int)
  rw [hN]; push_cast; ring_uor

/-- A `sin²` factorial term equals `C(2m+2,2i+1)/(2m+2)!`. -/
theorem sinFct_term (m i : Nat) (hi : i ≤ m) :
    Qeq (⟨1, fct (2 * i + 1) * fct (2 * (m - i) + 1)⟩ : Q)
      ⟨(choose (2 * m + 2) (2 * i + 1) : Int), fct (2 * m + 2)⟩ := by
  have hfac := choose_mul_fct_mul_fct (n := 2 * m + 2) (k := 2 * i + 1) (by omega)
  rw [show (2 * m + 2) - (2 * i + 1) = 2 * (m - i) + 1 from by omega] at hfac
  have hN : fct (2 * m + 2) = choose (2 * m + 2) (2 * i + 1) * (fct (2 * i + 1) * fct (2 * (m - i) + 1)) := by
    rw [← hfac, Nat.mul_assoc]
  show (1 : Int) * ((fct (2 * m + 2) : Nat) : Int)
     = ((choose (2 * m + 2) (2 * i + 1) : Nat) : Int) * ((fct (2 * i + 1) * fct (2 * (m - i) + 1) : Nat) : Int)
  rw [hN]; push_cast; ring_uor

/-- **`CosFct(m+1) ≈ SinFct(m)`**: the degree-`(m+1)` `cos²` factorial sum equals the degree-`m` `sin²`
    factorial sum. Both collapse (via `cosFct_term`/`sinFct_term` + `Fsum_const_den`) to a single
    fraction over `(2m+2)!` whose numerators are the even/odd binomial sums, equal by `binom_even_odd_eq`. -/
theorem cosFct_eq_sinFct (m : Nat) :
    Qeq (Fsum (fun i => (⟨1, fct (2 * i) * fct (2 * ((m + 1) - i))⟩ : Q)) (m + 1))
      (Fsum (fun i => (⟨1, fct (2 * i + 1) * fct (2 * (m - i) + 1)⟩ : Q)) m) := by
  have hcos : Qeq (Fsum (fun i => (⟨1, fct (2 * i) * fct (2 * ((m + 1) - i))⟩ : Q)) (m + 1))
      ⟨NFsum (fun i => (choose (2 * m + 2) (2 * i) : Int)) (m + 1), fct (2 * m + 2)⟩ :=
    Qeq_trans (Fsum_den_pos (f := fun i => (⟨(choose (2 * m + 2) (2 * i) : Int), fct (2 * m + 2)⟩ : Q))
        (fun _ => fct_pos _) (m + 1))
      (Fsum_congr_le (fun i hi => cosFct_term m i hi))
      (Fsum_const_den (fun i => (choose (2 * m + 2) (2 * i) : Int)) (fct (2 * m + 2)) (fct_pos _) (m + 1))
  have hsin : Qeq (Fsum (fun i => (⟨1, fct (2 * i + 1) * fct (2 * (m - i) + 1)⟩ : Q)) m)
      ⟨NFsum (fun i => (choose (2 * m + 2) (2 * i + 1) : Int)) m, fct (2 * m + 2)⟩ :=
    Qeq_trans (Fsum_den_pos (f := fun i => (⟨(choose (2 * m + 2) (2 * i + 1) : Int), fct (2 * m + 2)⟩ : Q))
        (fun _ => fct_pos _) m)
      (Fsum_congr_le (fun i hi => sinFct_term m i hi))
      (Fsum_const_den (fun i => (choose (2 * m + 2) (2 * i + 1) : Int)) (fct (2 * m + 2)) (fct_pos _) m)
  have heq : Qeq (⟨NFsum (fun i => (choose (2 * m + 2) (2 * i) : Int)) (m + 1), fct (2 * m + 2)⟩ : Q)
      ⟨NFsum (fun i => (choose (2 * m + 2) (2 * i + 1) : Int)) m, fct (2 * m + 2)⟩ := by
    rw [binom_even_odd_eq m]; exact Qeq_refl _
  exact Qeq_trans (fct_pos _) hcos (Qeq_trans (fct_pos _) heq (Qeq_symm hsin))

/-- `a·(b·c) ≈ (a·b)·c`. -/
theorem Qmul_assoc3 (a b c : Q) : Qeq (mul a (mul b c)) (mul (mul a b) c) := by
  simp only [Qeq, mul]; push_cast; ring_uor

/-- `q²·(−q²)^m ≈ −(−q²)^{m+1}` — the sign/degree shift relating the `sin²` `x²` factor to `cos²`. -/
theorem Qmul_qsq_qpow (q : Q) (m : Nat) :
    Qeq (mul (mul q q) (qpow (neg (mul q q)) m)) (neg (qpow (neg (mul q q)) (m + 1))) := by
  rw [qpow_succ]; simp only [Qeq, mul, neg]; push_cast; ring_uor

/-- **The per-degree Pythagorean coefficient vanishes**: `cosConv(m+1) + q²·sinConv(m) ≈ 0`, where
    `cosConv d = Σ_{i≤d} cosTermᵢ·cosT_{d−i}` and `sinConv d` likewise. Both convolutions factor as
    `(−q²)^· × (factorial sum)` (`altConv_factor`); the factorial sums are equal (`cosFct_eq_sinFct`) and
    the `(−q²)` powers are opposite (`Qmul_qsq_qpow`), so the two terms cancel. -/
theorem altPyth_conv_vanish {q : Q} (hqd : 0 < q.den) (m : Nat) :
    Qeq (add (Fsum (fun i => mul (altTerm q 0 i) (altTerm q 0 ((m + 1) - i))) (m + 1))
      (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m))) ⟨0, 1⟩ := by
  have hN : 0 < (neg (mul q q)).den := Nat.mul_pos hqd hqd
  have hPden : 0 < (qpow (neg (mul q q)) (m + 1)).den := qpow_den_pos hN (m + 1)
  have hPmden : 0 < (qpow (neg (mul q q)) m).den := qpow_den_pos hN m
  have hCfden : 0 < (Fsum (fun i => (⟨1, fct (2 * i + 0) * fct (2 * ((m + 1) - i) + 0)⟩ : Q)) (m + 1)).den :=
    Fsum_den_pos (fun _ => Nat.mul_pos (fct_pos _) (fct_pos _)) (m + 1)
  have hSfden : 0 < (Fsum (fun i => (⟨1, fct (2 * i + 1) * fct (2 * (m - i) + 1)⟩ : Q)) m).den :=
    Fsum_den_pos (fun _ => Nat.mul_pos (fct_pos _) (fct_pos _)) m
  have heq : Qeq (Fsum (fun i => (⟨1, fct (2 * i + 0) * fct (2 * ((m + 1) - i) + 0)⟩ : Q)) (m + 1))
      (Fsum (fun i => (⟨1, fct (2 * i + 1) * fct (2 * (m - i) + 1)⟩ : Q)) m) := cosFct_eq_sinFct m
  -- cosC ≈ P·Sf
  have hc2 : Qeq (Fsum (fun i => mul (altTerm q 0 i) (altTerm q 0 ((m + 1) - i))) (m + 1))
      (mul (qpow (neg (mul q q)) (m + 1))
        (Fsum (fun i => (⟨1, fct (2 * i + 1) * fct (2 * (m - i) + 1)⟩ : Q)) m)) :=
    Qeq_trans (Qmul_den_pos hPden hCfden) (altConv_factor hqd 0 (m + 1))
      (Qmul_congr (Qeq_refl _) heq)
  -- q²·sinC ≈ (−P)·Sf
  have hs2 : Qeq (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m))
      (mul (neg (qpow (neg (mul q q)) (m + 1)))
        (Fsum (fun i => (⟨1, fct (2 * i + 1) * fct (2 * (m - i) + 1)⟩ : Q)) m)) :=
    Qeq_trans (Qmul_den_pos (Qmul_den_pos hqd hqd) (Qmul_den_pos hPmden hSfden))
      (Qmul_congr (Qeq_refl (mul q q)) (altConv_factor hqd 1 m))
      (Qeq_trans (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hqd hqd) hPmden) hSfden)
        (Qmul_assoc3 (mul q q) (qpow (neg (mul q q)) m)
          (Fsum (fun i => (⟨1, fct (2 * i + 1) * fct (2 * (m - i) + 1)⟩ : Q)) m))
        (Qmul_congr (Qmul_qsq_qpow q m) (Qeq_refl _)))
  -- add ≈ (P + (−P))·Sf ≈ 0
  refine Qeq_trans (add_den_pos (Qmul_den_pos hPden hSfden)
      (Qmul_den_pos (show 0 < (neg (qpow (neg (mul q q)) (m + 1))).den from hPden) hSfden))
    (Qadd_congr hc2 hs2) ?_
  refine Qeq_trans (Qmul_den_pos (add_den_pos (a := qpow (neg (mul q q)) (m + 1))
      (b := neg (qpow (neg (mul q q)) (m + 1))) hPden hPden) hSfden)
    (Qeq_symm (Qmul_add_right (qpow (neg (mul q q)) (m + 1)) (neg (qpow (neg (mul q q)) (m + 1)))
      (Fsum (fun i => (⟨1, fct (2 * i + 1) * fct (2 * (m - i) + 1)⟩ : Q)) m))) ?_
  refine Qeq_trans (Qmul_den_pos (show 0 < (⟨0, 1⟩ : Q).den from Nat.one_pos) hSfden)
    (Qmul_congr (show Qeq (add (qpow (neg (mul q q)) (m + 1)) (neg (qpow (neg (mul q q)) (m + 1)))) ⟨0, 1⟩
      from by simp only [Qeq, add, neg]; push_cast; ring_uor) (Qeq_refl _)) ?_
  simp only [Qeq, mul]; push_cast; ring_uor

/-- `(A+B) + (C+D) ≈ A + D` when `C + B ≈ 0`. -/
theorem Qadd_cancel_mid {A B C D : Q} (hA : 0 < A.den) (hB : 0 < B.den) (hC : 0 < C.den) (hD : 0 < D.den)
    (h : Qeq (add C B) ⟨0, 1⟩) : Qeq (add (add A B) (add C D)) (add A D) := by
  refine Qeq_trans (add_den_pos (add_den_pos hA hD) (add_den_pos hC hB))
    (show Qeq (add (add A B) (add C D)) (add (add A D) (add C B)) by
      simp only [Qeq, add]; push_cast; ring_uor) ?_
  refine Qeq_trans (add_den_pos (add_den_pos hA hD) Nat.one_pos)
    (Qadd_congr (Qeq_refl (add A D)) h) ?_
  exact Qadd_zero_right (add A D)

/-- **The Pythagorean telescope**: `Σ_{m≤N} cosConv(m) + Σ_{m≤N} q²·sinConv(m) ≈ 1 + q²·sinConv(N)`.
    By `altPyth_conv_vanish`, `cosConv(m+1) + q²·sinConv(m) ≈ 0`, so consecutive terms cancel, leaving the
    `m=0` cos term (`=1`) and the final `q²·sinConv(N)`. -/
theorem altPyth_telescope {q : Q} (hqd : 0 < q.den) :
    ∀ N, Qeq (add (Fsum (fun m => Fsum (fun i => mul (altTerm q 0 i) (altTerm q 0 (m - i))) m) N)
        (Fsum (fun m => mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m)) N))
      (add ⟨1, 1⟩ (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (N - i))) N)))
  | 0 => by
      refine Qadd_congr ?_ (Qeq_refl _)
      show Qeq (mul (altTerm q 0 0) (altTerm q 0 0)) ⟨1, 1⟩
      rw [show altTerm q 0 0 = (⟨1, 1⟩ : Q) from rfl]; decide
  | (N + 1) => by
      have hcc : ∀ m, 0 < (Fsum (fun i => mul (altTerm q 0 i) (altTerm q 0 (m - i))) m).den :=
        fun m => Fsum_den_pos (fun i => Qmul_den_pos (altTerm_den_pos hqd 0 i) (altTerm_den_pos hqd 0 (m - i))) m
      have hqsc : ∀ m, 0 < (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m)).den :=
        fun m => Qmul_den_pos (Qmul_den_pos hqd hqd)
          (Fsum_den_pos (fun i => Qmul_den_pos (altTerm_den_pos hqd 1 i) (altTerm_den_pos hqd 1 (m - i))) m)
      exact Qeq_trans
        (add_den_pos (add_den_pos (Fsum_den_pos hcc N) (Fsum_den_pos hqsc N))
          (add_den_pos (hcc (N + 1)) (hqsc (N + 1))))
        (Qadd_rearrange (Fsum (fun m => Fsum (fun i => mul (altTerm q 0 i) (altTerm q 0 (m - i))) m) N)
          (Fsum (fun i => mul (altTerm q 0 i) (altTerm q 0 (N + 1 - i))) (N + 1))
          (Fsum (fun m => mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m)) N)
          (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (N + 1 - i))) (N + 1))))
        (Qeq_trans
          (add_den_pos (add_den_pos Nat.one_pos (hqsc N)) (add_den_pos (hcc (N + 1)) (hqsc (N + 1))))
          (Qadd_congr (altPyth_telescope hqd N) (Qeq_refl _))
          (Qadd_cancel_mid Nat.one_pos (hqsc N) (hcc (N + 1)) (hqsc (N + 1)) (altPyth_conv_vanish hqd N)))

/-- **The partial-sum Pythagorean identity**: `(cosSum N)² + q²·(sinauxSum N)² ≈ 1 + ERR`, where the error
    `ERR = q²·sinConv(N) + cornerCos + q²·cornerSin` collects the final convolution tail and the two
    Cauchy corners. Assembled from `Fsum_sq_cauchy` (cos² and sin² decompositions) and `altPyth_telescope`
    (the antidiagonal telescope to `1`). -/
theorem altPyth_partial {q : Q} (hqd : 0 < q.den) (N : Nat) :
    Qeq (add (mul (Fsum (altTerm q 0) N) (Fsum (altTerm q 0) N))
        (mul (mul q q) (mul (Fsum (altTerm q 1) N) (Fsum (altTerm q 1) N))))
      (add ⟨1, 1⟩ (add (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (N - i))) N))
        (add (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) N)
              (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (N - i))) N)
          (mul (mul q q) (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) N)
              (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (N - i))) N))))) := by
  have ha0 : ∀ i, 0 < (altTerm q 0 i).den := altTerm_den_pos hqd 0
  have ha1 : ∀ i, 0 < (altTerm q 1 i).den := altTerm_den_pos hqd 1
  have hsqd : 0 < (mul q q).den := Qmul_den_pos hqd hqd
  -- the convolution sums and corners
  have hScosd : 0 < (Fsum (fun m => Fsum (fun i => mul (altTerm q 0 i) (altTerm q 0 (m - i))) m) N).den :=
    Fsum_den_pos (fun m => Fsum_den_pos (fun i => Qmul_den_pos (ha0 i) (ha0 (m - i))) m) N
  have hcorCosd : 0 < (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) N)
      (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (N - i))) N).den :=
    Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => Qmul_den_pos (ha0 i) (ha0 j)) N)
      (Fsum_den_pos (fun j => Qmul_den_pos (ha0 i) (ha0 j)) (N - i))) N
  have hsinConvd : ∀ m, 0 < (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m).den :=
    fun m => Fsum_den_pos (fun i => Qmul_den_pos (ha1 i) (ha1 (m - i))) m
  have hSsind : 0 < (Fsum (fun m => Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m) N).den :=
    Fsum_den_pos hsinConvd N
  have hcorSind : 0 < (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) N)
      (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (N - i))) N).den :=
    Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => Qmul_den_pos (ha1 i) (ha1 j)) N)
      (Fsum_den_pos (fun j => Qmul_den_pos (ha1 i) (ha1 j)) (N - i))) N
  have hSqsind : 0 < (Fsum (fun m => mul (mul q q)
      (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m)) N).den :=
    Fsum_den_pos (fun m => Qmul_den_pos hsqd (hsinConvd m)) N
  -- q²·sin² ≈ Σqsin + q²·cornerSin
  have hqsin : Qeq (mul (mul q q) (mul (Fsum (altTerm q 1) N) (Fsum (altTerm q 1) N)))
      (add (Fsum (fun m => mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m)) N)
        (mul (mul q q) (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) N)
            (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (N - i))) N))) :=
    Qeq_trans (Qmul_den_pos hsqd (add_den_pos hSsind hcorSind))
      (Qmul_congr (Qeq_refl (mul q q)) (Fsum_sq_cauchy ha1 N))
      (Qeq_trans (add_den_pos (Qmul_den_pos hsqd hSsind) (Qmul_den_pos hsqd hcorSind))
        (Qmul_add_left (mul q q)
          (Fsum (fun m => Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m) N)
          (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) N)
            (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (N - i))) N))
        (Qadd_congr (Qeq_symm (Fsum_mul_left hsqd hsinConvd N)) (Qeq_refl _)))
  -- combine cos² and q²·sin²
  refine Qeq_trans (add_den_pos (add_den_pos hScosd hcorCosd) (add_den_pos hSqsind (Qmul_den_pos hsqd hcorSind)))
    (Qadd_congr (Fsum_sq_cauchy ha0 N) hqsin) ?_
  refine Qeq_trans (add_den_pos (add_den_pos hScosd hSqsind) (add_den_pos hcorCosd (Qmul_den_pos hsqd hcorSind)))
    (Qadd_rearrange
      (Fsum (fun m => Fsum (fun i => mul (altTerm q 0 i) (altTerm q 0 (m - i))) m) N)
      (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) N)
        (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (N - i))) N)
      (Fsum (fun m => mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (m - i))) m)) N)
      (mul (mul q q) (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) N)
        (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (N - i))) N))) ?_
  refine Qeq_trans (add_den_pos (add_den_pos Nat.one_pos (Qmul_den_pos hsqd (hsinConvd N)))
      (add_den_pos hcorCosd (Qmul_den_pos hsqd hcorSind)))
    (Qadd_congr (altPyth_telescope hqd N) (Qeq_refl _)) ?_
  exact Qadd_assoc3 ⟨1, 1⟩
    (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (N - i))) N))
    (add (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) N)
        (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (N - i))) N)
      (mul (mul q q) (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) N)
        (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (N - i))) N)))

/-- The alt-series Cauchy corner factored per row: `Σᵢ altTermᵢ·(altSum N − altSum(N−i))`. -/
theorem altCorner_factored {q : Q} (hqd : 0 < q.den) (off N : Nat) :
    Qeq (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q off i) (altTerm q off j)) N)
          (Fsum (fun j => mul (altTerm q off i) (altTerm q off j)) (N - i))) N)
      (Fsum (fun i => mul (altTerm q off i)
          (Qsub (Fsum (altTerm q off) N) (Fsum (altTerm q off) (N - i)))) N) := by
  have ha : ∀ i, 0 < (altTerm q off i).den := altTerm_den_pos hqd off
  refine Fsum_congr (fun i => ?_) N
  exact Qeq_trans
    (Qsub_den_pos (Qmul_den_pos (ha i) (Fsum_den_pos ha N)) (Qmul_den_pos (ha i) (Fsum_den_pos ha (N - i))))
    (QsubCongr (Fsum_mul_left (ha i) ha N) (Fsum_mul_left (ha i) ha (N - i)))
    (Qeq_symm (Qmul_sub_distrib (altTerm q off i) (Fsum (altTerm q off) N) (Fsum (altTerm q off) (N - i))))

/-- `|corner| ≤ Σᵢ |altTermᵢ · (altSum N − altSum(N−i))|` — the triangle inequality applied to the
    factored corner, reducing the signed-corner bound to a sum of absolute values. -/
theorem altCorner_abs_le {q : Q} (hqd : 0 < q.den) (off N : Nat) :
    Qle (Qabs (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q off i) (altTerm q off j)) N)
          (Fsum (fun j => mul (altTerm q off i) (altTerm q off j)) (N - i))) N))
      (Fsum (fun i => Qabs (mul (altTerm q off i)
          (Qsub (Fsum (altTerm q off) N) (Fsum (altTerm q off) (N - i))))) N) := by
  have ha : ∀ i, 0 < (altTerm q off i).den := altTerm_den_pos hqd off
  have hfactterm_den : ∀ i, 0 < (mul (altTerm q off i)
      (Qsub (Fsum (altTerm q off) N) (Fsum (altTerm q off) (N - i)))).den :=
    fun i => Qmul_den_pos (ha i) (Qsub_den_pos (Fsum_den_pos ha N) (Fsum_den_pos ha (N - i)))
  exact Qle_congr_left (Qabs_den_pos (Fsum_den_pos hfactterm_den N))
    (Qeq_symm (Qabs_Qeq (altCorner_factored hqd off N)))
    (Fsum_abs_le hfactterm_den N)

/-- `(↑m)ⁱ = ↑(mⁱ)` as a rational (`qpow` of a natural base). -/
theorem qpow_natBase (m : Nat) : ∀ i, Qeq (qpow (⟨(m : Int), 1⟩ : Q) i) ⟨(npow m i : Int), 1⟩
  | 0 => Qeq_refl _
  | (i + 1) => by
      refine Qeq_trans (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_congr (Qeq_refl _) (qpow_natBase m i)) ?_
      show Qeq (mul (⟨(m : Int), 1⟩ : Q) ⟨(npow m i : Int), 1⟩) ⟨(npow m (i + 1) : Int), 1⟩
      rw [npow_succ]; simp only [Qeq, mul]; push_cast; ring_uor

/-- `expTerm` of a natural base `m` is `mⁱ/i!`. -/
theorem expTerm_natBase (m : Nat) (i : Nat) :
    Qeq (expTerm (⟨(m : Int), 1⟩ : Q) i) ⟨(npow m i : Int), fct i⟩ := by
  refine Qeq_trans (Qmul_den_pos Nat.one_pos (fct_pos i))
    (Qmul_congr (qpow_natBase m i) (Qeq_refl (⟨1, fct i⟩ : Q))) ?_
  show Qeq (mul (⟨(npow m i : Int), 1⟩ : Q) ⟨1, fct i⟩) ⟨(npow m i : Int), fct i⟩
  simp only [Qeq, mul]; push_cast; ring_uor

/-- The alternating partial sum is the `Fsum` of its terms (bridge between `altSum` and the `Fsum` library). -/
theorem altSum_eq_Fsum (q : Q) (off : Nat) : ∀ N, altSum q off N = Fsum (altTerm q off) N
  | 0 => rfl
  | (n + 1) => by
      show add (altSum q off n) (altTerm q off (n + 1)) = add (Fsum (altTerm q off) n) (altTerm q off (n + 1))
      rw [altSum_eq_Fsum q off n]

/-- The `M`-base exponential partial sum as an `Fsum` of its terms `Mⁱ/i!`. -/
theorem expSumM_eq_Fsum (M : Nat) : ∀ N, expSumM M N = Fsum (fun i => (⟨(npow M i : Int), fct i⟩ : Q)) N
  | 0 => rfl
  | (n + 1) => by
      show add (expSumM M n) (⟨(npow M (n + 1) : Int), fct (n + 1)⟩ : Q)
        = add (Fsum (fun i => (⟨(npow M i : Int), fct i⟩ : Q)) n) (⟨(npow M (n + 1) : Int), fct (n + 1)⟩ : Q)
      rw [expSumM_eq_Fsum M n]

/-- **Uniform bound on the absolute alt-series sum**: `Σ_{i≤N} |altTermᵢ| ≤ expM_U(M²)(2M²)`, a constant
    independent of `N` (each `|altTermᵢ| ≤ (M²)ⁱ/i!`, summing to `expSumM(M²) N ≤` the uniform bound). -/
theorem altAbsSum_le_U {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off N : Nat) :
    Qle (Fsum (fun i => Qabs (altTerm q off i)) N) (expM_U (M * M) (2 * (M * M))) := by
  refine Qle_trans (Fsum_den_pos (fun i => fct_pos i) N)
    (Fsum_le_congr (fun i _ => altTerm_abs_le hqd hq off i)) ?_
  rw [← expSumM_eq_Fsum]
  exact expSumM_le_U (M * M) N

/-- **Absolute-sum tail bound**: `Σ_{i'≤d} |altTerm_{K+1+i'}| ≤ 2(M²)^{K+1}/(K+1)!` (for `2M² ≤ K+2`).
    Each term is `≤ (M²)^{K+1+i'}/(K+1+i')!`; summed (via `Fsum_split_add` + `expSumM_eq_Fsum`) it is the
    high block of `expSumM(M²)`, bounded by `expM_diff_bound`. -/
theorem altAbsTail_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off K d : Nat) (hK : 2 * (M * M) ≤ K + 2) :
    Qle (Fsum (fun i' => Qabs (altTerm q off (K + 1 + i'))) d)
      ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ := by
  have hf : ∀ i, 0 < ((⟨(npow (M * M) i : Int), fct i⟩ : Q)).den := fun i => fct_pos i
  refine Qle_trans (Fsum_den_pos (fun i' => hf (K + 1 + i')) d)
    (Fsum_le_congr (fun i' _ => altTerm_abs_le hqd hq off (K + 1 + i'))) ?_
  have hsplit := Fsum_split_add (fun i => (⟨(npow (M * M) i : Int), fct i⟩ : Q)) hf K d
  have hconv : Qeq (Fsum (fun i' => (⟨(npow (M * M) (K + 1 + i') : Int), fct (K + 1 + i')⟩ : Q)) d)
      (Qsub (expSumM (M * M) (K + 1 + d)) (expSumM (M * M) K)) := by
    rw [expSumM_eq_Fsum (M * M) (K + 1 + d), expSumM_eq_Fsum (M * M) K]
    exact Qeq_symm (Qeq_trans
      (Qsub_den_pos (add_den_pos (Fsum_den_pos hf K)
        (Fsum_den_pos (fun i' => hf (K + 1 + i')) d)) (Fsum_den_pos hf K))
      (QsubCongr hsplit (Qeq_refl _))
      (Qsub_add_left_cancel (Fsum (fun i => (⟨(npow (M * M) i : Int), fct i⟩ : Q)) K)
        (Fsum (fun i' => (⟨(npow (M * M) (K + 1 + i') : Int), fct (K + 1 + i')⟩ : Q)) d)))
  exact Qle_congr_left
    (Qsub_den_pos (expSumM_den_pos (M * M) (K + 1 + d)) (expSumM_den_pos (M * M) K))
    (Qeq_symm hconv) (expM_diff_bound (M * M) hK (by omega))

/-- **Uniform deep-tail bound for the low block**: for `i ≤ K` (and `2M² ≤ K+3`), the gap
    `|altSum(2K+1) − altSum(2K+1−i)| ≤ 4(M²)^{K+2}/(K+2)!`. Both `2K+1` and `2K+1−i` lie at depth `≥ K+1`,
    so each leg of the triangle through `altSum(K+1)` is bounded by `altSum_trunc_bound` at `a = K+1`. -/
theorem altTail_deep_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off K i : Nat) (hi : i ≤ K) (hK : 2 * (M * M) ≤ K + 3) :
    Qle (Qabs (Qsub (Fsum (altTerm q off) (2 * K + 1)) (Fsum (altTerm q off) (2 * K + 1 - i))))
      ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩ := by
  rw [← altSum_eq_Fsum, ← altSum_eq_Fsum]
  have hleg1 : Qle (Qabs (Qsub (altSum q off (2 * K + 1)) (altSum q off (K + 1))))
      ⟨(2 * npow (M * M) (K + 1 + 1) : Int), fct (K + 1 + 1)⟩ :=
    altSum_trunc_bound hqd hq off (by omega) (by omega)
  have hleg2 : Qle (Qabs (Qsub (altSum q off (K + 1)) (altSum q off (2 * K + 1 - i))))
      ⟨(2 * npow (M * M) (K + 1 + 1) : Int), fct (K + 1 + 1)⟩ := by
    rw [Qabs_Qsub_comm]
    exact altSum_trunc_bound hqd hq off (by omega) (by omega)
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (altSum_den_pos hqd off (2 * K + 1))
      (altSum_den_pos hqd off (K + 1)))) (Qabs_den_pos (Qsub_den_pos (altSum_den_pos hqd off (K + 1))
      (altSum_den_pos hqd off (2 * K + 1 - i)))))
    (Qabs_sub_triangle (altSum_den_pos hqd off (2 * K + 1)) (altSum_den_pos hqd off (K + 1))
      (altSum_den_pos hqd off (2 * K + 1 - i))) ?_
  refine Qle_trans (add_den_pos (fct_pos _) (fct_pos _)) (Qadd_le_add hleg1 hleg2) ?_
  have he : K + 1 + 1 = K + 2 := by omega
  rw [he]
  exact Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)

/-- `x − y ≤ x` for `y ≥ 0` (local copy; `Log.Qsub_le_self` isn't imported here). -/
theorem Qsub_le_self_loc {a b : Q} (hb : 0 ≤ b.num) : Qle (Qsub a b) a := by
  show (a.num * (b.den : Int) + (-b.num) * (a.den : Int)) * (a.den : Int)
      ≤ a.num * ((a.den * b.den : Nat) : Int)
  have key : a.num * ((a.den * b.den : Nat) : Int)
      = (a.num * (b.den : Int) + (-b.num) * (a.den : Int)) * (a.den : Int)
        + b.num * ((a.den : Int) * (a.den : Int)) := by push_cast; ring_uor
  have hnn : 0 ≤ b.num * ((a.den : Int) * (a.den : Int)) :=
    Int.mul_nonneg hb (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _))
  omega

/-- **Uniform gap bound**: any alt-series gap `|Σ_{a<j≤b} altTermⱼ|` is `≤ expM_U(M²)(2M²)`. -/
theorem altGap_le_U {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off : Nat) {a b : Nat} (hab : a ≤ b) :
    Qle (Qabs (Qsub (Fsum (altTerm q off) b) (Fsum (altTerm q off) a)))
      (expM_U (M * M) (2 * (M * M))) := by
  rw [← altSum_eq_Fsum, ← altSum_eq_Fsum]
  exact Qle_trans (Qsub_den_pos (expSumM_den_pos (M * M) b) (expSumM_den_pos (M * M) a))
    (altSum_abs_diff_le hqd hq off hab)
    (Qle_trans (expSumM_den_pos (M * M) b)
      (Qsub_le_self_loc (expSumM_num_nonneg (M * M) a)) (expSumM_le_U (M * M) b))

/-- **The alt-series Cauchy corner vanishes (Mertens bound)**: for `|q| ≤ M` and `2M² ≤ K+2`,
    `|corner(2K+1)| ≤ U·(4(M²)^{K+2}/(K+2)!) + (2(M²)^{K+1}/(K+1)!)·U` where `U = expM_U(M²)(2M²)`.
    Split rows at `K`: low block = small (deep) tails × `U`-bounded term sums; high block = small term
    sums × `U`-bounded tails. Both factorial factors `→ 0`. -/
theorem altCorner_mertens {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off K : Nat) (hK : 2 * (M * M) ≤ K + 2) :
    Qle (Qabs (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q off i) (altTerm q off j)) (2 * K + 1))
          (Fsum (fun j => mul (altTerm q off i) (altTerm q off j)) (2 * K + 1 - i))) (2 * K + 1)))
      (add (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩)
        (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M))))) := by
  have ha : ∀ i, 0 < (altTerm q off i).den := altTerm_den_pos hqd off
  have htd : ∀ i, 0 < (Qsub (Fsum (altTerm q off) (2 * K + 1)) (Fsum (altTerm q off) (2 * K + 1 - i))).den :=
    fun i => Qsub_den_pos (Fsum_den_pos ha (2 * K + 1)) (Fsum_den_pos ha (2 * K + 1 - i))
  have hh : ∀ i, 0 < (Qabs (mul (altTerm q off i)
      (Qsub (Fsum (altTerm q off) (2 * K + 1)) (Fsum (altTerm q off) (2 * K + 1 - i))))).den :=
    fun i => Qabs_den_pos (Qmul_den_pos (ha i) (htd i))
  have hCnn : (0 : Int) ≤ (4 * npow (M * M) (K + 2) : Int) := Int.ofNat_nonneg _
  have hUnn : (0 : Int) ≤ (expM_U (M * M) (2 * (M * M))).num := expM_U_num_nonneg _ _
  have hlow : Qle (Fsum (fun i => Qabs (mul (altTerm q off i)
        (Qsub (Fsum (altTerm q off) (2 * K + 1)) (Fsum (altTerm q off) (2 * K + 1 - i))))) K)
      (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩) := by
    have hmid : Qle (Fsum (fun i => Qabs (mul (altTerm q off i)
          (Qsub (Fsum (altTerm q off) (2 * K + 1)) (Fsum (altTerm q off) (2 * K + 1 - i))))) K)
        (Fsum (fun i => mul (Qabs (altTerm q off i))
          (⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩ : Q)) K) :=
      Fsum_le_congr (fun i hi => by
        rw [Qabs_mul]
        exact Qmul_le_mul_left (Qabs_num_nonneg _) (altTail_deep_le hqd hq off K i hi (by omega)))
    exact Qle_trans (Fsum_den_pos (fun i => Qmul_den_pos (Qabs_den_pos (ha i)) (fct_pos _)) K) hmid
      (Qle_trans (Qmul_den_pos (Fsum_den_pos (fun i => Qabs_den_pos (ha i)) K) (fct_pos _))
        (Qeq_le (Qeq_symm (Fsum_mul_const_right (fct_pos _) (fun i => Qabs_den_pos (ha i)) K)))
        (Qmul_le_mul_right hCnn (altAbsSum_le_U hqd hq off K)))
  have hhigh : Qle (Fsum (fun i' => Qabs (mul (altTerm q off (K + 1 + i'))
        (Qsub (Fsum (altTerm q off) (2 * K + 1)) (Fsum (altTerm q off) (2 * K + 1 - (K + 1 + i')))))) K)
      (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M)))) := by
    have hmid : Qle (Fsum (fun i' => Qabs (mul (altTerm q off (K + 1 + i'))
          (Qsub (Fsum (altTerm q off) (2 * K + 1)) (Fsum (altTerm q off) (2 * K + 1 - (K + 1 + i')))))) K)
        (Fsum (fun i' => mul (Qabs (altTerm q off (K + 1 + i')))
          (expM_U (M * M) (2 * (M * M)))) K) :=
      Fsum_le_congr (fun i' _ => by
        rw [Qabs_mul]
        exact Qmul_le_mul_left (Qabs_num_nonneg _)
          (altGap_le_U hqd hq off (a := 2 * K + 1 - (K + 1 + i')) (b := 2 * K + 1) (by omega)))
    exact Qle_trans (Fsum_den_pos (fun i' => Qmul_den_pos (Qabs_den_pos (ha (K + 1 + i')))
        (expM_U_den_pos (M * M) (2 * (M * M)))) K) hmid
      (Qle_trans (Qmul_den_pos (Fsum_den_pos (fun i' => Qabs_den_pos (ha (K + 1 + i'))) K)
        (expM_U_den_pos (M * M) (2 * (M * M))))
        (Qeq_le (Qeq_symm (Fsum_mul_const_right (expM_U_den_pos (M * M) (2 * (M * M)))
          (fun i' => Qabs_den_pos (ha (K + 1 + i'))) K)))
        (Qmul_le_mul_right hUnn (altAbsTail_le hqd hq off K K hK)))
  refine Qle_trans (Fsum_den_pos hh (2 * K + 1)) (altCorner_abs_le hqd off (2 * K + 1)) ?_
  refine Qle_trans (add_den_pos (Fsum_den_pos hh K)
      (Fsum_den_pos (fun i' => hh (K + 1 + i')) K)) (Qeq_le (Fsum_split_at _ hh K)) ?_
  exact Qadd_le_add hlow hhigh

/-- `|altTermᵢ| ≤ (M²)ⁱ/i! = expTerm ⟨M²,1⟩ i`. -/
theorem altTerm_abs_le_exp {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off i : Nat) : Qle (Qabs (altTerm q off i)) (expTerm (⟨(M * M : Int), 1⟩ : Q) i) :=
  Qle_congr_right (fct_pos i) (Qeq_symm (expTerm_natBase (M * M) i)) (altTerm_abs_le hqd hq off i)

/-- **Antidiagonal bound**: `|Σ_{i≤N} altTermᵢ·altTerm_{N−i}| ≤ (2M²)ᴺ/N!`. Each `|altTermᵢ| ≤ (M²)ⁱ/i!`,
    so the antidiagonal is `≤` the exp convolution `Σ (M²)ⁱ/i!·(M²)^{N−i}/(N−i)! = (M²+M²)ᴺ/N!`
    (`expTerm_conv`). This bounds the leading `sinConv(N)` term of `ERR`. -/
theorem altAntidiag_abs_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off N : Nat) :
    Qle (Qabs (Fsum (fun i => mul (altTerm q off i) (altTerm q off (N - i))) N))
      (expTerm (add (⟨(M * M : Int), 1⟩ : Q) ⟨(M * M : Int), 1⟩) N) := by
  have hmid : Qle (Fsum (fun i => Qabs (mul (altTerm q off i) (altTerm q off (N - i)))) N)
      (Fsum (fun i => mul (expTerm (⟨(M * M : Int), 1⟩ : Q) i)
        (expTerm (⟨(M * M : Int), 1⟩ : Q) (N - i))) N) :=
    Fsum_le_congr (fun i _ => by
      rw [Qabs_mul]
      exact Qmul_le_mul (Qabs_den_pos (altTerm_den_pos hqd off i)) (expTerm_den_pos Nat.one_pos i)
        (Qabs_den_pos (altTerm_den_pos hqd off (N - i)))
        (Qabs_num_nonneg _) (Qabs_num_nonneg _)
        (altTerm_abs_le_exp hqd hq off i) (altTerm_abs_le_exp hqd hq off (N - i)))
  exact Qle_trans (Fsum_den_pos (fun i => Qabs_den_pos
      (Qmul_den_pos (altTerm_den_pos hqd off i) (altTerm_den_pos hqd off (N - i)))) N)
    (Fsum_abs_le (fun i => Qmul_den_pos (altTerm_den_pos hqd off i) (altTerm_den_pos hqd off (N - i))) N)
    (Qle_trans (Fsum_den_pos (fun i => Qmul_den_pos (expTerm_den_pos Nat.one_pos i)
        (expTerm_den_pos Nat.one_pos (N - i))) N)
      hmid
      (Qeq_le (expTerm_conv (x := (⟨(M * M : Int), 1⟩ : Q)) (y := (⟨(M * M : Int), 1⟩ : Q))
        Nat.one_pos Nat.one_pos N)))

/-- Three-term triangle inequality `|A + (B + C)| ≤ |A| + (|B| + |C|)`. -/
theorem Qabs_add3_le (A B C : Q) (hA : 0 < A.den) (hB : 0 < B.den) (hC : 0 < C.den) :
    Qle (Qabs (add A (add B C))) (add (Qabs A) (add (Qabs B) (Qabs C))) :=
  Qle_trans (add_den_pos (Qabs_den_pos hA) (Qabs_den_pos (add_den_pos hB hC)))
    (Qabs_add_le A (add B C)) (Qadd_le_add (Qle_refl _) (Qabs_add_le B C))

/-- `|q²·R| ≤ M²·|R|` (the `q²` factor of two ERR terms is bounded by `M²`). -/
theorem Qabs_qsq_mul_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    {R B : Q} (hRd : 0 < R.den) (hB : Qle (Qabs R) B) :
    Qle (Qabs (mul (mul q q) R)) (mul ⟨((M * M : Nat) : Int), 1⟩ B) := by
  have hq2 : Qle (Qabs (mul q q)) ⟨((M * M : Nat) : Int), 1⟩ := by
    rw [← Qabs_neg]; exact qsq_abs_le hqd hq
  rw [Qabs_mul]
  exact Qmul_le_mul (Qabs_den_pos (Qmul_den_pos hqd hqd)) Nat.one_pos (Qabs_den_pos hRd)
    (Qabs_num_nonneg _) (Qabs_num_nonneg _) hq2 hB

/-- **Pythagorean deviation = ERR**: `(cosSum N)² + q²(sinauxSum N)² − 1 ≈ ERR`, the exact rearrangement
    of `altPyth_partial`. The real lift bounds `|ERR|` via `altAntidiag_abs_le` + `altCorner_mertens`. -/
theorem altPyth_dev_eq_err {q : Q} (hqd : 0 < q.den) (N : Nat) :
    Qeq (Qsub (add (mul (Fsum (altTerm q 0) N) (Fsum (altTerm q 0) N))
        (mul (mul q q) (mul (Fsum (altTerm q 1) N) (Fsum (altTerm q 1) N)))) ⟨1, 1⟩)
      (add (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (N - i))) N))
        (add (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) N)
              (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (N - i))) N)
          (mul (mul q q) (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) N)
              (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (N - i))) N)))) := by
  have ha0 : ∀ i, 0 < (altTerm q 0 i).den := altTerm_den_pos hqd 0
  have ha1 : ∀ i, 0 < (altTerm q 1 i).den := altTerm_den_pos hqd 1
  have hsqd : 0 < (mul q q).den := Qmul_den_pos hqd hqd
  have hERR : 0 < (add (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (N - i))) N))
      (add (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) N)
            (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (N - i))) N)
        (mul (mul q q) (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) N)
            (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (N - i))) N)))).den :=
    add_den_pos (Qmul_den_pos hsqd (Fsum_den_pos (fun i => Qmul_den_pos (ha1 i) (ha1 (N - i))) N))
      (add_den_pos
        (Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => Qmul_den_pos (ha0 i) (ha0 j)) N)
          (Fsum_den_pos (fun j => Qmul_den_pos (ha0 i) (ha0 j)) (N - i))) N)
        (Qmul_den_pos hsqd (Fsum_den_pos (fun i => Qsub_den_pos
          (Fsum_den_pos (fun j => Qmul_den_pos (ha1 i) (ha1 j)) N)
          (Fsum_den_pos (fun j => Qmul_den_pos (ha1 i) (ha1 j)) (N - i))) N)))
  exact Qeq_trans (Qsub_den_pos (add_den_pos Nat.one_pos hERR) Nat.one_pos)
    (QsubCongr (altPyth_partial hqd N) (Qeq_refl (⟨1, 1⟩ : Q)))
    (Qsub_add_left_cancel (⟨1, 1⟩ : Q) _)

/-- **The ERR bound**: at `N = 2K+1` (with `|q| ≤ M`, `2M² ≤ K+2`), the Pythagorean error
    `|ERR| ≤ M²·(antidiagonal) + cornerMertens₀ + M²·cornerMertens₁`, each summand `→ 0`. Combines
    `Qabs_add3_le`, `Qabs_qsq_mul_le`, `altAntidiag_abs_le`, and `altCorner_mertens`. -/
theorem altErr_abs_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (K : Nat) (hK : 2 * (M * M) ≤ K + 2) :
    Qle (Qabs (add (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (2 * K + 1 - i))) (2 * K + 1)))
        (add (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (2 * K + 1))
              (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (2 * K + 1 - i))) (2 * K + 1))
          (mul (mul q q) (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (2 * K + 1))
              (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (2 * K + 1 - i))) (2 * K + 1))))))
      (add (mul ⟨((M * M : Nat) : Int), 1⟩
          (expTerm (add (⟨(M * M : Int), 1⟩ : Q) ⟨(M * M : Int), 1⟩) (2 * K + 1)))
        (add (add (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩)
              (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M)))))
          (mul ⟨((M * M : Nat) : Int), 1⟩
            (add (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩)
              (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M)))))))) := by
  have ha0 : ∀ i, 0 < (altTerm q 0 i).den := altTerm_den_pos hqd 0
  have ha1 : ∀ i, 0 < (altTerm q 1 i).den := altTerm_den_pos hqd 1
  have hsd : 0 < (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (2 * K + 1 - i))) (2 * K + 1)).den :=
    Fsum_den_pos (fun i => Qmul_den_pos (ha1 i) (ha1 (2 * K + 1 - i))) (2 * K + 1)
  have hAd : 0 < (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (2 * K + 1 - i))) (2 * K + 1))).den :=
    Qmul_den_pos (Qmul_den_pos hqd hqd) hsd
  have hBd : 0 < (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (2 * K + 1))
      (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (2 * K + 1 - i))) (2 * K + 1)).den :=
    Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => Qmul_den_pos (ha0 i) (ha0 j)) (2 * K + 1))
      (Fsum_den_pos (fun j => Qmul_den_pos (ha0 i) (ha0 j)) (2 * K + 1 - i))) (2 * K + 1)
  have hCsd : 0 < (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (2 * K + 1))
      (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (2 * K + 1 - i))) (2 * K + 1)).den :=
    Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => Qmul_den_pos (ha1 i) (ha1 j)) (2 * K + 1))
      (Fsum_den_pos (fun j => Qmul_den_pos (ha1 i) (ha1 j)) (2 * K + 1 - i))) (2 * K + 1)
  have hCd : 0 < (mul (mul q q) (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (2 * K + 1))
      (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (2 * K + 1 - i))) (2 * K + 1))).den :=
    Qmul_den_pos (Qmul_den_pos hqd hqd) hCsd
  refine Qle_trans (add_den_pos (Qabs_den_pos hAd) (add_den_pos (Qabs_den_pos hBd) (Qabs_den_pos hCd)))
    (Qabs_add3_le _ _ _ hAd hBd hCd) ?_
  refine Qadd_le_add (Qabs_qsq_mul_le hqd hq hsd (altAntidiag_abs_le hqd hq 1 (2 * K + 1)))
    (Qadd_le_add (altCorner_mertens hqd hq 0 K hK)
      (Qabs_qsq_mul_le hqd hq hCsd (altCorner_mertens hqd hq 1 K hK)))

-- ===========================================================================
-- The real lift: `cos² + sin² = 1` as constructive reals (begins here).
-- ===========================================================================

/-- **Factorial decay at the diagonal depth** (extracted from `RaltReal_diag_le`): with `M = xBound x`,
    the truncation term at depth `R = RaltReal_R x j` satisfies `2(M²)^{R+1}·2(j+1) ≤ (R+1)!`. -/
theorem RaltReal_trunc_decay (x : Real) (j : Nat) :
    2 * npow (xBound x * xBound x) (RaltReal_R x j + 1) * (2 * (j + 1))
      ≤ fct (RaltReal_R x j + 1) := by
  have hM : 0 < xBound x := xBound_pos x
  have hB : 0 < xBound x * xBound x := Nat.mul_pos hM hM
  have hK : npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1) ≤ RaltReal_K x := by
    unfold RaltReal_K; omega
  have htr := trunc_reindex (xBound x * xBound x) (2 * (j + 1)) (4 * (j + 1) * RaltReal_K x) hB (by
    have h4 : 4 * (j + 1) * npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1)
        ≤ 4 * (j + 1) * RaltReal_K x := Nat.mul_le_mul (Nat.le_refl _) hK
    rw [show 2 * (2 * (j + 1)) = 4 * (j + 1) from by omega]
    omega)
  have hd : 2 * (xBound x * xBound x) + 1 + 4 * (j + 1) * RaltReal_K x = RaltReal_R x j + 1 := by
    unfold RaltReal_R; omega
  rw [hd] at htr; exact htr

/-- The diagonal truncation term as a rational bound: `2(M²)^{R+1}/(R+1)! ≤ 1/(2(j+1))` at `R = RaltReal_R x j`. -/
theorem RaltReal_trunc_le (x : Real) (j : Nat) :
    Qle (⟨(2 * npow (xBound x * xBound x) (RaltReal_R x j + 1) : Int), fct (RaltReal_R x j + 1)⟩ : Q)
      ⟨1, 2 * (j + 1)⟩ := by
  show (2 * npow (xBound x * xBound x) (RaltReal_R x j + 1) : Int) * ((2 * (j + 1) : Nat) : Int)
      ≤ (1 : Int) * ((fct (RaltReal_R x j + 1) : Nat) : Int)
  have h := RaltReal_trunc_decay x j
  have hI : ((2 * npow (xBound x * xBound x) (RaltReal_R x j + 1) * (2 * (j + 1)) : Nat) : Int)
      ≤ ((fct (RaltReal_R x j + 1) : Nat) : Int) := by exact_mod_cast h
  push_cast at hI ⊢; omega

/-- A non-negative rational is bounded by the integer `⌈num/den⌉`-overestimate `⟨num.toNat, 1⟩`. -/
theorem Q_le_num_toNat (a : Q) (ha : 0 ≤ a.num) (hd : 0 < a.den) :
    Qle a ⟨(a.num.toNat : Int), 1⟩ := by
  show a.num * ((1 : Nat) : Int) ≤ (a.num.toNat : Int) * (a.den : Int)
  rw [Int.toNat_of_nonneg ha]
  exact Int.mul_le_mul_of_nonneg_left (by exact_mod_cast hd) ha

/-- `qpow` respects `≈`. -/
theorem qpow_Qeq {a b : Q} (h : Qeq a b) : ∀ n, Qeq (qpow a n) (qpow b n)
  | 0 => Qeq_refl _
  | (n + 1) => by
      show Qeq (mul a (qpow a n)) (mul b (qpow b n))
      exact Qmul_congr h (qpow_Qeq h n)

/-- `expTerm` respects `≈` in the base. -/
theorem expTerm_Qeq {a b : Q} (h : Qeq a b) (i : Nat) : Qeq (expTerm a i) (expTerm b i) := by
  show Qeq (mul (qpow a i) ⟨1, fct i⟩) (mul (qpow b i) ⟨1, fct i⟩)
  exact Qmul_congr (qpow_Qeq h i) (Qeq_refl _)

/-- The antidiagonal majorant `expTerm (M²+M²) N` in closed form `(2M²)^N / N!`. -/
theorem expTerm_2MM (M N : Nat) :
    Qeq (expTerm (add (⟨(M * M : Int), 1⟩ : Q) ⟨(M * M : Int), 1⟩) N)
      ⟨(npow (2 * (M * M)) N : Int), fct N⟩ := by
  have hbase : Qeq (add (⟨(M * M : Int), 1⟩ : Q) ⟨(M * M : Int), 1⟩) ⟨((2 * (M * M) : Nat) : Int), 1⟩ := by
    simp only [Qeq, add]; push_cast; ring_uor
  exact Qeq_trans (expTerm_den_pos (q := (⟨((2 * (M * M) : Nat) : Int), 1⟩ : Q)) Nat.one_pos N)
    (expTerm_Qeq hbase N) (expTerm_natBase (2 * (M * M)) N)

/-- **Corner-term bound**: `U · (cc·(M²)^E / E!) ≤ 1/(n+1)` at a deep exponent `E`, where `U = expM_U M² (2M²)`.
    Bounds `U ≤ ⟨U.num.toNat,1⟩` then applies `truncCoef_QE` with coefficient `U.num.toNat·cc`. -/
theorem uterm_le (M E n cc : Nat) (hm : 0 < M * M) (hE : 2 * (M * M) + 1 ≤ E)
    (hc : (expM_U (M * M) (2 * (M * M))).num.toNat * cc * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        ≤ E - (2 * (M * M) + 1) + 1) :
    Qle (mul (expM_U (M * M) (2 * (M * M))) ⟨(cc * npow (M * M) E : Int), fct E⟩) ⟨1, n + 1⟩ := by
  have hU0 := expM_U_num_nonneg (M * M) (2 * (M * M))
  have hUd := expM_U_den_pos (M * M) (2 * (M * M))
  have hstep : Qle (mul (expM_U (M * M) (2 * (M * M))) ⟨(cc * npow (M * M) E : Int), fct E⟩)
      (mul (⟨((expM_U (M * M) (2 * (M * M))).num.toNat : Int), 1⟩ : Q) ⟨(cc * npow (M * M) E : Int), fct E⟩) :=
    Qmul_le_mul_right (Int.ofNat_nonneg _) (Q_le_num_toNat _ hU0 hUd)
  have htrunc := truncCoef_QE (M * M) ((expM_U (M * M) (2 * (M * M))).num.toNat * cc) (n + 1) E hm hE hc
  refine Qle_trans (Qmul_den_pos Nat.one_pos (fct_pos E)) hstep
    (Qle_congr_left (fct_pos E) ?_ htrunc)
  simp only [Qeq, mul]; push_cast; ring_uor

set_option maxHeartbeats 1000000 in
/-- **The Pythagorean error bound vanishes at a deep reference**: the `altErr_abs_le` majorant — at the
    odd depth `2K+1`, with `M = xBound`-style modulus — is `≤ 5/(n+1)` once `K` exceeds the explicit
    threshold (so `truncCoef_QE` applies to each of the five summands: the antidiagonal, two corners,
    and the two `q²`-scaled corners). This converts the rational Pythagorean error into `Req` tolerance. -/
theorem altErr_bound_decay (M K n : Nat) (hm : 0 < M * M)
    (hK : (expM_U (M * M) (2 * (M * M))).num.toNat * 4 * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (expM_U (M * M) (2 * (M * M))).num.toNat * 2 * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (expM_U (M * M) (2 * (M * M))).num.toNat * (4 * (M * M)) * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (expM_U (M * M) (2 * (M * M))).num.toNat * (2 * (M * M)) * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (M * M) * (n + 1) * npow (2 * (M * M)) (2 * (2 * (M * M)) + 1)
        + 2 * (M * M) ≤ K) :
    Qle (add (mul ⟨((M * M : Nat) : Int), 1⟩
          (expTerm (add (⟨(M * M : Int), 1⟩ : Q) ⟨(M * M : Int), 1⟩) (2 * K + 1)))
        (add (add (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩)
              (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M)))))
          (mul ⟨((M * M : Nat) : Int), 1⟩
            (add (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩)
              (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M))))))))
      ⟨5, n + 1⟩ := by
  obtain ⟨g1, g2, g3, g4, g5, hg1, hg2, hg3, hg4, hg5⟩ :
      ∃ g1 g2 g3 g4 g5,
        (expM_U (M * M) (2 * (M * M))).num.toNat * 4 * (n + 1) * npow (M * M) (2 * (M * M) + 1) = g1 ∧
        (expM_U (M * M) (2 * (M * M))).num.toNat * 2 * (n + 1) * npow (M * M) (2 * (M * M) + 1) = g2 ∧
        (expM_U (M * M) (2 * (M * M))).num.toNat * (4 * (M * M)) * (n + 1) * npow (M * M) (2 * (M * M) + 1) = g3 ∧
        (expM_U (M * M) (2 * (M * M))).num.toNat * (2 * (M * M)) * (n + 1) * npow (M * M) (2 * (M * M) + 1) = g4 ∧
        (M * M) * (n + 1) * npow (2 * (M * M)) (2 * (2 * (M * M)) + 1) = g5 :=
    ⟨_, _, _, _, _, rfl, rfl, rfl, rfl, rfl⟩
  rw [hg1, hg2, hg3, hg4, hg5] at hK
  have hUd := expM_U_den_pos (M * M) (2 * (M * M))
  -- the five truncation conditions (each product is one summand of the threshold)
  have hcc1 : (expM_U (M * M) (2 * (M * M))).num.toNat * 4 * (n + 1) * npow (M * M) (2 * (M * M) + 1)
      ≤ (K + 2) - (2 * (M * M) + 1) + 1 := by rw [hg1]; omega
  have hcc2 : (expM_U (M * M) (2 * (M * M))).num.toNat * 2 * (n + 1) * npow (M * M) (2 * (M * M) + 1)
      ≤ (K + 1) - (2 * (M * M) + 1) + 1 := by rw [hg2]; omega
  have hcc3 : (expM_U (M * M) (2 * (M * M))).num.toNat * (4 * (M * M)) * (n + 1) * npow (M * M) (2 * (M * M) + 1)
      ≤ (K + 2) - (2 * (M * M) + 1) + 1 := by rw [hg3]; omega
  have hcc4 : (expM_U (M * M) (2 * (M * M))).num.toNat * (2 * (M * M)) * (n + 1) * npow (M * M) (2 * (M * M) + 1)
      ≤ (K + 1) - (2 * (M * M) + 1) + 1 := by rw [hg4]; omega
  have hcc5 : (M * M) * (n + 1) * npow (2 * (M * M)) (2 * (2 * (M * M)) + 1)
      ≤ (2 * K + 1) - (2 * (2 * (M * M)) + 1) + 1 := by rw [hg5]; omega
  -- per-term bounds
  have hc1 : Qle (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩) ⟨1, n + 1⟩ :=
    uterm_le M (K + 2) n 4 hm (by omega) hcc1
  have hc2 : Qle (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M)))) ⟨1, n + 1⟩ :=
    Qle_congr_left (Qmul_den_pos hUd (fct_pos (K + 1)))
      (mul_comm (expM_U (M * M) (2 * (M * M))) ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩)
      (uterm_le M (K + 1) n 2 hm (by omega) hcc2)
  have hMc1 : Qle (mul (⟨((M * M : Nat) : Int), 1⟩ : Q)
      (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩)) ⟨1, n + 1⟩ :=
    Qle_congr_left (Qmul_den_pos hUd (fct_pos (K + 2)))
      (by simp only [Qeq, mul]; push_cast; ring_uor)
      (uterm_le M (K + 2) n (4 * (M * M)) hm (by omega) hcc3)
  have hMc2 : Qle (mul (⟨((M * M : Nat) : Int), 1⟩ : Q)
      (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M))))) ⟨1, n + 1⟩ :=
    Qle_congr_left (Qmul_den_pos hUd (fct_pos (K + 1)))
      (by simp only [Qeq, mul]; push_cast; ring_uor)
      (uterm_le M (K + 1) n (2 * (M * M)) hm (by omega) hcc4)
  have hT1 : Qle (mul (⟨((M * M : Nat) : Int), 1⟩ : Q)
      (expTerm (add (⟨(M * M : Int), 1⟩ : Q) ⟨(M * M : Int), 1⟩) (2 * K + 1))) ⟨1, n + 1⟩ := by
    have hle1 : Qle (mul (⟨((M * M : Nat) : Int), 1⟩ : Q)
        (expTerm (add (⟨(M * M : Int), 1⟩ : Q) ⟨(M * M : Int), 1⟩) (2 * K + 1)))
        (mul (⟨((M * M : Nat) : Int), 1⟩ : Q) ⟨(npow (2 * (M * M)) (2 * K + 1) : Int), fct (2 * K + 1)⟩) :=
      Qmul_le_mul_left (Int.ofNat_nonneg _) (Qeq_le (expTerm_2MM M (2 * K + 1)))
    have htr := truncCoef_QE (2 * (M * M)) (M * M) (n + 1) (2 * K + 1) (by omega) (by omega) hcc5
    refine Qle_trans (Qmul_den_pos Nat.one_pos (fct_pos (2 * K + 1))) hle1
      (Qle_congr_left (fct_pos (2 * K + 1)) ?_ htr)
    simp only [Qeq, mul]; push_cast; ring_uor
  -- combine: BOUND ≤ ⟨1⟩ + ((⟨1⟩+⟨1⟩) + M²·(⟨1⟩+⟨1⟩)) ≤ ⟨5,n+1⟩
  have hden1 : (0 : Nat) < (⟨1, n + 1⟩ : Q).den := Nat.succ_pos n
  have hMcorner : Qle (mul (⟨((M * M : Nat) : Int), 1⟩ : Q)
        (add (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩)
          (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M))))))
      (add ⟨1, n + 1⟩ ⟨1, n + 1⟩) := by
    refine Qle_congr_left ?_ (Qeq_symm (Qmul_add_left (⟨((M * M : Nat) : Int), 1⟩ : Q)
      (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩)
      (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M)))))) (Qadd_le_add hMc1 hMc2)
    exact add_den_pos (Qmul_den_pos Nat.one_pos (Qmul_den_pos hUd (fct_pos (K + 2))))
      (Qmul_den_pos Nat.one_pos (Qmul_den_pos (fct_pos (K + 1)) hUd))
  refine Qle_trans (add_den_pos hden1 (add_den_pos (add_den_pos hden1 hden1) (add_den_pos hden1 hden1)))
    (Qadd_le_add hT1 (Qadd_le_add (Qadd_le_add hc1 hc2) hMcorner)) ?_
  exact Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)

/-- **Squaring difference**: `|a² − b²| ≤ |a − b|·(|a| + |b|)` over `Q` (since `a²−b² = (a−b)(a+b)`).
    The vehicle for reconciling `(altSum R)²` to `(altSum R')²` once the partial sums are close. -/
theorem Qsq_diff_le (a b : Q) (had : 0 < a.den) (hbd : 0 < b.den) :
    Qle (Qabs (Qsub (mul a a) (mul b b))) (mul (Qabs (Qsub a b)) (add (Qabs a) (Qabs b))) := by
  have hring : Qeq (Qsub (mul a a) (mul b b)) (mul (Qsub a b) (add a b)) := by
    simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  refine Qle_congr_left (Qabs_den_pos (Qmul_den_pos (Qsub_den_pos had hbd) (add_den_pos had hbd)))
    (Qeq_symm (Qabs_Qeq hring)) ?_
  rw [Qabs_mul]
  exact Qmul_le_mul_left (Qabs_num_nonneg _) (Qabs_add_le a b)


/-- Squared regularity at a common floor: `|(x.seq i)² − (x.seq j)²| ≤ 4·xBound/(n+1)` for `n ≤ i, j`. -/
theorem xsq_diff_n_le (x : Real) {n i j : Nat} (hi : n ≤ i) (hj : n ≤ j) :
    Qle (Qabs (Qsub (mul (x.seq i) (x.seq i)) (mul (x.seq j) (x.seq j)))) ⟨(4 * xBound x : Nat), n + 1⟩ := by
  refine Qle_trans (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos (x.den_pos i) (x.den_pos j)))
      (add_den_pos (Qabs_den_pos (x.den_pos i)) (Qabs_den_pos (x.den_pos j))))
    (Qsq_diff_le (x.seq i) (x.seq j) (x.den_pos i) (x.den_pos j)) ?_
  have hprod : Qle (mul (Qabs (Qsub (x.seq i) (x.seq j))) (add (Qabs (x.seq i)) (Qabs (x.seq j))))
      (mul (⟨2, n + 1⟩ : Q) ⟨((2 * xBound x : Nat) : Int), 1⟩) :=
    Qmul_le_mul (Qabs_den_pos (Qsub_den_pos (x.den_pos i) (x.den_pos j))) (Nat.succ_pos n)
      (add_den_pos (Qabs_den_pos (x.den_pos i)) (Qabs_den_pos (x.den_pos j))) (Qabs_num_nonneg _)
      (Int.add_nonneg (Int.mul_nonneg (Qabs_num_nonneg _) (Int.ofNat_nonneg _))
        (Int.mul_nonneg (Qabs_num_nonneg _) (Int.ofNat_nonneg _)))
      (xreg_n_le x hi hj)
      (Qle_trans (add_den_pos Nat.one_pos Nat.one_pos)
        (Qadd_le_add (canon_bound x i) (canon_bound x j))
        (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)))
  exact Qle_trans (Qmul_den_pos (Nat.succ_pos n) Nat.one_pos) hprod
    (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor))

/-- **Product-of-squares difference**: `|(p·b)² − q²·d²| ≤ |b²|·|p²−q²| + |q²|·|b²−d²|` (over `Q`), via
    `(pb)² − q²d² = b²(p²−q²) + q²(b²−d²)` and the triangle/`|·|`-multiplicativity. -/
theorem Qprodsq_diff_le (p b q d : Q) (hpd : 0 < p.den) (hbd : 0 < b.den) (hqd : 0 < q.den) (hdd : 0 < d.den) :
    Qle (Qabs (Qsub (mul (mul p b) (mul p b)) (mul (mul q q) (mul d d))))
      (add (mul (Qabs (mul b b)) (Qabs (Qsub (mul p p) (mul q q))))
        (mul (Qabs (mul q q)) (Qabs (Qsub (mul b b) (mul d d))))) := by
  have hid : Qeq (Qsub (mul (mul p b) (mul p b)) (mul (mul q q) (mul d d)))
      (add (mul (mul b b) (Qsub (mul p p) (mul q q))) (mul (mul q q) (Qsub (mul b b) (mul d d)))) := by
    simp only [Qeq, Qsub, add, mul, neg]; push_cast; ring_uor
  refine Qle_congr_left (Qabs_den_pos (add_den_pos (Qmul_den_pos (Qmul_den_pos hbd hbd)
      (Qsub_den_pos (Qmul_den_pos hpd hpd) (Qmul_den_pos hqd hqd)))
      (Qmul_den_pos (Qmul_den_pos hqd hqd) (Qsub_den_pos (Qmul_den_pos hbd hbd) (Qmul_den_pos hdd hdd)))))
    (Qeq_symm (Qabs_Qeq hid)) ?_
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qmul_den_pos (Qmul_den_pos hbd hbd)
      (Qsub_den_pos (Qmul_den_pos hpd hpd) (Qmul_den_pos hqd hqd))))
      (Qabs_den_pos (Qmul_den_pos (Qmul_den_pos hqd hqd) (Qsub_den_pos (Qmul_den_pos hbd hbd) (Qmul_den_pos hdd hdd)))))
    (Qabs_add_le _ _) ?_
  rw [Qabs_mul (mul b b) (Qsub (mul p p) (mul q q)), Qabs_mul (mul q q) (Qsub (mul b b) (mul d d))]
  exact Qle_refl _

/-- A larger denominator gives a smaller rational: `⟨a,d1⟩ ≤ ⟨a,d2⟩` when `0 ≤ a` and `d2 ≤ d1`. -/
theorem Q_den_mono {a : Int} (ha : 0 ≤ a) {d1 d2 : Nat} (hd : d2 ≤ d1) :
    Qle (⟨a, d1⟩ : Q) ⟨a, d2⟩ := by
  show a * ((d2 : Nat) : Int) ≤ a * ((d1 : Nat) : Int)
  exact Int.mul_le_mul_of_nonneg_left (by exact_mod_cast hd) ha

/-- **Reconciliation term decays**: `(2(M²)^{R_m+1}/(R_m+1)!)·(U+U) ≤ 2·Un/(n+1)` for `n ≤ m`
    (`R_m = RaltReal_R x m`, `Un = U.num.toNat`), via `RaltReal_trunc_le` and `U ≤ ⟨Un,1⟩`. -/
theorem diagU_le (x : Real) (m n : Nat) (hmn : n ≤ m) :
    Qle (mul ⟨(2 * npow (xBound x * xBound x) (RaltReal_R x m + 1) : Int), fct (RaltReal_R x m + 1)⟩
        (add (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x)))
          (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x)))))
      ⟨(2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Nat), n + 1⟩ := by
  have hUn0 := expM_U_num_nonneg (xBound x * xBound x) (2 * (xBound x * xBound x))
  have hUnd := expM_U_den_pos (xBound x * xBound x) (2 * (xBound x * xBound x))
  have h2m : 0 < 2 * (m + 1) := Nat.mul_pos (by decide) (Nat.succ_pos m)
  have hUU : Qle (add (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x)))
        (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))))
      ⟨(2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Nat), 1⟩ :=
    Qle_trans (add_den_pos Nat.one_pos Nat.one_pos)
      (Qadd_le_add (Q_le_num_toNat _ hUn0 hUnd) (Q_le_num_toNat _ hUn0 hUnd))
      (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  have hstep : Qle (mul ⟨(2 * npow (xBound x * xBound x) (RaltReal_R x m + 1) : Int), fct (RaltReal_R x m + 1)⟩
        (add (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x)))
          (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x)))))
      (mul (⟨1, 2 * (m + 1)⟩ : Q)
        ⟨(2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Nat), 1⟩) :=
    Qmul_le_mul (b := (⟨1, 2 * (m + 1)⟩ : Q)) (fct_pos _) h2m (add_den_pos hUnd hUnd)
      (Int.ofNat_nonneg _)
      (Int.add_nonneg (Int.mul_nonneg hUn0 (Int.ofNat_nonneg _)) (Int.mul_nonneg hUn0 (Int.ofNat_nonneg _)))
      (RaltReal_trunc_le x m) hUU
  refine Qle_trans (Qmul_den_pos h2m Nat.one_pos) hstep
    (Qle_trans (b := ⟨(2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Nat), 2 * (m + 1)⟩)
      h2m (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor)) ?_)
  show ((2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Nat) : Int) * ((n + 1 : Nat) : Int)
      ≤ ((2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Nat) : Int) * ((2 * (m + 1) : Nat) : Int)
  exact Int.mul_le_mul_of_nonneg_left (by exact_mod_cast (show (n + 1 : Nat) ≤ 2 * (m + 1) by omega))
    (Int.ofNat_nonneg _)

/-- The diagonal depth dominates its index: `n ≤ RaltReal_R x n`. -/
theorem n_le_RaltReal_R (x : Real) (n : Nat) : n ≤ RaltReal_R x n := by
  have hK : 0 < RaltReal_K x := by unfold RaltReal_K; omega
  have h4 : 4 * (n + 1) ≤ 4 * (n + 1) * RaltReal_K x := Nat.le_mul_of_pos_right (4 * (n + 1)) hK
  unfold RaltReal_R; omega

/-- The diagonal depth schedule `RaltReal_R x j = 2M² + 4(j+1)·RaltReal_K` is monotone in `j`. -/
theorem RaltReal_R_mono (x : Real) {j k : Nat} (hjk : j ≤ k) : RaltReal_R x j ≤ RaltReal_R x k := by
  unfold RaltReal_R
  have hmul : 4 * (j + 1) * RaltReal_K x ≤ 4 * (k + 1) * RaltReal_K x :=
    Nat.mul_le_mul_right _ (by omega)
  omega

/-- The alternating partial sum is bounded by the constant `U = expM_U M² (2M²)` (uniformly in depth). -/
theorem altSum_abs_le_U {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off N : Nat) : Qle (Qabs (altSum q off N)) (expM_U (M * M) (2 * (M * M))) := by
  rw [altSum_eq_Fsum]
  exact Qle_trans (Fsum_den_pos (fun i => Qabs_den_pos (altTerm_den_pos hqd off i)) N)
    (Fsum_abs_le (fun i => altTerm_den_pos hqd off i) N) (altAbsSum_le_U hqd hq off N)

/-- **Squared depth reconciliation**: `|(altSum R)² − (altSum N)²| ≤ (2(M²)^{R+1}/(R+1)!)·(U+U)` for
    `R ≤ N` — the squaring bound `Qsq_diff_le` fed by the depth tail `altSum_trunc_bound` and the
    uniform bound `altSum_abs_le_U`. -/
theorem altSq_reconcile {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off R N : Nat) (hR2 : 2 * (M * M) ≤ R + 2) (hRN : R ≤ N) :
    Qle (Qabs (Qsub (mul (altSum q off R) (altSum q off R)) (mul (altSum q off N) (altSum q off N))))
      (mul ⟨(2 * npow (M * M) (R + 1) : Int), fct (R + 1)⟩
        (add (expM_U (M * M) (2 * (M * M))) (expM_U (M * M) (2 * (M * M))))) := by
  have hRd := altSum_den_pos hqd off R
  have hNd := altSum_den_pos hqd off N
  refine Qle_trans (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos hRd hNd))
      (add_den_pos (Qabs_den_pos hRd) (Qabs_den_pos hNd)))
    (Qsq_diff_le (altSum q off R) (altSum q off N) hRd hNd) ?_
  exact Qmul_le_mul (Qabs_den_pos (Qsub_den_pos hRd hNd)) (fct_pos (R + 1))
    (add_den_pos (Qabs_den_pos hRd) (Qabs_den_pos hNd)) (Qabs_num_nonneg _)
    (Int.add_nonneg (Int.mul_nonneg (Qabs_num_nonneg _) (Int.ofNat_nonneg _))
      (Int.mul_nonneg (Qabs_num_nonneg _) (Int.ofNat_nonneg _)))
    (by rw [Qabs_Qsub_comm]; exact altSum_trunc_bound hqd hq off hR2 hRN)
    (Qadd_le_add (altSum_abs_le_U hqd hq off R) (altSum_abs_le_U hqd hq off N))

/-- **The deep Pythagorean error** at the odd reference depth `2K+1`: `|cos²_{2K+1}+q²sinaux²_{2K+1}−1| ≤ 5/(n+1)`
    once `K` is deep — `altPyth_dev_eq_err` rewrites it to `ERR`, `altErr_abs_le` majorises, `altErr_bound_decay` decays. -/
theorem deepErr_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (hm : 0 < M * M) (K n : Nat) (hKsmall : 2 * (M * M) ≤ K + 2)
    (hKbig : (expM_U (M * M) (2 * (M * M))).num.toNat * 4 * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (expM_U (M * M) (2 * (M * M))).num.toNat * 2 * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (expM_U (M * M) (2 * (M * M))).num.toNat * (4 * (M * M)) * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (expM_U (M * M) (2 * (M * M))).num.toNat * (2 * (M * M)) * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (M * M) * (n + 1) * npow (2 * (M * M)) (2 * (2 * (M * M)) + 1)
        + 2 * (M * M) ≤ K) :
    Qle (Qabs (Qsub (add (mul (altSum q 0 (2 * K + 1)) (altSum q 0 (2 * K + 1)))
        (mul (mul q q) (mul (altSum q 1 (2 * K + 1)) (altSum q 1 (2 * K + 1))))) ⟨1, 1⟩)) ⟨5, n + 1⟩ := by
  have ha0 : ∀ i, 0 < (altTerm q 0 i).den := altTerm_den_pos hqd 0
  have ha1 : ∀ i, 0 < (altTerm q 1 i).den := altTerm_den_pos hqd 1
  have hsqd : 0 < (mul q q).den := Qmul_den_pos hqd hqd
  have hUd := expM_U_den_pos (M * M) (2 * (M * M))
  rw [altSum_eq_Fsum q 0 (2 * K + 1), altSum_eq_Fsum q 1 (2 * K + 1)]
  have hERRd : 0 < (add (mul (mul q q) (Fsum (fun i => mul (altTerm q 1 i) (altTerm q 1 (2 * K + 1 - i))) (2 * K + 1)))
      (add (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (2 * K + 1))
            (Fsum (fun j => mul (altTerm q 0 i) (altTerm q 0 j)) (2 * K + 1 - i))) (2 * K + 1))
        (mul (mul q q) (Fsum (fun i => Qsub (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (2 * K + 1))
            (Fsum (fun j => mul (altTerm q 1 i) (altTerm q 1 j)) (2 * K + 1 - i))) (2 * K + 1))))).den :=
    add_den_pos (Qmul_den_pos hsqd (Fsum_den_pos (fun i => Qmul_den_pos (ha1 i) (ha1 (2 * K + 1 - i))) (2 * K + 1)))
      (add_den_pos
        (Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => Qmul_den_pos (ha0 i) (ha0 j)) (2 * K + 1))
          (Fsum_den_pos (fun j => Qmul_den_pos (ha0 i) (ha0 j)) (2 * K + 1 - i))) (2 * K + 1))
        (Qmul_den_pos hsqd (Fsum_den_pos (fun i => Qsub_den_pos
          (Fsum_den_pos (fun j => Qmul_den_pos (ha1 i) (ha1 j)) (2 * K + 1))
          (Fsum_den_pos (fun j => Qmul_den_pos (ha1 i) (ha1 j)) (2 * K + 1 - i))) (2 * K + 1))))
  have hmajd : 0 < (add (mul (⟨((M * M : Nat) : Int), 1⟩ : Q)
        (expTerm (add (⟨(M * M : Int), 1⟩ : Q) ⟨(M * M : Int), 1⟩) (2 * K + 1)))
      (add (add (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩)
            (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M)))))
        (mul (⟨((M * M : Nat) : Int), 1⟩ : Q)
          (add (mul (expM_U (M * M) (2 * (M * M))) ⟨(4 * npow (M * M) (K + 2) : Int), fct (K + 2)⟩)
            (mul ⟨(2 * npow (M * M) (K + 1) : Int), fct (K + 1)⟩ (expM_U (M * M) (2 * (M * M)))))))).den :=
    add_den_pos (Qmul_den_pos Nat.one_pos (expTerm_den_pos (add_den_pos Nat.one_pos Nat.one_pos) (2 * K + 1)))
      (add_den_pos (add_den_pos (Qmul_den_pos hUd (fct_pos (K + 2))) (Qmul_den_pos (fct_pos (K + 1)) hUd))
        (Qmul_den_pos Nat.one_pos (add_den_pos (Qmul_den_pos hUd (fct_pos (K + 2))) (Qmul_den_pos (fct_pos (K + 1)) hUd))))
  exact Qle_congr_left (Qabs_den_pos hERRd) (Qeq_symm (Qabs_Qeq (altPyth_dev_eq_err hqd (2 * K + 1))))
    (Qle_trans hmajd (altErr_abs_le hqd hq K hKsmall) (altErr_bound_decay M K n hm hKbig))

set_option maxHeartbeats 1000000 in
/-- **The rational Pythagorean deviation at a diagonal depth `R`** (with `R ≤ 2K+1`, `K` deep): split
    `cos²_R + q²·sinaux²_R − 1` through the deep reference `2K+1` — cos-reconciliation `|cos²_R − cos²_{2K+1}|`
    (`altSq_reconcile`), `q²·`sin-reconciliation, and the deep error `|cos²_{2K+1}+q²sinaux²_{2K+1}−1|`
    (`altPyth_dev_eq_err` + `altErr_abs_le` + `altErr_bound_decay` ≤ `5/(n+1)`). -/
theorem ratPyth_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (hm : 0 < M * M) (R K n : Nat) (hR2 : 2 * (M * M) ≤ R + 2) (hRK : R ≤ 2 * K + 1)
    (hKsmall : 2 * (M * M) ≤ K + 2)
    (hKbig : (expM_U (M * M) (2 * (M * M))).num.toNat * 4 * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (expM_U (M * M) (2 * (M * M))).num.toNat * 2 * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (expM_U (M * M) (2 * (M * M))).num.toNat * (4 * (M * M)) * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (expM_U (M * M) (2 * (M * M))).num.toNat * (2 * (M * M)) * (n + 1) * npow (M * M) (2 * (M * M) + 1)
        + (M * M) * (n + 1) * npow (2 * (M * M)) (2 * (2 * (M * M)) + 1)
        + 2 * (M * M) ≤ K) :
    Qle (Qabs (Qsub (add (mul (altSum q 0 R) (altSum q 0 R))
        (mul (mul q q) (mul (altSum q 1 R) (altSum q 1 R)))) ⟨1, 1⟩))
      (add (mul ⟨(2 * npow (M * M) (R + 1) : Int), fct (R + 1)⟩
            (add (expM_U (M * M) (2 * (M * M))) (expM_U (M * M) (2 * (M * M)))))
        (add (mul ⟨((M * M : Nat) : Int), 1⟩ (mul ⟨(2 * npow (M * M) (R + 1) : Int), fct (R + 1)⟩
              (add (expM_U (M * M) (2 * (M * M))) (expM_U (M * M) (2 * (M * M))))))
          ⟨5, n + 1⟩)) := by
  have hRd0 := altSum_den_pos hqd 0 R
  have hRd1 := altSum_den_pos hqd 1 R
  have hNd0 := altSum_den_pos hqd 0 (2 * K + 1)
  have hNd1 := altSum_den_pos hqd 1 (2 * K + 1)
  have hsqd : 0 < (mul q q).den := Qmul_den_pos hqd hqd
  -- abbreviations
  have hAd : 0 < (mul (altSum q 0 R) (altSum q 0 R)).den := Qmul_den_pos hRd0 hRd0
  have hA'd : 0 < (mul (altSum q 0 (2 * K + 1)) (altSum q 0 (2 * K + 1))).den := Qmul_den_pos hNd0 hNd0
  have hBd : 0 < (mul (mul q q) (mul (altSum q 1 R) (altSum q 1 R))).den :=
    Qmul_den_pos hsqd (Qmul_den_pos hRd1 hRd1)
  have hB'd : 0 < (mul (mul q q) (mul (altSum q 1 (2 * K + 1)) (altSum q 1 (2 * K + 1)))).den :=
    Qmul_den_pos hsqd (Qmul_den_pos hNd1 hNd1)
  -- algebraic three-term split
  have hsplit : Qeq (Qsub (add (mul (altSum q 0 R) (altSum q 0 R))
        (mul (mul q q) (mul (altSum q 1 R) (altSum q 1 R)))) ⟨1, 1⟩)
      (add (Qsub (mul (altSum q 0 R) (altSum q 0 R)) (mul (altSum q 0 (2 * K + 1)) (altSum q 0 (2 * K + 1))))
        (add (Qsub (mul (mul q q) (mul (altSum q 1 R) (altSum q 1 R)))
              (mul (mul q q) (mul (altSum q 1 (2 * K + 1)) (altSum q 1 (2 * K + 1)))))
          (Qsub (add (mul (altSum q 0 (2 * K + 1)) (altSum q 0 (2 * K + 1)))
              (mul (mul q q) (mul (altSum q 1 (2 * K + 1)) (altSum q 1 (2 * K + 1))))) ⟨1, 1⟩))) := by
    generalize mul (altSum q 0 R) (altSum q 0 R) = A
    generalize mul (altSum q 0 (2 * K + 1)) (altSum q 0 (2 * K + 1)) = A'
    generalize mul (mul q q) (mul (altSum q 1 R) (altSum q 1 R)) = B
    generalize mul (mul q q) (mul (altSum q 1 (2 * K + 1)) (altSum q 1 (2 * K + 1))) = B'
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hAd hA'd))
      (add_den_pos (Qabs_den_pos (Qsub_den_pos hBd hB'd)) (Qabs_den_pos (Qsub_den_pos (add_den_pos hA'd hB'd) Nat.one_pos))))
    (Qle_congr_left (Qabs_den_pos (add_den_pos (Qsub_den_pos hAd hA'd)
        (add_den_pos (Qsub_den_pos hBd hB'd) (Qsub_den_pos (add_den_pos hA'd hB'd) Nat.one_pos))))
      (Qeq_symm (Qabs_Qeq hsplit))
      (Qabs_add3_le _ _ _ (Qsub_den_pos hAd hA'd) (Qsub_den_pos hBd hB'd)
        (Qsub_den_pos (add_den_pos hA'd hB'd) Nat.one_pos))) ?_
  -- bound the three terms
  refine Qadd_le_add (altSq_reconcile hqd hq 0 R (2 * K + 1) hR2 hRK) (Qadd_le_add ?_ ?_)
  · -- sin reconciliation: |B − B'| ≤ M²·(sin altSq_reconcile)
    have hBdist : Qeq (Qsub (mul (mul q q) (mul (altSum q 1 R) (altSum q 1 R)))
          (mul (mul q q) (mul (altSum q 1 (2 * K + 1)) (altSum q 1 (2 * K + 1)))))
        (mul (mul q q) (Qsub (mul (altSum q 1 R) (altSum q 1 R))
          (mul (altSum q 1 (2 * K + 1)) (altSum q 1 (2 * K + 1))))) :=
      Qeq_symm (Qmul_sub_distrib (mul q q) (mul (altSum q 1 R) (altSum q 1 R))
        (mul (altSum q 1 (2 * K + 1)) (altSum q 1 (2 * K + 1))))
    refine Qle_congr_left (Qabs_den_pos (Qmul_den_pos hsqd
        (Qsub_den_pos (Qmul_den_pos hRd1 hRd1) (Qmul_den_pos hNd1 hNd1))))
      (Qeq_symm (Qabs_Qeq hBdist)) ?_
    exact Qabs_qsq_mul_le hqd hq (Qsub_den_pos (Qmul_den_pos hRd1 hRd1) (Qmul_den_pos hNd1 hNd1))
      (altSq_reconcile hqd hq 1 R (2 * K + 1) hR2 hRK)
  · -- deep error: |cos²_{2K+1} + q²sinaux²_{2K+1} − 1| ≤ 5/(n+1)
    exact deepErr_le hqd hq hm K n hKsmall hKbig

/-- **cos² diagonal de-reindex**: the `Rmul` diagonal of `cos²` at `n` is within `2·xBound/(n+1)` of the
    natural-diagonal square `(RaltReal_seq x 0 n)²`. (Removes `Rmul`'s `Ridx` reindex via the diagonal
    regularity `RaltReal_diag_le` and the squaring bound `Qsq_diff_le`.) -/
theorem Rcos_sq_diag_le (x : Real) (n : Nat) :
    Qle (Qabs (Qsub ((Rmul (Rcos x) (Rcos x)).seq n)
        (mul (RaltReal_seq x 0 n) (RaltReal_seq x 0 n))))
      (mul (Qbound n) ⟨(2 * xBound (Rcos x) : Int), 1⟩) := by
  have hJ : n ≤ Ridx (Rcos x) (Rcos x) n := Ridx_ge (Rcos x) (Rcos x) n
  have hAd : 0 < (RaltReal_seq x 0 (Ridx (Rcos x) (Rcos x) n)).den := (Rcos x).den_pos _
  have hBd : 0 < (RaltReal_seq x 0 n).den := (Rcos x).den_pos n
  show Qle (Qabs (Qsub (mul (RaltReal_seq x 0 (Ridx (Rcos x) (Rcos x) n))
        (RaltReal_seq x 0 (Ridx (Rcos x) (Rcos x) n)))
      (mul (RaltReal_seq x 0 n) (RaltReal_seq x 0 n))))
    (mul (Qbound n) ⟨(2 * xBound (Rcos x) : Int), 1⟩)
  refine Qle_trans (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos hAd hBd))
      (add_den_pos (Qabs_den_pos hAd) (Qabs_den_pos hBd)))
    (Qsq_diff_le (RaltReal_seq x 0 (Ridx (Rcos x) (Rcos x) n)) (RaltReal_seq x 0 n) hAd hBd) ?_
  refine Qmul_le_mul (Qabs_den_pos (Qsub_den_pos hAd hBd)) (Qbound_den_pos n)
    (add_den_pos (Qabs_den_pos hAd) (Qabs_den_pos hBd)) (Qabs_num_nonneg _)
    (Int.add_nonneg (Int.mul_nonneg (Qabs_num_nonneg _) (Int.ofNat_nonneg _))
      (Int.mul_nonneg (Qabs_num_nonneg _) (Int.ofNat_nonneg _)))
    (by rw [Qabs_Qsub_comm]; exact RaltReal_diag_le x 0 hJ)
    (Qle_trans (add_den_pos Nat.one_pos Nat.one_pos)
      (Qadd_le_add (canon_bound (Rcos x) (Ridx (Rcos x) (Rcos x) n)) (canon_bound (Rcos x) n))
      (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)))

set_option maxHeartbeats 1000000 in
/-- **sin² diagonal de-reindex**: `(Rmul (Rsin x) (Rsin x)).seq n` is within `C/(n+1)` of the natural form
    `(x.seq R_n)²·(altSum (x.seq R_n) 1 R_n)²` (`R_n = RaltReal_R x n`). Splits via `Qprodsq_diff_le` into the
    `x²`-factor drift (`xsq_diff_n_le`) and the alt-series diagonal reconciliation (`RaltReal_diag_le`). -/
theorem Rsin_sq_diag_le (x : Real) (n : Nat) :
    Qle (Qabs (Qsub ((Rmul (Rsin x) (Rsin x)).seq n)
        (mul (mul (x.seq (RaltReal_R x n)) (x.seq (RaltReal_R x n)))
          (mul (altSum (x.seq (RaltReal_R x n)) 1 (RaltReal_R x n))
               (altSum (x.seq (RaltReal_R x n)) 1 (RaltReal_R x n))))))
      ⟨((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
            * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (4 * xBound x)
          + xBound x * xBound x
            * (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat) : Nat), n + 1⟩ := by
  -- names
  have hnJ2 : n ≤ Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n) :=
    Nat.le_trans (Ridx_ge (Rsin x) (Rsin x) n) (Ridx_ge x (RsinAux x) (Ridx (Rsin x) (Rsin x) n))
  have hnRn : n ≤ RaltReal_R x n := n_le_RaltReal_R x n
  have hnR1 : n ≤ RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)) :=
    Nat.le_trans hnJ2 (n_le_RaltReal_R x _)
  -- abbreviations for the four factors
  have hUn0 := expM_U_num_nonneg (xBound x * xBound x) (2 * (xBound x * xBound x))
  have hUnd := expM_U_den_pos (xBound x * xBound x) (2 * (xBound x * xBound x))
  -- |b| ≤ Un, |d| ≤ Un  (the alt-series partial sums)
  have hb_abs : Qle (Qabs (altSum (x.seq (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)))) 1
        (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)))))
      ⟨((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Int), 1⟩ :=
    Qle_trans (expM_U_den_pos _ _) (altSum_abs_le_U (x.den_pos _) (canon_bound x _) 1 _)
      (Q_le_num_toNat _ hUn0 hUnd)
  have hd_abs : Qle (Qabs (altSum (x.seq (RaltReal_R x n)) 1 (RaltReal_R x n)))
      ⟨((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Int), 1⟩ :=
    Qle_trans (expM_U_den_pos _ _) (altSum_abs_le_U (x.den_pos _) (canon_bound x _) 1 _)
      (Q_le_num_toNat _ hUn0 hUnd)
  refine Qle_trans (add_den_pos
      (Qmul_den_pos (Qabs_den_pos (Qmul_den_pos (altSum_den_pos (x.den_pos _) 1 _)
          (altSum_den_pos (x.den_pos _) 1 _)))
        (Qabs_den_pos (Qsub_den_pos (Qmul_den_pos (x.den_pos _) (x.den_pos _))
          (Qmul_den_pos (x.den_pos _) (x.den_pos _)))))
      (Qmul_den_pos (Qabs_den_pos (Qmul_den_pos (x.den_pos _) (x.den_pos _)))
        (Qabs_den_pos (Qsub_den_pos (Qmul_den_pos (altSum_den_pos (x.den_pos _) 1 _)
          (altSum_den_pos (x.den_pos _) 1 _)) (Qmul_den_pos (altSum_den_pos (x.den_pos _) 1 _)
          (altSum_den_pos (x.den_pos _) 1 _))))))
    (Qprodsq_diff_le (x.seq (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)))
      (altSum (x.seq (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)))) 1
        (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n))))
      (x.seq (RaltReal_R x n)) (altSum (x.seq (RaltReal_R x n)) 1 (RaltReal_R x n))
      (x.den_pos _) (altSum_den_pos (x.den_pos _) 1 _) (x.den_pos _) (altSum_den_pos (x.den_pos _) 1 _)) ?_
  -- term1 = |b²|·|p²−q²| ≤ ⟨Un²·4·xBound, n+1⟩ ; term2 = |q²|·|b²−d²| ≤ ⟨xBound²·2Un, n+1⟩
  refine Qle_trans (b := add
      ⟨((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
          * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (4 * xBound x) : Nat), n + 1⟩
      ⟨(xBound x * xBound x
          * (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat) : Nat), n + 1⟩)
    (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add ?term1 ?term2)
    (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  · -- term1
    have hbb : Qle (Qabs (mul (altSum (x.seq (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)))) 1
          (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n))))
        (altSum (x.seq (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)))) 1
          (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n))))))
        ⟨((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
            * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Nat), 1⟩ := by
      rw [Qabs_mul]
      exact Qle_trans (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_le_mul (Qabs_den_pos (altSum_den_pos (x.den_pos _) 1 _)) Nat.one_pos
          (Qabs_den_pos (altSum_den_pos (x.den_pos _) 1 _)) (Qabs_num_nonneg _) (Qabs_num_nonneg _)
          hb_abs hb_abs)
        (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor))
    exact Qle_trans (Qmul_den_pos Nat.one_pos (Nat.succ_pos n))
      (Qmul_le_mul (Qabs_den_pos (Qmul_den_pos (altSum_den_pos (x.den_pos _) 1 _)
          (altSum_den_pos (x.den_pos _) 1 _))) Nat.one_pos
        (Qabs_den_pos (Qsub_den_pos (Qmul_den_pos (x.den_pos _) (x.den_pos _))
          (Qmul_den_pos (x.den_pos _) (x.den_pos _)))) (Qabs_num_nonneg _) (Qabs_num_nonneg _)
        hbb (xsq_diff_n_le x hnJ2 hnRn))
      (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor))
  · -- term2
    have hqq : Qle (Qabs (mul (x.seq (RaltReal_R x n)) (x.seq (RaltReal_R x n))))
        ⟨(xBound x * xBound x : Nat), 1⟩ := by
      rw [Qabs_mul]
      exact Qle_trans (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_le_mul (Qabs_den_pos (x.den_pos _)) Nat.one_pos (Qabs_den_pos (x.den_pos _))
          (Qabs_num_nonneg _) (Qabs_num_nonneg _) (canon_bound x _) (canon_bound x _))
        (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor))
    have hbmd : Qle (Qabs (Qsub
          (altSum (x.seq (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)))) 1
            (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n))))
          (altSum (x.seq (RaltReal_R x n)) 1 (RaltReal_R x n)))) ⟨1, n + 1⟩ := by
      rw [Qabs_Qsub_comm]; exact RaltReal_diag_le x 1 hnJ2
    have hb2d2 : Qle (Qabs (Qsub
          (mul (altSum (x.seq (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)))) 1
            (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n))))
            (altSum (x.seq (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)))) 1
              (RaltReal_R x (Ridx x (RsinAux x) (Ridx (Rsin x) (Rsin x) n)))))
          (mul (altSum (x.seq (RaltReal_R x n)) 1 (RaltReal_R x n))
            (altSum (x.seq (RaltReal_R x n)) 1 (RaltReal_R x n)))))
        ⟨(2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Nat), n + 1⟩ := by
      refine Qle_trans (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos
          (altSum_den_pos (x.den_pos _) 1 _) (altSum_den_pos (x.den_pos _) 1 _)))
          (add_den_pos (Qabs_den_pos (altSum_den_pos (x.den_pos _) 1 _))
            (Qabs_den_pos (altSum_den_pos (x.den_pos _) 1 _))))
        (Qsq_diff_le _ _ (altSum_den_pos (x.den_pos _) 1 _) (altSum_den_pos (x.den_pos _) 1 _)) ?_
      exact Qle_trans (Qmul_den_pos (Nat.succ_pos n) Nat.one_pos)
        (Qmul_le_mul (d := ⟨(2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Nat), 1⟩)
          (Qabs_den_pos (Qsub_den_pos (altSum_den_pos (x.den_pos _) 1 _)
            (altSum_den_pos (x.den_pos _) 1 _))) (Nat.succ_pos n)
          (add_den_pos (Qabs_den_pos (altSum_den_pos (x.den_pos _) 1 _))
            (Qabs_den_pos (altSum_den_pos (x.den_pos _) 1 _))) (Qabs_num_nonneg _)
          (Int.add_nonneg (Int.mul_nonneg (Qabs_num_nonneg _) (Int.ofNat_nonneg _))
            (Int.mul_nonneg (Qabs_num_nonneg _) (Int.ofNat_nonneg _)))
          hbmd (Qle_trans (add_den_pos Nat.one_pos Nat.one_pos) (Qadd_le_add hb_abs hd_abs)
            (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))))
        (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor))
    exact Qle_trans (Qmul_den_pos Nat.one_pos (Nat.succ_pos n))
      (Qmul_le_mul (Qabs_den_pos (Qmul_den_pos (x.den_pos _) (x.den_pos _))) Nat.one_pos
        (Qabs_den_pos (Qsub_den_pos (Qmul_den_pos (altSum_den_pos (x.den_pos _) 1 _)
          (altSum_den_pos (x.den_pos _) 1 _)) (Qmul_den_pos (altSum_den_pos (x.den_pos _) 1 _)
          (altSum_den_pos (x.den_pos _) 1 _)))) (Qabs_num_nonneg _) (Qabs_num_nonneg _)
        hqq hb2d2)
      (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor))

/-- Four-factor real rearrangement `(a·b)·(c·d) ≈ (a·c)·(b·d)` (via `Rmul` associativity/commutativity). -/
theorem Rmul4_rearrange (a b c d : Real) :
    Req (Rmul (Rmul a b) (Rmul c d)) (Rmul (Rmul a c) (Rmul b d)) :=
  Req_trans (Rmul_assoc a b (Rmul c d))
    (Req_trans (Rmul_congr (Req_refl a) (Req_symm (Rmul_assoc b c d)))
      (Req_trans (Rmul_congr (Req_refl a) (Rmul_congr (Rmul_comm b c) (Req_refl d)))
        (Req_trans (Rmul_congr (Req_refl a) (Rmul_assoc c b d))
          (Req_symm (Rmul_assoc a c (Rmul b d))))))

/-- **`sin²x = x²·(sinaux x)²`** as reals (since `Rsin x = Rmul x (RsinAux x)`). This rewrites the
    `sin²` summand into the `x²·(alt-series)²` form that matches the rational Pythagorean identity. -/
theorem Rsin_sq_eq (x : Real) :
    Req (Rmul (Rsin x) (Rsin x)) (Rmul (Rmul x x) (Rmul (RsinAux x) (RsinAux x))) :=
  Rmul4_rearrange x (RsinAux x) x (RsinAux x)

/-- **The diagonal reconciliation**: two alt-series partial sums at *different arguments and depths*
    differ by a depth tail plus an argument-Lipschitz term:
    `|altSum a off R − altSum b off R'| ≤ 2(M²)^{R'+1}/(R'+1)! + LipS(M²,R')·|−a² − (−b²)|`
    (for `R' ≤ R`, `2M² ≤ R'+2`, `|a|,|b| ≤ M`). Triangle through `altSum a off R'`:
    `altSum_trunc_bound` (depth) + `altSum_Lip_le` (argument). -/
theorem altSum_reconcile {a b : Q} {M : Nat} (had : 0 < a.den) (hbd : 0 < b.den)
    (ha : Qle (Qabs a) ⟨(M : Int), 1⟩) (hb : Qle (Qabs b) ⟨(M : Int), 1⟩) (off : Nat)
    {R R' : Nat} (hRR' : R' ≤ R) (hR'2 : 2 * (M * M) ≤ R' + 2) :
    Qle (Qabs (Qsub (altSum a off R) (altSum b off R')))
      (add ⟨(2 * npow (M * M) (R' + 1) : Int), fct (R' + 1)⟩
        (mul (LipS (M * M) R') (Qabs (Qsub (neg (mul a a)) (neg (mul b b)))))) := by
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (altSum_den_pos had off R)
      (altSum_den_pos had off R'))) (Qabs_den_pos (Qsub_den_pos (altSum_den_pos had off R')
      (altSum_den_pos hbd off R'))))
    (Qabs_sub_triangle (altSum_den_pos had off R) (altSum_den_pos had off R')
      (altSum_den_pos hbd off R')) ?_
  exact Qadd_le_add (altSum_trunc_bound had ha off hR'2 hRR') (altSum_Lip_le had hbd ha hb off R')

set_option maxHeartbeats 1600000 in
/-- **`cos² x + sin² x = 1` as constructive reals.** The diagonal of `cos²+sin²` at `n` (sampled at
    `2n+1` by `Radd`) is reconciled to the rational Pythagorean identity at the natural depth
    `R_{2n+1}`: `Rcos_sq_diag_le` + `Rsin_sq_diag_le` de-reindex the two squares, and `ratPyth_le`
    (with the deep reference `K`) controls the residual — every piece `≤ C/(n+1)`, the `Req` tolerance. -/
theorem Rcos_sq_add_sin_sq (x : Real) :
    Req (Radd (Rmul (Rcos x) (Rcos x)) (Rmul (Rsin x) (Rsin x))) one := by
  refine Req_of_lin_bound
    (C := 2 * xBound (Rcos x)
      + ((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
            * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (4 * xBound x)
          + xBound x * xBound x * (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat))
      + (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
          + xBound x * xBound x * (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat)
          + 5)) ?_
  intro n
  show Qle (Qabs (Qsub (add ((Rmul (Rcos x) (Rcos x)).seq (2 * n + 1))
      ((Rmul (Rsin x) (Rsin x)).seq (2 * n + 1))) ⟨1, 1⟩))
    ⟨(2 * xBound (Rcos x)
      + ((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
            * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (4 * xBound x)
          + xBound x * xBound x * (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat))
      + (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
          + xBound x * xBound x * (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat)
          + 5) : Nat), n + 1⟩
  have hnm : n ≤ 2 * n + 1 := by omega
  have hRm2 : 2 * (xBound x * xBound x) ≤ RaltReal_R x (2 * n + 1) := by unfold RaltReal_R; omega
  -- den-positivity of the four factors
  have hA : 0 < ((Rmul (Rcos x) (Rcos x)).seq (2 * n + 1)).den := (Rmul (Rcos x) (Rcos x)).den_pos _
  have hB : 0 < ((Rmul (Rsin x) (Rsin x)).seq (2 * n + 1)).den := (Rmul (Rsin x) (Rsin x)).den_pos _
  have hC0 : 0 < (mul (RaltReal_seq x 0 (2 * n + 1)) (RaltReal_seq x 0 (2 * n + 1))).den :=
    Qmul_den_pos (altSum_den_pos (x.den_pos _) 0 _) (altSum_den_pos (x.den_pos _) 0 _)
  have hS0 : 0 < (mul (mul (x.seq (RaltReal_R x (2 * n + 1))) (x.seq (RaltReal_R x (2 * n + 1))))
      (mul (altSum (x.seq (RaltReal_R x (2 * n + 1))) 1 (RaltReal_R x (2 * n + 1)))
        (altSum (x.seq (RaltReal_R x (2 * n + 1))) 1 (RaltReal_R x (2 * n + 1))))).den :=
    Qmul_den_pos (Qmul_den_pos (x.den_pos _) (x.den_pos _))
      (Qmul_den_pos (altSum_den_pos (x.den_pos _) 1 _) (altSum_den_pos (x.den_pos _) 1 _))
  -- three-term split
  have hsplit : Qeq (Qsub (add ((Rmul (Rcos x) (Rcos x)).seq (2 * n + 1))
        ((Rmul (Rsin x) (Rsin x)).seq (2 * n + 1))) ⟨1, 1⟩)
      (add (Qsub ((Rmul (Rcos x) (Rcos x)).seq (2 * n + 1))
          (mul (RaltReal_seq x 0 (2 * n + 1)) (RaltReal_seq x 0 (2 * n + 1))))
        (add (Qsub ((Rmul (Rsin x) (Rsin x)).seq (2 * n + 1))
            (mul (mul (x.seq (RaltReal_R x (2 * n + 1))) (x.seq (RaltReal_R x (2 * n + 1))))
              (mul (altSum (x.seq (RaltReal_R x (2 * n + 1))) 1 (RaltReal_R x (2 * n + 1)))
                (altSum (x.seq (RaltReal_R x (2 * n + 1))) 1 (RaltReal_R x (2 * n + 1))))))
          (Qsub (add (mul (RaltReal_seq x 0 (2 * n + 1)) (RaltReal_seq x 0 (2 * n + 1)))
              (mul (mul (x.seq (RaltReal_R x (2 * n + 1))) (x.seq (RaltReal_R x (2 * n + 1))))
                (mul (altSum (x.seq (RaltReal_R x (2 * n + 1))) 1 (RaltReal_R x (2 * n + 1)))
                  (altSum (x.seq (RaltReal_R x (2 * n + 1))) 1 (RaltReal_R x (2 * n + 1)))))) ⟨1, 1⟩))) := by
    generalize (Rmul (Rcos x) (Rcos x)).seq (2 * n + 1) = A
    generalize (Rmul (Rsin x) (Rsin x)).seq (2 * n + 1) = B
    generalize mul (RaltReal_seq x 0 (2 * n + 1)) (RaltReal_seq x 0 (2 * n + 1)) = C0
    generalize mul (mul (x.seq (RaltReal_R x (2 * n + 1))) (x.seq (RaltReal_R x (2 * n + 1))))
      (mul (altSum (x.seq (RaltReal_R x (2 * n + 1))) 1 (RaltReal_R x (2 * n + 1)))
        (altSum (x.seq (RaltReal_R x (2 * n + 1))) 1 (RaltReal_R x (2 * n + 1)))) = S0
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hA hC0))
      (add_den_pos (Qabs_den_pos (Qsub_den_pos hB hS0)) (Qabs_den_pos (Qsub_den_pos (add_den_pos hC0 hS0) Nat.one_pos))))
    (Qle_congr_left (Qabs_den_pos (add_den_pos (Qsub_den_pos hA hC0)
        (add_den_pos (Qsub_den_pos hB hS0) (Qsub_den_pos (add_den_pos hC0 hS0) Nat.one_pos))))
      (Qeq_symm (Qabs_Qeq hsplit))
      (Qabs_add3_le _ _ _ (Qsub_den_pos hA hC0) (Qsub_den_pos hB hS0)
        (Qsub_den_pos (add_den_pos hC0 hS0) Nat.one_pos))) ?_
  -- bound the three pieces, each ≤ c_i/(n+1)
  refine Qle_trans (b := add ⟨(2 * xBound (Rcos x) : Nat), n + 1⟩
      (add ⟨((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
              * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (4 * xBound x)
            + xBound x * xBound x * (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat) : Nat), n + 1⟩
        ⟨(2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
            + xBound x * xBound x * (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat)
            + 5 : Nat), n + 1⟩))
    (add_den_pos (Nat.succ_pos n) (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)))
    (Qadd_le_add ?p1 (Qadd_le_add ?p2 ?p3))
    (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  · -- p1: cos² de-reindex
    refine Qle_trans (Qmul_den_pos (Qbound_den_pos _) Nat.one_pos) (Rcos_sq_diag_le x (2 * n + 1))
      (Qle_trans (b := ⟨((2 * xBound (Rcos x) : Nat) : Int), 2 * n + 1 + 1⟩) (Nat.succ_pos _)
        (Qeq_le (by simp only [Qeq, mul, Qbound]; push_cast; ring_uor))
        (Q_den_mono (by exact_mod_cast Nat.zero_le _) (by omega)))
  · -- p2: sin² de-reindex
    exact Qle_trans (b := ⟨((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat
            * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (4 * xBound x)
          + xBound x * xBound x * (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat) : Nat), 2 * n + 1 + 1⟩)
      (Nat.succ_pos _) (Rsin_sq_diag_le x (2 * n + 1)) (Q_den_mono (by exact_mod_cast Nat.zero_le _) (by omega))
  · -- p3: rational Pythagorean at the deep reference
    refine Qle_trans (b := add (mul ⟨(2 * npow (xBound x * xBound x) (RaltReal_R x (2 * n + 1) + 1) : Int),
          fct (RaltReal_R x (2 * n + 1) + 1)⟩
        (add (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x)))
          (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x)))))
        (add (mul ⟨((xBound x * xBound x : Nat) : Int), 1⟩ (mul ⟨(2 * npow (xBound x * xBound x) (RaltReal_R x (2 * n + 1) + 1) : Int),
            fct (RaltReal_R x (2 * n + 1) + 1)⟩
          (add (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x)))
            (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))))))
          ⟨5, n + 1⟩))
      (add_den_pos (Qmul_den_pos (fct_pos _) (add_den_pos (expM_U_den_pos _ _) (expM_U_den_pos _ _)))
        (add_den_pos (Qmul_den_pos Nat.one_pos (Qmul_den_pos (fct_pos _)
          (add_den_pos (expM_U_den_pos _ _) (expM_U_den_pos _ _)))) (Nat.succ_pos n)))
      (ratPyth_le (x.den_pos _) (canon_bound x _) (Nat.mul_pos (xBound_pos x) (xBound_pos x))
        (RaltReal_R x (2 * n + 1))
        ((expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * 4 * (n + 1) * npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1)
          + (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * 2 * (n + 1) * npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1)
          + (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (4 * (xBound x * xBound x)) * (n + 1) * npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1)
          + (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat * (2 * (xBound x * xBound x)) * (n + 1) * npow (xBound x * xBound x) (2 * (xBound x * xBound x) + 1)
          + (xBound x * xBound x) * (n + 1) * npow (2 * (xBound x * xBound x)) (2 * (2 * (xBound x * xBound x)) + 1)
          + 2 * (xBound x * xBound x) + RaltReal_R x (2 * n + 1))
        n (by omega) (by omega) (by omega) (Nat.le_add_right _ _)) ?_
    -- bound ratPyth output ≤ c3/(n+1)
    refine Qle_trans (b := add ⟨(2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat : Nat), n + 1⟩
        (add ⟨(xBound x * xBound x * (2 * (expM_U (xBound x * xBound x) (2 * (xBound x * xBound x))).num.toNat) : Nat), n + 1⟩ ⟨5, n + 1⟩))
      (add_den_pos (Nat.succ_pos n) (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)))
      (Qadd_le_add (diagU_le x (2 * n + 1) n hnm)
        (Qadd_le_add ?mc (Qle_refl ⟨5, n + 1⟩)))
      (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
    -- mc: M²·(diagU) ≤ ⟨M²·2Un, n+1⟩
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Nat.succ_pos n))
      (Qmul_le_mul_left (Int.ofNat_nonneg _) (diagU_le x (2 * n + 1) n hnm)) ?_
    exact Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor)

end UOR.Bridge.F1Square.Analysis
