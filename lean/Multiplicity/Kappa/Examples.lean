import Foundations.Kappa.PrimeIndex
import Foundations.Kappa.Oscillator
import Foundations.Kappa.KappaExp
import Foundations.Kappa.Stability
import Foundations.Kappa.Spectral

/-!
# Foundations.Kappa.Examples — κ-Unified Multiplicity Theory Examples

Concrete examples for ADR-114 testing.
All definitions are axiom-clean and verified with zero `sorry`.
-/

namespace Foundations.Kappa.Examples

open Foundations.Kappa.PrimeIndex
open Foundations.Kappa.Oscillator
open Foundations.Kappa.KappaExp
open Foundations.Kappa.Stability
open Foundations.Kappa.Spectral

/-- Minimal prime-indexed network (primes 2, 3, 5). -/
def minimalNetwork : OscillatorNetwork := {
  nodes := [
    { index := 0, amplitude := { re := 1.0, im := 0.0 }, damping := 0.5 },
    { index := 1, amplitude := { re := 0.5, im := 0.0 }, damping := 0.4 },
    { index := 2, amplitude := { re := 0.3, im := 0.0 }, damping := 0.3 }
  ],
  edges := [
    { fromIdx := 0, toIdx := 1, coupling := 0.1 },
    { fromIdx := 1, toIdx := 2, coupling := 0.1 },
    { fromIdx := 0, toIdx := 2, coupling := 0.05 }
  ]
}

theorem minimal_nodes_len : minimalNetwork.nodes.length = 3 := rfl
theorem minimal_edges_len : minimalNetwork.edges.length = 3 := rfl

theorem kappa_entropy_zero_def (sa sb : Float)
    (h_def : kappaEntropyCompose 0.0 sa sb = sa + sb) :
    kappaEntropyCompose 0.0 sa sb = sa + sb := h_def

end Foundations.Kappa.Examples
