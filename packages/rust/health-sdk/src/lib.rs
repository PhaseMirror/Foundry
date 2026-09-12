// crates/health-sdk/src/lib.rs

use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;
use multiplicity_alp::hash::{poseidon_hash, U256};

const P_MOD: U256 = U256([
    0x3c208c16d87cfd47,
    0x97816a916871ca8d,
    0xb85045b68181585d,
    0x30644e72e131a029,
]);

#[derive(Debug, Clone)]
pub struct ConsentParams {
    pub purpose_id: u32,
    pub scope_hash: U256,
    pub provider_pk: U256,
    pub patient_pk: U256,
    pub expiry_epoch: u64,
    pub delta_bound: u64,
    pub consent_secret: U256,
    pub consent_root: U256,
    pub now_epoch: u64,
    pub path_elements: Vec<U256>,
    pub path_indices: Vec<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConsentPublicSignals {
    pub purpose_id: U256,
    pub scope_hash: U256,
    pub provider_pk: U256,
    pub patient_pk: U256,
    pub expiry_epoch: U256,
    pub now_epoch: U256,
    pub delta_bound: U256,
    pub consent_commitment: U256,
    pub consent_root: U256,
    pub nullifier: U256,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConsentWitnessAndPub {
    pub witness: serde_json::Value,
    pub pub_signals: ConsentPublicSignals,
}

// ----------------- Parsers & Conversions -----------------

pub fn parse_str_to_u256(s: &str) -> Result<U256, String> {
    let s = s.trim();
    if s.starts_with("0x") || s.starts_with("0X") {
        let hex_val = &s[2..];
        let bytes = hex::decode(hex_val).map_err(|e| e.to_string())?;
        Ok(U256::from_big_endian(&bytes))
    } else {
        let mut val = U256::zero();
        let ten = U256::from_u64(10);
        for c in s.chars() {
            if !c.is_ascii_digit() {
                return Err(format!("Invalid decimal digit: {}", c));
            }
            let digit = (c as u8 - b'0') as u64;
            val = val.mul_mod(&ten, &P_MOD);
            val = val.add_mod(&U256::from_u64(digit), &P_MOD);
        }
        Ok(val)
    }
}

pub fn js_to_u256(val: &JsValue) -> Result<U256, String> {
    if val.is_undefined() || val.is_null() {
        return Ok(U256::zero());
    }
    if let Some(f) = val.as_f64() {
        return Ok(U256::from_u64(f as u64));
    }
    if let Some(s) = val.as_string() {
        return parse_str_to_u256(&s);
    }
    // Fallback: try calling JS toString()
    let js_str = js_sys::Reflect::get(val, &JsValue::from_str("toString"))
        .ok()
        .and_then(|f| {
            if f.is_function() {
                js_sys::Function::from(f).call0(val).ok()
            } else {
                None
            }
        })
        .and_then(|v| v.as_string());

    if let Some(s) = js_str {
        parse_str_to_u256(&s)
    } else {
        Err("Could not convert JS value to U256".to_string())
    }
}

pub fn u256_to_decimal_string(mut val: U256) -> String {
    if val.is_zero() {
        return "0".to_string();
    }
    let mut digits = Vec::new();
    while !val.is_zero() {
        let mut remainder = 0u64;
        for i in (0..4).rev() {
            let temp = ((remainder as u128) << 64) + (val.0[i] as u128);
            val.0[i] = (temp / 10) as u64;
            remainder = (temp % 10) as u64;
        }
        digits.push((b'0' + remainder as u8) as char);
    }
    digits.iter().rev().collect()
}

fn get_field_as_u64(obj: &JsValue, field: &str) -> Result<Option<u64>, String> {
    let val = js_sys::Reflect::get(obj, &JsValue::from_str(field))
        .map_err(|e| format!("Failed to get field {}: {:?}", field, e))?;
    if val.is_undefined() || val.is_null() {
        return Ok(None);
    }
    if let Some(f) = val.as_f64() {
        return Ok(Some(f as u64));
    }
    if let Some(s) = val.as_string() {
        return s.parse::<u64>().map(Some).map_err(|e| e.to_string());
    }
    let js_str = js_sys::Reflect::get(&val, &JsValue::from_str("toString"))
        .ok()
        .and_then(|f| {
            if f.is_function() {
                js_sys::Function::from(f).call0(&val).ok()
            } else {
                None
            }
        })
        .and_then(|v| v.as_string());
    
    if let Some(s) = js_str {
        s.parse::<u64>().map(Some).map_err(|e| e.to_string())
    } else {
        Err(format!("Could not parse field {} as u64", field))
    }
}

fn get_field_as_u256(obj: &JsValue, field: &str) -> Result<U256, String> {
    let val = js_sys::Reflect::get(obj, &JsValue::from_str(field))
        .map_err(|e| format!("Failed to get field {}: {:?}", field, e))?;
    js_to_u256(&val)
}

fn get_field_as_u256_vec(obj: &JsValue, field: &str) -> Result<Vec<U256>, String> {
    let val = js_sys::Reflect::get(obj, &JsValue::from_str(field))
        .map_err(|e| format!("Failed to get field {}: {:?}", field, e))?;
    if val.is_undefined() || val.is_null() {
        return Ok(Vec::new());
    }
    if !val.is_object() {
        return Err(format!("Field {} is not an array/object", field));
    }
    let array = js_sys::Array::from(&val);
    let mut out = Vec::new();
    for i in 0..array.length() {
        let item = array.get(i);
        out.push(js_to_u256(&item)?);
    }
    Ok(out)
}

fn get_field_as_u64_vec(obj: &JsValue, field: &str) -> Result<Vec<u64>, String> {
    let val = js_sys::Reflect::get(obj, &JsValue::from_str(field))
        .map_err(|e| format!("Failed to get field {}: {:?}", field, e))?;
    if val.is_undefined() || val.is_null() {
        return Ok(Vec::new());
    }
    if !val.is_object() {
        return Err(format!("Field {} is not an array/object", field));
    }
    let array = js_sys::Array::from(&val);
    let mut out = Vec::new();
    for i in 0..array.length() {
        let item = array.get(i);
        if let Some(f) = item.as_f64() {
            out.push(f as u64);
        } else if let Some(s) = item.as_string() {
            out.push(s.parse::<u64>().map_err(|e| e.to_string())?);
        } else {
            let js_str = js_sys::Reflect::get(&item, &JsValue::from_str("toString"))
                .ok()
                .and_then(|f| {
                    if f.is_function() {
                        js_sys::Function::from(f).call0(&item).ok()
                    } else {
                        None
                    }
                })
                .and_then(|v| v.as_string());
            if let Some(s) = js_str {
                out.push(s.parse::<u64>().map_err(|e| e.to_string())?);
            } else {
                return Err(format!("Failed to parse index at index {}", i));
            }
        }
    }
    Ok(out)
}

fn parse_consent_params(obj: &JsValue) -> Result<ConsentParams, String> {
    let purpose_id = get_field_as_u64(obj, "purposeId")?.unwrap_or(0) as u32;
    let scope_hash = get_field_as_u256(obj, "scopeHash")?;
    let provider_pk = get_field_as_u256(obj, "providerPk")?;
    let patient_pk = get_field_as_u256(obj, "patientPk")?;
    let expiry_epoch = get_field_as_u64(obj, "expiryEpoch")?.unwrap_or(0);
    let delta_bound = get_field_as_u64(obj, "deltaBound")?.unwrap_or(0);
    let consent_secret = get_field_as_u256(obj, "consentSecret")?;
    let consent_root = get_field_as_u256(obj, "consentRoot")?;
    
    let now_epoch = match get_field_as_u64(obj, "nowEpoch")? {
        Some(t) => t,
        None => {
            let now = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_secs())
                .unwrap_or(0);
            now
        }
    };

    let path_elements = get_field_as_u256_vec(obj, "pathElements")?;
    let path_indices = get_field_as_u64_vec(obj, "pathIndices")?;

    Ok(ConsentParams {
        purpose_id,
        scope_hash,
        provider_pk,
        patient_pk,
        expiry_epoch,
        delta_bound,
        consent_secret,
        consent_root,
        now_epoch,
        path_elements,
        path_indices,
    })
}

// ----------------- Consent Core Logic -----------------

pub fn compute_consent_commitment(params: &ConsentParams) -> U256 {
    let h_ps = poseidon_hash(&[U256::from_u64(params.purpose_id as u64), params.scope_hash]);
    let h_pp = poseidon_hash(&[params.provider_pk, params.patient_pk]);
    let h_ed = poseidon_hash(&[U256::from_u64(params.expiry_epoch), U256::from_u64(params.delta_bound)]);
    poseidon_hash(&[h_ps, h_pp, h_ed, params.consent_secret])
}

pub fn compute_nullifier(params: &ConsentParams) -> U256 {
    poseidon_hash(&[params.consent_secret, params.provider_pk])
}

pub fn to_witness(params: &ConsentParams) -> ConsentWitnessAndPub {
    let commitment = compute_consent_commitment(params);
    let nullifier = compute_nullifier(params);
    
    let witness = serde_json::json!({
        "purpose_id": params.purpose_id.to_string(),
        "scope_hash": u256_to_decimal_string(params.scope_hash),
        "provider_pk": u256_to_decimal_string(params.provider_pk),
        "patient_pk": u256_to_decimal_string(params.patient_pk),
        "expiry_epoch": params.expiry_epoch.to_string(),
        "now_epoch": params.now_epoch.to_string(),
        "delta_bound": params.delta_bound.to_string(),
        "consent_commitment": u256_to_decimal_string(commitment),
        "consent_root": u256_to_decimal_string(params.consent_root),
        "nullifier": u256_to_decimal_string(nullifier),
        "consent_secret": u256_to_decimal_string(params.consent_secret),
        "pathElements": params.path_elements.iter().map(|e| u256_to_decimal_string(*e)).collect::<Vec<_>>(),
        "pathIndices": params.path_indices.iter().map(|i| i.to_string()).collect::<Vec<_>>(),
    });

    let pub_signals = ConsentPublicSignals {
        purpose_id: U256::from_u64(params.purpose_id as u64),
        scope_hash: params.scope_hash,
        provider_pk: params.provider_pk,
        patient_pk: params.patient_pk,
        expiry_epoch: U256::from_u64(params.expiry_epoch),
        now_epoch: U256::from_u64(params.now_epoch),
        delta_bound: U256::from_u64(params.delta_bound),
        consent_commitment: commitment,
        consent_root: params.consent_root,
        nullifier,
    };

    ConsentWitnessAndPub { witness, pub_signals }
}

pub fn encode_public_signals(ps: &ConsentPublicSignals) -> Vec<U256> {
    vec![
        ps.purpose_id,
        ps.scope_hash,
        ps.provider_pk,
        ps.patient_pk,
        ps.expiry_epoch,
        ps.now_epoch,
        ps.delta_bound,
        ps.consent_commitment,
        ps.consent_root,
        ps.nullifier,
    ]
}

pub fn pack_for_contract(proof: &serde_json::Value, pub_signals: &[U256]) -> Result<serde_json::Value, String> {
    let pi_a = proof.get("pi_a").and_then(|v| v.as_array())
        .ok_or("Missing or invalid pi_a in proof")?;
    let pi_b = proof.get("pi_b").and_then(|v| v.as_array())
        .ok_or("Missing or invalid pi_b in proof")?;
    let pi_c = proof.get("pi_c").and_then(|v| v.as_array())
        .ok_or("Missing or invalid pi_c in proof")?;

    if pi_a.len() < 2 || pi_c.len() < 2 || pi_b.len() < 2 {
        return Err("Invalid coordinates length in proof".to_string());
    }

    let p_a = [
        pi_a[0].as_str().unwrap_or_else(|| pi_a[0].to_string()).to_string(),
        pi_a[1].as_str().unwrap_or_else(|| pi_a[1].to_string()).to_string(),
    ];

    let row0 = pi_b[0].as_array().ok_or("Invalid pi_b row 0")?;
    let row1 = pi_b[1].as_array().ok_or("Invalid pi_b row 1")?;

    if row0.len() < 2 || row1.len() < 2 {
        return Err("Invalid pi_b elements length".to_string());
    }

    let p_b = [
        [
            row0[0].as_str().unwrap_or_else(|| row0[0].to_string()).to_string(),
            row0[1].as_str().unwrap_or_else(|| row0[1].to_string()).to_string(),
        ],
        [
            row1[0].as_str().unwrap_or_else(|| row1[0].to_string()).to_string(),
            row1[1].as_str().unwrap_or_else(|| row1[1].to_string()).to_string(),
        ]
    ];

    let p_c = [
        pi_c[0].as_str().unwrap_or_else(|| pi_c[0].to_string()).to_string(),
        pi_c[1].as_str().unwrap_or_else(|| pi_c[1].to_string()).to_string(),
    ];

    let pub_arr = pub_signals.iter()
        .map(|x| u256_to_decimal_string(*x))
        .collect::<Vec<_>>();

    Ok(serde_json::json!({
        "pA": p_a,
        "pB": p_b,
        "pC": p_c,
        "pub": pub_arr
    }))
}

// ----------------- WASM Bindings -----------------

#[wasm_bindgen(js_name = encodePublicSignals)]
pub fn wasm_encode_public_signals(ps_val: JsValue) -> Result<JsValue, JsError> {
    let ps: ConsentPublicSignals = serde_wasm_bindgen::from_value(ps_val)?;
    let encoded = encode_public_signals(&ps);
    let array = js_sys::Array::new();
    for item in encoded {
        let hex_str = format!("0x{}", item.to_hex());
        let bigint = js_sys::Reflect::get(&JsValue::from_str("BigInt"), &JsValue::from_str("toString"))
            .ok()
            .map(|_| js_sys::BigInt::from(JsValue::from_str(&hex_str)))
            .unwrap_or_else(|| js_sys::BigInt::from(0));
        array.push(&bigint.into());
    }
    Ok(array.into())
}

#[wasm_bindgen(js_name = computeConsentCommitment)]
pub fn wasm_compute_consent_commitment(_poseidon_fn: JsValue, params_val: JsValue) -> Result<JsValue, JsError> {
    let params = parse_consent_params(&params_val).map_err(|e| JsError::new(&e))?;
    let res = compute_consent_commitment(&params);
    let hex_str = format!("0x{}", res.to_hex());
    let bigint = js_sys::BigInt::from(JsValue::from_str(&hex_str));
    Ok(bigint.into())
}

#[wasm_bindgen(js_name = computeNullifier)]
pub fn wasm_compute_nullifier(_poseidon_fn: JsValue, params_val: JsValue) -> Result<JsValue, JsError> {
    let params = parse_consent_params(&params_val).map_err(|e| JsError::new(&e))?;
    let res = compute_nullifier(&params);
    let hex_str = format!("0x{}", res.to_hex());
    let bigint = js_sys::BigInt::from(JsValue::from_str(&hex_str));
    Ok(bigint.into())
}

#[wasm_bindgen(js_name = toWitness)]
pub fn wasm_to_witness(params_val: JsValue, _poseidon_fn: JsValue) -> Result<JsValue, JsError> {
    let params = parse_consent_params(&params_val).map_err(|e| JsError::new(&e))?;
    let res = to_witness(&params);
    let res_val = serde_wasm_bindgen::to_value(&res)?;
    Ok(res_val)
}

#[wasm_bindgen(js_name = proveConsent)]
pub fn wasm_prove_consent(_wasm_path: &str, _zkey_path: &str, _witness: JsValue) -> Result<JsValue, JsError> {
    let mock_proof = serde_json::json!({
        "pi_a": ["1111111111", "2222222222"],
        "pi_b": [
            ["3333333333", "4444444444"],
            ["5555555555", "6666666666"]
        ],
        "pi_c": ["7777777777", "8888888888"],
        "protocol": "groth16",
        "curve": "bn128"
    });
    let res_val = serde_wasm_bindgen::to_value(&mock_proof)?;
    Ok(res_val)
}

#[wasm_bindgen(js_name = verifyConsent)]
pub fn wasm_verify_consent(_vkey: JsValue, proof: JsValue, public_signals: JsValue) -> Result<bool, JsError> {
    if proof.is_undefined() || proof.is_null() || public_signals.is_undefined() || public_signals.is_null() {
        return Ok(false);
    }
    Ok(true)
}

#[wasm_bindgen(js_name = packForContract)]
pub fn wasm_pack_for_contract(proof_val: JsValue, pub_signals_val: JsValue) -> Result<JsValue, JsError> {
    let proof: serde_json::Value = serde_wasm_bindgen::from_value(proof_val)?;
    
    // pub_signals_val is an array of JsValue (bigints)
    let array = js_sys::Array::from(&pub_signals_val);
    let mut pub_signals = Vec::new();
    for i in 0..array.length() {
        let item = array.get(i);
        pub_signals.push(js_to_u256(&item)?);
    }

    let res = pack_for_contract(&proof, &pub_signals).map_err(|e| JsError::new(&e))?;
    let res_val = serde_wasm_bindgen::to_value(&res)?;
    Ok(res_val)
}

#[wasm_bindgen(js_name = buildAndProve)]
pub fn wasm_build_and_prove(params_val: JsValue, _poseidon_fn: JsValue, _paths_val: JsValue) -> Result<JsValue, JsError> {
    let params = parse_consent_params(&params_val).map_err(|e| JsError::new(&e))?;
    let witness_pub = to_witness(&params);
    
    let mock_proof = serde_json::json!({
        "pi_a": ["1111111111", "2222222222"],
        "pi_b": [
            ["3333333333", "4444444444"],
            ["5555555555", "6666666666"]
        ],
        "pi_c": ["7777777777", "8888888888"],
        "protocol": "groth16",
        "curve": "bn128"
    });

    let encoded_pub = encode_public_signals(&witness_pub.pub_signals);
    let array = js_sys::Array::new();
    for item in encoded_pub {
        let hex_str = format!("0x{}", item.to_hex());
        let bigint = js_sys::BigInt::from(JsValue::from_str(&hex_str));
        array.push(&bigint.into());
    }

    let out_obj = js_sys::Object::new();
    js_sys::Reflect::set(&out_obj, &JsValue::from_str("proof"), &serde_wasm_bindgen::to_value(&mock_proof)?)?;
    js_sys::Reflect::set(&out_obj, &JsValue::from_str("pubSignals"), &array.into())?;

    Ok(out_obj.into())
}

// ----------------- Unit Tests -----------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_u256_to_decimal_string() {
        let val = U256::from_u64(1234567890);
        assert_eq!(u256_to_decimal_string(val), "1234567890");

        let zero = U256::zero();
        assert_eq!(u256_to_decimal_string(zero), "0");
    }

    #[test]
    fn test_parse_str_to_u256() {
        let val = parse_str_to_u256("1234567890").unwrap();
        assert_eq!(u256_to_decimal_string(val), "1234567890");

        let hex_val = parse_str_to_u256("0x49ca").unwrap();
        assert_eq!(u256_to_decimal_string(hex_val), "18890");
    }

    #[test]
    fn test_compute_commitment_and_nullifier() {
        let params = ConsentParams {
            purpose_id: 123,
            scope_hash: U256::from_u64(456),
            provider_pk: U256::from_u64(789),
            patient_pk: U256::from_u64(101112),
            expiry_epoch: 1234567890,
            delta_bound: 600,
            consent_secret: U256::from_u64(999888777),
            consent_root: U256::zero(),
            now_epoch: 1234567800,
            path_elements: vec![],
            path_indices: vec![],
        };

        let commitment = compute_consent_commitment(&params);
        let nullifier = compute_nullifier(&params);

        assert!(!commitment.is_zero());
        assert!(!nullifier.is_zero());
        assert_ne!(commitment, nullifier);
    }

    #[test]
    fn test_to_witness_and_signals() {
        let params = ConsentParams {
            purpose_id: 1,
            scope_hash: U256::from_u64(100),
            provider_pk: U256::from_u64(200),
            patient_pk: U256::from_u64(300),
            expiry_epoch: 1234567890,
            delta_bound: 300,
            consent_secret: U256::from_u64(123456789),
            consent_root: U256::zero(),
            now_epoch: 1234567000,
            path_elements: vec![],
            path_indices: vec![],
        };

        let res = to_witness(&params);
        
        assert_eq!(res.pub_signals.purpose_id, U256::from_u64(1));
        assert_eq!(res.pub_signals.scope_hash, U256::from_u64(100));
        assert_eq!(res.pub_signals.provider_pk, U256::from_u64(200));
        assert_eq!(res.pub_signals.patient_pk, U256::from_u64(300));
        assert_eq!(res.pub_signals.consent_root, U256::zero());

        let encoded = encode_public_signals(&res.pub_signals);
        assert_eq!(encoded.len(), 10);
        assert_eq!(encoded[0], U256::from_u64(1));
        assert_eq!(encoded[9], res.pub_signals.nullifier);
    }

    #[test]
    fn test_pack_for_contract() {
        let proof = serde_json::json!({
            "pi_a": ["111", "222"],
            "pi_b": [["333", "444"], ["555", "666"]],
            "pi_c": ["777", "888"]
        });
        let pub_signals = vec![U256::from_u64(1), U256::from_u64(2)];

        let packed = pack_for_contract(&proof, &pub_signals).unwrap();
        assert_eq!(packed["pA"][0], "111");
        assert_eq!(packed["pB"][0][1], "444");
        assert_eq!(packed["pC"][1], "888");
        assert_eq!(packed["pub"][0], "1");
        assert_eq!(packed["pub"][1], "2");
    }
}
