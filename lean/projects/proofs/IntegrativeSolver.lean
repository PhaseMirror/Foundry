import Kernel

/-!
# IntegrativeSolver — composition preserves correctness

Formalizes the Integrative Solver's composition principle: if each sub-solver meets
its specification, their sequential composition meets the composite specification.
No `Mathlib`, no `sorry`.
-/
namespace IntegrativeSolver

open proofs.Kernel

/-- A solver from `In` to `Out` together with its specification. -/
structure Solver (In Out : Type) where
  run : In → Out
  spec : In → Out → Prop
  sound : ∀ i, spec i (run i)

/-- The composite specification is existential in the intermediate value. -/
def compose {A B C : Type} (f : Solver A B) (g : Solver B C) : Solver A C where
  run := fun a => g.run (f.run a)
  spec := fun a c => ∃ b, f.spec a b ∧ g.spec b c
  sound := fun a => ⟨f.run a, f.sound a, g.sound (f.run a)⟩

/-- The identity solver is correct. -/
def identity (T : Type) : Solver T T where
  run := id
  spec := fun a b => a = b
  sound := fun a => rfl

end IntegrativeSolver
