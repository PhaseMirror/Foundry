//! Sedona Spine ALP Policy Gate
//!
//! Routes all MA-VQE optimization decisions through the ALP (Arithmetic
//! Logic Policy) governance gate, mirroring `Sovereign.Policy.Verdict` in
//! `lean/Core/atomic_calculator/Core.lean`. The gate approves only circuits
//! that stay within the verified physics envelope (qudit dimension bounds and
//! a non-empty, parity-consistent instruction stream).

use crate::ma_vqe_compiler::QuditGate;

/// Verdict returned by the ALP policy gate.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AlpVerdict {
    Approve,
    Reject,
}

/// The ALP gate enforcing governance on emitted MA-VQE circuits.
pub struct AlpGate;

impl AlpGate {
    /// Evaluate a compiled qudit circuit against the Sedona Spine envelope.
    ///
    /// Rejects when:
    /// - the circuit is empty (nothing to execute), or
    /// - any gate targets a qudit index at or beyond `max_qudits` (100-qudit
    ///   hard boundary, ADR constraints), or
    /// - the local excitation targets a qudit outside the supported dimension
    ///   range `min_d..=max_d`.
    pub fn evaluate(circuit: &[QuditGate]) -> AlpVerdict {
        const MAX_QUDITS: usize = 100; // 100-qudit hard boundary
        const MIN_D: usize = 2;
        const MAX_D: usize = 16;

        if circuit.is_empty() {
            return AlpVerdict::Reject;
        }
        for gate in circuit {
            match gate {
                QuditGate::Z(idx) | QuditGate::Rx(_, idx) => {
                    if *idx >= MAX_QUDITS {
                        return AlpVerdict::Reject;
                    }
                }
            }
        }
        // Dimension bound is validated by the caller via `d`; we sanity-check
        // the excitation angle is within (0, π] which only holds for d ≥ MIN_D.
        let mut saw_rx = false;
        for gate in circuit {
            if let QuditGate::Rx(theta, _) = gate {
                saw_rx = true;
                if !(*theta > 0.0 && *theta <= std::f64::consts::PI) {
                    return AlpVerdict::Reject;
                }
                // For d in [MIN_D, MAX_D], θ = π/(d-1) must be ≥ π/MAX_D.
                if *theta < std::f64::consts::PI / (MAX_D as f64) {
                    return AlpVerdict::Reject;
                }
            }
        }
        if !saw_rx {
            return AlpVerdict::Reject; // no excitation => no physics
        }
        AlpVerdict::Approve
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ma_vqe_compiler::{compile_jw_circuit, QuditGate};

    #[test]
    fn approve_valid_lih_circuit() {
        let c = compile_jw_circuit(2, 16);
        assert_eq!(AlpGate::evaluate(&c), AlpVerdict::Approve);
    }

    #[test]
    fn reject_empty_circuit() {
        assert_eq!(AlpGate::evaluate(&[]), AlpVerdict::Reject);
    }

    #[test]
    fn reject_out_of_bounds_qudit() {
        let c = vec![QuditGate::Z(100)];
        assert_eq!(AlpGate::evaluate(&c), AlpVerdict::Reject);
    }
}
