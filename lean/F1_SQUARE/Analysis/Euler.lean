/-
F1 square — the **Euler–Mascheroni constant** `γ₀` as a genuine constructive real, via the
alternating series

  γ = Σ_{k≥2} (−1)ᵏ ζ(k)/k     (reindex i = k−2:  γ = Σ_{i≥0} (−1)ⁱ · ζ(i+2)/(i+2)).

The terms `b(i) = ζ(i+2)/(i+2)` are positive and **antitone** (both `ζ(s)` decreasing in `s` and the
`1/(i+2)` factor decreasing), so this is a textbook alternating series. We mechanize the alternating
bracket from scratch over `Q`:

  `AltSum b (L+1) = b 0 − AltSum (shift b) L`

— the "Leibniz" recursion that makes both the enclosure `0 ≤ AltSum b L ≤ b 0` and the gap bound
`|AltSum b (L+m) − AltSum b L| ≤ b L` provable by a single induction (no parity case-split). γ₀ is then
a custom single rational diagonal `gammaSeq j`, exactly as `Rpi`: a finite double sum of the rational
ζ-approximants whose truncation (in the number of terms) and approximation (in the ζ-depth) errors are
each driven below the Bishop modulus `1/(j+1)`.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.Zeta
import F1Square.Analysis.Complete
import F1Square.Analysis.Pi

namespace UOR.Bridge.F1Square.Analysis

/-! ### The alternating (Leibniz) partial sum over `Q` -/

/-- The alternating partial sum `Σ_{i=0}^{L-1} (−1)ⁱ b i`, via the Leibniz recursion
    `AltSum b (L+1) = b 0 − AltSum (b∘succ) L`. -/
def AltSum (b : Nat → Q) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (L + 1) => Qsub (b 0) (AltSum (fun i => b (i + 1)) L)

theorem AltSum_succ (b : Nat → Q) (L : Nat) :
    AltSum b (L + 1) = Qsub (b 0) (AltSum (fun i => b (i + 1)) L) := rfl

/-- `0 ≤ a − c` when `c ≤ a`. -/
theorem Qsub_nonneg_of_le {a c : Q} (h : Qle c a) : Qle (⟨0, 1⟩ : Q) (Qsub a c) := by
  show (0 : Int) * ((add a (neg c)).den : Int) ≤ (add a (neg c)).num * 1
  simp only [add, neg]
  have h' : c.num * (a.den : Int) ≤ a.num * (c.den : Int) := h
  push_cast
  rw [Int.neg_mul]
  generalize a.num * (c.den : Int) = X at h' ⊢
  generalize c.num * (a.den : Int) = Y at h' ⊢
  omega

/-- `0 ≤ q` (as `Qle ⟨0,1⟩ q`) from `0 ≤ q.num`. -/
theorem Qzero_le {q : Q} (h : 0 ≤ q.num) : Qle (⟨0, 1⟩ : Q) q := by
  show (0 : Int) * (q.den : Int) ≤ q.num * 1; omega

/-- `0 ≤ q.num` from `0 ≤ q` (as `Qle ⟨0,1⟩ q`). -/
theorem num_nonneg_of_Qzero_le {q : Q} (h : Qle (⟨0, 1⟩ : Q) q) : 0 ≤ q.num := by
  have h' : (0 : Int) * (q.den : Int) ≤ q.num * 1 := h; omega

/-- `a − 0 ≈ a`. -/
theorem Qsub_zero_eq (a : Q) : Qeq (Qsub a (⟨0, 1⟩ : Q)) a := by
  simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- The Leibniz partial sum has positive denominator (its terms do). -/
theorem AltSum_den_pos (b : Nat → Q) (hden : ∀ i, 0 < (b i).den) :
    ∀ L, 0 < (AltSum b L).den
  | 0 => Nat.one_pos
  | (L + 1) => by
      rw [AltSum_succ]
      exact Qsub_den_pos (hden 0)
        (AltSum_den_pos (fun i => b (i + 1)) (fun i => hden (i + 1)) L)

/-! ### The alternating bracket and gap bound -/

/-- **The Leibniz enclosure**: for a non-negative, antitone sequence `b`, every alternating partial
    sum lies in `[0, b 0]`. -/
theorem altSum_bracket (b : Nat → Q) (hnn : ∀ i, 0 ≤ (b i).num) (hden : ∀ i, 0 < (b i).den)
    (hanti : ∀ i, Qle (b (i + 1)) (b i)) (L : Nat) :
    Qle (⟨0, 1⟩ : Q) (AltSum b L) ∧ Qle (AltSum b L) (b 0) := by
  induction L generalizing b with
  | zero =>
    exact ⟨Qle_refl _, Qzero_le (hnn 0)⟩
  | succ L ih =>
    have ihb := ih (fun i => b (i + 1)) (fun i => hnn (i + 1)) (fun i => hden (i + 1))
      (fun i => hanti (i + 1))
    rw [AltSum_succ]
    refine ⟨Qsub_nonneg_of_le (Qle_trans (hden 1) ihb.2 (hanti 0)),
      Qsub_le_self (num_nonneg_of_Qzero_le ihb.1)⟩

/-- **The alternating gap bound**: consecutive tails are controlled by the first omitted term —
    `|AltSum b (L+m) − AltSum b L| ≤ b L`. The Bishop modulus for γ₀'s truncation error. -/
theorem altSum_gap (b : Nat → Q) (hnn : ∀ i, 0 ≤ (b i).num) (hden : ∀ i, 0 < (b i).den)
    (hanti : ∀ i, Qle (b (i + 1)) (b i)) (L m : Nat) :
    Qle (Qabs (Qsub (AltSum b (L + m)) (AltSum b L))) (b L) := by
  induction L generalizing b with
  | zero =>
    rw [Nat.zero_add, show AltSum b 0 = (⟨0, 1⟩ : Q) from rfl]
    have hbr := altSum_bracket b hnn hden hanti m
    have hnn' : 0 ≤ (Qsub (AltSum b m) (⟨0, 1⟩ : Q)).num :=
      num_nonneg_of_Qzero_le (Qle_congr_right (AltSum_den_pos b hden m)
        (Qeq_symm (Qsub_zero_eq _)) hbr.1)
    refine Qabs_le_of_nonneg hnn' ?_
    exact Qle_congr_left (AltSum_den_pos b hden m) (Qeq_symm (Qsub_zero_eq _)) hbr.2
  | succ L ih =>
    have ihb := ih (fun i => b (i + 1)) (fun i => hnn (i + 1)) (fun i => hden (i + 1))
      (fun i => hanti (i + 1))
    rw [show L + 1 + m = (L + m) + 1 from by omega, AltSum_succ, AltSum_succ]
    -- `Qsub (Qsub b0 X) (Qsub b0 Y)` cancels `b0` to `Qsub Y X`; abs equals `|Qsub X Y|` (ihb's).
    have hcancel : Qeq (Qsub (Qsub (b 0) (AltSum (fun i => b (i + 1)) (L + m)))
        (Qsub (b 0) (AltSum (fun i => b (i + 1)) L)))
        (Qsub (AltSum (fun i => b (i + 1)) L) (AltSum (fun i => b (i + 1)) (L + m))) := by
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
    have e1 := Qabs_Qeq hcancel
    rw [Qabs_Qsub_comm (AltSum (fun i => b (i + 1)) L) (AltSum (fun i => b (i + 1)) (L + m))] at e1
    exact Qle_congr_left
      (Qabs_den_pos (Qsub_den_pos (AltSum_den_pos (fun i => b (i + 1)) (fun i => hden (i + 1)) (L + m))
        (AltSum_den_pos (fun i => b (i + 1)) (fun i => hden (i + 1)) L)))
      (Qeq_symm e1) ihb

/-! ### ζ-approximant facts for the γ-terms -/

/-- `ζ`'s partial sums are antitone in the exponent (one step): `Σ 1/iˢ⁺¹ ≤ Σ 1/iˢ`. -/
theorem zetaSum_s_anti_step (s : Nat) : ∀ N, Qle (zetaSum (s + 1) N) (zetaSum s N)
  | 0 => by
      show Qle (⟨1, npow 1 (s + 1)⟩ : Q) ⟨1, npow 1 s⟩
      rw [npow_one, npow_one]; exact Qle_refl _
  | (N + 1) => by
      show Qle (add (zetaSum (s + 1) N) ⟨1, npow (N + 2) (s + 1)⟩)
        (add (zetaSum s N) ⟨1, npow (N + 2) s⟩)
      have hterm : Qle (⟨1, npow (N + 2) (s + 1)⟩ : Q) ⟨1, npow (N + 2) s⟩ := by
        show (1 : Int) * ((npow (N + 2) s : Nat) : Int) ≤ 1 * ((npow (N + 2) (s + 1) : Nat) : Int)
        have := npow_mono (i := N + 2) (by omega) (a := s) (b := s + 1) (by omega)
        have hc : ((npow (N + 2) s : Nat) : Int) ≤ ((npow (N + 2) (s + 1) : Nat) : Int) := by
          exact_mod_cast this
        omega
      exact Qadd_le_add (zetaSum_s_anti_step s N) hterm

/-- The partial sums are non-negative (sums of positive terms). -/
theorem zetaSum_num_nonneg (s : Nat) : ∀ N, 0 ≤ (zetaSum s N).num
  | 0 => by show (0 : Int) ≤ 1; decide
  | (N + 1) => by
      show 0 ≤ (add (zetaSum s N) ⟨1, npow (N + 2) s⟩).num
      simp only [add]
      have ih := zetaSum_num_nonneg s N
      have hpI : (0 : Int) ≤ ((npow (N + 2) s : Nat) : Int) := by exact_mod_cast Nat.zero_le _
      push_cast
      have hmul : 0 ≤ (zetaSum s N).num * ((npow (N + 2) s : Nat) : Int) :=
        Int.mul_nonneg ih hpI
      omega

/-- A uniform bound: every `ζ(s)` partial sum (`s ≥ 2`) is `≤ 2` — since `U(N) := S(N)+1/(N+1)` is
    decreasing with `U(0) = 1 + 1 = 2`. -/
theorem zetaSum_le_two (s : Nat) (hs : 2 ≤ s) (N : Nat) : Qle (zetaSum s N) (⟨2, 1⟩ : Q) := by
  have h1 : Qle (zetaSum s N) (zetaU s N) :=
    Qle_self_add (by show (0 : Int) ≤ 1; decide)
  have h2 : Qle (zetaU s N) (zetaU s 0) := zetaU_le s hs (Nat.zero_le N)
  have h3 : Qeq (zetaU s 0) (⟨2, 1⟩ : Q) := by
    show Qeq (add (⟨1, npow 1 s⟩ : Q) ⟨1, 1⟩) ⟨2, 1⟩
    rw [npow_one]; decide
  exact Qle_trans (zetaU_den_pos s N) h1
    (Qle_congr_right (zetaU_den_pos s 0) h3 h2)

/-- **Term-wise difference of two alternating sums** (same length, possibly different summands): if
    each term differs by at most `1/e`, the partial sums differ by at most `L/e`. -/
theorem altSum_diff_le (b c : Nat → Q) (e : Nat) (he : 0 < e) (hbd : ∀ i, 0 < (b i).den)
    (hcd : ∀ i, 0 < (c i).den) (hdiff : ∀ i, Qle (Qabs (Qsub (b i) (c i))) (⟨1, e⟩ : Q)) :
    ∀ L, Qle (Qabs (Qsub (AltSum b L) (AltSum c L))) (⟨(L : Int), e⟩ : Q) := by
  intro L
  induction L generalizing b c with
  | zero =>
    show Qle (Qabs (Qsub (⟨0, 1⟩ : Q) ⟨0, 1⟩)) (⟨(0 : Int), e⟩ : Q)
    have hx : (Qabs (Qsub (⟨0, 1⟩ : Q) ⟨0, 1⟩)).num = 0 := by decide
    unfold Qle; rw [hx]; simp
  | succ L ih =>
    have ihbc := ih (fun i => b (i + 1)) (fun i => c (i + 1)) (fun i => hbd (i + 1))
      (fun i => hcd (i + 1)) (fun i => hdiff (i + 1))
    rw [AltSum_succ, AltSum_succ]
    have hBpd : 0 < (AltSum (fun i => b (i + 1)) L).den :=
      AltSum_den_pos (fun i => b (i + 1)) (fun i => hbd (i + 1)) L
    have hCpd : 0 < (AltSum (fun i => c (i + 1)) L).den :=
      AltSum_den_pos (fun i => c (i + 1)) (fun i => hcd (i + 1)) L
    have htri := Qabs_sub_triangle
      (a := Qsub (b 0) (AltSum (fun i => b (i + 1)) L))
      (b := Qsub (c 0) (AltSum (fun i => b (i + 1)) L))
      (c := Qsub (c 0) (AltSum (fun i => c (i + 1)) L))
      (Qsub_den_pos (hbd 0) hBpd) (Qsub_den_pos (hcd 0) hBpd) (Qsub_den_pos (hcd 0) hCpd)
    -- term1 ≈ |b0 − c0| ≤ 1/e ;  term2 ≈ |Bp − Cp| ≤ L/e
    have hc1 : Qeq (Qsub (Qsub (b 0) (AltSum (fun i => b (i + 1)) L))
        (Qsub (c 0) (AltSum (fun i => b (i + 1)) L))) (Qsub (b 0) (c 0)) := by
      simp only [Qeq, Qsub, add, neg]; push_cast
      generalize (b 0).num = B; generalize (AltSum (fun i => b (i + 1)) L).num = P
      generalize (c 0).num = C; generalize ((b 0).den : Int) = bd
      generalize ((AltSum (fun i => b (i + 1)) L).den : Int) = pd
      generalize ((c 0).den : Int) = cd
      ring_uor
    have hc2 : Qeq (Qsub (Qsub (c 0) (AltSum (fun i => b (i + 1)) L))
        (Qsub (c 0) (AltSum (fun i => c (i + 1)) L)))
        (Qsub (AltSum (fun i => c (i + 1)) L) (AltSum (fun i => b (i + 1)) L)) := by
      simp only [Qeq, Qsub, add, neg]; push_cast
      generalize (c 0).num = C; generalize (AltSum (fun i => b (i + 1)) L).num = P
      generalize (AltSum (fun i => c (i + 1)) L).num = Qn; generalize ((c 0).den : Int) = cd
      generalize ((AltSum (fun i => b (i + 1)) L).den : Int) = pd
      generalize ((AltSum (fun i => c (i + 1)) L).den : Int) = qd
      ring_uor
    have ht1 : Qle (Qabs (Qsub (Qsub (b 0) (AltSum (fun i => b (i + 1)) L))
        (Qsub (c 0) (AltSum (fun i => b (i + 1)) L)))) (⟨1, e⟩ : Q) :=
      Qle_congr_left (Qabs_den_pos (Qsub_den_pos (hbd 0) (hcd 0)))
        (Qeq_symm (Qabs_Qeq hc1)) (hdiff 0)
    have ht2 : Qle (Qabs (Qsub (Qsub (c 0) (AltSum (fun i => b (i + 1)) L))
        (Qsub (c 0) (AltSum (fun i => c (i + 1)) L)))) (⟨(L : Int), e⟩ : Q) := by
      have key : Qeq (Qabs (Qsub (Qsub (c 0) (AltSum (fun i => b (i + 1)) L))
          (Qsub (c 0) (AltSum (fun i => c (i + 1)) L))))
          (Qabs (Qsub (AltSum (fun i => b (i + 1)) L) (AltSum (fun i => c (i + 1)) L))) := by
        rw [← Qabs_Qsub_comm (AltSum (fun i => c (i + 1)) L) (AltSum (fun i => b (i + 1)) L)]
        exact Qabs_Qeq hc2
      exact Qle_congr_left (Qabs_den_pos (Qsub_den_pos hBpd hCpd)) (Qeq_symm key) ihbc
    have hsum : Qeq (add (⟨1, e⟩ : Q) ⟨(L : Int), e⟩) (⟨((L + 1 : Nat) : Int), e⟩ : Q) := by
      simp only [Qeq, add]; push_cast
      generalize ((e : Nat) : Int) = E; generalize ((L : Nat) : Int) = Lc
      ring_uor
    refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (Qsub_den_pos (hbd 0) hBpd)
        (Qsub_den_pos (hcd 0) hBpd))) (Qabs_den_pos (Qsub_den_pos (Qsub_den_pos (hcd 0) hBpd)
        (Qsub_den_pos (hcd 0) hCpd)))) htri ?_
    exact Qle_trans (add_den_pos (show 0 < (⟨1, e⟩ : Q).den from he)
        (show 0 < (⟨(L : Int), e⟩ : Q).den from he))
      (Qadd_le_add ht1 ht2) (Qeq_le hsum)

/-! ### The γ-term `b(i) = ζ(i+2)/(i+2)` at ζ-approximation depth `D` -/

/-- The `i`-th alternating-series magnitude, `ζ(i+2)/(i+2)`, using the depth-`D` ζ-approximant. -/
def bterm (D i : Nat) : Q := mul (zetaSum (i + 2) D) ⟨1, i + 2⟩

theorem bterm_den_pos (D i : Nat) : 0 < (bterm D i).den :=
  Qmul_den_pos (zetaSum_den_pos (i + 2) D) (by show 0 < i + 2; omega)

theorem bterm_num_nonneg (D i : Nat) : 0 ≤ (bterm D i).num := by
  show 0 ≤ (mul (zetaSum (i + 2) D) ⟨1, i + 2⟩).num
  simp only [mul]
  have := zetaSum_num_nonneg (i + 2) D
  omega

/-- The γ-terms are antitone: `ζ(i+3)/(i+3) ≤ ζ(i+2)/(i+2)` (both factors shrink). -/
theorem bterm_anti (D i : Nat) : Qle (bterm D (i + 1)) (bterm D i) := by
  show Qle (mul (zetaSum (i + 3) D) ⟨1, i + 3⟩) (mul (zetaSum (i + 2) D) ⟨1, i + 2⟩)
  have hz : Qle (zetaSum (i + 3) D) (zetaSum (i + 2) D) := zetaSum_s_anti_step (i + 2) D
  have hf : Qle (⟨1, i + 3⟩ : Q) ⟨1, i + 2⟩ := by
    show (1 : Int) * ((i + 2 : Nat) : Int) ≤ 1 * ((i + 3 : Nat) : Int); push_cast; omega
  have h1 : Qle (mul (zetaSum (i + 3) D) ⟨1, i + 3⟩) (mul (zetaSum (i + 2) D) ⟨1, i + 3⟩) :=
    Qmul_le_mul_right (by show (0 : Int) ≤ 1; decide) hz
  have h2 : Qle (mul (zetaSum (i + 2) D) ⟨1, i + 3⟩) (mul (zetaSum (i + 2) D) ⟨1, i + 2⟩) :=
    Qmul_le_mul_left (zetaSum_num_nonneg (i + 2) D) hf
  exact Qle_trans (Qmul_den_pos (zetaSum_den_pos (i + 2) D) (by show 0 < i + 3; omega)) h1 h2

/-- Each γ-term is bounded by `2/(i+2)` (since `ζ ≤ 2`) — the truncation-tail estimate. -/
theorem bterm_le (D i : Nat) : Qle (bterm D i) (⟨2, i + 2⟩ : Q) := by
  show Qle (mul (zetaSum (i + 2) D) ⟨1, i + 2⟩) (⟨2, i + 2⟩ : Q)
  have hz : Qle (zetaSum (i + 2) D) (⟨2, 1⟩ : Q) := zetaSum_le_two (i + 2) (by omega) D
  have hstep : Qle (mul (zetaSum (i + 2) D) ⟨1, i + 2⟩) (mul (⟨2, 1⟩ : Q) ⟨1, i + 2⟩) :=
    Qmul_le_mul_right (by show (0 : Int) ≤ 1; decide) hz
  have heq : Qeq (mul (⟨2, 1⟩ : Q) ⟨1, i + 2⟩) ⟨2, i + 2⟩ := by
    simp only [Qeq, mul]; push_cast; ring_uor
  exact Qle_trans (Qmul_den_pos (by show 0 < (1 : Nat); decide) (by show 0 < i + 2; omega))
    hstep (Qeq_le heq)

/-- **Per-term depth bound**: deepening the ζ-approximant moves each γ-term by at most `1/(Dj+1)`
    (the smaller depth controls it; the `1/(i+2)` factor only helps). -/
theorem bterm_depth_diff (Dj Dk i : Nat) (hjk : Dj ≤ Dk) :
    Qle (Qabs (Qsub (bterm Dj i) (bterm Dk i))) (⟨1, Dj + 1⟩ : Q) := by
  show Qle (Qabs (Qsub (mul (zetaSum (i + 2) Dj) ⟨1, i + 2⟩)
    (mul (zetaSum (i + 2) Dk) ⟨1, i + 2⟩))) (⟨1, Dj + 1⟩ : Q)
  have hfac : Qeq (Qsub (mul (zetaSum (i + 2) Dj) ⟨1, i + 2⟩) (mul (zetaSum (i + 2) Dk) ⟨1, i + 2⟩))
      (mul (Qsub (zetaSum (i + 2) Dj) (zetaSum (i + 2) Dk)) ⟨1, i + 2⟩) :=
    Qeq_symm (Qmul_sub_right (zetaSum (i + 2) Dj) (zetaSum (i + 2) Dk) ⟨1, i + 2⟩)
  have hqc : Qabs (⟨1, i + 2⟩ : Q) = ⟨1, i + 2⟩ := rfl
  have heq : Qeq (Qabs (Qsub (mul (zetaSum (i + 2) Dj) ⟨1, i + 2⟩)
        (mul (zetaSum (i + 2) Dk) ⟨1, i + 2⟩)))
      (mul (Qabs (Qsub (zetaSum (i + 2) Dj) (zetaSum (i + 2) Dk))) ⟨1, i + 2⟩) := by
    have h := Qabs_Qeq hfac; rw [Qabs_mul, hqc] at h; exact h
  refine Qle_congr_left (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos (zetaSum_den_pos (i + 2) Dj)
      (zetaSum_den_pos (i + 2) Dk))) (by show 0 < i + 2; omega)) (Qeq_symm heq) ?_
  have step1 : Qle (Qabs (Qsub (zetaSum (i + 2) Dj) (zetaSum (i + 2) Dk))) (⟨1, Dj + 1⟩ : Q) := by
    rw [Qabs_Qsub_comm]; exact zetaabs_bound (i + 2) (by omega) hjk
  have step2 : Qle (mul (Qabs (Qsub (zetaSum (i + 2) Dj) (zetaSum (i + 2) Dk))) ⟨1, i + 2⟩)
      (mul (⟨1, Dj + 1⟩ : Q) ⟨1, i + 2⟩) := Qmul_le_mul_right (by show (0 : Int) ≤ 1; decide) step1
  have step3 : Qle (mul (⟨1, Dj + 1⟩ : Q) ⟨1, i + 2⟩) (⟨1, Dj + 1⟩ : Q) := by
    show Qle (⟨(1 : Int), (Dj + 1) * (i + 2)⟩ : Q) ⟨1, Dj + 1⟩
    refine Qfrac_le ?_
    have h : (Dj + 1) * 1 ≤ (Dj + 1) * (i + 2) := Nat.mul_le_mul (Nat.le_refl (Dj + 1)) (by omega)
    rw [Nat.mul_one] at h; rw [Nat.one_mul]; exact h
  exact Qle_trans (Qmul_den_pos (show 0 < Dj + 1 by omega) (by show 0 < i + 2; omega)) step2 step3

/-! ### The γ₀ diagonal -/

/-- Number of alternating terms at diagonal depth `j` (drives the truncation error `2/(N+2)`). -/
def gammaN (j : Nat) : Nat := 4 * (j + 1)

/-- ζ-approximation depth at diagonal depth `j` (drives the depth error `N/(D+1)`). -/
def gammaD (j : Nat) : Nat := 8 * (j + 1) * (j + 1)

/-- The `j`-th rational approximant of γ₀: the `gammaN j`-term Leibniz sum of the depth-`gammaD j`
    ζ-approximants of `(−1)ⁱ ζ(i+2)/(i+2)`. -/
def gammaSeq (j : Nat) : Q := AltSum (bterm (gammaD j)) (gammaN j)

theorem gammaSeq_den_pos (j : Nat) : 0 < (gammaSeq j).den :=
  AltSum_den_pos (bterm (gammaD j)) (bterm_den_pos (gammaD j)) (gammaN j)

/-- The one-sided regularity estimate `|γ(j) − γ(k)| ≤ 1/(j+1)` for `j ≤ k`: the depth error (≤
    `Nⱼ/(Dⱼ+1) ≤ 1/(2(j+1))`) plus the truncation error (≤ `2/(Nⱼ+2) ≤ 1/(2(j+1))`). -/
theorem gammaSeq_reg_le {j k : Nat} (hjk : j ≤ k) :
    Qle (Qabs (Qsub (gammaSeq j) (gammaSeq k))) (Qbound j) := by
  have hDmono : gammaD j ≤ gammaD k := by
    unfold gammaD
    exact Nat.mul_le_mul (Nat.mul_le_mul (Nat.le_refl 8) (by omega)) (by omega)
  -- triangle through the shared midpoint `AltSum (bterm Dk) Nj`
  have htri := Qabs_sub_triangle
    (a := AltSum (bterm (gammaD j)) (gammaN j))
    (b := AltSum (bterm (gammaD k)) (gammaN j))
    (c := AltSum (bterm (gammaD k)) (gammaN k))
    (AltSum_den_pos (bterm (gammaD j)) (bterm_den_pos (gammaD j)) (gammaN j))
    (AltSum_den_pos (bterm (gammaD k)) (bterm_den_pos (gammaD k)) (gammaN j))
    (AltSum_den_pos (bterm (gammaD k)) (bterm_den_pos (gammaD k)) (gammaN k))
  -- A: the depth error
  have hA : Qle (Qabs (Qsub (AltSum (bterm (gammaD j)) (gammaN j))
      (AltSum (bterm (gammaD k)) (gammaN j)))) (⟨(gammaN j : Int), gammaD j + 1⟩ : Q) :=
    altSum_diff_le (bterm (gammaD j)) (bterm (gammaD k)) (gammaD j + 1) (by omega)
      (bterm_den_pos (gammaD j)) (bterm_den_pos (gammaD k))
      (fun i => bterm_depth_diff (gammaD j) (gammaD k) i hDmono) (gammaN j)
  have hAbnd : Qle (⟨(gammaN j : Int), gammaD j + 1⟩ : Q) (⟨1, 2 * j + 2⟩ : Q) := by
    refine Qfrac_le (a := 2 * j + 1) ?_
    have e : gammaN j * (2 * j + 1 + 1) = gammaD j := by
      have hI : ((gammaN j * (2 * j + 1 + 1) : Nat) : Int) = ((gammaD j : Nat) : Int) := by
        unfold gammaN gammaD; push_cast; ring_uor
      exact_mod_cast hI
    rw [e]; omega
  -- B: the truncation error
  have hsplit : gammaN k = gammaN j + (gammaN k - gammaN j) := by unfold gammaN; omega
  have hB0 := altSum_gap (bterm (gammaD k)) (bterm_num_nonneg (gammaD k))
    (bterm_den_pos (gammaD k)) (bterm_anti (gammaD k)) (gammaN j) (gammaN k - gammaN j)
  rw [← hsplit] at hB0
  have hB : Qle (Qabs (Qsub (AltSum (bterm (gammaD k)) (gammaN j))
      (AltSum (bterm (gammaD k)) (gammaN k)))) (bterm (gammaD k) (gammaN j)) := by
    rw [Qabs_Qsub_comm]; exact hB0
  have hBbnd : Qle (⟨2, gammaN j + 2⟩ : Q) (⟨1, 2 * j + 2⟩ : Q) := by
    show (2 : Int) * ((2 * j + 2 : Nat) : Int) ≤ 1 * ((gammaN j + 2 : Nat) : Int)
    unfold gammaN; push_cast; omega
  have hsum : Qeq (add (⟨1, 2 * j + 2⟩ : Q) ⟨1, 2 * j + 2⟩) (Qbound j) := by
    simp only [Qeq, add, Qbound]; push_cast; ring_uor
  refine Qle_trans (add_den_pos
      (Qabs_den_pos (Qsub_den_pos (AltSum_den_pos (bterm (gammaD j)) (bterm_den_pos (gammaD j)) (gammaN j))
        (AltSum_den_pos (bterm (gammaD k)) (bterm_den_pos (gammaD k)) (gammaN j))))
      (Qabs_den_pos (Qsub_den_pos (AltSum_den_pos (bterm (gammaD k)) (bterm_den_pos (gammaD k)) (gammaN j))
        (AltSum_den_pos (bterm (gammaD k)) (bterm_den_pos (gammaD k)) (gammaN k))))) htri ?_
  refine Qle_trans (add_den_pos (by show 0 < 2 * j + 2; omega) (by show 0 < 2 * j + 2; omega))
    (Qadd_le_add
      (Qle_trans (show 0 < gammaD j + 1 by omega) hA hAbnd)
      (Qle_trans (bterm_den_pos (gammaD k) (gammaN j)) hB
        (Qle_trans (show 0 < gammaN j + 2 by omega) (bterm_le (gammaD k) (gammaN j)) hBbnd)))
    (Qeq_le hsum)

theorem gammaSeq_regular : IsRegular gammaSeq := by
  intro m n
  rcases Nat.le_total m n with h | h
  · exact Qle_trans (Qbound_den_pos m) (gammaSeq_reg_le h)
      (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · rw [Qabs_Qsub_comm]
    exact Qle_trans (Qbound_den_pos n) (gammaSeq_reg_le h)
      (Qle_add_self (by show (0 : Int) ≤ 1; decide))

/-- **The Euler–Mascheroni constant γ₀** as a constructive real, via the alternating series
    `Σ_{k≥2} (−1)ᵏ ζ(k)/k`, with the explicit Bishop modulus `1/(j+1)`. -/
def Rgamma0 : Real := ⟨gammaSeq, gammaSeq_regular, gammaSeq_den_pos⟩

end UOR.Bridge.F1Square.Analysis
