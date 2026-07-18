import ADR.Core
import ADR.Proofs
import ADR.Examples
import ADR.Resonance
import ADR.PhaseMirror
import ADR.Dissonance

open ADR

/-! ## Core Invariant Tests -/

-- @[test]
-- def test_accepted_immutability : Unit := by
--   have _ := Proofs.accepted_immutable adr1 adr1 adr1 (by simp) (by simp) (by rfl) (by rfl) (by simp)
--   exact Unit.unit

-- @[test]
-- def test_consequence_entailed : Unit := by
--   have _ := Proofs.accepted_immutable adr1 adr1 adr1 (by simp) (by simp) (by rfl) (by rfl) (by simp)
--   exact Unit.unit

/-! ## Resonance Tests -/

-- @[test]
-- def test_resonance_eval_allZero : Unit := by
--   let rt : ResonanceTerm := { pred := ResonancePredicate.allZero, factor := 1 }
--   let exps : List Int := [0, 0, 0]
--   have h : evalResonance rt exps = true := by rfl
--   exact Unit.unit

-- @[test]
-- def test_resonance_apply : Unit := by
--   let rt : ResonanceTerm := { pred := ResonancePredicate.sumZero, factor := 2 }
--   let exps : List Int := [1, -1]
--   let res := applyResonance rt exps
--   have : res = [2, -2] := by rfl
--   exact Unit.unit

-- @[test]
-- def test_resonance_attach : Unit := by
--   have h := Proofs.attached_to_accepted_true ({ pred := ResonancePredicate.allZero, factor := 1 }) adr1 (by rfl)
--   exact Unit.unit

/-! ## PhaseMirror Tests -/

-- @[test]
-- def test_phase_mirror_involutive : Unit := by
--   let pm : PhaseMirror := { mirrorId := fun id => id, involutive := by intro id; rfl }
--   have h := Proofs.phase_mirror_involutive pm adr1
--   exact Unit.unit

/-! ## Dissonance Tests -/

-- @[test]
-- def test_severity_to_risk_monotone : Unit := by
--   have h1 : Dissonance.severityToRisk Dissonance.Severity.Critical = RiskLevel.Critical := by rfl
--   have h2 : Dissonance.severityToRisk Dissonance.Severity.High = RiskLevel.High := by rfl
--   have h3 : Dissonance.severityToRisk Dissonance.Severity.Medium = RiskLevel.Medium := by rfl
--   have h4 : Dissonance.severityToRisk Dissonance.Severity.Low = RiskLevel.Low := by rfl
--   exact Unit.unit

-- @[test]
-- def test_risk_to_severity_monotone : Unit := by
--   have h1 : Dissonance.riskToSeverity RiskLevel.Critical = Dissonance.Severity.Critical := by rfl
--   have h2 : Dissonance.riskToSeverity RiskLevel.High = Dissonance.Severity.High := by rfl
--   have h3 : Dissonance.riskToSeverity RiskLevel.Medium = Dissonance.Severity.Medium := by rfl
--   have h4 : Dissonance.riskToSeverity RiskLevel.Low = Dissonance.Severity.Low := by rfl
--   exact Unit.unit

-- @[test]
-- def test_dissonant_adr_idempotent : Unit := by
--   let da := Dissonance.mkDissonantADR adr1
--   let da2 := Dissonance.attach_conflict da {
--     receipt_hash := "x", r_sc := 0, l_eff := 0, tau_r := 0, breach_type := "None", timestamp := 0
--   } Dissonance.Severity.Low
--   have h : da2.adr.id = da.adr.id := by rfl
--   exact Unit.unit

-- @[test]
-- def test_attach_preserves_adr_id : Unit := by
--   let da := Dissonance.mkDissonantADR adr1
--   let entry : Dissonance.ConflictLogEntry := {
--     receipt_hash := "abc", r_sc := 0, l_eff := 0, tau_r := 0, breach_type := "None", timestamp := 0
--   }
--   have h : (Dissonance.attach_conflict da entry Dissonance.Severity.Low).adr.id = da.adr.id := by rfl
--   exact Unit.unit

-- @[test]
-- def test_trip_preserves_adr : Unit := by
--   let da := Dissonance.mkDissonantADR adr1
--   have h : (Dissonance.trip_breaker da 42).adr = da.adr := by rfl
--   exact Unit.unit

-- @[test]
-- def test_accepted_immutable_with_dissonance : Unit := by
--   let da := Dissonance.mkDissonantADR adr1
--   let entry : Dissonance.ConflictLogEntry := {
--     receipt_hash := "abc", r_sc := 0, l_eff := 0, tau_r := 0, breach_type := "None", timestamp := 0
--   }
--   have h : (Dissonance.attach_conflict da entry Dissonance.Severity.Low).adr.status = ADRStatus.Accepted := by
--     apply Dissonance.accepted_immutable_with_dissonance
--     rfl
--   exact Unit.unit

-- @[test]
-- def test_phase_mirror_dissonance_involutive : Unit := by
--   let pm : PhaseMirror := { mirrorId := fun id => id, involutive := by intro id; rfl }
--   let da := Dissonance.mkDissonantADR adr1
--   have h := Dissonance.phase_mirror_dissonance_involutive pm da
--   exact Unit.unit

-- @[test]
-- def test_initial_traceable : Unit := by
--   have h := Dissonance.initial_traceable adr1
--   exact Unit.unit

-- @[test]
-- def test_conflict_log_traceable : Unit := by
--   let da := Dissonance.mkDissonantADR adr1
--   have h : Dissonance.conflict_log_traceable da := by
--     apply Dissonance.initial_traceable
--   exact Unit.unit

/-! ## Identity Integration Tests -/

-- @[test]
-- def test_identity_system_type_check : Unit := by
--   let sys : MOC.Identity.IdentitySystem Unit := MOC.Identity.emptyIdentitySystem
--   exact Unit.unit

-- @[test]
-- def test_prime_moc_type_check : Unit := by
--   let p2 : MOC.Identity.PrimeMoc := MOC.Identity.primeMoc2
--   let p3 : MOC.Identity.PrimeMoc := MOC.Identity.primeMoc3
--   exact Unit.unit
