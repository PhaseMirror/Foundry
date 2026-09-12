import Foundations.PMat.Core

/-!
# Foundations.PMat.CompactClosed — Extended Compact-Closed Monomial Matrix Algebra

Extends `Foundations.PMat.Core` with composition, product signature flattening,
and monoidal identity laws.
-/

namespace Foundations.PMat

/-- Flatten a list of signatures into a single joint signature. -/
def prodSigs (ss : List Signature) : Signature := ss.flatten

/-- Theorem: Empty signature is left identity for multiplication. -/
theorem sigMul_empty_left (s : Signature) : sigMul sigEmpty s = s := rfl

/-- Theorem: Empty signature is right identity for multiplication. -/
theorem sigMul_empty_right (s : Signature) : sigMul s sigEmpty = s := by
  dsimp [sigMul, sigEmpty]
  exact List.append_nil s

/-- Theorem: Inverting the empty signature yields the empty signature. -/
theorem sigInv_empty : sigInv sigEmpty = sigEmpty := rfl

/-- Theorem: Flattening an empty list of signatures yields the empty signature. -/
theorem prodSigs_nil : prodSigs [] = sigEmpty := rfl

/-- Theorem: Flattening a singleton list of signatures is identity. -/
theorem prodSigs_singleton (s : Signature) : prodSigs [s] = s := by
  dsimp [prodSigs, sigMul]
  exact List.append_nil s

end Foundations.PMat
