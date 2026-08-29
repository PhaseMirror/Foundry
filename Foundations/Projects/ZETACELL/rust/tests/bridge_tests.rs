use zetacell::bridge::{BridgeKernel, PRIMES, RIEMANN_ZEROS};

#[test]
fn test_bridge_kernel_and_forward_passes() {
    let n_p = 8;
    let n_z = 8;
    let n_f = 4;
    let n_g = 4;

    let zeros = &RIEMANN_ZEROS[..n_z];
    let primes = &PRIMES[..n_p];
    let bridge = BridgeKernel::new_explicit(n_p, n_z, zeros, primes);

    assert_eq!(bridge.k_matrix.len(), n_p * n_z);

    let psi = vec![1.0; n_p * n_f];
    let chi = vec![1.0; n_z * n_g];

    let pz_out = bridge.forward_pz(&psi, n_f, n_g);
    let zp_out = bridge.forward_zp(&chi, n_f, n_g);

    assert_eq!(pz_out.len(), n_z * n_g);
    assert_eq!(zp_out.len(), n_p * n_f);
}
