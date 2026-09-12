import EchoBraid.Core
import EchoBraid.FloerOperator
import EchoBraid.BraidFormalism
import EchoBraid.Contraction
import EchoBraid.SpectralCoherence

/-!
# EchoBraid.Examples

Concrete instantiations and simulation scenarios:
1. `fibonacciBraid3`: 3-strand braid on primes (2, 3, 5)
2. `sensorySpectrumBraid7`: 7-strand spectrum on primes (2, 3, 5, 7, 11, 13, 17)
3. Trajectory evaluation under Floer differential flow and braid permutations.
-/

namespace EchoBraid

/-- Construct a standard default strand -/
def makeStrand (primeId tintId initPhase intensity amp pos : Nat) : Strand := {
  prime    := primeId,
  tint     := { tintId := tintId, phaseDeg := initPhase, intensity := intensity },
  eigen    := { traceId := primeId * 100, amplitude := amp, phase := initPhase },
  position := pos
}

/-- 3-strand Fibonacci-prime initial state -/
def fibonacciBraid3 : EchoBraidState := {
  time              := 0,
  strands           := [
    makeStrand 2 1 0   80 90 0,
    makeStrand 3 2 120 70 85 1,
    makeStrand 5 3 240 60 75 2
  ],
  lambdaM           := 60,
  spectralCoherence := 85
}

/-- 7-strand sensory spectrum initial state -/
def sensorySpectrumBraid7 : EchoBraidState := {
  time              := 0,
  strands           := [
    makeStrand 2  1 0   90 95 0,
    makeStrand 3  2 50  85 90 1,
    makeStrand 5  3 100 80 85 2,
    makeStrand 7  4 150 75 80 3,
    makeStrand 11 5 200 70 75 4,
    makeStrand 13 6 250 65 70 5,
    makeStrand 17 7 300 60 65 6
  ],
  lambdaM           := 50,
  spectralCoherence := 90
}

/-- Simulate 5 steps of combined Floer flow and Braid crossing -/
def runSampleBraidSimulation : EchoBraidState :=
  let st0 := fibonacciBraid3
  let st1 := floerStep st0
  let st2 := applyBraidMove st1 (BraidMove.crossPos 0)
  let st3 := floerStep st2
  let st4 := applyBraidMove st3 (BraidMove.crossPos 1)
  floerStep st4

end EchoBraid
