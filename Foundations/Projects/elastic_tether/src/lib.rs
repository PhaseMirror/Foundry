//! ElasticTether – a simple spring‑like model with Kani verification.
//!
//! The Lean file `ElasticTether.lean` only contains a placeholder, so we provide a
//! concrete implementation here.  The model is intentionally minimal: a tether
//! (spring) with a stiffness constant `k` and a rest length `l0`.  Given a current
//! length `l`, the stored elastic energy is
//!
//! ```text
//!   E = 0.5 * k * (l - l0)^2
//! ```
//!
//! All quantities are `f64`.  The Kani proof checks that the computed energy is
//! always non‑negative when `k >= 0` and the lengths are finite.



/// Simple tether (spring) model.
#[derive(Clone, Copy, Debug)]
pub struct Tether {
    /// Stiffness constant `k` (≥ 0).
    pub stiffness: f64,
    /// Rest length `l0` (≥ 0).
    pub rest_length: f64,
}

impl Tether {
    /// Compute the elastic energy for a given current length `l`.
    ///
    /// Returns `0.5 * k * (l - l0)^2`.
    pub fn energy(&self, current_length: f64) -> f64 {
        let delta = current_length - self.rest_length;
        0.5 * self.stiffness * delta * delta
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use kani::proof;

    /// Verify that the energy is never negative for non‑negative parameters.
    #[proof]
    fn energy_is_nonnegative() {
        // nondeterministically choose parameters within a reasonable range.
        let k: f64 = any(); // Kani will treat this as any f64.
        let l0: f64 = any();
        let l: f64 = any();
        // Constrain parameters to be non‑negative for the proof.
        kani::assume(k >= 0.0);
        kani::assume(l0 >= 0.0);
        // No restriction on `l` – it can be any length.
        let tether = Tether { stiffness: k, rest_length: l0 };
        let e = tether.energy(l);
        // Energy formula yields a product of a non‑negative factor (k) and a squared term.
        kani::assert(e >= 0.0);
    }
}


#[kani::proof]
fn proof_energy_nonnegative_root() {
    let k: f64 = kani::any();
    let l0: f64 = kani::any();
    let l: f64 = kani::any();
    kani::assume(k >= 0.0);
    kani::assume(l0 >= 0.0);
    let tether = Tether { stiffness: k, rest_length: l0 };
    let e = tether.energy(l);
    kani::assert(e >= 0.0);
}
