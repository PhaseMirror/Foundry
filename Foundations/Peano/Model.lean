import Foundations.PeanoN.Nat

/-!
# Peano: Axiomatic Bridge Between the Two Developments

Reconciles the two natural-number developments in this library:

1. `Foundations.Peano.Peano` — the Peano laws *stated as propositions about*
   the built-in `ℕ` and proved by citing the standard library.
2. `Foundations.PeanoN.Nat` — a *from-scratch* inductive model of `ℕ`
   (`zero` / `succ`) with arithmetic, order, and division proved by
   explicit induction, using no built-in `Nat` and no mathlib.

The bridge makes the relationship between the two formally explicit:

- We first capture the Peano axioms **abstractly** in a structure
  `Peano` over an arbitrary carrier type: `zero_ne_succ` (P1), `succ_inj`
  (P2), and the induction principle (P5). (As in second-order Peano
  arithmetic, induction ranges over predicates `P : N → Prop`.)
- We then exhibit **two models** of these axioms: `natPeano` (the built-in
  `ℕ`) and `peanoNModel` (the from-scratch `Foundations.PeanoN.Nat`). Each
  `induction` field is discharged by the corresponding recursor.
- Finally we prove the classical **characterisation theorem** concretely
  for the from-scratch model: the canonical maps `toNat` and `ofNat` are
  mutual inverses, so `Foundations.PeanoN.Nat ≃ ℕ`. This confirms that the
  from-scratch construction is structurally the same object as the standard
  naturals, and hence that `Foundations.Peano.Peano` and
  `Foundations.PeanoN.*` describe the same structure.

No unproved axioms or `admit`s are used. The only place the built-in
arithmetic library is used is to state the *canonical target* `ℕ` of the
equivalence; every Peano law on the from-scratch side is proved by explicit
induction on the custom datatype.
-/

namespace Foundations.Peano

/-- The Peano axioms, stated over an arbitrary carrier type `N`.

- **P1** `zero_ne_succ`: zero is not a successor.
- **P2** `succ_inj`: the successor function is injective.
- **P5** `induction`: the induction principle over predicates
  `P : N → Prop`, as in second-order Peano arithmetic.
-/
structure Peano where
  N : Type
  zero : N
  succ : N → N
  zero_ne_succ : ∀ n : N, zero ≠ succ n
  succ_inj : ∀ {m n : N}, succ m = succ n → m = n
  induction : ∀ {P : N → Prop}, P zero → (∀ n : N, P n → P (succ n)) → ∀ n : N, P n

namespace Peano

/-- **Model 1**: the built-in `ℕ` satisfies the Peano axioms. -/
def natPeano : Peano where
  N := Nat
  zero := 0
  succ := Nat.succ
  zero_ne_succ := by
    intro n h
    exact Nat.noConfusion h
  succ_inj := by
    intro m n h
    exact Nat.succ.inj h
  induction := by
    intro P h0 hS n
    exact @Nat.rec P h0 hS n

/-- **Model 2**: the from-scratch `Foundations.PeanoN.Nat` satisfies the
Peano axioms. -/
def peanoNModel : Peano where
  N := Foundations.PeanoN.Nat
  zero := @Foundations.PeanoN.Nat.zero
  succ := @Foundations.PeanoN.Nat.succ
  zero_ne_succ := @Foundations.PeanoN.Nat.zero_ne_succ
  succ_inj := @Foundations.PeanoN.Nat.succ_inj
  induction := by
    intro P h0 hS n
    exact @Foundations.PeanoN.Nat.rec P h0 hS n

/-!
## Characterisation of the from-scratch model

The concrete equivalence between `Foundations.PeanoN.Nat` and the built-in
`ℕ`. `toNat` is defined by structural recursion on the custom datatype
(mapping its `zero` to `0` and its `succ` to `Nat.succ`); `ofNat` is its
inverse, defined by structural recursion on `ℕ`.
-/

/-- The canonical map `Foundations.PeanoN.Nat → ℕ`. -/
def toNat : Foundations.PeanoN.Nat → Nat
  | .zero => 0
  | .succ n => Nat.succ (toNat n)

/-- `toNat` sends `succ` to `Nat.succ`. -/
theorem toNat_succ (n : Foundations.PeanoN.Nat) :
    toNat (Foundations.PeanoN.Nat.succ n) = Nat.succ (toNat n) := by
  rfl

/-- `toNat zero = 0`. -/
theorem toNat_zero : toNat Foundations.PeanoN.Nat.zero = 0 := by
  rfl

/-- The canonical inverse map `ℕ → Foundations.PeanoN.Nat`. -/
def ofNat : Nat → Foundations.PeanoN.Nat
  | 0 => Foundations.PeanoN.Nat.zero
  | Nat.succ n => Foundations.PeanoN.Nat.succ (ofNat n)

/-- `ofNat` sends `Nat.succ` to `succ`. -/
theorem ofNat_succ (n : Nat) :
    ofNat (Nat.succ n) = Foundations.PeanoN.Nat.succ (ofNat n) := by
  rfl

/-- `ofNat 0 = zero`. -/
theorem ofNat_zero : ofNat 0 = Foundations.PeanoN.Nat.zero := by
  rfl

/-- Round-trip 1: `toNat (ofNat n) = n` for every built-in `n : ℕ`. -/
theorem toNat_ofNat : ∀ n : Nat, toNat (ofNat n) = n := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
      calc
        toNat (ofNat (Nat.succ n))
            = toNat (Foundations.PeanoN.Nat.succ (ofNat n)) := by rfl
        _ = Nat.succ (toNat (ofNat n)) := by rfl
        _ = Nat.succ n := by rw [ih]

/-- Round-trip 2: `ofNat (toNat m) = m` for every `m` in the from-scratch
model. This is the nexus of the reconciliation: it says the custom carrier
is faithfully represented by the built-in naturals. -/
theorem ofNat_toNat : ∀ m : Foundations.PeanoN.Nat, ofNat (toNat m) = m := by
  intro m
  induction m with
  | zero => rfl
  | succ n ih =>
      calc
        ofNat (toNat (Foundations.PeanoN.Nat.succ n))
            = ofNat (Nat.succ (toNat n)) := by rfl
        _ = Foundations.PeanoN.Nat.succ (ofNat (toNat n)) := by rfl
        _ = Foundations.PeanoN.Nat.succ n := by rw [ih]

/-- A minimal equivalence between two types: a pair of mutually inverse
maps. (Defined here because mathlib's `Equiv` is not a dependency of this
project.) -/
structure Equiv (A B : Type) where
  toFun : A → B
  invFun : B → A
  left_inv : ∀ a : A, invFun (toFun a) = a
  right_inv : ∀ b : B, toFun (invFun b) = b

namespace Equiv

/-- The identity equivalence. -/
def refl (A : Type) : Equiv A A where
  toFun := fun a => a
  invFun := fun a => a
  left_inv := fun _ => rfl
  right_inv := fun _ => rfl

/-- The symmetric equivalence of an equivalence. -/
def symm {A B : Type} (e : Equiv A B) : Equiv B A where
  toFun := e.invFun
  invFun := e.toFun
  left_inv := e.right_inv
  right_inv := e.left_inv

end Equiv

/-- **Characterisation theorem**: the from-scratch `Foundations.PeanoN.Nat`
is equivalent to the built-in `ℕ`. Together with the two models above, this
reconciles `Foundations.Peano.Peano` and `Foundations.PeanoN.Nat` as two
presentations of the same structure. -/
def peanoNEquiv : Equiv Foundations.PeanoN.Nat Nat where
  toFun := toNat
  invFun := ofNat
  left_inv := ofNat_toNat
  right_inv := toNat_ofNat

end Peano

end Foundations.Peano
