/-!
# Foundations.EchoBraid.Core — Multi-Strand Braid Coherence & Invariants
-/

namespace Foundations.EchoBraid

inductive BraidGenerator where
  | sigma (i : Nat)
  | sigmaInv (i : Nat)
  deriving Repr, DecidableEq

abbrev BraidWord := List BraidGenerator

def braidLength (w : BraidWord) : Nat :=
  w.length

def isPureIdentity (w : BraidWord) : Bool :=
  w.isEmpty

def invertGenerator : BraidGenerator → BraidGenerator
  | BraidGenerator.sigma i => BraidGenerator.sigmaInv i
  | BraidGenerator.sigmaInv i => BraidGenerator.sigma i

def invertWord (w : BraidWord) : BraidWord :=
  (w.map invertGenerator).reverse

theorem invert_involutive (g : BraidGenerator) :
    invertGenerator (invertGenerator g) = g := by
  cases g <;> rfl

theorem invert_length (w : BraidWord) :
    braidLength (invertWord w) = braidLength w := by
  unfold invertWord braidLength
  simp [List.length_reverse, List.length_map]

end Foundations.EchoBraid
