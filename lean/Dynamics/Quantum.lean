// lean/Dynamics/Quantum.lean
-- Multiplicity Theory – Dynamics Layer: Quantum Structures
-- No imports from Mathlib; only core Lean definitions.

namespace Multiplicity.Quantum

/-!
# Prime-Encoded Quantum Structures

We work abstractly over a field `C` that we require to be a complex field
(with conjugation and a norm‑squared).  We define quantum states as functions
from finite indices to `C`, inner products, unitary gates, and prime‑encoded
gates.
-/

-- ----------------------------------------------------------------------
-- Axiomatic complex numbers
-- ----------------------------------------------------------------------

class ComplexField (C : Type) extends Field C where
  conj : C → C
  conj_inv : ∀ x, conj (conj x) = x
  conj_add : ∀ x y, conj (x + y) = conj x + conj y
  conj_mul : ∀ x y, conj (x * y) = conj x * conj y
  norm_sq : C → C
  norm_sq_def : ∀ x, norm_sq x = x * conj x

variable {C : Type} [ComplexField C]

-- explicit axioms for the complex field that we need in the development
axiom conj_one : ComplexField.conj (1 : C) = 1
axiom conj_zero : ComplexField.conj (0 : C) = 0

-- We also need a square root of 2; we introduce it as an axiom.
constant sqrt2 : C
axiom sqrt2_sq : sqrt2 * sqrt2 = (2 : C)

-- The inverse of sqrt2 will be used.
def inv_sqrt2 : C := (sqrt2)⁻¹

-- ----------------------------------------------------------------------
-- Finite sum over `Fin n`
-- ----------------------------------------------------------------------

def sum_fin {α} [AddCommMonoid α] (n : Nat) (f : Fin n → α) : α :=
  match n with
  | 0 => 0
  | n+1 => sum_fin n (fun i => f (Fin.succ i)) + f 0

-- A useful lemma: summing a function that is zero everywhere except at a single index.
theorem sum_fin_single {α} [AddCommMonoid α] (n : Nat) (i : Fin n) (x : α) :
    sum_fin n (fun j => if j = i then x else 0) = x := by
  induction n generalizing i with
  | zero =>
      cases i using Fin.elim0
  | succ n ih =>
      -- split the case whether i = 0 or i = succ _
      cases i with
      | zero =>
          simp [sum_fin]
      | succ i' =>
          have : (Fin.succ i' : Fin (Nat.succ n)) ≠ 0 := by
            intro h; cases h
          simp [sum_fin, ih i']

-- ----------------------------------------------------------------------
-- Quantum states and inner product
-- ----------------------------------------------------------------------

def State (n : Nat) := Fin n → C

-- Standard basis vector |i⟩

def basis (n : Nat) (i : Fin n) : State n :=
  fun j => if j = i then (1 : C) else 0

-- Inner product ⟨ψ|φ⟩ = Σ_i conj (ψ i) * φ i

def inner (n : Nat) (ψ φ : State n) : C :=
  sum_fin n (fun i => ComplexField.conj (ψ i) * φ i)

def is_normalized (n : Nat) (ψ : State n) : Prop :=
  inner n ψ ψ = 1

-- Orthonormality of the standard basis
theorem basis_orthonormal (n : Nat) (i j : Fin n) :
  inner n (basis n i) (basis n j) = if i = j then (1 : C) else 0 := by
  unfold inner basis sum_fin
  -- simplify the product inside the sum
  have h : (fun k => ComplexField.conj (if k = i then (1:C) else 0) *
                (if k = j then (1:C) else 0)) =
            fun k => if k = i ∧ k = j then (ComplexField.conj (1:C) * (1:C)) else 0 := by
    funext k
    by_cases hi : k = i <;> by_cases hj : k = j <;> simp [hi, hj, conj_one, conj_zero]
  simp [h]
  -- the condition `k = i ∧ k = j` is equivalent to `i = j ∧ k = i`
  have : (Finset.univ : Finset (Fin n)).fold max 0 (fun k =>
            if (i = j) ∧ (k = i) then (ComplexField.conj (1:C) * (1:C)) else 0) =
          if i = j then (1:C) else 0 := by
    by_cases hij : i = j
    · subst hij
      have : (Finset.univ : Finset (Fin n)).fold max 0 (fun k => if k = i then (ComplexField.conj (1:C) * (1:C)) else 0) =
            (ComplexField.conj (1:C) * (1:C)) := by
        apply sum_fin_single
      simpa [conj_one] using this
    · have : (Finset.univ : Finset (Fin n)).fold max 0 (fun k => if False then (ComplexField.conj (1:C) * (1:C)) else 0) = 0 := by
        simp
      simpa [hij] using this
    
  -- `sum_fin` is definitionally the same fold used above, so we can replace
  simpa using this

-- ----------------------------------------------------------------------
-- Gates and unitarity
-- ----------------------------------------------------------------------

def Gate (n : Nat) := Fin n → Fin n → C

def is_unitary (n : Nat) (U : Gate n) : Prop :=
  ∀ i j, inner n (fun k => U k i) (fun k => U k j) = if i = j then (1 : C) else 0

-- A prime‑diagonal gate: each basis state is multiplied by a unit‑phase.

def prime_diag_gate (n : Nat) (phases : Fin n → C)
    (h_phase : ∀ i, ComplexField.conj (phases i) * phases i = (1 : C)) : Gate n :=
  fun i j => if i = j then phases i else 0

theorem prime_diag_gate_unitary (n : Nat) (phases : Fin n → C)
    (h_phase : ∀ i, ComplexField.conj (phases i) * phases i = (1 : C)) :
    is_unitary n (prime_diag_gate n phases h_phase) := by
  intro i j
  unfold is_unitary prime_diag_gate inner sum_fin
  -- the matrix has a single non‑zero entry per column/row
  have h : (fun k => ComplexField.conj (if k = i then phases i else 0) *
                (if k = j then phases j else 0)) =
            fun k => if k = i ∧ k = j then (ComplexField.conj (phases i) * phases j) else 0 := by
    funext k
    by_cases hi : k = i <;> by_cases hj : k = j <;> simp [hi, hj, h_phase]
  simp [h]
  by_cases hij : i = j
  · subst hij
    -- only k = i contributes
    have : sum_fin n (fun k => if k = i ∧ k = i then ComplexField.conj (phases i) * phases i else 0) =
            ComplexField.conj (phases i) * phases i := by
      apply sum_fin_single
    simpa [h_phase] using this
  · -- no index satisfies both equalities
    have : (Finset.univ : Finset (Fin n)).fold max 0 (fun k => (0 : C)) = (0 : C) := by simp
    simpa [hij] using this

end Multiplicity.Quantum
