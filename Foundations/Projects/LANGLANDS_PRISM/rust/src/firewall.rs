use crate::core::LAMBDA_M;
use crate::tensor::{TensorNode, PrismTensorState};

pub const ETHICAL_THRESHOLD: f64 = 0.75;

/// Compute state tomography ethical expectation E(t) = Tr(rho * H_Ethical).
pub fn compute_ethical_metric(st: &PrismTensorState) -> f64 {
    if st.nodes.is_empty() {
        return 0.0;
    }
    let total_power: f64 = st.nodes.iter().map(|n| {
        let state_power = n.weight * n.energy;
        let phase_skew = (n.phase % 1.57) / 1.57 * 0.2;
        state_power + phase_skew
    }).sum();

    (total_power / (st.nodes.len() as f64)).clamp(0.0, 1.0)
}

/// Automated Recursion Collapse Protocol:
/// Quenches high energy modes with Lambda_m^2 and aligns phases harmonically.
pub fn execute_automated_collapse(st: &PrismTensorState) -> PrismTensorState {
    let collapsed_nodes: Vec<TensorNode> = st.nodes.iter().map(|node| {
        let quenched_w = node.weight * LAMBDA_M * LAMBDA_M;
        let harmonic_phase = ((node.prime as f64) * 0.4) % std::f64::consts::PI;
        let quenched_e = node.energy * 0.3;
        TensorNode {
            prime: node.prime,
            weight: quenched_w.clamp(0.0, 1.0),
            phase: harmonic_phase,
            energy: quenched_e.clamp(0.0, 1.0),
        }
    }).collect();

    let mut new_st = PrismTensorState {
        time: st.time,
        lambda_m: st.lambda_m,
        nodes: collapsed_nodes,
        coherence: 0.9,
        is_stable: true,
    };
    new_st.recompute_metrics();
    new_st
}

/// Firewall validation gate: evaluates state and triggers collapse if ethical metric breaches threshold.
pub fn firewall_gate(st: &PrismTensorState) -> (PrismTensorState, bool) {
    let metric = compute_ethical_metric(st);
    if metric > ETHICAL_THRESHOLD {
        let collapsed = execute_automated_collapse(st);
        (collapsed, true)
    } else {
        (st.clone(), false)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ethical_firewall_and_collapse() {
        let primes = [2, 3, 5, 7, 11];
        let st0 = PrismTensorState::new_with_primes(&primes, LAMBDA_M);
        let (safe_st, was_triggered) = firewall_gate(&st0);
        assert!(!was_triggered);
        assert!(compute_ethical_metric(&safe_st) <= ETHICAL_THRESHOLD);

        // Construct high-energy breach state
        let breach_nodes = vec![TensorNode::new(2, 1.0, 1.5, 1.0), TensorNode::new(3, 1.0, 1.5, 1.0)];
        let breach_st = PrismTensorState {
            time: 0,
            lambda_m: LAMBDA_M,
            nodes: breach_nodes,
            coherence: 0.5,
            is_stable: true,
        };

        let (recovered_st, was_triggered_breach) = firewall_gate(&breach_st);
        assert!(was_triggered_breach);
        assert!(compute_ethical_metric(&recovered_st) < ETHICAL_THRESHOLD);
    }
}
