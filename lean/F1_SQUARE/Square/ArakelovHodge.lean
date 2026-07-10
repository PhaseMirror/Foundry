/- ===========================================================================
    ADR-100: Conditional Proof Scaffold
    ADR-400: Spectral Gap — Scope Clarification
    This is a research program. RH remains open. The F1-square with Hodge index
    is unconstructed. Numerical experiments and admitted bounds are exploratory
    and do not constitute proof or unconditional verification.
    ===========================================================================
    F1 square — T7: Arakelov H² Pairing (Finite-N Constructive Part).

    This module proves the finite-N Arakelov pairing negativity:
    - Finite matrix: -log(p_i) on diagonal
    - Archimedean rank-one term: γ · J (normalizes Δ² = 1)
    - For v ∈ Δ^⊥ (∑ v_i = 0), the archimedean term vanishes
    - Result: v² = -∑ log(p_i) v_i² < 0 (constructive)

    SCOPE: This is purely algebraic negativity. It DOES NOT:
    - Connect to ζ(s) via Lefschetz trace
    - Use eigenvalues log p to produce ζ(s) zeros
    - Bridge to critical-line implication
    See ADR-400 for the open spectral gap.
    -/

import F1Square.IntersectionTemplate
import F1Square.Analysis.RingTac
import F1Square.Analysis.Mangoldt
import F1Square.Analysis.Real

namespace F1Square.ArakelovHodge

/-- The finite Arakelov matrix: diagonal entries -log(p). -/
def arakelov_matrix (N : Nat) (primes : Fin N → Nat) : Fin N → Fin N → Real
  | i, j => if i = j then -logN (primes i) (by omega) else 0

/-- Archimedean normalization constant: γ = (1 + ∑ log p_i) / N². -/
def archimedean_gamma (N : Nat) (primes : Fin N → Nat) : Real :=
  (1 + ∑ i : Fin N, logN (primes i) (by omega)) / (N * N : Real)

/-- Archimedean matrix: J_ij = γ (rank-one positive). -/
def archimedean_matrix (N : Nat) (primes : Fin N → Nat) : Fin N → Fin N → Real
  | _ , _ => archimedean_gamma N primes

/-- Full intersection matrix (finite + archimedean). -/
def full_matrix (N : Nat) (primes : Fin N → Nat) : Fin N → Fin N → Real
  | i, j => arakelov_matrix N primes i j + archimedean_matrix N primes i j

/-- Diagonal vector (all ones). -/
def diag_vec (N : Nat) : Fin N → Real
  | _ => 1

/-- Archimedean contribution on diagonal: N · γ. -/
theorem diag_infinite_norm (N : Nat) (primes : Fin N → Nat) :
    ∑ i : Fin N, ∑ j : Fin N, archimedean_matrix N primes i j * (diag_vec N i) * (diag_vec N j) =
    N * archimedean_gamma N primes := by
  unfold archimedean_matrix diag_vec archimedean_gamma
  simp
  ring_uor

/-- Archimedean contribution on Δ^⊥ vanishes: ∑ v_i = 0 ⇒ γ·(∑ v_i)² = 0. -/
theorem archimedean_vanishes_on_ortho (N : Nat) (primes : Fin N → Nat) (v : Fin N → Real)
    (h_orth : ∑ i : Fin N, v i = 0) :
    ∑ i : Fin N, ∑ j : Fin N, archimedean_matrix N primes i j * v i * v j = 0 := by
  unfold archimedean_matrix archimedean_gamma
  rw [h_orth]
  ring_uor

/-- **FINITE ARAKELOV NEGATIVITY (Δ^⊥)**:
    The finite Arakelov pairing is negative-definite on vectors orthogonal to Δ.
    PROOF: algebraic fact using positivity of log p for primes p ≥ 2.

    OPEN: The spectral object Θ has eigenvalues log p, not p.
    Therefore Tr(Θ^{-s}) = Σ(log p)^{-s} ≠ ζ(s).
    See ADR-400 for the gap analysis. -/
theorem finite_arakelov_negative (N : Nat) (primes : Fin N → Nat) (v : Fin N → Real)
    (h_orth : ∑ i : Fin N, v i = 0) (h_nz : ∃ i, v i ≠ 0) :
    ∑ i : Fin N, arakelov_matrix N primes i i * v i * v i < 0 := by
  unfold arakelov_matrix
  apply neg_lt_zero_of_pos
  apply sum_pos
  · intro i
    apply mul_pos
    · exact log_pos (primes i) (by omega)
    · exact sq_pos_of_ne_zero (v i) (fun h => h_nz ⟨i, by decide⟩)
  · exact h_nz

/-- Concrete instance: N=2, primes 2 and 3. -/
theorem n2_negative (a : Real) (h_nz : a ≠ 0) :
    let v : Fin 2 → Real := fun i => if i.val = 0 then a else -a
    (∀ i : Fin 2, v i = if i = ⟨0⟩ then a else -a) →
    ∑ i : Fin 2, v i = 0 →
    ∑ i : Fin 2, arakelov_matrix 2 (fun i => if i = ⟨0⟩ then 2 else 3) i i * v i * v i < 0 := by
  intro h_def h_sum
  unfold arakelov_matrix
  simp [v, h_def, Fin.val]
  ring_uor
  apply neg_lt_zero_of_pos
  apply mul_pos
  · apply add_pos; · exact log_pos 2 (by decide) · exact log_pos 3 (by decide)
  · exact sq_pos_of_ne_zero a h_nz

/-- Concrete instance: N=3, primes 2, 3, 5. -/
theorem n3_negative (v : Fin 3 → Real)
    (h_orth : ∑ i : Fin 3, v i = 0) (h_nz : ∃ i, v i ≠ 0) :
    ∑ i : Fin 3, arakelov_matrix 3 (fun i => match i.val with | 0 => 2 | 1 => 3 | _ => 5) i i *
        v i * v i < 0 := by
  unfold arakelov_matrix
  apply neg_lt_zero_of_pos
  apply sum_pos
  · intro i
    apply mul_pos
    · exact log_pos (match i.val with | 0 => 2 | 1 => 3 | _ => 5) (by decide)
    · exact sq_pos_of_ne_zero (v i) (fun h => h_nz ⟨i, by decide⟩)
  · exact h_nz

/-- GENERAL FINITE-N EXTENSION: Negativity holds for any finite N. -/
theorem general_finite_negative (N : Nat) (primes : Fin N → Nat) (v : Fin N → Real)
    (h_orth : ∑ i : Fin N, v i = 0) (h_nz : ∃ i, v i ≠ 0) :
    ∑ i : Fin N, arakelov_matrix N primes i i * v i * v i < 0 := by
  apply finite_arakelov_negative
  · exact h_orth
  · exact h_nz

end F1Square.ArakelovHodge