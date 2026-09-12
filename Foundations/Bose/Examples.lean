import Foundations.Bose.Core

/-!
# ADR-0036: Satyendra Nath Bose Multiplicity Examples

Concrete computational instances and evaluation suites for Bose Multiplicity
and Bose-Einstein Arithmetic Statistics (ADR-0036 §17 and §S5 Table).

## System Configuration: $g = 3$ modes (Primes 2, 3, 5)

We examine the finite-mode Bose gas with $g=3$ across particle counts $N \in \{1, \dots, 20\}$.
-/

namespace Multiplicity.Bose.Examples

open Multiplicity.Bose

/-! ## 1. S2: The (C, F) Coordinate Independence Pair -/

/-- State A: $(3, 1, 1)$, $N = 5$.
    Concentration: $C = 3/5$. Fragmentation: $F = 3/5$ (all 3 modes active). -/
def state_3_1_1 : BoseStateRecord :=
  makeBoseRecord [3, 1, 1] [2, 3, 5]

/-- State B: $(3, 2, 0)$, $N = 5$.
    Concentration: $C = 3/5$. Fragmentation: $F = 2/5$ (only 2 modes active). -/
def state_3_2_0 : BoseStateRecord :=
  makeBoseRecord [3, 2, 0] [2, 3, 5]

/-! ## 2. Concrete State Instances for $N = 5, g = 3$ -/

/-- State $(2, 0, 3)$ with 5 particles.
    Prime signature: $2^2 \cdot 3^0 \cdot 5^3 = 500$. -/
def state_2_0_3 : BoseStateRecord :=
  makeBoseRecord [2, 0, 3] [2, 3, 5]

/-- Pure condensate in ground mode $(5, 0, 0)$. Prime signature: $2^5 = 32$. -/
def condensate_ground : BoseStateRecord :=
  makeBoseRecord [5, 0, 0] [2, 3, 5]

/-- Pure condensate in second mode $(0, 5, 0)$. Prime signature: $3^5 = 243$. -/
def condensate_second : BoseStateRecord :=
  makeBoseRecord [0, 5, 0] [2, 3, 5]

/-- Pure condensate in third mode $(0, 0, 5)$. Prime signature: $5^5 = 3125$. -/
def condensate_third : BoseStateRecord :=
  makeBoseRecord [0, 0, 5] [2, 3, 5]

/-- Symmetric distributed state $(2, 2, 1)$. Prime signature: $180$. -/
def distributed_symmetric : BoseStateRecord :=
  makeBoseRecord [2, 2, 1] [2, 3, 5]

/-! ## 3. S5: Full Multiplicity Table ($g = 3, N = 1 \dots 20$) -/

structure MultiplicityRow where
  N   : Nat
  g   : Nat
  fd  : Nat
  be  : Nat
  mb  : Nat
  deriving Repr, BEq

def computeRow (N g : Nat) : MultiplicityRow :=
  {
    N  := N
    g  := g
    fd := fermiDiracMultiplicity N g
    be := boseMultiplicity N g
    mb := maxwellBoltzmannMultiplicity N g
  }

/-- Multiplicity table for $g = 3$ and $N \in \{1, \dots, 20\}$. -/
def multiplicityTable_N1_to_N20 : List MultiplicityRow :=
  (List.range 20).map (fun i => computeRow (i + 1) 3)

/-! ## 4. S3: Finite Bose Partition Function (ADR-0037 Interface) -/

/-- Finite partition function evaluation for $g=3$ ($p \in \{2, 3, 5\}$) at $\beta = 2.0$. -/
def finitePartition_g3_beta2 : Float :=
  finiteBosePartition [2, 3, 5] 2.0

end Multiplicity.Bose.Examples
