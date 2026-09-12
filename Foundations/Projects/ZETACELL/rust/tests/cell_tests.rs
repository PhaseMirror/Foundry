use zetacell::bridge::{BridgeKernel, PRIMES, RIEMANN_ZEROS};
use zetacell::cell::{ZetaCell, ZetaCellConfig};
use zetacell::state::ZetaState;

#[test]
fn test_zetacell_step_and_contraction() {
    let n_p = 4;
    let n_z = 4;
    let n_f = 2;
    let n_g = 2;

    let zeros = &RIEMANN_ZEROS[..n_z];
    let primes = &PRIMES[..n_p];
    let bridge = BridgeKernel::new_explicit(n_p, n_z, zeros, primes);

    let config = ZetaCellConfig::default();
    let cell = ZetaCell::new(config, bridge);

    let mut state = ZetaState::new(n_p, n_f, n_z, n_g);
    for x in &mut state.psi {
        *x = 2.0;
    }
    for x in &mut state.chi {
        *x = 2.0;
    }

    let initial_norm = state.norm();
    let trajectory = cell.run_trajectory(&state, 20, 0.0);
    let final_norm = trajectory.last().unwrap().norm();

    assert!(final_norm < initial_norm, "Trajectory must contract toward fixed point");
}
