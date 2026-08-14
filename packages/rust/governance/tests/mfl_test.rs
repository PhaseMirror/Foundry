use governance_core_rs::mfl::*;

#[test]
fn test_classify_lambda_band() {
    assert_eq!(classify_lambda_band(0.1, 0.33, 0.66).unwrap(), "quiet");
    assert_eq!(classify_lambda_band(0.4, 0.33, 0.66).unwrap(), "amber");
    assert_eq!(classify_lambda_band(0.7, 0.33, 0.66).unwrap(), "red");
}

#[test]
fn test_clamp_mode() {
    assert_eq!(clamp_mode("full", Some("to_advisory")).unwrap(), "advisory");
    assert_eq!(clamp_mode("advisory", Some("full")).unwrap(), "advisory"); // stricter of two
    assert_eq!(clamp_mode("suspended", Some("full")).unwrap(), "suspended");
}

#[test]
fn test_derive_allowed_set() {
    let baseline = vec!["a".to_string(), "b".to_string(), "c".to_string()];
    let mut blocked = std::collections::HashSet::new();
    blocked.insert("b".to_string());
    
    let allowed = derive_allowed_set(&baseline, &blocked);
    assert_eq!(allowed.len(), 2);
    assert!(allowed.contains("a"));
    assert!(allowed.contains("c"));
    assert!(!allowed.contains("b"));
}
