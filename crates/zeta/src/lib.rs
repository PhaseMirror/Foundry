pub mod conflict_log;
pub mod evaluation_order;

pub use conflict_log::*;
pub use evaluation_order::*;

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;
    use tempfile::tempdir;

    #[test]
    fn test_conflict_entry_validation() {
        let entry = ConflictEntry::new(
            ConflictType::SafetyVeto,
            5,
            vec!["Z-RANDOMGEN".to_string()],
            vec!["1.0".to_string()],
            5,
            "HALT".to_string(),
            None,
            false,
            true,
        ).unwrap();
        assert!(entry.validate().is_ok());

        // Missing pipeline_halted for SafetyVeto
        let mut entry = entry;
        entry.pipeline_halted = false;
        assert!(entry.validate().is_err());
    }

    #[test]
    fn test_tier_precedence() {
        assert_eq!(tier_precedence(Tier::Spectral, Tier::Safety), Tier::Spectral);
        assert_eq!(tier_precedence(Tier::Predictive, Tier::Structural), Tier::Structural);
    }

    #[test]
    fn test_check_safety_veto() {
        let mut meta = HashMap::new();
        meta.insert("semantic_class".to_string(), serde_json::json!("safety"));
        meta.insert("safety_veto".to_string(), serde_json::json!(true));
        assert!(check_safety_veto(&meta));

        meta.insert("safety_veto".to_string(), serde_json::json!(false));
        assert!(!check_safety_veto(&meta));
    }
}
