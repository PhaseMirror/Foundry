/-
F1 square — Track 1, item 3 substrate: **`genSum` distribution over a constant factor** and the
**finite geometric sum bound** `Σ_{m<N} 2^{-m} ≤ 2`. Both feed the theta decay estimate
`ψ(t) ≤ 2·e^{-πt}`: the terms `e^{-(m+1)²πt}` are dominated by `e^{-πt}·2^{-m}` (consecutive ratio
`< ½`), so the partial sums are `≤ e^{-πt}·Σ2^{-m} ≤ 2·e^{-πt}`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ImproperIntegral

namespace UOR.Bridge.F1Square.Analysis

/-- **`genSum` distributes over a constant left factor**: `Σ_{m<N} c·g(m) = c·Σ_{m<N} g(m)`. -/
theorem genSum_Rmul_const (c : Real) (g : Nat → Real) :
    ∀ N, Req (genSum (fun m => Rmul c (g m)) N) (Rmul c (genSum g N))
  | 0 => Req_symm (Rmul_zero c)
  | (N + 1) => by
    show Req (Radd (genSum (fun m => Rmul c (g m)) N) (Rmul c (g N))) (Rmul c (Radd (genSum g N) (g N)))
    exact Req_trans (Radd_congr (genSum_Rmul_const c g N) (Req_refl _))
      (Req_symm (Rmul_distrib c (genSum g N) (g N)))

/-- **The geometric partial sum** `Σ_{m<N} 2^{-m} = 2 − 2^{1−N}` (in the form `(2^{N+1}−2)/2^N`). -/
theorem genSum_geom_eq : ∀ N : Nat,
    Req (genSum (fun m => ofQ (⟨1, 2 ^ m⟩ : Q) Nat.one_le_two_pow) N)
        (ofQ (⟨(2 : Int) ^ (N + 1) - 2, 2 ^ N⟩ : Q) Nat.one_le_two_pow)
  | 0 => Req_of_seq_Qeq (fun n => by
      show Qeq (⟨0, 1⟩ : Q) (⟨(2 : Int) ^ (0 + 1) - 2, 2 ^ 0⟩ : Q); decide)
  | (N + 1) => by
    show Req (Radd (genSum (fun m => ofQ (⟨1, 2 ^ m⟩ : Q) Nat.one_le_two_pow) N)
        (ofQ (⟨1, 2 ^ N⟩ : Q) Nat.one_le_two_pow))
      (ofQ (⟨(2 : Int) ^ (N + 1 + 1) - 2, 2 ^ (N + 1)⟩ : Q) Nat.one_le_two_pow)
    refine Req_trans (Radd_congr (genSum_geom_eq N) (Req_refl _)) ?_
    refine Req_trans (Radd_ofQ_ofQ Nat.one_le_two_pow Nat.one_le_two_pow) ?_
    refine ofQ_congr _ Nat.one_le_two_pow ?_
    show Qeq (add (⟨(2 : Int) ^ (N + 1) - 2, 2 ^ N⟩ : Q) (⟨1, 2 ^ N⟩ : Q))
      (⟨(2 : Int) ^ (N + 1 + 1) - 2, 2 ^ (N + 1)⟩ : Q)
    have hI1 : (2 : Int) ^ (N + 1) = 2 * (2 : Int) ^ N := by
      have h : (2 : Nat) ^ (N + 1) = 2 ^ N * 2 := by rw [Nat.pow_succ]
      have h2 : ((2 ^ (N + 1) : Nat) : Int) = ((2 ^ N * 2 : Nat) : Int) := by rw [h]
      push_cast at h2; push_cast; omega
    have hI2 : (2 : Int) ^ (N + 1 + 1) = 2 * (2 : Int) ^ (N + 1) := by
      have h : (2 : Nat) ^ (N + 1 + 1) = 2 ^ (N + 1) * 2 := by rw [Nat.pow_succ]
      have h2 : ((2 ^ (N + 1 + 1) : Nat) : Int) = ((2 ^ (N + 1) * 2 : Nat) : Int) := by rw [h]
      push_cast at h2; push_cast; omega
    have hN1 : ((2 ^ (N + 1) : Nat) : Int) = 2 * ((2 ^ N : Nat) : Int) := by
      have h : (2 : Nat) ^ (N + 1) = 2 ^ N * 2 := by rw [Nat.pow_succ]
      have h2 : ((2 ^ (N + 1) : Nat) : Int) = ((2 ^ N * 2 : Nat) : Int) := by rw [h]
      push_cast at h2; omega
    simp only [Qeq, add]
    rw [hI2, hI1, hN1]
    push_cast
    have hpoly : ∀ a : Int, ((2 * a - 2) * a + 1 * a) * (2 * a) = (2 * (2 * a) - 2) * (a * a) :=
      fun a => by ring_uor
    exact hpoly ((2 : Int) ^ N)

/-- **`Σ_{m<N} 2^{-m} ≤ 2`.** -/
theorem genSum_geom_le (N : Nat) :
    Rle (genSum (fun m => ofQ (⟨1, 2 ^ m⟩ : Q) Nat.one_le_two_pow) N)
      (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
  Rle_trans (Rle_of_Req (genSum_geom_eq N))
    (Rle_ofQ_ofQ Nat.one_le_two_pow (by decide) (by
      have hI1 : (2 : Int) ^ (N + 1) = 2 * (2 : Int) ^ N := by
        have h : (2 : Nat) ^ (N + 1) = 2 ^ N * 2 := by rw [Nat.pow_succ]
        have h2 : ((2 ^ (N + 1) : Nat) : Int) = ((2 ^ N * 2 : Nat) : Int) := by rw [h]
        push_cast at h2; push_cast; omega
      have hN1 : ((2 ^ N : Nat) : Int) ≥ 1 := by
        have : 1 ≤ 2 ^ N := Nat.one_le_two_pow; exact_mod_cast this
      simp only [Qle]; rw [hI1]; push_cast; omega))

end UOR.Bridge.F1Square.Analysis
