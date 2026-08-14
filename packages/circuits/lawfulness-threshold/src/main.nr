// lawfulness-threshold/src/main.nr
// Public inputs (order must match LawfulnessGuard expectations):
//   artifactHash: Field
//   vkHash:       Field
//   level:        u8
//   expiry:       u64
//   caller:       Field
//
// This circuit enforces a minimal policy: level >= MIN_LEVEL.
// Expiry is not checked (the contract checks it against block.timestamp).
// The values are *committed* as public inputs.

// ---- constants ----
global MIN_LEVEL: u8 = 100u8; // set your policy floor

fn main(
    artifactHash: pub Field,
    vkHash:       pub Field,
    level:        pub u8,
    expiry:       pub u64,
    caller:       pub Field,
) {
    // Range check is inherent for u8/u64 in Noir.
    // Enforce threshold:
    constrain(level >= MIN_LEVEL);

    // Optionally, encode a trivial sanity that caller != 0
    // (0 check is not necessary but harmless)
    constrain(caller != 0);

    // No additional constraints; success means the tuple is attested with level >= MIN_LEVEL.
}
