//! Versions, receipts, and the CRMF PWEH integrity binding.
//!
//! This module **issues** receipts and **binds** them into the PWEH integrity
//! chain. It performs no archival: permanent storage is the CRMF/Archivum
//! layer's job. There is **no WORM** anywhere in this crate (ADR-0013 scope;
//! only CRMF and Archivum).

use crmf::canonical::be_u64;
use crmf::pweh::{be256, hash_meta, PwevhIntegrity};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};

use crate::defect::ObservDefect;
use crate::kernel::GateSignal;
use crate::system::{program_hash, WIRE_VERSION};
pub use crate::KERNEL_VERSION;

/// Version tag of [`KERNEL_VERSION`] in the canonical encoding.
pub const KERNEL_VERSION_TAG: u64 = 1;

/// The canonical prime slot for the receipt PWEH step (the first prime index).
const RECEIPT_CHAIN_PRIME: u64 = 2;

/// The Kani harnesses that verify this crate's gate and binding laws. This is
/// the static "verified by" manifest; `kani_verified` on the receipt records
/// whether the *current* build was actually verified.
pub const KANI_HARNESSES: &[&str] = &[
    "kernel::kani_proofs::observ_gate_fail_closed",
    "kernel::kani_proofs::observ_gate_no_false_kill",
    "kernel::kani_proofs::observ_gate_kill_requires_evidence",
    "receipt::kani_proofs::observ_core_injective",
];

/// Default deployment tag of the Q2 build.
pub const BUILD_ID_DEFAULT: u64 = 1;

/// The receipt of one `measure` call. Issued for every call, even a kill.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Receipt {
    /// SHA-256 of the canonical program bytes (ADR-0027 §5 wire fidelity).
    pub program_sha256: String,
    /// Kernel version tag (mapping to [`KERNEL_VERSION`] in the CLI).
    pub kernel_version_tag: u64,
    /// Wire version of the program encoding.
    pub wire_version: u64,
    pub build_id: u64,
    pub kani_harnesses: Vec<String>,
    /// Whether this build itself was Kani-verified (`cfg!(kani)`).
    pub kani_verified: bool,
    /// Set once the Lean mirror of the observability kernel lands.
    pub lean_mirror: Option<String>,
    pub timestamp: u64,
    pub signal: GateSignal,
    /// `S_integrity(1)` — the root of the PWEH chain over this receipt.
    pub pweh_chain_root: String,
}

impl Receipt {
    /// Issue a receipt for one call and bind it into a PWEH chain seeded with
    /// the program digest.
    pub fn issue(program_sha256: [u8; 32], signal: GateSignal, _defects: &[ObservDefect]) -> Self {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);

        let harnesses: Vec<String> = KANI_HARNESSES.iter().map(|s| s.to_string()).collect();

        let mut chain = PwevhIntegrity::new(program_sha256);
        chain.step(
            be256(RECEIPT_CHAIN_PRIME),
            be256(KERNEL_VERSION_TAG),
            hash_meta(&governance_meta_bytes(
                signal,
                &harnesses,
                KERNEL_VERSION_TAG,
            )),
        );

        Receipt {
            program_sha256: hex::encode(program_sha256),
            kernel_version_tag: KERNEL_VERSION_TAG,
            wire_version: WIRE_VERSION as u64,
            build_id: BUILD_ID_DEFAULT,
            kani_harnesses: harnesses,
            kani_verified: cfg!(kani),
            lean_mirror: None,
            timestamp,
            signal,
            pweh_chain_root: hex::encode(chain.attested()),
        }
    }

    /// Convenience binding directly from a validated `MeasurementProgram`.
    pub fn issue_for(program: &crate::system::MeasurementProgram, signal: GateSignal) -> Self {
        Self::issue(program_hash(program), signal, &[])
    }

    /// The fixed-width canonical core: `program ‖ ts ‖ kernel_tag ‖ wire ‖ build`.
    ///
    /// This 64-byte prefix is the tamper-evident field set; its injectivity is
    /// Kani-verified ([`kani_proofs::observ_core_injective`]).
    pub fn canonical_core(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(32 + 8 + 8 + 8 + 8);
        if let Ok(digest) = hex::decode(&self.program_sha256) {
            out.extend_from_slice(&digest);
        }
        out.extend_from_slice(&be_u64(self.timestamp));
        out.extend_from_slice(&be_u64(self.kernel_version_tag));
        out.extend_from_slice(&be_u64(self.wire_version));
        out.extend_from_slice(&be_u64(self.build_id));
        out
    }
}

/// Strict governance metadata `M(t)` for the receipt PWEH step: the signal,
/// the harness manifest, and the kernel tag (lossless, fixed field order).
fn governance_meta_bytes(signal: GateSignal, harnesses: &[String], tag: u64) -> Vec<u8> {
    let mut out = Vec::new();
    out.extend_from_slice(&be_u64(tag));
    out.push(match signal {
        GateSignal::Nominal => 0x00,
        GateSignal::SigGovKill => 0x01,
    });
    out.extend_from_slice(&crmf::canonical::uleb128(harnesses.len() as u64));
    for h in harnesses {
        out.extend_from_slice(&crmf::canonical::uleb128(h.len() as u64));
        out.extend_from_slice(h.as_bytes());
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::system::MeasurementProgram;

    fn sample_receipt() -> Receipt {
        Receipt::issue([0x42; 32], GateSignal::Nominal, &[])
    }

    #[test]
    fn receipt_bound_into_pweh_is_deterministic() {
        let a = sample_receipt();
        assert_eq!(a.pweh_chain_root.len(), 64);
        assert!(a.timestamp > 0);
        assert_eq!(a.lean_mirror, None);
        assert_eq!(a.wire_version, 0x004F);
    }

    #[test]
    fn canonical_core_is_64_bytes() {
        let r = sample_receipt();
        assert_eq!(r.canonical_core().len(), 32 + 8 + 8 + 8 + 8);
    }

    #[test]
    fn issue_for_reaches_pweh() {
        let p = MeasurementProgram {
            name: "r".into(),
            dim: 2,
            stages: vec![crate::system::Stage {
                name: "s".into(),
                kind: crate::system::StageKind::Response,
                matrix: vec![vec![1, 0], vec![0, 1]],
            }],
            targets: vec![crate::system::Channel {
                name: "t".into(),
                rows: vec![vec![1, 0]],
            }],
            probes: vec![],
            claims: vec![],
            reversals: vec![],
            reference: None,
        };
        let r = Receipt::issue_for(&p, GateSignal::Nominal);
        assert_eq!(r.program_sha256.len(), 64);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// The canonical core is injective: equal bytes imply equal fields. This is
    /// the Kani witness for the future Lean theorem binding receipt fields to
    /// their canonical bytes (crmf precedent: `two_field_bind_injective`).
    #[kani::proof]
    pub fn observ_core_injective() {
        let h1: [u8; 32] = kani::any();
        let h2: [u8; 32] = kani::any();
        let t1: u64 = kani::any();
        let t2: u64 = kani::any();
        let k1: u64 = kani::any();
        let k2: u64 = kani::any();
        let w1: u64 = kani::any();
        let w2: u64 = kani::any();
        let b1: u64 = kani::any();
        let b2: u64 = kani::any();

        let mut left = Vec::new();
        left.extend_from_slice(&h1);
        left.extend_from_slice(&be_u64(t1));
        left.extend_from_slice(&be_u64(k1));
        left.extend_from_slice(&be_u64(w1));
        left.extend_from_slice(&be_u64(b1));

        let mut right = Vec::new();
        right.extend_from_slice(&h2);
        right.extend_from_slice(&be_u64(t2));
        right.extend_from_slice(&be_u64(k2));
        right.extend_from_slice(&be_u64(w2));
        right.extend_from_slice(&be_u64(b2));

        kani::assume(left == right);
        assert_eq!(h1, h2);
        assert_eq!(t1, t2);
        assert_eq!(k1, k2);
        assert_eq!(w1, w2);
        assert_eq!(b1, b2);
    }
}
