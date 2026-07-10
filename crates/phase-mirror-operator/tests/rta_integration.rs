use reqwest;
use serde_json::Value;

#[tokio::test]
async fn test_rta_health_endpoint_returns_valid_data() {
    // Assumes the operator is running locally on port 8080
    let resp = reqwest::get("http://localhost:8080/audit/v1/test_operator/rta/health")
        .await
        .expect("Failed to query health endpoint");
    assert_eq!(resp.status(), 200);
    let body: Value = resp.json().await.unwrap();
    assert!(body["arta_defect"].as_f64().is_some());
    assert!(body["rta_dist_to_bindu"].as_f64().is_some());
    assert!(body["timestamp"].as_u64().is_some());
}

#[tokio::test]
async fn test_rta_history_endpoint_returns_time_series() {
    let resp = reqwest::get("http://localhost:8080/audit/v1/test_operator/rta/history")
        .await
        .expect("Failed to query history endpoint");
    assert_eq!(resp.status(), 200);
    let history: Vec<Value> = resp.json().await.unwrap();
    // After running test fixtures, history should have at least one entry
    assert!(!history.is_empty());
    // Check each entry has required fields
    for entry in &history {
        assert!(entry["arta_defect"].as_f64().is_some());
        assert!(entry["rta_dist_to_bindu"].as_f64().is_some());
    }
}

#[tokio::test]
async fn test_witness_includes_rta_fields() {
    // First, we need a witness to query; the valid-deploy fixture should generate one.
    // Get the list of transitions and pick the first witness.
    let resp = reqwest::get("http://localhost:8080/audit/v1/test_operator/transitions")
        .await.unwrap();
    let list: Value = resp.json().await.unwrap();
    let transitions = list["transitions"].as_array().expect("No transitions");
    assert!(!transitions.is_empty());
    let witness = &transitions[0];
    assert!(witness["arta_defect_before"].as_f64().is_some());
    assert!(witness["arta_defect_after"].as_f64().is_some());
    assert!(witness["rta_dist_to_bindu"].as_f64().is_some());
}
