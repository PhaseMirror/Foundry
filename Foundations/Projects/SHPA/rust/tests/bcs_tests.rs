use shpa::bcs::BcsSerializer;

#[test]
fn test_uleb128_roundtrip() {
    let test_values = [0, 1, 127, 128, 255, 300, 16384, 2097151, 100000000];
    for &val in &test_values {
        let encoded = BcsSerializer::uleb128_encode(val);
        let (decoded, read_len) = BcsSerializer::uleb128_decode(&encoded).expect("Decode failed");
        assert_eq!(val, decoded);
        assert_eq!(encoded.len(), read_len);
    }
}

#[test]
fn test_bcs_operator_determinism() {
    let schema_ref = [0x01; 32];
    let activation_fn = [0x02; 32];

    let bytes1 = BcsSerializer::serialize_operator(&schema_ref, 3, 500, &activation_fn, 2);
    let bytes2 = BcsSerializer::serialize_operator(&schema_ref, 3, 500, &activation_fn, 2);
    assert_eq!(bytes1, bytes2);

    let hash1 = BcsSerializer::compute_operator_hash(&bytes1);
    let hash2 = BcsSerializer::compute_operator_hash(&bytes2);
    assert_eq!(hash1, hash2);
}
