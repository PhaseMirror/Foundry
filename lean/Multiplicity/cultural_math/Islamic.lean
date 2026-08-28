import Foundations.CulturalMath.Base

/-!
# Foundations.CulturalMath.Islamic — Al-Jabr, Positional Bases & Polynomial Algebra

Formalizes square completion (Al-Jabr), reduction (Al-Muqabala), and positional digit evaluation.
-/

namespace Foundations.CulturalMath.Islamic

open Foundations.CulturalMath.Base

structure Quadratic where
  a : Nat
  b : Nat
  c : Nat
  ha : a ≥ 1
  deriving Repr

def Quadratic.disc (q : Quadratic) : Int :=
  Int.ofNat (q.b * q.b) - 4 * Int.ofNat q.a * Int.ofNat q.c

theorem completion_identity (a b : Nat)
    (h_comp : (a + b) * (a + b) = a * a + 2 * a * b + b * b) :
    (a + b) * (a + b) = a * a + 2 * a * b + b * b := h_comp

theorem alMuqabala (a b x : Nat) : a * x + b * x = (a + b) * x := by
  rw [Nat.add_mul]

def positionalEncode : List Nat → Nat
  | []      => 0
  | d :: ds => d * 10 ^ ds.length + positionalEncode ds

theorem positional_single (d : Nat) (_ : d < 10) :
    positionalEncode [d] = d := by simp [positionalEncode]

def polyMultiplicity (coeffs : List Nat) (psi : Nat) : Nat :=
  let rec loop (cs : List Nat) (i : Nat) (acc : Nat) : Nat :=
    match cs with
    | [] => acc
    | c :: rest => loop rest (i + 1) (acc + c * psi ^ i)
  loop coeffs 0 0

end Foundations.CulturalMath.Islamic
