/-
F1 square — analytic substrate: the **Bishop comparison** (constructive approximate dichotomy).

For rationals `q₁ < q₂` and any constructive real `x`, *either* `x ≤ q₂` *or* `q₁ ≤ x` — a genuine
disjunction (`Or`), decided by examining one approximant `x.seq N` at an index `N` fine enough that the
regulator gap is below `(q₂−q₁)/2`. The decision `2·x.seq N ≤ q₁+q₂ ?` is a *rational* comparison
(`Qle_or_Qlt`, decidable), so no classical choice enters; the `Or` is constructed, not postulated.

This is the missing primitive for every **regime-split** real estimate (e.g. a global Lipschitz bound
glued from a near-origin estimate and a far-field one): without it, a real `≤` cannot be case-split.
The fiddly part is the rational arithmetic with a *variable* approximant `x.seq N`; the factor-2 book-
keeping is kept linear by representing doubling as `mul ⟨2,1⟩ ·` (whose `2` cancels under `omega`),
never `add a a` (whose denominator squares).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ROrder

namespace UOR.Bridge.F1Square.Analysis

/-- Doubling (as `mul ⟨2,1⟩`) distributes over `add`. -/
private theorem Qdbl_add (a b : Q) :
    Qeq (mul (⟨2, 1⟩ : Q) (add a b)) (add (mul (⟨2, 1⟩ : Q) a) (mul (⟨2, 1⟩ : Q) b)) := by
  simp only [Qeq, mul, add]; push_cast; ring_uor

/-- The factor `2` cancels: `2·a ≤ 2·b ⟹ a ≤ b`. -/
private theorem Qle_of_dbl_le {a b : Q} (h : Qle (mul (⟨2, 1⟩ : Q) a) (mul (⟨2, 1⟩ : Q) b)) :
    Qle a b := by
  show a.num * (b.den : Int) ≤ b.num * (a.den : Int)
  have hh : (2 * a.num) * ((1 * b.den : Nat) : Int) ≤ (2 * b.num) * ((1 * a.den : Nat) : Int) := h
  have e1 : (2 * a.num) * ((1 * b.den : Nat) : Int) = 2 * (a.num * (b.den : Int)) := by
    push_cast; ring_uor
  have e2 : (2 * b.num) * ((1 * a.den : Nat) : Int) = 2 * (b.num * (a.den : Int)) := by
    push_cast; ring_uor
  rw [e1, e2] at hh; omega

/-- `2·q₂ = (q₁+q₂) + (q₂−q₁)`. -/
private theorem Qdbl_q2 (q1 q2 : Q) :
    Qeq (mul (⟨2, 1⟩ : Q) q2) (add (add q1 q2) (Qsub q2 q1)) := by
  simp only [Qeq, mul, add, Qsub, neg]; push_cast; ring_uor

/-- **Additive cancellation** on the right: `a + c ≤ b + c ⟹ a ≤ b` (any positive `c.den`). -/
private theorem Qadd_le_cancel_right {a b c : Q} (hc : 0 < c.den)
    (h : Qle (add a c) (add b c)) : Qle a b := by
  have hcI : (0 : Int) < (c.den : Int) := by exact_mod_cast hc
  have hcc : (0 : Int) < (c.den : Int) * (c.den : Int) := Int.mul_pos hcI hcI
  refine Int.le_of_mul_le_mul_right ?_ hcc
  unfold Qle add at h
  push_cast at h
  show a.num * (b.den : Int) * ((c.den : Int) * (c.den : Int))
     ≤ b.num * (a.den : Int) * ((c.den : Int) * (c.den : Int))
  have eL : a.num * (b.den : Int) * ((c.den : Int) * (c.den : Int))
      = (a.num * (c.den : Int) + c.num * (a.den : Int)) * ((b.den : Int) * (c.den : Int))
        - c.num * (a.den : Int) * ((b.den : Int) * (c.den : Int)) := by ring_uor
  have eR : b.num * (a.den : Int) * ((c.den : Int) * (c.den : Int))
      = (b.num * (c.den : Int) + c.num * (b.den : Int)) * ((a.den : Int) * (c.den : Int))
        - c.num * (b.den : Int) * ((a.den : Int) * (c.den : Int)) := by ring_uor
  have hcross : c.num * (a.den : Int) * ((b.den : Int) * (c.den : Int))
      = c.num * (b.den : Int) * ((a.den : Int) * (c.den : Int)) := by ring_uor
  rw [eL, eR]; omega

/-- The chosen index `N = 2·den(q₂−q₁)` makes `2·Qbound N ≤ q₂−q₁`. -/
private theorem cmp_gap (q1 q2 : Q) (hdn : 0 < (Qsub q2 q1).num) :
    Qle (mul (⟨2, 1⟩ : Q) (Qbound (2 * (Qsub q2 q1).den))) (Qsub q2 q1) := by
  show (2 * 1 : Int) * ((Qsub q2 q1).den : Int)
     ≤ (Qsub q2 q1).num * ((1 * (2 * (Qsub q2 q1).den + 1) : Nat) : Int)
  have hdd : (0 : Int) ≤ ((Qsub q2 q1).den : Int) := Int.ofNat_nonneg _
  have h1 : (1 : Int) ≤ (Qsub q2 q1).num := hdn
  have hmul : ((Qsub q2 q1).den : Int) ≤ (Qsub q2 q1).num * ((Qsub q2 q1).den : Int) := by
    have hm := Int.mul_le_mul_of_nonneg_right h1 hdd
    omega
  have hexp : (Qsub q2 q1).num * ((1 * (2 * (Qsub q2 q1).den + 1) : Nat) : Int)
      = 2 * ((Qsub q2 q1).num * ((Qsub q2 q1).den : Int)) + (Qsub q2 q1).num := by
    push_cast; ring_uor
  rw [hexp]; omega

/-- **The Bishop comparison**: for `q₁ < q₂` and any real `x`, *either* `x ≤ q₂` *or* `q₁ ≤ x`. -/
theorem Rle_or_Rle {x : Real} {q1 q2 : Q} (hq1 : 0 < q1.den) (hq2 : 0 < q2.den)
    (hlt : Qlt q1 q2) :
    Rle x (ofQ q2 hq2) ∨ Rle (ofQ q1 hq1) x := by
  have hdn : 0 < (Qsub q2 q1).num := by
    have he : (Qsub q2 q1).num = q2.num * (q1.den : Int) - q1.num * (q2.den : Int) := by
      simp only [Qsub, add, neg]; push_cast; ring_uor
    have hl : q1.num * (q2.den : Int) < q2.num * (q1.den : Int) := hlt
    rw [he]; omega
  let N : Nat := 2 * (Qsub q2 q1).den
  have hN : Qle (mul (⟨2, 1⟩ : Q) (Qbound N)) (Qsub q2 q1) := cmp_gap q1 q2 hdn
  rcases Qle_or_Qlt (mul (⟨2, 1⟩ : Q) (x.seq N)) (add q1 q2) with hL | hR
  · -- left branch: `x ≤ q₂`
    left
    have hcore : Qle (add (x.seq N) (Qbound N)) q2 := by
      have hsum := Qadd_le_add hL hN
      have hQ : Qeq (add (add q1 q2) (Qsub q2 q1)) (mul (⟨2, 1⟩ : Q) q2) :=
        Qeq_symm (Qdbl_q2 q1 q2)
      refine Qle_of_dbl_le ?_
      refine Qle_trans (add_den_pos (Qmul_den_pos (by decide) (x.den_pos N))
          (Qmul_den_pos (by decide) (Qbound_den_pos N))) (Qeq_le (Qdbl_add (x.seq N) (Qbound N))) ?_
      exact Qle_trans (add_den_pos (add_den_pos hq1 hq2) (Qsub_den_pos hq2 hq1)) hsum (Qeq_le hQ)
    intro n
    show Qle (x.seq n) (add q2 (⟨2, n + 1⟩ : Q))
    have hreg : Qle (x.seq n) (add (x.seq N) (add (Qbound n) (Qbound N))) :=
      Qle_add_of_Qabs_sub (x.den_pos n) (x.den_pos N)
        (add_den_pos (Qbound_den_pos n) (Qbound_den_pos N)) (x.reg n N)
    refine Qle_trans (add_den_pos (x.den_pos N)
      (add_den_pos (Qbound_den_pos n) (Qbound_den_pos N))) hreg ?_
    have hassoc : Qeq (add (x.seq N) (add (Qbound n) (Qbound N)))
        (add (add (x.seq N) (Qbound N)) (Qbound n)) := by
      simp only [Qeq, add, Qbound]; push_cast; ring_uor
    refine Qle_trans (add_den_pos (add_den_pos (x.den_pos N) (Qbound_den_pos N))
        (Qbound_den_pos n)) (Qeq_le hassoc) ?_
    refine Qle_trans (add_den_pos hq2 (Qbound_den_pos n))
      (Qadd_le_add hcore (Qle_refl (Qbound n))) ?_
    exact Qadd_le_add (Qle_refl q2)
      (by show Qle (⟨1, n + 1⟩ : Q) (⟨2, n + 1⟩ : Q); unfold Qle; push_cast; omega)
  · -- right branch: `q₁ ≤ x`
    right
    have hRle : Qle (add q1 q2) (mul (⟨2, 1⟩ : Q) (x.seq N)) := by
      simp only [Qle, Qlt] at hR ⊢; omega
    have hcore : Qle (add q1 (Qbound N)) (x.seq N) := by
      have hq2' : Qle (add q1 (mul (⟨2, 1⟩ : Q) (Qbound N))) q2 :=
        Qle_trans (add_den_pos hq1 (Qsub_den_pos hq2 hq1)) (Qadd_le_add (Qle_refl q1) hN)
          (Qeq_le (by show Qeq (add q1 (Qsub q2 q1)) q2
                      simp only [Qeq, add, Qsub, neg]; push_cast; ring_uor))
      have hsum : Qle (add q1 (add q1 (mul (⟨2, 1⟩ : Q) (Qbound N)))) (mul (⟨2, 1⟩ : Q) (x.seq N)) :=
        Qle_trans (add_den_pos hq1 hq2) (Qadd_le_add (Qle_refl q1) hq2') hRle
      refine Qle_of_dbl_le ?_
      refine Qle_trans (add_den_pos hq1 (add_den_pos hq1
          (Qmul_den_pos (by decide) (Qbound_den_pos N))))
        (Qeq_le (by
          show Qeq (mul (⟨2, 1⟩ : Q) (add q1 (Qbound N)))
            (add q1 (add q1 (mul (⟨2, 1⟩ : Q) (Qbound N))))
          simp only [Qeq, add, mul, Qbound]; push_cast; ring_uor)) hsum
    intro n
    show Qle q1 (add (x.seq n) (⟨2, n + 1⟩ : Q))
    have hreg : Qle (x.seq N) (add (x.seq n) (add (Qbound N) (Qbound n))) :=
      Qle_add_of_Qabs_sub (x.den_pos N) (x.den_pos n)
        (add_den_pos (Qbound_den_pos N) (Qbound_den_pos n)) (x.reg N n)
    have hchain : Qle (add q1 (Qbound N)) (add (add (x.seq n) (Qbound n)) (Qbound N)) :=
      Qle_trans (x.den_pos N) hcore
        (Qle_trans (add_den_pos (x.den_pos n) (add_den_pos (Qbound_den_pos N) (Qbound_den_pos n)))
          hreg
          (Qeq_le (by
            show Qeq (add (x.seq n) (add (Qbound N) (Qbound n)))
              (add (add (x.seq n) (Qbound n)) (Qbound N))
            simp only [Qeq, add, Qbound]; push_cast; ring_uor)))
    have hdrop : Qle q1 (add (x.seq n) (Qbound n)) :=
      Qadd_le_cancel_right (Qbound_den_pos N) hchain
    refine Qle_trans (add_den_pos (x.den_pos n) (Qbound_den_pos n)) hdrop ?_
    exact Qadd_le_add (Qle_refl (x.seq n))
      (by show Qle (⟨1, n + 1⟩ : Q) (⟨2, n + 1⟩ : Q); unfold Qle; push_cast; omega)

end UOR.Bridge.F1Square.Analysis
