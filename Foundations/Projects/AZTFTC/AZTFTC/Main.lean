import Init
import AZTFTC.Core
import AZTFTC.Hilbert
import AZTFTC.Lawful
import AZTFTC.Operators
import AZTFTC.GeoPotential
import AZTFTC.Boundary
import AZTFTC.Spectral
import AZTFTC.Casimir
import AZTFTC.Examples
import AZTFTC.Proofs
import AZTFTC.Test
import AZTFTC.Export

/-! # AZ-TFTC v0.1.0

Lean 4 formalization of the AZ-TFTC numerical model.

Build: `lake build`
Test:  `lake exe AZTFTCTest`
-/

def main : IO Unit := AZTFTC.Test.main
