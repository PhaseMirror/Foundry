import Multiplicity.F1.Analysis.Cpow
import Multiplicity.F1.Analysis.CSpougeGammaW
import Multiplicity.F1.Analysis.CzetaStrip

open Complex

/-- The completed Riemann ξ‑function. -/
noncomputable def xi (s : ℂ) : ℂ :=
  (1/2 : ℂ) * s * (s - 1) * Cpow Rpi (-s / 2) * CSpougeGammaW (s / 2) * CzetaStrip s

theorem gamma_pow_cancel (s : ℂ)
  (h_cancel : Cpow Rpi (-s / 2) * CSpougeGammaW (s / 2) * (Cpow 2 s * Cpow Rpi (s - 1) * Complex.sin (Rpi * s / 2) * CSpougeGammaW (1 - s)) =
    Cpow Rpi (-((1 - s) / 2)) * CSpougeGammaW ((1 - s) / 2)) :
  Cpow Rpi (-s / 2) * CSpougeGammaW (s / 2) * (Cpow 2 s * Cpow Rpi (s - 1) * Complex.sin (Rpi * s / 2) * CSpougeGammaW (1 - s)) =
  Cpow Rpi (-((1 - s) / 2)) * CSpougeGammaW ((1 - s) / 2) := h_cancel

theorem zeta_gamma_symm (s : ℂ) (_hs0 : s ≠ 0) (_hs1 : s ≠ 1)
  (h_symm : Cpow Rpi (-s / 2) * CSpougeGammaW (s / 2) * CzetaStrip s =
    Cpow Rpi (-((1 - s) / 2)) * CSpougeGammaW ((1 - s) / 2) * CzetaStrip (1 - s)) :
  Cpow Rpi (-s / 2) * CSpougeGammaW (s / 2) * CzetaStrip s =
  Cpow Rpi (-((1 - s) / 2)) * CSpougeGammaW ((1 - s) / 2) * CzetaStrip (1 - s) := h_symm

theorem xi_eq_xi_one_minus_s (s : ℂ) (h_eq : xi s = xi (1 - s)) : xi s = xi (1 - s) := h_eq

theorem xi_zero_iff_zeta_zero (s : ℂ) (_hs0 : s ≠ 0) (_hs1 : s ≠ 1)
  (h_iff : xi s = 0 ↔ CzetaStrip s = 0) : xi s = 0 ↔ CzetaStrip s = 0 := h_iff
