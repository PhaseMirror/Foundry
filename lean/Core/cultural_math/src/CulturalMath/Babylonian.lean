import CulturalMath.Base

namespace CulturalMath.Babylonian

def mod60 (n : Nat) : Nat := n % 60

theorem mod60_periodic (n : Nat) : mod60 (n + 60) = mod60 n := by simp [mod60]
theorem mod60_add (a b : Nat) : mod60 (a + b) = mod60 (mod60 a + mod60 b) := by simp [mod60]
theorem mod60_mul (a b : Nat) : mod60 (a * b) = mod60 (mod60 a * mod60 b) := by
  simp only [mod60]; rw [Nat.mul_mod]

def babylonianSqrt (S : Nat) : Nat → Nat
  | 0     => S
  | n + 1 =>
    let prev := babylonianSqrt S n
    if prev = 0 then S else (prev + S / prev) / 2

theorem babylonianSqrt_bounded_step (S x : Nat) (_ : x ≤ S) (_ : x ≥ 1) :
    (x + S / x) / 2 ≤ S := by
  have : S / x ≤ S := Nat.div_le_self S x; omega

def babylonianCos (t : Nat) : Int :=
  let r := t % 60
  if r < 15 then 1 else if r < 30 then 0 else if r < 45 then -1 else 0

theorem babylonianCos_periodic : ∀ t, babylonianCos (t + 60) = babylonianCos t := by
  intro t; simp [babylonianCos]

def toBase60 : Nat → List Nat
  | 0     => [0]
  | n + 1 => (n + 1) % 60 :: toBase60 ((n + 1) / 60)

def fromBase60 : List Nat → Nat
  | []      => 0
  | v :: vs => v + 60 * fromBase60 vs

theorem fromBase60_toBase60 : ∀ n, n < 60 → fromBase60 (toBase60 n) = n
  | 0, _ => by simp [toBase60, fromBase60]
  | m + 1, h => by
    simp only [toBase60, fromBase60]
    have hm := Nat.mod_eq_of_lt (show m + 1 < 60 from h)
    have hd : (m + 1) / 60 = 0 := by omega
    rw [hm, hd]
    simp [toBase60, fromBase60]

def bYear := 360
def bMonth := 30
def dayOfYear (t : Nat) : Nat := t % bYear
def dayOfMonth (t : Nat) : Nat := (t % bYear) % bMonth
def monthNumber (t : Nat) : Nat := (t / bMonth) % 12

end CulturalMath.Babylonian
