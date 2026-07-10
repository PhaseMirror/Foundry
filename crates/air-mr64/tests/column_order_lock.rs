/// Column order freeze test - ensures air.json matches executor implementation
/// This test MUST fail if column order changes to prevent silent spec drift

use std::fs;
use serde_json::Value;

const EXPECTED_COLUMN_ORDER: [&str; 20] = [
    "round",
    "step",
    "is_round_start",
    "is_mul",
    "is_square",
    "is_end",
    "a",
    "d",
    "s",
    "bit",
    "acc",
    "base",
    "t_lo",
    "t_hi",
    "q",
    "r",
    "mu_lo",
    "mu_hi",
    "hit_nm1",
    "witness_flag",
];

#[test]
fn air_json_column_order_frozen() {
    let air_path = concat!(env!("CARGO_MANIFEST_DIR"), "/../../air.json");
    let contents = fs::read_to_string(air_path)
        .expect("air.json must exist at repository root");
    
    let air: Value = serde_json::from_str(&contents)
        .expect("air.json must be valid JSON");
    
    let columns = air["columns"].as_array()
        .expect("air.json must have 'columns' array");
    
    assert_eq!(
        columns.len(),
        20,
        "air.json must define exactly 20 columns"
    );
    
    // Verify each column name and index matches expected order
    for (i, expected_name) in EXPECTED_COLUMN_ORDER.iter().enumerate() {
        let col = &columns[i];
        let actual_index = col["index"].as_u64().expect("column must have index");
        let actual_name = col["name"].as_str().expect("column must have name");
        
        assert_eq!(
            actual_index as usize,
            i,
            "Column index mismatch at position {}: expected index {}, got {}",
            i, i, actual_index
        );
        
        assert_eq!(
            actual_name,
            *expected_name,
            "Column name mismatch at position {}: expected '{}', got '{}'",
            i, expected_name, actual_name
        );
    }
    
    // Verify frozen flag
    let frozen = air["frozen"].as_bool()
        .expect("air.json must have 'frozen' boolean field");
    
    assert!(
        frozen,
        "air.json must be marked as frozen=true to prevent modifications"
    );
}

#[test]
fn air_json_commitment_scheme_keccak() {
    let air_path = concat!(env!("CARGO_MANIFEST_DIR"), "/../../air.json");
    let contents = fs::read_to_string(air_path).unwrap();
    let air: Value = serde_json::from_str(&contents).unwrap();
    
    let commitment = air["commitment_scheme"].as_str()
        .expect("air.json must specify commitment_scheme");
    
    assert!(
        commitment.contains("Keccak"),
        "commitment_scheme must use Keccak256, got: {}",
        commitment
    );
    
    let transcript = air["transcript_hash"].as_str()
        .expect("air.json must specify transcript_hash");
    
    assert!(
        transcript.contains("Keccak"),
        "transcript_hash must use Keccak256, got: {}",
        transcript
    );
}
