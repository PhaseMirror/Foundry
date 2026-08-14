//! MA-VQE Custom Compiler Pipeline
//!
//! Applies Generalized Jordan-Wigner ($JW_d$) transformations to map fermionic
//! operators to qudit instructions. Uses the `QuantumM` monad for pruning
//! search spaces. Formal spec: `lean/Core/atomic_calculator/Core.lean`
//! (`UAC.Math.GeneralizedJW`), which proves the excitation angle
//! `θ = π/(d-1)` and the Z-parity prefix exactly match this emission.

use crate::bounds::{CHEMICAL_ACCURACY_THRESHOLD_MHA_SCALED, SCALE};
use crate::ma_vqe::QuantumM;
use crate::policy_gate::{AlpGate, AlpVerdict};

/// Represents a single gate operation in a qudit circuit.
#[derive(Debug, Clone, PartialEq)]
pub enum QuditGate {
    /// Pauli-Z gate on a specific qudit index (parity string element)
    Z(usize),
    /// Generalized X rotation for qudits: Rx(theta, index)
    Rx(f64, usize),
}

/// Emits the generalized Jordan-Wigner term for qudit mode `j` at dimension `d`.
///
/// The term is the parity Z-string `Z(0)..Z(j-1)` followed by the local
/// excitation `Rx(π/(d-1), j)`, matching `UAC.Math.GeneralizedJW.jwTerm`.
pub fn jw_qudit_term(j: usize, _n: usize, d: usize) -> Vec<QuditGate> {
    let mut circuit = Vec::new();
    for k in 0..j {
        circuit.push(QuditGate::Z(k));
    }
    let theta = std::f64::consts::PI / ((d - 1) as f64);
    circuit.push(QuditGate::Rx(theta, j));
    circuit
}

/// Collapses a list of per-mode JW_d terms into a single minimal-depth circuit
/// by fusing adjacent Z gates on the same qudit (the parity prefix of mode `j+1`
/// overlaps the prefix of mode `j`, so consecutive Z(k) gates are deduped).
pub fn compile_jw_circuit(num_modes: usize, d: usize) -> Vec<QuditGate> {
    let mut circuit: Vec<QuditGate> = Vec::new();
    let mut last_z: Option<usize> = None;
    for j in 0..num_modes {
        for gate in jw_qudit_term(j, num_modes, d) {
            match gate {
                QuditGate::Z(k) => {
                    if last_z != Some(k) {
                        circuit.push(QuditGate::Z(k));
                        last_z = Some(k);
                    }
                }
                rx @ QuditGate::Rx(..) => {
                    circuit.push(rx);
                    last_z = None;
                }
            }
        }
    }
    circuit
}

/// Prunes variational search tree paths that exceed the chemical accuracy
/// threshold. Scales the energy (mHa) by `SCALE` to compare against the
/// Lean-derived constant `CHEMICAL_ACCURACY_THRESHOLD_MHA_SCALED` (15 mHa).
pub fn multiplicity_prune(energy_mha: f64) -> bool {
    let energy_scaled = (energy_mha * (SCALE as f64)) as u64;
    energy_scaled < CHEMICAL_ACCURACY_THRESHOLD_MHA_SCALED
}

/// Evaluates a branch using the QuantumM monad's `bind` for MA-VQE pruning.
/// Failed/unphysical branches collapse to the empty fallback (no-cloning
/// corollary), which the caller treats as a pruned circuit.
pub fn evaluate_branch(branch_energy: f64, circuit: Vec<QuditGate>) -> QuantumM<Vec<QuditGate>> {
    let qm_state = QuantumM::Pure(circuit.clone());
    qm_state.bind(
        |circ| {
            if multiplicity_prune(branch_energy) {
                QuantumM::Pure(circ)
            } else {
                QuantumM::Superpose(vec![]) // Monad collapse/prune
            }
        },
        vec![],
    )
}

/// Full ADR-004 compilation of a molecular target into a qudit circuit, with
/// the Sedona Spine ALP policy gate enforced on the emitted instructions.
///
/// Returns `Err` if the ALP gate rejects the circuit (governance violation).
pub fn compile_and_gate(num_modes: usize, d: usize) -> Result<Vec<QuditGate>, &'static str> {
    let circuit = compile_jw_circuit(num_modes, d);
    match AlpGate::evaluate(&circuit) {
        AlpVerdict::Approve => Ok(circuit),
        AlpVerdict::Reject => Err("ALP policy gate rejected MA-VQE circuit"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lih_compression() {
        // Mock LiH energy within chemical accuracy
        let lih_energy_mha = 13.0; // 13 mHa < 15 mHa
        assert!(multiplicity_prune(lih_energy_mha));

        let circuit = jw_qudit_term(2, 4, 16);
        let result = evaluate_branch(lih_energy_mha, circuit);
        match result {
            QuantumM::Pure(_) => (), // Expected success
            _ => panic!("Expected Pure branch for LiH within chemical accuracy"),
        }
    }

    #[test]
    fn test_lih_full_compile_meets_accuracy_and_gate() {
        // LiH: 4 spin-orbitals -> 2 fermionic modes. d=16 (^133Cs).
        // Minimal-depth JW_d: mode 0 has no parity prefix (just Rx), mode 1
        // carries Z(0) parity then Rx. Total = 3 gates.
        let circuit = compile_and_gate(2, 16).expect("ALP gate must approve LiH circuit");
        assert_eq!(circuit.len(), 3);
        // mode 0: local excitation only
        assert!(matches!(circuit[0], QuditGate::Rx(_, 0)));
        // mode 1: parity Z(0) then local excitation
        assert!(matches!(circuit[1], QuditGate::Z(0)));
        assert!(matches!(circuit[2], QuditGate::Rx(_, 1)));
        // Excitation angle must equal π/(d-1) per the Lean spec.
        if let QuditGate::Rx(theta, _) = circuit[0] {
            assert!((theta - std::f64::consts::PI / 15.0).abs() < 1e-12);
        } else {
            panic!("expected Rx");
        }
    }

    #[test]
    fn test_exceeds_accuracy_pruned() {
        // 45 mHa exceeds the 15 mHa threshold -> branch collapses.
        let circuit = compile_jw_circuit(2, 16);
        let result = evaluate_branch(45.0, circuit);
        match result {
            QuantumM::Superpose(bs) => assert!(bs.is_empty(), "unphysical branch must be pruned"),
            _ => panic!("expected collapsed/empty superposition"),
        }
    }
}
