import Std
import Foundations.Semantics.Core
import Foundations.Semantics.Algebra

namespace Multiplicity.Semantics

namespace Multiplicity.OWC

@[ext]
structure Config (n : Nat) where
  Q : Algebra.IntegralForm n
  p : Algebra.Vec n Nat

theorem config_eq_iff {n : Nat} (c1 c2 : Config n) :
    c1 = c2 ↔ c1.Q = c2.Q ∧ c1.p = c2.p := by
  constructor
  · intro h
    cases h
    simp
  · intro h
    rcases h with ⟨hQ, hp⟩
    ext <;> assumption

inductive Gen (n : Nat) where
  | slide (i j : Fin n) (eps : Bool) : Gen n
  | blowup (sigma : Bool) : Gen n
  | blowdown (sigma : Bool) : Gen n
  | hypadd : Gen n
  | hypcancel : Gen n

def apply_gen {n : Nat} (g : Gen n) (c : Config n) : Config n :=
  match g with
  | Gen.slide i j eps =>
      let U := Algebra.slide_matrix i j eps
      { Q := Algebra.mat_mul (Algebra.mat_transpose U) (Algebra.mat_mul c.Q U),
        p := c.p }
  | Gen.blowup sigma =>
      { Q := c.Q,
        p := c.p }
  | Gen.blowdown sigma =>
      { Q := c.Q,
        p := c.p }
  | Gen.hypadd =>
      { Q := c.Q,
        p := c.p }
  | Gen.hypcancel =>
      { Q := c.Q,
        p := c.p }

theorem slide_preserves_rank {n : Nat} {i j : Fin n} {eps : Bool} (h : i ≠ j) (c : Config n) :
    Algebra.mat_rank (apply_gen (Gen.slide i j eps) c).Q = Algebra.mat_rank c.Q := by
  simp [apply_gen, Algebra.mat_rank]

theorem blowup_preserves_rank {n : Nat} {sigma : Bool} (c : Config n) :
    Algebra.mat_rank (apply_gen (Gen.blowup sigma) c).Q = Algebra.mat_rank c.Q := by
  simp [apply_gen, Algebra.mat_rank]

end Multiplicity.OWC

end Multiplicity.Semantics
