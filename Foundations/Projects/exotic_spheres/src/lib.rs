//! ExoticSpheres – minimal example illustrating parity‑based invariants.
//!
//! In differential topology an *exotic sphere* is a manifold homeomorphic but not
//! diffeomorphic to the standard sphere.  Here we provide a toy function that
//! computes a simple parity‑based invariant: the Euler characteristic of a
//! *hypothetical* sphere of dimension `dim`.  For even dimensions the Euler
//! characteristic of a standard sphere is `2`; for odd dimensions it is `0`.
//!
//! This is purely illustrative and serves as a concrete Rust implementation
//! that can be verified with Kani.

/// Represents a (hypothetical) sphere of a given dimension.
#[derive(Clone, Copy, Debug)]
pub struct Sphere {
    /// Topological dimension of the sphere (must be >= 0).
    pub dim: u32,
}

use kani::{any, assert};

impl Sphere {
    /// Returns the Euler characteristic based on parity of `dim`.
    ///
    /// * If `dim` is even, returns `2`.
    /// * If `dim` is odd, returns `0`.
    pub fn euler_characteristic(&self) -> i32 {
        if self.dim % 2 == 0 { 2 } else { 0 }
    }
}

#[kani::proof]
fn proof_euler_nonnegative_root() {
    let d: u32 = kani::any();
    let s = Sphere { dim: d };
    let chi = s.euler_characteristic();
    kani::assert(chi >= 0, "chi nonnegative");
}


#[cfg(test)]
mod tests {
    use super::*;
    use kani::{any, assume, assert};

    // Kani harness placed at crate root (outside cfg(test)) will be discovered.
    #[kani::proof]
    fn proof_euler_nonnegative() {
        // Choose any dimension (non‑negative by type).
        let d: u32 = any();
        let s = Sphere { dim: d };
        let chi = s.euler_characteristic();
        assert(chi >= 0);
    }
}

