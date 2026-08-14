#[path = "../src/l0_verification_gate.rs"]
mod l0_verification_gate;

use l0_verification_gate::{L0VerificationGate, ResonanceBufferState};

#[cfg(test)]
mod tests {
    use super::*;

    const VALID_SCHEMA: &str = "SCHEMA_PWEH_V1";
    const REQUIRED_PERMS: u32 = 0x00000001;

    fn get_gate() -> L0VerificationGate {
        L0VerificationGate::new(VALID_SCHEMA, REQUIRED_PERMS)
    }

    #[test]
    fn test_lawful_state_adr003() {
        let gate = get_gate();
        // Weight 30: Autonomy (2) * Governance (3) * Attestation (5)
        let state = ResonanceBufferState {
            session_id: "ADR-003".to_string(),
            proposed_weight: 30,
            schema_hash: VALID_SCHEMA.to_string(),
            permission_bits: REQUIRED_PERMS,
        };

        assert!(gate.verify_state(&state).is_ok());
    }

    #[test]
    fn test_lawful_state_full_compliance() {
        let gate = get_gate();
        // Weight 210: Autonomy (2) * Governance (3) * Attestation (5) * Metric (7)
        let state = ResonanceBufferState {
            session_id: "ADR-FULL".to_string(),
            proposed_weight: 210,
            schema_hash: VALID_SCHEMA.to_string(),
            permission_bits: REQUIRED_PERMS,
        };

        assert!(gate.verify_state(&state).is_ok());
    }

    #[test]
    fn test_adversarial_missing_governance() {
        let gate = get_gate();
        // Weight 10: Autonomy (2) * Attestation (5) -> Missing Governance (3)
        let state = ResonanceBufferState {
            session_id: "ADR-ROGUE-1".to_string(),
            proposed_weight: 10,
            schema_hash: VALID_SCHEMA.to_string(),
            permission_bits: REQUIRED_PERMS,
        };

        let result = gate.verify_state(&state);
        assert!(result.is_err());
        let err_msg = result.unwrap_err().to_string();
        assert!(err_msg.contains("SIG_GOV_KILL"));
        assert!(err_msg.contains("Missing Governance Prime"));
    }

    #[test]
    fn test_adversarial_missing_attestation() {
        let gate = get_gate();
        // Weight 6: Autonomy (2) * Governance (3) -> Missing Attestation (5)
        let state = ResonanceBufferState {
            session_id: "ADR-ROGUE-2".to_string(),
            proposed_weight: 6,
            schema_hash: VALID_SCHEMA.to_string(),
            permission_bits: REQUIRED_PERMS,
        };

        let result = gate.verify_state(&state);
        assert!(result.is_err());
        let err_msg = result.unwrap_err().to_string();
        assert!(err_msg.contains("SIG_GOV_KILL"));
        assert!(err_msg.contains("Missing Attestation Prime"));
    }

    #[test]
    fn test_adversarial_null_state() {
        let gate = get_gate();
        // Weight 1: No tags -> Missing both
        let state = ResonanceBufferState {
            session_id: "ADR-NULL".to_string(),
            proposed_weight: 1,
            schema_hash: VALID_SCHEMA.to_string(),
            permission_bits: REQUIRED_PERMS,
        };

        let result = gate.verify_state(&state);
        assert!(result.is_err());
        let err_msg = result.unwrap_err().to_string();
        assert!(err_msg.contains("SIG_GOV_KILL"));
    }

    #[test]
    fn test_invalid_schema_hash() {
        let gate = get_gate();
        let state = ResonanceBufferState {
            session_id: "ADR-SCHEMA-FAIL".to_string(),
            proposed_weight: 30, // Otherwise valid weight
            schema_hash: "INVALID_HASH".to_string(),
            permission_bits: REQUIRED_PERMS,
        };

        let result = gate.verify_state(&state);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Schema hash mismatch"));
    }

    #[test]
    fn test_invalid_permissions() {
        let gate = get_gate();
        let state = ResonanceBufferState {
            session_id: "ADR-PERM-FAIL".to_string(),
            proposed_weight: 30, // Otherwise valid weight
            schema_hash: VALID_SCHEMA.to_string(),
            permission_bits: 0x00000000, // Missing required bit
        };

        let result = gate.verify_state(&state);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Permission bits rejected"));
    }
}
