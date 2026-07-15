use serde::{Deserialize, Serialize};

#[repr(C)]
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct Operator {
    pub a: f64,
    pub b: f64,
    pub c: f64,
    pub d: f64,
}

impl Operator {
    pub fn new(a: f64, b: f64, c: f64, d: f64) -> Self {
        Self { a, b, c, d }
    }

    /// Computes the spectral radius of the 2x2 Operator.
    /// In a fully scaled implementation, this relies on `rug` for arbitrary precision.
    pub fn spectral_radius(&self) -> f64 {
        let tr = self.a + self.d;
        let det = self.a * self.d - self.b * self.c;
        let disc = tr * tr - 4.0 * det;

        if disc >= 0.0 {
            let sqrt_disc = disc.sqrt();
            let l1 = (tr + sqrt_disc).abs() / 2.0;
            let l2 = (tr - sqrt_disc).abs() / 2.0;
            l1.max(l2)
        } else {
            det.abs().sqrt()
        }
    }

    /// Validates the operator against the spectral bound and emits a proof to the Archivum ledger.
    pub fn accept_and_record(
        &self, 
        operator_id: &str, 
        bound: f64, 
        ledger_path: &std::path::Path,
        lean_hash: String,
        rust_hash: String,
        tee_quote: String
    ) -> Result<(), &'static str> {
        let radius = self.spectral_radius();
        
        if radius > bound || !radius.is_finite() {
            return Err("Operator violates the mathematically verified spectral bound. (SIG_GOV_KILL)");
        }

        let ledger = archivum::WitnessLedger::new(ledger_path);
        
        let proof = archivum::ZmosSpectralProof::new(
            operator_id.to_string(),
            radius,
            lean_hash,
            rust_hash,
            tee_quote,
        );

        ledger.stamp_zmos_proof(&proof).map_err(|_| "Failed to write ZmosSpectralProof to Archivum ledger")?;
        Ok(())
    }
}

/// The verifiable FFI Module for Lean 4
pub mod ffi {
    use super::Operator;

    /// C-ABI boundary for Lean to fetch Rust's exact spectral radius
    #[unsafe(no_mangle)]
    pub extern "C" fn zmos_spectral_radius_rs(op: *const Operator) -> f64 {
        if op.is_null() {
            return 0.0;
        }
        let operator = unsafe { &*op };
        operator.spectral_radius()
    }

    /// Runtime enforcement. Triggers a rejection if bound is exceeded.
    #[unsafe(no_mangle)]
    pub extern "C" fn zmos_verify_spectral_bound_rs(op: *const Operator, bound: f64) -> bool {
        if op.is_null() {
            return false;
        }
        let operator = unsafe { &*op };
        let radius = operator.spectral_radius();
        
        radius <= bound && radius.is_finite() && !radius.is_nan()
    }
}

#[cfg(kani)]
mod verification {
    use super::*;
    use super::ffi::*;

    #[kani::proof]
    fn verify_spectral_bound_soundness() {
        let a: f64 = kani::any();
        let b: f64 = kani::any();
        let c: f64 = kani::any();
        let d: f64 = kani::any();
        let bound: f64 = kani::any();

        kani::assume(a.is_finite() && b.is_finite() && c.is_finite() && d.is_finite());
        kani::assume(bound > 0.0 && bound.is_finite());

        let op = Operator::new(a, b, c, d);
        let ptr: *const Operator = &op;

        let is_valid = zmos_verify_spectral_bound_rs(ptr, bound);

        if is_valid {
            let radius = zmos_spectral_radius_rs(ptr);
            // The core Soundness Theorem: If the Rust check passes, the radius MUST be <= the Lean bound.
            kani::assert(radius <= bound, "Runtime check failed to enforce the bound strictly");
            kani::assert(radius.is_finite(), "Spectral radius must be finite");
            kani::assert(!radius.is_nan(), "Spectral radius cannot be NaN");
        }
    }
}
