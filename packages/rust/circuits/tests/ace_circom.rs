//! End-to-end coverage against the real `Foundry/circuits/ace.circom` source
//! (no snarkjs required — the constraint count line is exercised via a
//! canned snarkjs sample in `budget_gate_*` tests in the lib).

use circuits::{count_poseidon2_instantiations, parse_circom_components, poseidon2_topology_check};
use std::path::PathBuf;

fn ace_circom_src() -> String {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../../circuits/ace.circom");
    std::fs::read_to_string(&path).unwrap_or_else(|e| panic!("read {}: {e}", path.display()))
}

#[test]
fn ace_circom_parses_expected_components() {
    let content = ace_circom_src();
    let components = parse_circom_components(&content);
    assert_eq!(components.get("Num2Bits"), Some(&1));
    assert_eq!(components.get("Poseidon"), Some(&1));
}

#[test]
fn ace_circom_poseidon2_topology_is_pending() {
    // ace.circom currently instantiates circomlib Poseidon(t); the canonical
    // Poseidon2(t=9, r=8) topology is enforced at the Rust layer. The python
    // test asserts count == 0 as a documented, not-yet-integrated state.
    let content = ace_circom_src();
    let count = count_poseidon2_instantiations(&content);
    assert_eq!(count, 0);
    poseidon2_topology_check(count).expect("topology state is accepted");
}
