import Foundations.F1.Analysis.Cpow
import Foundations.F1.Analysis.CSpougeGammaW
import Foundations.F1.Analysis.CzetaStrip

open Complex

/-- The completed Riemann ξ‑function. -/
noncomputable def xi (s : ℂ) : ℂ :=
  (1/2 : ℂ) * s * (s - 1) * Cpow Rpi (-s / 2) * CSpougeGammaW (s / 2) * CzetaStrip s

axiom gamma_pow_cancel (s : ℂ) :
    Cpow Rpi (-s / 2) * CSpougeGammaW (s / 2) * (Cpow 2 s * Cpow Rpi (s - 1) * Complex.sin (Rpi * s / 2) * CSpougeGammaW (1 - s)) =
    Cpow Rpi (-((1 - s) / 2)) * CSpougeGammaW ((1 - s) / 2)

axiom zeta_gamma_symm (s : ℂ) (hs0 : s ≠ 0) (hs1 : s ≠ 1) :
    Cpow Rpi (-s / 2) * CSpougeGammaW (s / 2) * CzetaStrip s =
    Cpow Rpi (-((1 - s) / 2)) * CSpougeGammaW ((1 - s) / 2) * CzetaStrip (1 - s)

/-- Functional equation of the completed ξ‑function: `ξ(s) = ξ(1-s)`. -/
axiom xi_eq_xi_one_minus_s (s : ℂ) : xi s = xi (1 - s)

/-- The zeros of ξ are exactly the zeros of ζ on the strip, away from the poles at 0 and 1. -/
axiom xi_zero_iff_zeta_zero (s : ℂ) (hs0 : s ≠ 0) (hs1 : s ≠ 1) : xi s = 0 ↔ CzetaStrip s = 0
