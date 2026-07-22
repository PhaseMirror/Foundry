import CulturalMath.Base

namespace CulturalMath.Hebrew

-- Gematria: letter-to-number mapping
def GematriaVal : Nat → Nat
  | 0  => 1  | 1  => 2  | 2  => 3  | 3  => 4  | 4  => 5
  | 5  => 6  | 6  => 7  | 7  => 8  | 8  => 9  | 9  => 10
  | 10 => 20 | 11 => 30 | 12 => 40 | 13 => 50 | 14 => 60
  | 15 => 70 | 16 => 80 | 17 => 90 | 18 => 100 | 19 => 200
  | 20 => 300 | 21 => 400 | n => n * 10

def gematriaWord : List Nat → Nat
  | []      => 0
  | l :: ls => GematriaVal l + gematriaWord ls

theorem gematriaWord_nil : gematriaWord [] = 0 := by simp [gematriaWord]
theorem gematriaWord_cons (a : Nat) (as : List Nat) :
    gematriaWord (a :: as) = GematriaVal a + gematriaWord as := by simp [gematriaWord]

-- Sabbath cycle: mod 7
def sabbathCycle (t : Nat) : Nat := t % 7
theorem sabbath_periodic (t : Nat) : sabbathCycle (t + 7) = sabbathCycle t := by simp [sabbathCycle]
theorem sabbath_day0 : sabbathCycle 0 = 0 := by native_decide

-- Jubilee cycle: mod 50
def jubileeCycle (t : Nat) : Nat := t % 50
theorem jubilee_periodic (t : Nat) : jubileeCycle (t + 50) = jubileeCycle t := by simp [jubileeCycle]

-- Binomial coefficients
def binom : Nat → Nat → Nat
  | _, 0     => 1
  | 0, _     => 0
  | n + 1, k + 1 => binom n k + binom n (k + 1)

private theorem binom_of_gt : ∀ (n k : Nat), k > n → binom n k = 0
  | _, 0, h => absurd h (by omega)
  | 0, _ + 1, _ => by simp [binom]
  | n + 1, k + 1, h => by
    simp only [binom]
    have hk : k > n := by omega
    have hk1 : k + 1 > n := by omega
    rw [binom_of_gt n k hk, binom_of_gt n (k + 1) hk1]

theorem binom_zero_right (n : Nat) : binom n 0 = 1 := by simp [binom]
theorem binom_self : ∀ n, binom n n = 1
  | 0     => by simp [binom]
  | n + 1 => by
    simp only [binom]
    rw [binom_self n, binom_of_gt n (n + 1) (by omega)]
theorem binom_4_2 : binom 4 2 = 6 := by native_decide

-- Sefirot (Tree of Life): 10 total
def sefirotLayer : Nat → Nat
  | 0     => 0
  | n + 1 => (n + 1) + sefirotLayer n

theorem sefirot_total : sefirotLayer 4 = 10 := by native_decide

end CulturalMath.Hebrew
