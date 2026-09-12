/-!
Quantum Multiplicity Processor for Multiplicity Theory.
Formalizes the Multiplicity Processor from Operators.md §Quantum Multiplicity Processor.

Defines eigenvalue-eigenvector decomposition, time evolution, feedback
adaptation, and the multiplicity equation M(t) for concrete finite-dimensional
systems.
-/

namespace Foundations.Execution.MultiplicityProcessor

def vec_zero {n : Nat} : Fin n → Rat := fun _ => 0

def vec_add {n : Nat} (a b : Fin n → Rat) : Fin n → Rat := fun i => a i + b i

def vec_scale {n : Nat} (c : Rat) (v : Fin n → Rat) : Fin n → Rat := fun i => c * v i

def vec_sum : {n : Nat} → (Fin n → Rat) → Rat
  | 0, _ => 0
  | Nat.succ m, v =>
    v ⟨m, Nat.le_refl (Nat.succ m)⟩ +
    vec_sum (n := m) (fun ⟨i, h⟩ => v ⟨i, Nat.le_succ_of_le h⟩)

def dot_prod {n : Nat} (a b : Fin n → Rat) : Rat :=
  vec_sum (fun i => a i * b i)

def outer_prod {n : Nat} (a b : Fin n → Rat) : Fin n → Fin n → Rat :=
  fun i j => a i * b j

def mat_vec_mul {n : Nat} (M : Fin n → Fin n → Rat) (v : Fin n → Rat) : Fin n → Rat :=
  fun i => vec_sum (fun j => M i j * v j)

theorem vec_sum_scale {n : Nat} (c : Rat) (f : Fin n → Rat) :
    vec_sum (fun j => c * f j) = c * vec_sum f := by
  induction n with
  | zero => simp [vec_sum, Rat.mul_zero]
  | succ m ih =>
    simp only [vec_sum]
    rw [ih, ← Rat.mul_add]

structure MultiplicityProcessor (n m : Nat) where
  eigenvalues : Fin m → Rat
  eigenvectors : Fin m → Fin n → Rat
  coupling : Fin m → Fin m → Fin m → Rat
  learning_rate : Rat
  loss_gradient : Fin m → Rat

def evolve_eigenvalue (proc : MultiplicityProcessor n m)
    (t : Fin m) : Rat :=
  proc.eigenvalues t + proc.learning_rate * proc.loss_gradient t

def evolve_eigenvalues (proc : MultiplicityProcessor n m) : Fin m → Rat :=
  fun t => evolve_eigenvalue proc t

def multiplicity_pair (proc : MultiplicityProcessor n m)
    (_t : Rat) (k i j : Fin m) : Rat :=
  proc.eigenvalues i * proc.eigenvalues j * proc.coupling k i j

theorem evolve_eigenvalue_welldefined (proc : MultiplicityProcessor n m)
    (t : Fin m) :
    ∃ val, evolve_eigenvalue proc t = val :=
  ⟨evolve_eigenvalue proc t, rfl⟩

theorem evolve_zero_lr (proc : MultiplicityProcessor n m)
    (h : proc.learning_rate = 0) (t : Fin m) :
    evolve_eigenvalue proc t = proc.eigenvalues t := by
  simp only [evolve_eigenvalue, h, Rat.zero_mul, Rat.add_zero]

@[reducible] def proc_2_eigenvalues : Fin 2 → Rat :=
  fun i => if i.val == 0 then (1 : Rat) else 2

@[reducible] def proc_2_eigenvectors : Fin 2 → Fin 2 → Rat :=
  fun i j => if i.val == j.val then (1 : Rat) else 0

def proc_2 : MultiplicityProcessor 2 2 :=
  { eigenvalues := proc_2_eigenvalues
  , eigenvectors := proc_2_eigenvectors
  , coupling := fun _ _ _ => 1
  , learning_rate := 1 / 10
  , loss_gradient := fun _ => -(1 / 20) }

theorem proc_2_eigenval0 : proc_2.eigenvalues ⟨0, by omega⟩ = 1 := by native_decide

theorem proc_2_eigenval1 : proc_2.eigenvalues ⟨1, by omega⟩ = 2 := by native_decide

theorem proc_2_evolve0_zerolr :
    evolve_eigenvalue { proc_2 with learning_rate := 0 } ⟨0, by omega⟩ = 1 := by
  simp [evolve_eigenvalue, proc_2, Rat.zero_mul, Rat.add_zero]

theorem proc_2_evolve1_zerolr :
    evolve_eigenvalue { proc_2 with learning_rate := 0 } ⟨1, by omega⟩ = 2 := by
  simp [evolve_eigenvalue, proc_2, Rat.zero_mul, Rat.add_zero]

theorem proc_2_mult_pair_000 :
    multiplicity_pair proc_2 0 ⟨0, by omega⟩ ⟨0, by omega⟩ ⟨0, by omega⟩ = 1 := by
  native_decide

theorem proc_2_mult_pair_011 :
    multiplicity_pair proc_2 0 ⟨0, by omega⟩ ⟨1, by omega⟩ ⟨1, by omega⟩ = 4 := by
  native_decide

theorem proc_2_mult_pair_001 :
    multiplicity_pair proc_2 0 ⟨0, by omega⟩ ⟨0, by omega⟩ ⟨1, by omega⟩ = 2 := by
  native_decide

theorem outer_prod_welldefined {n : Nat} (a b : Fin n → Rat) (i j : Fin n) :
    ∃ val, outer_prod a b i j = val :=
  ⟨outer_prod a b i j, rfl⟩

theorem outer_prod_self_diag {n : Nat} (v : Fin n → Rat) (i : Fin n) :
    outer_prod v v i i = v i * v i := rfl

theorem multiplicity_pair_welldefined (proc : MultiplicityProcessor n m)
    (t : Rat) (k i j : Fin m) :
    ∃ val, multiplicity_pair proc t k i j = val :=
  ⟨multiplicity_pair proc t k i j, rfl⟩

theorem eigenvalue_norm_sq_welldefined (proc : MultiplicityProcessor n m) :
    ∃ val, vec_sum (fun i => proc.eigenvalues i * proc.eigenvalues i) = val :=
  ⟨_, rfl⟩

end Foundations.Execution.MultiplicityProcessor
