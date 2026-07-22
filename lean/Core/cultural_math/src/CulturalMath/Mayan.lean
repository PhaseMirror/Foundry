import CulturalMath.Base

namespace CulturalMath.Mayan

-- Base-20 (vigesimal)
def mod20 (n : Nat) : Nat := n % 20

theorem mod20_periodic (n : Nat) : mod20 (n + 20) = mod20 n := by simp [mod20]
theorem mod20_add (a b : Nat) : mod20 (a + b) = mod20 (mod20 a + mod20 b) := by simp [mod20]
theorem mod20_mul (a b : Nat) : mod20 (a * b) = mod20 (mod20 a * mod20 b) := by
  simp only [mod20]; rw [Nat.mul_mod]

-- Zero as ground state
theorem mayanZero_add (n : Nat) : 0 + n = n := by omega
theorem mayanZero_mul (n : Nat) : 0 * n = 0 := by omega

-- Calendrical cycles
def tzolkinCycle := 260
def haabCycle := 365
def tzolkinDay (t : Nat) : Nat := t % tzolkinCycle
def haabDay (t : Nat) : Nat := t % haabCycle

theorem tzolkin_periodic (t : Nat) : tzolkinDay (t + tzolkinCycle) = tzolkinDay t := by
  simp [tzolkinDay, tzolkinCycle]

theorem haab_periodic (t : Nat) : haabDay (t + haabCycle) = haabDay t := by
  simp [haabDay, haabCycle]

def calendarRound := 18980
theorem calendarRound_sync :
    calendarRound % tzolkinCycle = 0 ∧ calendarRound % haabCycle = 0 := by
  simp [calendarRound, tzolkinCycle, haabCycle]

-- Vigesimal encoding
def fromBase20 : List Nat → Nat
  | []      => 0
  | v :: vs => v + 20 * fromBase20 vs

def toBase20 : Nat → List Nat
  | 0     => [0]
  | n + 1 => (n + 1) % 20 :: toBase20 ((n + 1) / 20)

theorem fromBase20_toBase20 : ∀ n, n < 20 → fromBase20 (toBase20 n) = n
  | 0, _ => by simp [toBase20, fromBase20]
  | m + 1, h => by
    simp only [toBase20, fromBase20]
    have hm := Nat.mod_eq_of_lt (show m + 1 < 20 from h)
    have hd : (m + 1) / 20 = 0 := by omega
    rw [hm, hd]
    simp [toBase20, fromBase20]

-- Fractal in base 20
def vigesimalFractal (T0 : Nat) : Nat → Nat
  | 0     => T0
  | n + 1 => vigesimalFractal T0 n / 20

theorem vigesimalFractal_contracting (T0 n : Nat) (_hT0 : T0 ≥ 1) :
    vigesimalFractal T0 (n + 1) ≤ vigesimalFractal T0 n := by
  simp [vigesimalFractal]; omega

-- Positional encoding
def mayanPositional : List Nat → Nat
  | []      => 0
  | v :: vs => v + 20 * mayanPositional vs

theorem mayanPositional_single (v : Nat) (_hv : v < 20) :
    mayanPositional [v] = v := by simp [mayanPositional]

end CulturalMath.Mayan
