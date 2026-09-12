/-
# Hundian Social Physics — Pauli Gate & Multiplicity Theorem

Formal verification of the Pauli exclusion gate, the term-order
fail-closed gate, and the exact multiplicity formula `M = n_unpaired + 1`
underlying ADR-0064 (Hundian Social Physics Occupancy Governance).

This module is the canonical home of the Hundian/Pauli types and
theorems; the `adr_scaffolding/src/ADR/ADR_0064.lean` file has been
decommissioned in favor of this location (ADR-Integral). All proofs
discharged without `sorry`.
-/

import ADR.Core

namespace PhaseMirror.HundianPauli

/-- A Pauli key identifies a unique slot in a degenerate role-class set. -/
structure PauliKey where
  roleClass : String
  slotId    : String
  periodId  : String
  deriving Repr, DecidableEq

/-- Spin tag of a participant occupying a Pauli-keyed slot. -/
inductive SpinTag where
  | alpha | beta
  deriving Repr, DecidableEq, Inhabited

/-- Outcome of the Hundian term-order / Pauli gate. -/
inductive GateResult where
  | okSingle    (sigma : SpinTag)
  | okPair      (sigma : SpinTag)
  | rejUnknownClass
  | rejDualHat
  | rejPauli
  | rejTermOrder
  deriving Repr, DecidableEq

/-- Closed-shell multiplicity rule: every unpaired electron contributes one
multiplicity degree of freedom. For a closed shell, `n_unpaired = 0`,
so `M = 1` (singlet). -/
def calculateMultiplicity (nUnpaired : Nat) : Nat :=
  nUnpaired + 1

theorem half_fill_max_multiplicity (numSlots : Nat) :
    calculateMultiplicity numSlots = numSlots + 1 := by
  rfl

theorem closed_shell_singlet_multiplicity :
    calculateMultiplicity 0 = 1 := by
  rfl

theorem open_shell_multiplicity_two :
    calculateMultiplicity 1 = 2 := by
  rfl

/-- Hundian term-order / Pauli gate evaluation.

`occupantsCount` is the number of occupants already in the role class,
`emptySlotsInD` is the number of empty slots remaining in the degenerate
shell, and `isDegenerate` flags whether the role class is degenerate. -/
def evaluatePauliGate (occupantsCount : Nat) (emptySlotsInD : Nat)
    (isDegenerate : Bool) : GateResult :=
  if occupantsCount > 1 then
    GateResult.rejPauli
  else if occupantsCount == 1 then
    if isDegenerate && emptySlotsInD > 0 then
      GateResult.rejTermOrder
    else
      GateResult.okPair SpinTag.beta
  else
    GateResult.okSingle SpinTag.alpha

/-- Pauli exclusion rejects the third occupant regardless of shell state. -/
theorem pauli_exclusion_rejects_third_occupant
    (emptySlots : Nat) (isDeg : Bool) :
    evaluatePauliGate 2 emptySlots isDeg = GateResult.rejPauli := by
  simp [evaluatePauliGate]

/-- When degenerate slots remain empty, term-order rejects premature pairing. -/
theorem term_order_rejects_pairing_while_slots_empty
    (emptySlots : Nat) (h : emptySlots > 0) :
    evaluatePauliGate 1 emptySlots true = GateResult.rejTermOrder := by
  simp [evaluatePauliGate, h]

/-- When the degenerate shell is full, pairing is permitted. -/
theorem term_order_allows_pairing_when_all_slots_filled :
    evaluatePauliGate 1 0 true = GateResult.okPair SpinTag.beta := by
  simp [evaluatePauliGate]

/-- With zero occupants, the single state is admitted with alpha spin. -/
theorem empty_shell_admits_single_alpha
    (emptySlots : Nat) (isDeg : Bool) :
    evaluatePauliGate 0 emptySlots isDeg = GateResult.okSingle SpinTag.alpha := by
  simp [evaluatePauliGate]

end PhaseMirror.HundianPauli
