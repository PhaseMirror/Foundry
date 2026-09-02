/-!
# Prime Tensors: CPIRTM (Contractive PIRTM)

Formal specification of the Contractive Prime-Indexed Resonance
Tensor Machine (CPIRTM) framework, integrating Sedona Spine
contractivity mandates with prime-indexed state transitions.

Self-contained in Lean 4 Core (Mathlib-Free).
-/

namespace prime_tensors.CPIRTM

/-! ## Contractivity Metric -/

/-- Discrete metric on prime-indexed configurations: count of differing indices. -/
def configDist (s1 s2 : List Nat) : Nat :=
  (s1.filter (fun p => p ∈ s2)).length + (s2.filter (fun p => p ∉ s1)).length

/-- A CPIRTM operator is contractive if it does not increase configuration distance. -/
def IsContractive (op : List Nat → List Nat) : Prop :=
  ∀ s1 s2, configDist (op s1) (op s2) ≤ configDist s1 s2

/-! ## CPIRTM Kernel -/

/-- A CPIRTM kernel pairs a transition operator with its contractivity proof. -/
structure CPIRTMKernel where
  op : List Nat → List Nat
  contractive : IsContractive op

/-- Construct a CPIRTM kernel from a contractive operator. -/
def mkCPIRTM (op : List Nat → List Nat) (h : IsContractive op) : CPIRTMKernel :=
  { op := op, contractive := h }

/-- Identity is contractive. -/
theorem id_contractive : IsContractive (fun s => s) := by
  unfold IsContractive
  intro s1 s2
  unfold configDist
  simp

end prime_tensors.CPIRTM
