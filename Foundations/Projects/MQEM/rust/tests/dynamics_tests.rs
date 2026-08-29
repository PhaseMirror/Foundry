use mqem::dynamics::MqemSimulator;
use mqem::types::{DispersalEdge, HabitatGraph, ModelConfig, PatchState};

#[test]
fn test_dynamics_step_and_non_negativity() {
    let edges = vec![
        DispersalEdge {
            source: 0,
            target: 1,
            weight: 0.2,
        },
        DispersalEdge {
            source: 1,
            target: 2,
            weight: 0.2,
        },
    ];
    let graph = HabitatGraph::new(3, edges);
    let config = ModelConfig {
        dim_d: 1,
        delay_tau: 2,
        dt: 0.05,
        growth_rate: 1.0,
        carrying_capacity: 5.0,
        noise_sigma: 0.01,
        coupling_scale: 0.2,
    };
    let initial_states = vec![
        PatchState::new(vec![2.0]),
        PatchState::new(vec![1.0]),
        PatchState::new(vec![0.5]),
    ];

    let mut sim = MqemSimulator::new(graph, config, initial_states);
    let mut rng = rand::thread_rng();

    for _ in 0..50 {
        sim.step(None, &mut rng);
        for state in &sim.states {
            assert!(state.values[0] >= 0.0, "State must remain non-negative");
            assert!(state.values[0].is_finite(), "State must remain finite");
        }
    }
    assert_eq!(sim.current_time, 50);
}

#[test]
fn test_zero_dt_preserves_state() {
    let graph = HabitatGraph::new(2, Vec::new());
    let config = ModelConfig {
        dim_d: 1,
        delay_tau: 1,
        dt: 0.0,
        noise_sigma: 0.0,
        ..Default::default()
    };
    let initial = vec![PatchState::new(vec![3.14]), PatchState::new(vec![2.71])];
    let mut sim = MqemSimulator::new(graph, config, initial.clone());
    let mut rng = rand::thread_rng();

    sim.step(None, &mut rng);
    assert_eq!(sim.states[0].values[0], initial[0].values[0]);
    assert_eq!(sim.states[1].values[0], initial[1].values[0]);
}
