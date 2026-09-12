/-!
# Foundations.SpectralAttractor.Core — Spectral Attractor Geometry & Lyapunov Energy Descent

Formalizes the locked numerical data of the 9-dimensional spectral attractor (ADR-0034),
the 8 certified zeta zero ordinates $\gamma_1, \dots, \gamma_8$, integral dissipation quanta,
and strict Lyapunov configuration energy descent under squaring orbits.
-/

namespace Foundations.SpectralAttractor

/-- Local Hilbert-space dimension: one ground state plus eight zero modes. -/
def dim : Nat := 9

/-- Number of zero ordinates carried by the attractor. -/
def numOrdinates : Nat := 8

/-- Index of a zero mode (n = 1,…,8 encoded 0-based). -/
abbrev ZeroMode : Type := Fin numOrdinates

/-- Common denominator of all certified constants: certScale = 10^10. -/
def certScale : Nat := 10 ^ 10

/-- Numerator of the envelope width σ = 1/1000. -/
def sigmaNum : Int := 1

/-- Denominator of the envelope width. -/
def sigmaDen : Nat := 1000

theorem sigmaDen_pos : 0 < sigmaDen := by decide
theorem sigmaNum_nonneg : 0 ≤ sigmaNum := by decide

/-- Value table for the 8 locked zero ordinates scaled by 10^10. -/
def gammaScaledV : Nat → Int
  | 0 => 141347251417
  | 1 => 210220396387
  | 2 => 250108575801
  | 3 => 304248761258
  | 4 => 329350615877
  | 5 => 375861781588
  | 6 => 409187190121
  | 7 => 433270732809
  | _ => 0

def gammaScaled (n : ZeroMode) : Int := gammaScaledV n.val

theorem gammaScaledV_step : ∀ k : Nat, k < 7 →
    gammaScaledV k < gammaScaledV (k + 1) := by
  intro k hk
  match k with
  | 0 => decide
  | 1 => decide
  | 2 => decide
  | 3 => decide
  | 4 => decide
  | 5 => decide
  | 6 => decide
  | _ + 7 => omega

theorem gammaScaled_pos (n : ZeroMode) : 0 < gammaScaled n := by
  have hv : n.val < 8 := n.isLt
  dsimp [gammaScaled]
  match h : n.val with
  | 0 => decide
  | 1 => decide
  | 2 => decide
  | 3 => decide
  | 4 => decide
  | 5 => decide
  | 6 => decide
  | 7 => decide
  | _ + 8 => omega

theorem gammaScaled_lt_bound (n : ZeroMode) : gammaScaled n < 44 * (10 ^ 10 : Int) := by
  have hv : n.val < 8 := n.isLt
  dsimp [gammaScaled]
  match h : n.val with
  | 0 => decide
  | 1 => decide
  | 2 => decide
  | 3 => decide
  | 4 => decide
  | 5 => decide
  | 6 => decide
  | 7 => decide
  | _ + 8 => omega

/-- Integer envelope exponent attached to an ordinate value:
    E(g) = -(σ_num · g²) / σ_den -/
def weightExpScaledV (g : Int) : Int :=
  Int.fdiv (-(sigmaNum * g * g)) (sigmaDen : Int)

def weightExpScaled (n : ZeroMode) : Int :=
  weightExpScaledV (gammaScaled n)

theorem weightExpScaledV_neg : ∀ g : Int, 0 < g → weightExpScaledV g < 0 := by
  intro g hg
  have hsn : (0 : Int) < sigmaNum := by decide
  have hd : (0 : Int) < sigmaDen := by decide
  have hp : (0 : Int) < sigmaNum * g * g :=
    Int.mul_pos (Int.mul_pos hsn hg) hg
  have hneg : (-(sigmaNum * g * g) : Int) < 0 := by omega
  exact Int.fdiv_neg_of_neg_of_pos hneg hd

theorem weightExpScaled_neg (n : ZeroMode) : weightExpScaled n < 0 :=
  weightExpScaledV_neg _ (gammaScaled_pos n)

/-- Damping quantum of mode n: the negated envelope exponent. -/
def dissipation (n : ZeroMode) : Int := -weightExpScaled n

theorem dissipation_ge_one (n : ZeroMode) : 1 ≤ dissipation n := by
  have hw := weightExpScaled_neg n
  dsimp [dissipation]
  omega

/-- Squaring-orbit integer exponent:
    orbitExp n 0 = 2 * weightExpScaled n,
    orbitExp n (k+1) = orbitExp n k + orbitExp n k. -/
def orbitExp (n : ZeroMode) : Nat → Int
  | 0 => 2 * weightExpScaled n
  | Nat.succ k => orbitExp n k + orbitExp n k

theorem orbitExp_neg (n : ZeroMode) (k : Nat) : orbitExp n k < 0 := by
  induction k with
  | zero =>
    dsimp [orbitExp]
    have hw := weightExpScaled_neg n
    omega
  | succ k ih =>
    dsimp [orbitExp]
    omega

theorem orbitExp_strict_step (n : ZeroMode) (k : Nat) :
    orbitExp n (Nat.succ k) + 1 ≤ orbitExp n k := by
  induction k with
  | zero =>
    dsimp [orbitExp]
    have hw := weightExpScaled_neg n
    have hd := dissipation_ge_one n
    dsimp [dissipation] at hd
    omega
  | succ k ih =>
    dsimp [orbitExp] at *
    omega

end Foundations.SpectralAttractor
