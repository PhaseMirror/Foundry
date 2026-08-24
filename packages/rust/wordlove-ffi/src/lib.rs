//! Rust binding to the Lean WordLove C ABI (ADR-0031 §6 / ADR-0033 P5).
//!
//! Realizes the **P5 Realization** stratum of the Prism model: the
//! kernel-checked definitions in `Multiplicity.WordLove.FFI` are lowered to
//! `@[export]` symbols by Lake and consumed here through typed handles —
//! no arithmetic is re-implemented on the Rust side, so the provenance chain
//! Definition → Proof → Executable → Binding stays unbroken.
//!
//! Two export groups are bound:
//!
//! * [`LargePrimeExport`] — hybrid primality gate (Tier-1 static table for
//!   n ≤ 65536, Tier-2 Pratt-certificate verification above) plus prime
//!   support statistics ω/Ω and the canonical PARM sealed state.
//! * [`CertifiedCouplingExport`] — the certified fixed-point coupling
//!   γ_pn (scale N = 1024) whose four joint invariants are proved in
//!   `Multiplicity.WordLove.Certified`.
//!
//! The dylib path and manifest location arrive as compile-time environment
//! variables emitted by `build.rs` (`LEAN_RS_CAPABILITY_WORD_LOVE_DYLIB` /
//  `LEAN_RS_CAPABILITY_WORD_LOVE_MANIFEST`).

use lean_rs::{LeanBuiltCapability, LeanCapability, LeanError, LeanRuntime};
use std::sync::OnceLock;

/// Compile-time env var carrying the built `libWordLove.so` path.
pub const DYLIB_ENV: &str = "LEAN_RS_CAPABILITY_WORD_LOVE_DYLIB";
/// Compile-time env var carrying the capability manifest path.
pub const MANIFEST_ENV: &str = "LEAN_RS_CAPABILITY_WORD_LOVE_MANIFEST";

/// Typed error boundary for bridge construction and export dispatch.
#[derive(Debug)]
pub enum Error {
    /// Runtime bring-up, dylib load, initializer, or dispatch failure.
    Lean(LeanError),
    /// Manifest-checked export lookup failure (absent or shape-mismatched).
    Export(Box<lean_rs::LeanCheckedExportError>),
}

impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Error::Lean(err) => write!(f, "lean runtime error: {err}"),
            Error::Export(err) => write!(f, "export lookup failed: {err}"),
        }
    }
}

impl std::error::Error for Error {}

impl From<LeanError> for Error {
    fn from(err: LeanError) -> Self {
        Error::Lean(err)
    }
}

impl From<lean_rs::LeanCheckedExportError> for Error {
    fn from(err: lean_rs::LeanCheckedExportError) -> Self {
        Error::Export(Box::new(err))
    }
}

/// Convenience alias for bridge results.
pub type Result<T> = std::result::Result<T, Error>;

/// Process-once capability anchor.
///
/// The WordLove shared library runs its module initializer exactly once per
/// process (it registers environment extensions, which are single-shot), so
/// both export groups share one [`LeanCapability`] behind a [`OnceLock`].
fn shared_capability() -> Result<&'static LeanCapability<'static>> {
    // SAFETY: `LeanCapability` is neither `Send` nor `Sync` (it carries the
    // raw `dlopen` handle), so it cannot live directly inside a `static`.
    // We instead initialize exactly once behind a [`OnceLock`], leak the
    // boxed capability via `Box::into_raw`, and hand out `&'static` aliases.
    // The pointer is written before any reader can observe the cell, never
    // freed, and all exported calls take the capability only by shared
    // reference — matching how the underlying C ABI is used by Lake-built
    // executables.
    static STATE: OnceLock<std::result::Result<usize, LeanError>> = OnceLock::new();
    match STATE.get_or_init(|| {
        let outcome = (|| -> std::result::Result<LeanCapability<'static>, LeanError> {
            let runtime = LeanRuntime::init()?;
            let spec = LeanBuiltCapability::env(DYLIB_ENV).manifest_env_var(MANIFEST_ENV);
            LeanCapability::from_build_manifest(runtime, spec)
        })();
        match outcome {
            Ok(capability) => Ok(Box::into_raw(Box::new(capability)) as usize),
            Err(err) => Err(err),
        }
    }) {
        Ok(ptr) => Ok(unsafe { &*(*ptr as *const LeanCapability<'static>) }),
        Err(err) => Err(Error::Lean(err.clone())),
    }
}

/// Binding to the hybrid-primality export group.
///
/// Tier semantics (proved on the Lean side, honored here):
/// * n ≤ 65536: static primality table decides, certificates ignored;
/// * n > 65536: a matching, verifiable Pratt certificate is mandatory.
pub struct LargePrimeExport {
    capability: &'static LeanCapability<'static>,
}

impl LargePrimeExport {
    /// Initialize the Lean runtime and load the WordLove capability.
    pub fn connect() -> Result<Self> {
        // Idempotent per process; also marks the calling thread as
        // permitted to invoke Lean (TLS bookkeeping in `lean-rs`).
        LeanRuntime::init()?;
        Ok(Self { capability: shared_capability()? })
    }

    /// Hybrid primality decision for one orbital.
    pub fn hybrid_prime(&self, n: u64) -> Result<bool> {
        let f = self
            .capability
            .exported::<(u64,), u8>("wordlove_is_hybrid_prime_fast_ffi")?;
        Ok(f.call(n)? != 0)
    }

    /// Distinct prime support size ω(n).
    pub fn prime_omega(&self, n: u32) -> Result<u32> {
        let f = self
            .capability
            .exported::<(u32,), u32>("wordlove_prime_omega_ffi")?;
        Ok(f.call(n)?)
    }

    /// Total prime multiplicity Ω(n).
    pub fn prime_omega_total(&self, n: u32) -> Result<u32> {
        let f = self
            .capability
            .exported::<(u32,), u32>("wordlove_prime_Omega_ffi")?;
        Ok(f.call(n)?)
    }

    /// Canonical PARM sealed state of the 108-cycle trajectory [3,3,3,2,2].
    pub fn parm_sealed_state_108(&self) -> Result<u64> {
        let f = self
            .capability
            .exported::<(u32,), u64>("wordlove_parm_sealed_state_108_ffi")?;
        Ok(f.call(0)?)
    }
}

/// Binding to the certified-coupling export group.
///
/// γ_pn lives in fixed-point scale N = 1024, decays with orbital separation
/// through the care-decay table, and collapses to exactly 0 whenever either
/// orbital fails the hybrid gate (`certified_gamma_zero_on_inadmissible`);
/// on admissible orbitals it equals the ungated reference arithmetic
/// (`certified_gamma_agrees_when_admissible`).
pub struct CertifiedCouplingExport {
    capability: &'static LeanCapability<'static>,
}

impl CertifiedCouplingExport {
    /// Initialize the Lean runtime and load the WordLove capability.
    pub fn connect() -> Result<Self> {
        // Idempotent per process; also marks the calling thread as
        // permitted to invoke Lean (TLS bookkeeping in `lean-rs`).
        LeanRuntime::init()?;
        Ok(Self { capability: shared_capability()? })
    }

    /// Certified coupling γ(p, n; trust) in scale-1024 fixed point.
    pub fn gamma_certified(&self, p: u32, n: u32, trust: u32) -> Result<u32> {
        let f = self
            .capability
            .exported::<(u32, u32, u32), u32>("wordlove_gamma_certified_ffi")?;
        Ok(f.call(p, n, trust)?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn large_prime_gate_accepts_and_rejects() -> Result<()> {
        let lp = LargePrimeExport::connect()?;
        assert!(lp.hybrid_prime(13)?);
        assert!(lp.hybrid_prime(65537)?); // Fermat prime via Pratt witness
        assert!(!lp.hybrid_prime(65535)?); // 3 · 5 · 17 · 257
        assert!(!lp.hybrid_prime(131072)?); // power of two, no certificate
        Ok(())
    }

    #[test]
    fn factor_statistics_round_trip() -> Result<()> {
        let lp = LargePrimeExport::connect()?;
        assert_eq!(lp.prime_omega(13)?, 1);
        assert_eq!(lp.prime_omega_total(13)?, 1);
        assert_eq!(lp.prime_omega(12)?, 2); // 12 = 2² · 3
        assert_eq!(lp.prime_omega_total(12)?, 3);
        let _sealed = lp.parm_sealed_state_108()?;
        Ok(())
    }

    #[test]
    fn gamma_matches_kernel_checked_anchors() -> Result<()> {
        let cc = CertifiedCouplingExport::connect()?;
        // sedona_spine_certified_coupling anchor: γ(13,13) at full trust.
        assert_eq!(cc.gamma_certified(13, 13, 1024)?, 1024);
        // Gate collapse: composite orbital ⇒ 0 (WL-CERTCOUPLE-007).
        assert_eq!(cc.gamma_certified(12, 13, 1024)?, 0);
        // Decay-window collapse between verified large primes.
        assert_eq!(cc.gamma_certified(131071, 65537, 1024)?, 0);
        // Trust scaling: half trust halves a full-weight self-coupling.
        assert_eq!(cc.gamma_certified(13, 13, 512)?, 512);
        Ok(())
    }
}
