/-!
# ADR Test Suite
Extended tests for core invariants, Resonance, and PhaseMirror.
-/

import Lean.Test
import "./Core"
import "./Proofs"
import "./Examples"
import "./Resonance"
import "./PhaseMirror"

open ADR

@[test]
def test_accepted_immutability : Unit := by
  have _ := Proofs.accepted_immutable adr1 adr1 adr1 (by simp) (by simp) (by rfl) (by rfl) (by simp)
  exact Unit.unit

@[test]
def test_no_circular : Unit := by
  have _ := Proofs.no_cycle (List.cons adr1 (List.cons adr2 [])) (by
    intro a ha; cases a <;> simp [Proofs.supersedes_lt] at *; trivial)
  exact Unit.unit

@[test]
def test_consequence_entailed : Unit := by
  have _ := Proofs.consequence_entailment adr1
  exact Unit.unit

@[test]
def test_resonance_eval_allZero : Unit := by
  let rt : ResonanceTerm := { pred := ResonancePredicate.allZero, factor := 1 }
  let exps : List Int := [0, 0, 0]
  have h : evalResonance rt exps = true := by rfl
  exact Unit.unit

@[test]
def test_resonance_apply : Unit := by
  let rt : ResonanceTerm := { pred := ResonancePredicate.sumZero, factor := 2 }
  let exps : List Int := [1, -1]
  let res := applyResonance rt exps
  have : res = [2, -2] := by rfl
  exact Unit.unit

@[test]
def test_resonance_attach : Unit := by
  have h := Proofs.attached_to_accepted_true ({ pred := ResonancePredicate.allZero, factor := 1 }) adr1 (by rfl)
  exact Unit.unit

@[test]
def test_phase_mirror_involutive : Unit := by
  -- trivial mirror that returns same id
  let pm : PhaseMirror := { mirrorId := fun id => id, involutive := by intro id; rfl }
  have h := Proofs.phase_mirror_involutive pm adr1
  exact Unit.unit
