use mtpi_rs::{
    MTPICertifier, CertifyInput, CertifierConfig, DefaultDependencies,
    SubjectValue, Verdict, FailureCode
};
use serde_json::json;

#[tokio::test]
async fn test_certifier_basic_compliance() {
    let config = CertifierConfig::default();
    let deps = Box::new(DefaultDependencies);
    let certifier = MTPICertifier::new(config, deps);

    let intent_object = json!({ "action": "route", "amount": 10, "asset": "ETH" });
    let policy_rules = json!({ "max": 100, "jurisdiction": "global" });
    let ltrace = json!({
        "traceId": "trace-1",
        "eventCount": 2,
        "rootHash": "root-hash",
        "eventsDigest": "events-digest"
    });

    let subject_id_hash = "0x123456:999";
    
    let token = json!({
        "tokenId": "tok-1",
        "systemId": "sys-1",
        "issuerPublicKey": "pk",
        "signature": "sig",
        "nbf": 0,
        "exp": 9999999999u64,
        "subjectIdHash": subject_id_hash,
        "intentHash": "placeholder",
        "policyBundleHash": "placeholder",
        "ltraceRef": "placeholder",
        "nullifier": "n1"
    });

    let input = CertifyInput {
        token,
        ltrace,
        epoch_index: 2,
        drift_value: 0.1,
        subject_secret: SubjectValue::U64(123456),
        subject_salt: SubjectValue::U64(999),
        intent_object,
        policy_rules,
        policy_version: "1.0.0".to_string(),
        policy_issued_at: 1700000000,
        rights_material: false,
        domain_matches: false,
        amber_blocked_actions: None,
    };

    let report = certifier.certify(input).await;

    assert_eq!(report.verdict, Verdict::NonCompliant);
    assert!(report.failure_codes.contains(&FailureCode::IntentMismatch));
}

#[tokio::test]
async fn test_prime_gate() {
    let config = CertifierConfig::default();
    let deps = Box::new(DefaultDependencies);
    let certifier = MTPICertifier::new(config, deps);

    let token = json!({
        "tokenId": "tok-1",
        "systemId": "sys-1",
        "issuerPublicKey": "pk",
        "signature": "sig",
        "nbf": 0,
        "exp": 9999999999u64,
        "subjectIdHash": "h1",
        "intentHash": "h2",
        "policyBundleHash": "h3",
        "ltraceRef": "h4",
        "nullifier": "n1"
    });

    let input = CertifyInput {
        token: token.clone(),
        ltrace: json!({
            "traceId": "t",
            "eventCount": 0,
            "rootHash": "r",
            "eventsDigest": "d"
        }),
        epoch_index: 4, // Not prime
        drift_value: 0.1,
        subject_secret: SubjectValue::U64(1),
        subject_salt: SubjectValue::U64(2),
        intent_object: json!({}),
        policy_rules: json!({}),
        policy_version: "1".to_string(),
        policy_issued_at: 1,
        rights_material: false,
        domain_matches: false,
        amber_blocked_actions: None,
    };

    let report = certifier.certify(input).await;
    assert_eq!(report.verdict, Verdict::Silent);
    assert!(report.failure_codes.contains(&FailureCode::PrimeGateClosed));
}
