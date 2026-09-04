import Init
import SpiralCore.Core

namespace SpiralCore.Cantor

def cantorPair (a b : Nat) : Nat :=
  let s := a + b
  (s * (s + 1)) / 2 + b

def zigzag (n : Int) : Nat :=
  if n >= 0 then
    2 * (Int.toNat n)
  else
    2 * (Int.toNat (-n)) - 1

def zigzagInv (z : Nat) : Int :=
  if z % 2 == 0 then
    Int.ofNat (z / 2)
  else
    -Int.ofNat ((z + 1) / 2)

theorem cantorPair_nonneg (a b : Nat) : cantorPair a b >= 0 := Nat.zero_le _

theorem zigzag_roundtrip (n : Int) : zigzagInv (zigzag n) = n := by
  cases n with
  | ofNat k =>
    dsimp [zigzag, zigzagInv]
    have h1 : (2 * k % 2 == 0) = true := by
      have h_mod : 2 * k % 2 = 0 := by omega
      exact decide_eq_true h_mod
    rw [h1]
    dsimp
    have h2 : Int.ofNat (2 * k / 2) = Int.ofNat k := by
      have h3 : 2 * k / 2 = k := by omega
      rw [h3]
    exact h2
  | negSucc k =>
    dsimp [zigzag, zigzagInv]
    have h1 : ((2 * (k + 1) - 1) % 2 == 0) = false := by
      exact decide_eq_false (by omega)
    rw [h1]
    dsimp
    have h2 : -Int.ofNat ((2 * (k + 1) - 1 + 1) / 2) = Int.negSucc k := by
      have h3 : (2 * (k + 1) - 1 + 1) / 2 = k + 1 := by omega
      rw [h3]
      rfl
    exact h2

end SpiralCore.Cantor
