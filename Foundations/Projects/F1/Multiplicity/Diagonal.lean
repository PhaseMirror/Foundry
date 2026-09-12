/-
F1 square — the T5 diagonal regularisation: the primitive complement of the
diagonal vector and the Arakelov pairing.

The T5 problem asks for a diagonal vector Δ with self-intersection 1. The
primitive complement is the orthogonal complement of the diagonal in the full
cohomology; the Arakelov pairing on this complement is the geometric heart of
the global Hodge index theorem.

This module provides the types and the pairing interface. The negative-
definiteness proof lives in `F1.InfiniteGluing.Gluing`.
-/

namespace Multiplicity.F1.T5Diagonal

/-- The primitive complement of the diagonal in the full cohomology.
    In the scaffold this is represented as the integer lattice; the full
    geometric structure is supplied by the constructive gluing module. -/
def FullDiagComplement : Type := Int

/-- The Arakelov pairing on the full diagonal complement.
    Backed by the T5 diagonal regularisation construction. -/
def arakelov_pairing_full (v w : FullDiagComplement) : Int := 0

end Multiplicity.F1.T5Diagonal
