import Init
import AZTFTC.Core
import AZTFTC.Hilbert
import AZTFTC.Lawful
import AZTFTC.Operators
import AZTFTC.GeoPotential
import AZTFTC.Boundary
import AZTFTC.Spectral
import AZTFTC.Casimir

/-! # AZ-TFTC — Proofs

Verified theorems with 0 sorry.
-/

namespace AZTFTC.Proofs

open AZTFTC
open AZTFTC.Hilbert
open AZTFTC.Operators
open AZTFTC.Boundary
open AZTFTC.Spectral
open AZTFTC.Casimir
open AZTFTC.GeoPotential

theorem fp_den_correct : FP_DEN = 100 := rfl
theorem prime_2 : isPrime 2 = true := rfl
theorem prime_3 : isPrime 3 = true := rfl
theorem not_prime_4 : isPrime 4 = false := rfl
theorem pi_10 : pi 10 = 4 := rfl
theorem pi_20 : pi 20 = 8 := rfl

theorem examplePhiSigma_pos : examplePhiSigma.length > 0 := by
  dsimp [examplePhiSigma]
  decide

theorem exampleVGeo_pos : exampleVGeo.length > 0 := by
  dsimp [exampleVGeo, vGeo, examplePhiSigma]
  decide

theorem exampleSpectrum_len : exampleSpectrum.length = 3 := by
  dsimp [exampleSpectrum]
  decide

end AZTFTC.Proofs
