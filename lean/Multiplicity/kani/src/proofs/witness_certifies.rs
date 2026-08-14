//! Mirror of `witness_certifies` (Multiplicity/Kernel.lean): a witness is
//! accepted exactly when it carries a non-empty statement.  Kani does not
//! model arbitrary `String` content, so the witness is built from a symbolic
//! `bool` choosing between an empty and a non-empty statement; the harness
//! verifies the extraction rule on both reachable outcomes.

use multiplicity_core::FormWitness;

#[kani::proof]
fn witness_certifies() {
    let nonempty: bool = kani::any();
    let statement = if nonempty { "P".to_string() } else { String::new() };
    let w = FormWitness {
        statement: statement.clone(),
        rust_fn: String::new(),
        kani_proof: String::new(),
        regression: String::new(),
    };
    assert_eq!(w.certifies(), !statement.is_empty());
    assert_eq!(w.certifies(), nonempty);
}
