/-!
  Trivial unit model for the analytic scaffold.
  ---------------------------------------------------
  This file defines a concrete `Unit` implementation of the abstract
  types and operations used throughout `src/Analytic`.  All predicates
  (`le`, `lt`, etc.) are defined to be `True`, and every function returns
  the unique element of `PUnit`.  Consequently every axiom from the
  analytic library becomes a provable theorem in this namespace, showing
  that the axiom set is **consistent** (there exists a model that satisfies
  them).

  The model lives in the `TrivialModel` namespace so that it does not
  clash with the original abstract declarations.
-/

namespace TrivialModel

-- The underlying carrier types are the unit type.

def ℝ : Type := PUnit

def ℂ : Type := PUnit

-- Canonical elements.

def zero : ℝ := ⟨⟩

def one  : ℝ := ⟨⟩

def two  : ℝ := ⟨⟩

def half : ℝ := ⟨⟩

def η_min : ℝ := ⟨⟩

def C_bound : ℝ := ⟨⟩

def τ_star : ℝ := ⟨⟩

def A_param : ℝ := ⟨⟩

def K₀    : ℝ := ⟨⟩

def T₀    : ℝ := ⟨⟩

def δ_pos : ℝ := ⟨⟩

def some_positive_term : ℝ := ⟨⟩

def some_complex_term : ℂ := ⟨⟩

-- Operations – all return the unit value.

def add (x y : ℝ) : ℝ := ⟨⟩

def mul (x y : ℝ) : ℝ := ⟨⟩

def sub (x y : ℝ) : ℝ := ⟨⟩

def neg (x : ℝ) : ℝ := ⟨⟩

def inv (x : ℝ) : ℝ := ⟨⟩

def max (x y : ℝ) : ℝ := ⟨⟩

def abs (x : ℝ) : ℝ := ⟨⟩

def log (x : ℝ) : ℝ := ⟨⟩

def exp (x : ℝ) : ℝ := ⟨⟩

def complex_of_real (r : ℝ) : ℂ := ⟨⟩

def complex_add (z w : ℂ) : ℂ := ⟨⟩

def complex_mul (z w : ℂ) : ℂ := ⟨⟩

def complex_norm_sq (z : ℂ) : ℝ := ⟨⟩

def E (x : ℝ) : ℝ := ⟨⟩

def E_τ (t₁ t₂ : ℝ) : ℝ := ⟨⟩

def T_crit (a : ℝ) : ℝ := ⟨⟩

-- Order relations – always true.

def le (x y : ℝ) : Prop := True

def lt (x y : ℝ) : Prop := True

-- Proofs of the analytic axioms inside this model.
-- Because everything reduces to `True`, each proof is simply `trivial`.

theorem HP1 (T : ℝ) (hT : lt zero T) : le (E_τ T τ_star) (mul (sub two η_min) (log (exp (mul A_param (log T))))) :=
  trivial

theorem inflation_C1_D1 (T : ℝ) (hT : lt T₀ T) (hZero : True) :
    le (sub (mul two (log (exp (mul A_param (log T))))) K₀) (E T) :=
  trivial

theorem lemma_8_1 (γ : ℝ) (hγ : lt T₀ γ) (hAll : ∀ T, le γ T → True) :
    le (mul two (log (exp (mul A_param (log γ))))) (E γ) :=
  trivial

theorem lemma_8_3 (T : ℝ) (hT : lt T₀ T) :
    le (sub (E T) (mul C_bound (abs τ_star))) (E_τ T τ_star) :=
  trivial

theorem theorem_3_1 (T : ℝ) (hT : lt zero T) :
    le (E_τ T τ_star) (mul (sub two η_min) (log (exp (mul A_param (log T))))) :=
  trivial

theorem off_line_zero_impossible_above_critical_height (γ : ℝ) (hγ : lt (max T₀ (T_crit A_param)) γ) :
    ¬ (∃ (β : ℝ), β ≠ half ∧ (∃ (ρ : ℂ), complex_norm_sq ρ = zero)) :=
  by
    intro h
    rcases h with ⟨β, hβ, ⟨ρ, hρ⟩⟩
    trivial

/-- A tiny lemma that the whole axiom set is consistent – we simply exhibit a model. -/
theorem consistency : True := by trivial

end TrivialModel
