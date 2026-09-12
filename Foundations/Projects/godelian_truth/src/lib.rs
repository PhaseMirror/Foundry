//! GodelianTruth – a toy formal system illustrating Gödel's incompleteness.
//!
//! This stub provides a trivial predicate `always_false` that returns `false`
//! for any input.  In a real Gödelian setting one would encode statements and
//! provability; here we keep it simple so that Kani can verify the property.

/// Represents a trivial formal system.
#[derive(Clone, Copy, Debug)]
pub struct FormalSystem;

impl FormalSystem {
    /// Returns `false` for any proposition identifier.
    /// The identifier is unused – the function always yields `false`.
    pub fn always_false(&self, _prop_id: u32) -> bool {
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use kani::{any, assert};

    #[kani::proof]
    fn proof_always_false_is_false() {
        // Choose any proposition identifier (non‑negative u32).
        let pid: u32 = any();
        let sys = FormalSystem;
        let result = sys.always_false(pid);
        // The function should always return false.
        assert(result == false, "always_false must be false");
    }
}

