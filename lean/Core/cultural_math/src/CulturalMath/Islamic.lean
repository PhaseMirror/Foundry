import CulturalMath.Base

namespace CulturalMath.Islamic

structure Quadratic where
  a : Nat
  b : Nat
  c : Nat
  ha : a ≥ 1

def Quadratic.disc (q : Quadratic) : Int :=
  Int.ofNat (q.b * q.b) - 4 * Int.ofNat q.a * Int.ofNat q.c

theorem completion_identity (a b : Nat) :
    (a + b) * (a + b) = a * a + 2 * a * b + b * b := by
  rw [Nat.add_mul, Nat.mul_add, Nat.mul_add, Nat.mul_comm b a,
      show (2 : Nat) = 1 + 1 from rfl, Nat.add_mul, Nat.one_mul, Nat.add_mul]
  omega

theorem alMuqabala (a b x : Nat) : a * x + b * x = (a + b) * x := by
  rw [Nat.add_mul]

def positionalEncode : List Nat → Nat
  | []      => 0
  | d :: ds => d * 10 ^ ds.length + positionalEncode ds

theorem positional_single (d : Nat) (_ : d < 10) :
    positionalEncode [d] = d := by simp [positionalEncode]

def polyMultiplicity (coeffs : List Nat) (psi : Nat) : Nat :=
  coeffs.enum.foldl (fun acc (i, a) => acc + a * psi ^ i) 0

end CulturalMath.Islamic
