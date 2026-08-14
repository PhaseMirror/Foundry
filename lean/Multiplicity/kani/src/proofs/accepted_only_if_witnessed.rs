//! Mirror of `accepted_only_if_witnessed` (Multiplicity/Kernel.lean):
//! acceptance happens only through a witness, so the accepted statement is
//! exactly the certified statement.  The witness is built from a symbolic
//! `bool` choosing between an empty and a non-empty statement.

use multiplicity_core::FormWitness;

#[kani::proof]
fn accepted_only_if_witnessed() {
    let nonempty: bool = kani::any();
    let statement = if nonempty { "P".to_string() } else { String::new() };
    let w = FormWitness {
        statement: statement.clone(),
        rust_fn: String::new(),
        kani_proof: String::new(),
        regression: String::new(),
    };
    let accepted = w.certifies();
    assert_eq!(accepted, !statement.is_empty());
    assert_eq!(accepted, nonempty);
}
