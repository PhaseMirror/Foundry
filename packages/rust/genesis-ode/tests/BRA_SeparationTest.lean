# tests/BRA_SeparationTest.lean

import «GenesisODE».BRA_Telemetry
import «GenesisODE».Builder

-- Simple internal reconstruction word (no external operators, represented by even ids)
def internalWord : List Nat := [0, 2, 4]
-- Overlay reconstruction word (contains external operators, represented by odd ids)
def overlayWord  : List Nat := [1, 3, 5]

def internalCost : Real := ShrapnelMap.computeCost internalWord
def overlayCost  : Real := ShrapnelMap.computeCost overlayWord

#eval internalCost   -- expected: 3.0 (length) + 0 (r) + 0 (q) = 3.0
#eval overlayCost    -- expected: 3.0 + r (≈2) + q (3) = 8.0 (approx)

-- Boolean check that internal cost is strictly less than overlay cost
#eval internalCost < overlayCost
