use serde::{Deserialize, Serialize};
use std::f64::consts::PI;
use crate::core::{dirichlet_char_4, dirichlet_euler_factor};
use crate::tensor::{TensorNode, PrismTensorState};

/// Galois Group Action variants.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum GaloisAction {
    FrobeniusTwist { power: u64 },
    PrimePermute { i: usize, j: usize },
    CharacterShift { mod_val: u64 },
    FullDuality,
}

/// Apply a Galois symmetry operator to the Prism Tensor State.
pub fn apply_galois_action(st: &PrismTensorState, action: &GaloisAction) -> PrismTensorState {
    let mut new_nodes = st.nodes.clone();

    match action {
        GaloisAction::FrobeniusTwist { power } => {
            for node in &mut new_nodes {
                let shift = (2.0 * PI * (node.prime as f64) * (*power as f64) * 0.1) % (2.0 * PI);
                node.phase = (node.phase + shift) % (2.0 * PI);
            }
        }
        GaloisAction::PrimePermute { i, j } => {
            if *i < new_nodes.len() && *j < new_nodes.len() {
                new_nodes.swap(*i, *j);
            }
        }
        GaloisAction::CharacterShift { .. } => {
            for node in &mut new_nodes {
                let chi = dirichlet_char_4(node.prime);
                let l_factor = dirichlet_euler_factor(node.prime, 1.0, chi);
                node.weight = (node.weight * l_factor).clamp(0.0, 2.0);
                if chi == 1 {
                    node.phase = (node.phase + PI / 2.0) % (2.0 * PI);
                } else if chi == -1 {
                    node.phase = (node.phase + 3.0 * PI / 2.0) % (2.0 * PI);
                }
            }
        }
        GaloisAction::FullDuality => {
            for node in &mut new_nodes {
                let chi = dirichlet_char_4(node.prime);
                let l_factor = dirichlet_euler_factor(node.prime, 1.0, chi);
                node.weight = (node.weight * l_factor * st.lambda_m).clamp(0.0, 2.0);
                node.phase = (node.phase + PI) % (2.0 * PI);
            }
            new_nodes.reverse();
        }
    }

    let mut new_st = PrismTensorState {
        time: st.time,
        lambda_m: st.lambda_m,
        nodes: new_nodes,
        coherence: st.coherence,
        is_stable: st.is_stable,
    };
    new_st.recompute_metrics();
    new_st
}

/// Compute Langlands Dual Tensor state:
/// T^{Langlands} = sum_{p_i in P_N} L_{p_i}(s) * G_{p_i} * T_t
pub fn compute_langlands_dual_tensor(st: &PrismTensorState) -> PrismTensorState {
    let dual_nodes: Vec<TensorNode> = st.nodes.iter().map(|node| {
        let chi = dirichlet_char_4(node.prime);
        let l_factor = dirichlet_euler_factor(node.prime, 1.0, chi);
        let dual_weight = (node.weight * l_factor * st.lambda_m).clamp(0.0, 2.0);
        let dual_phase = (node.phase + (node.prime as f64) * 0.5) % (2.0 * PI);
        TensorNode {
            prime: node.prime,
            weight: dual_weight,
            phase: dual_phase,
            energy: node.energy,
        }
    }).collect();

    let mut dual_st = PrismTensorState {
        time: st.time,
        lambda_m: st.lambda_m,
        nodes: dual_nodes,
        coherence: st.coherence,
        is_stable: st.is_stable,
    };
    dual_st.recompute_metrics();
    dual_st
}

/// Compute entanglement fidelity between original and dual state in [0.0, 1.0].
pub fn entanglement_fidelity(st1: &PrismTensorState, st2: &PrismTensorState) -> f64 {
    if st1.nodes.len() != st2.nodes.len() || st1.nodes.is_empty() {
        return 0.0;
    }
    let n = st1.nodes.len() as f64;
    let mut sum_overlap = 0.0;

    for (n1, n2) in st1.nodes.iter().zip(st2.nodes.iter()) {
        let weight_overlap = (n1.weight.min(n2.weight)) / (n1.weight.max(n2.weight).max(1e-6));
        let phase_diff = (n1.phase - n2.phase).abs();
        let phase_cos = phase_diff.cos().max(0.0);
        sum_overlap += weight_overlap * phase_cos;
    }

    (sum_overlap / n).clamp(0.0, 1.0)
}

/// Gravitational Wave packet amplitude modulation:
/// Phi_G(t) = sum_{p_i in P_N} L_{p_i}(s) * G_{p_i} * Psi_t
pub fn gravitational_wave_modulation(st: &PrismTensorState) -> f64 {
    let dual = compute_langlands_dual_tensor(st);
    let mut total_amp = 0.0;
    for node in &dual.nodes {
        total_amp += node.weight * node.energy * (node.phase).sin();
    }
    total_amp / (dual.nodes.len().max(1) as f64)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::LAMBDA_M;

    #[test]
    fn test_galois_permutation_and_duality() {
        let primes = [2, 3, 5, 7, 11];
        let st0 = PrismTensorState::new_with_primes(&primes, LAMBDA_M);

        let perm_st = apply_galois_action(&st0, &GaloisAction::PrimePermute { i: 0, j: 1 });
        assert_eq!(perm_st.nodes[0].prime, 3);
        assert_eq!(perm_st.nodes[1].prime, 2);

        let dual_st = compute_langlands_dual_tensor(&st0);
        assert_eq!(dual_st.nodes.len(), 5);

        let fidelity = entanglement_fidelity(&st0, &dual_st);
        assert!(fidelity >= 0.0 && fidelity <= 1.0);
    }
}
