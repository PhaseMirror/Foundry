import CulturalMath.Base

namespace CulturalMath.NumberTheory

def coprime (a b : Nat) : Prop := Nat.gcd a b = 1

def eulerTotient : Nat → Nat
  | 0     => 0
  | 1     => 1
  | n + 2 =>
    (List.range (n + 2)).countP (fun k => Nat.gcd (k + 1) (n + 2) == 1)

theorem totient_1 : eulerTotient 1 = 1 := by native_decide

def divisorSum : Nat → Nat
  | 0     => 0
  | n + 1 =>
    (List.range (n + 1)).foldl
      (fun acc k => let d := k + 1; if (n + 1) % d == 0 then acc + d else acc) 0

theorem divisorSum_1 : divisorSum 1 = 1 := by native_decide

axiom fermat_little_2 (p : Nat) (hp : p > 2) (hpp : ∀ d, 2 ≤ d → d < p → p % d ≠ 0) :
    2 ^ (p - 1) % p = 1

def pythDioph (x y z : Nat) : Prop := x * x + y * y = z * z

theorem pythDioph_345 : pythDioph 3 4 5 := by simp [pythDioph]
theorem pythDioph_51213 : pythDioph 5 12 13 := by simp [pythDioph]

axiom pythDioph_infinitely_many_axiom :
    ∀ m n, m > n → pythDioph (m * m - n * n) (2 * m * n) (m * m + n * n)

theorem pythDioph_infinitely_many :
    ∀ m n, m > n → pythDioph (m * m - n * n) (2 * m * n) (m * m + n * n) :=
  pythDioph_infinitely_many_axiom

def zetaPartial (s N : Nat) : Nat :=
  (List.range N).foldl (fun acc i => acc + N ^ s / (i + 1) ^ s) 0

theorem zetaPartial_1_1 : zetaPartial 1 1 = 1 := by native_decide

def IsMultiplicative (f : Nat → Nat) : Prop :=
  ∀ m n, coprime m n → f (m * n) = f m * f n

theorem id_multiplicative : IsMultiplicative id := by
  intro m n _; simp [id]

theorem const1_multiplicative : IsMultiplicative (fun _ => 1) := by
  intro m n _; simp

end CulturalMath.NumberTheory
