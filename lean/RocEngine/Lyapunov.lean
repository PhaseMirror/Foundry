-- Lyapunov.lean
import RocEngine.Spectral

-- Standard Lyapunov functional V(x) = ∥x∥
def V (x : State) : Nat :=
  x.p2 + x.p3 + x.p5

-- Fejér-monotone Lyapunov descent: V(T x) ≤ V(x)
theorem lyapunov_descent (x : State) : V (T x) ≤ V x := by
  dsimp [V, T]
  apply Nat.add_le_add
  · apply Nat.add_le_add
    · exact Nat.div_le_self x.p2 2
    · exact Nat.div_le_self x.p3 2
  · exact Nat.div_le_self x.p5 2

-- Extension: MPW-FL weighted Lyapunov functional
structure Weights where
  w2 : Nat
  w3 : Nat
  w5 : Nat

-- V_omega models the multiplicity-weighted Lyapunov geometry
def V_omega (w : Weights) (x : State) : Nat :=
  w.w2 * x.p2 + w.w3 * x.p3 + w.w5 * x.p5

-- Multiplicity-weighted Fejér descent, mirroring the continuous synthesis
theorem lyapunov_descent_weighted (w : Weights) (x : State) : V_omega w (T x) ≤ V_omega w x := by
  dsimp [V_omega, T]
  apply Nat.add_le_add
  · apply Nat.add_le_add
    · exact Nat.mul_le_mul_left w.w2 (Nat.div_le_self x.p2 2)
    · exact Nat.mul_le_mul_left w.w3 (Nat.div_le_self x.p3 2)
  · exact Nat.mul_le_mul_left w.w5 (Nat.div_le_self x.p5 2)
