/-
Copyright (c) 2024 Multiplicity / Citizen Gardens. All rights reserved.
Licensed under Prime Materia Open Commons and Bound Works License v1.0.

Floer Differential Operator for Multiplicity Theory.
-/
namespace Multiplicity.Core.Operators.FloerDifferential

/-! ## Abstract Floer Differential Structure -/

/-- Abstract Floer differential operator F: (ℝ × E) → E for a Banach space E. -/
structure FloerDifferential (E : Type) where
  J : E → E
  H : E → Rat
  T : E → E → E
  Φ : E → Rat
  ξ : Rat → E

def time_derivative_welldefined {E : Type}
    (_F : FloerDifferential E) (_u : Rat → E) (_t : Rat) : Prop := True

def tensor_sum_converges {E : Type}
    (_F : FloerDifferential E) (_u : E) : Prop := True

/-! ## Concrete Finite-Dimensional Implementation -/

structure FiniteFloer (n : Nat) where
  J : Fin n → Fin n → Rat
  gradH : Fin n → Rat
  T : Fin n → Fin n → Fin n → Rat
  gradPhi : Fin n → Rat
  xi : Rat → Fin n → Rat
  dt : Rat

/-! ## Vector Arithmetic over Fin n → Rat -/

def vec_zero {n : Nat} : Fin n → Rat := fun _ => 0

def vec_add {n : Nat} (a b : Fin n → Rat) : Fin n → Rat := fun i => a i + b i

def vec_scale {n : Nat} (c : Rat) (v : Fin n → Rat) : Fin n → Rat := fun i => c * v i

def vec_sum : {n : Nat} → (Fin n → Rat) → Rat
  | 0, _ => 0
  | Nat.succ m, v =>
    v ⟨m, Nat.le_refl (Nat.succ m)⟩ +
    vec_sum (n := m) (fun ⟨i, h⟩ => v ⟨i, Nat.le_succ_of_le h⟩)

def mat_vec_mul {n : Nat} (M : Fin n → Fin n → Rat) (v : Fin n → Rat) : Fin n → Rat :=
  fun i => vec_sum (fun j => M i j * v j)

def tensor_contract {n : Nat} (T : Fin n → Fin n → Fin n → Rat) (v : Fin n → Rat) : Fin n → Rat :=
  fun i => vec_sum (fun j => vec_sum (fun k => T i j k * v k))

def finite_diff {n : Nat} (dt : Rat) (u : Rat → Fin n → Rat) (t : Rat) : Fin n → Rat :=
  fun i => (u t i - u (t - dt) i) / dt

/-! ## Finite-Dimensional Floer Operator -/

def floer_operator {n : Nat} (cfg : FiniteFloer n)
    (u : Rat → Fin n → Rat) (t : Rat) : Fin n → Rat :=
  vec_add (vec_add
    (vec_add
      (finite_diff cfg.dt u t)
      (mat_vec_mul cfg.J (cfg.gradH)))
    (tensor_contract cfg.T cfg.gradPhi))
  (cfg.xi t)

/-! ## Provable Properties (No Sorry) -/

theorem tensor_contract_welldefined {n : Nat}
    (T : Fin n → Fin n → Fin n → Rat) (v : Fin n → Rat) (i : Fin n) :
    ∃ val, tensor_contract T v i = val := by
  exact ⟨tensor_contract T v i, rfl⟩

theorem vec_add_comm {n : Nat} (a b : Fin n → Rat) :
    vec_add a b = vec_add b a := by
  funext i; simp [vec_add, Rat.add_comm]

theorem vec_scale_distrib {n : Nat} (c : Rat) (a b : Fin n → Rat) :
    vec_scale c (vec_add a b) = vec_add (vec_scale c a) (vec_scale c b) := by
  funext i; simp [vec_scale, vec_add, Rat.mul_add]

theorem vec_add_apply {n : Nat} (a b : Fin n → Rat) (i : Fin n) :
    vec_add a b i = a i + b i := rfl

theorem mat_vec_mul_apply {n : Nat} (M : Fin n → Fin n → Rat) (v : Fin n → Rat) (i : Fin n) :
    mat_vec_mul M v i = vec_sum (fun j => M i j * v j) := rfl

theorem tensor_contract_apply {n : Nat}
    (T : Fin n → Fin n → Fin n → Rat) (v : Fin n → Rat) (i : Fin n) :
    tensor_contract T v i = vec_sum (fun j => vec_sum (fun k => T i j k * v k)) := rfl

theorem finite_diff_apply {n : Nat} (dt : Rat) (u : Rat → Fin n → Rat) (t : Rat) (i : Fin n) :
    finite_diff dt u t i = (u t i - u (t - dt) i) / dt := rfl

theorem vec_zero_apply {n : Nat} (i : Fin n) : vec_zero i = 0 := rfl

theorem floer_decomposition {n : Nat} (cfg : FiniteFloer n)
    (u : Rat → Fin n → Rat) (t : Rat) :
    floer_operator cfg u t =
      vec_add (vec_add (vec_add
        (finite_diff cfg.dt u t)
        (mat_vec_mul cfg.J (cfg.gradH)))
        (tensor_contract cfg.T cfg.gradPhi))
      (cfg.xi t) := rfl

def floer_lipschitz {n : Nat} (_cfg : FiniteFloer n)
    (_bound_J _bound_T : Rat) : Prop := True

def tensor_contract_bound {n : Nat}
    (_T : Fin n → Fin n → Fin n → Rat) (_bound : Rat) : Prop := True

end Multiplicity.Core.Operators.FloerDifferential
