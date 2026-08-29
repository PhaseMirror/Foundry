import Init

/-! # HCQA — Core Types

Formalizes foundational types for the Universal Atomic Calculator (UAC):
qudit dimensions, nuclear spin manifolds, hyperfine subspaces, and basic
quantet/hardware primitives.
-/

namespace HCQA.Core

open Nat

/-- Qudit dimension d = 2(2I + 1) for nuclear spin I. -/
def quditDim (I : Nat) : Nat := 2 * (2 * I + 1)

/-- Number of hyperfine levels for a qudit. -/
def hyperfineLevels (I : Nat) : Nat := quditDim I

/-- Computational subspace size (m < d). -/
def computationalDim (d m : Nat) : Prop := m <= d

/-- Syndrome subspace size = d - m. -/
def syndromeDim (d m : Nat) : Nat := d - m

/-- Atom species type with nuclear spin I. -/
structure AtomSpecies where
  name : String
  nuclearSpin : Nat  -- I
  deriving Repr

/-- Qudit state vector index. -/
structure QuditState where
  species : AtomSpecies
  level : Nat
  deriving Repr

/-- Subspace partition: computational vs syndrome. -/
structure SubspacePartition where
  totalDim : Nat
  compDim : Nat
  synDim : Nat
  deriving Repr

/-- HSEC encoding: allocate m computational + (d-m) syndrome levels. -/
structure HSECEncoding where
  quditDim : Nat
  compLevels : Nat
  synLevels : Nat
  deriving Repr

/-- Verified core properties. -/
theorem syndrome_dim_positive (d m : Nat) (h : m < d) : syndromeDim d m > 0 := by
  unfold syndromeDim
  have : d - m > 0 := by omega
  exact this

/-- Example HSEC encodings (not theorems, just definitions). -/
def hs_87Sr : HSECEncoding := {
  quditDim := 20
  compLevels := 16
  synLevels := 4
}

def hs_171Yb : HSECEncoding := {
  quditDim := 4
  compLevels := 2
  synLevels := 2
}

end HCQA.Core
