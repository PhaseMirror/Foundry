use crate::{Result, ComplexKappaError};

/// Compute the nth non-trivial zero of the Riemann zeta function.
/// Returns (gamma_n, a_n) where a_n = epsilon^2 * exp(-2 * sigma * gamma_n^2).
///
/// This implementation uses a precomputed table of the first 32 zeros
/// for bounded verification. In production, replace with a numerical
/// root-finder (e.g., Riemann-Siegel formula) behind a configurable backend.
///
/// # Kani Verification
///
/// For Kani bounded model checking, n is bounded to N <= 32.
#[inline]
pub fn zeta_zero(n: u32, epsilon: f64, sigma: f64) -> Result<(f64, f64)> {
    if n == 0 || n > 32 {
        return Err(ComplexKappaError::InvalidParameter(
            format!("n must be in [1, 32], got {}", n)
        ));
    }
    if epsilon <= 0.0 || sigma <= 0.0 {
        return Err(ComplexKappaError::InvalidParameter(
            "epsilon and sigma must be positive".into()
        ));
    }

    let gamma = ZETA_ZERO_TABLE[(n - 1) as usize];
    let a_n = epsilon.powi(2) * (-2.0 * sigma * gamma.powi(2)).exp();
    Ok((gamma, a_n))
}

/// Precomputed table of the first 32 nontrivial zeros of the Riemann zeta function.
/// Source: Odlyzko-Schonhage tables (high-precision).
const ZETA_ZERO_TABLE: [f64; 32] = [
    14.134725141734693790457251983562470270,
    21.022039638771554992628479593896902075,
    25.010857580145688763213790992562551427,
    30.424876125859513210311897530584091320,
    32.935061587739189691662588928332207252,
    37.586178158825671257217763480705532857,
    40.918719012147465187059153133763075409,
    43.327073280914999519496122165406805782,
    48.005150881167159727942472749427595141,
    49.773832477672302194916282898551035571,
    52.970321477714460639148296338227141555,
    56.446247697063394804367759476706432223,
    59.347044002602353079653648674992219831,
    60.831778524609809844259613472994251614,
    65.112544048081606660875054253383705486,
    67.079810529494173714478828496535390762,
    69.546401711173979252747857106446629020,
    72.067158674840929907524557371971657044,
    75.704690699083933169546594176694459441,
    77.144840068874805372628664320159943577,
    79.337375020249367922723597524499254908,
    82.854380446044328885896290579506955287,
    84.735492980517450105255265553678297616,
    87.425274613125229406094883324341002161,
    88.809111207634465824600697013779449153,
    92.491899270558484100156146266689766128,
    94.651344040519886966412007022924371516,
    95.870782228524324132415860131809873414,
    98.831194218193692235324527223572094526,
    101.317851005857399406241258408128691694,
    103.725538824115873699427481374637054087,
    105.446623052326074640263034419133373927,
];

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_zeta_zero_first() {
        let (gamma, a_n) = zeta_zero(1, 1e-2, 1e-3).unwrap();
        assert!((gamma - 14.1347251417).abs() < 1e-6);
        let expected_a = 1e-4 * (-2.0 * 1e-3 * 14.1347251417_f64.powi(2)).exp();
        assert!((a_n - expected_a).abs() < 1e-10);
    }

    #[test]
    fn test_zeta_zero_bounds() {
        assert!(zeta_zero(0, 1e-2, 1e-3).is_err());
        assert!(zeta_zero(33, 1e-2, 1e-3).is_err());
        assert!(zeta_zero(1, 0.0, 1e-3).is_err());
        assert!(zeta_zero(1, 1e-2, 0.0).is_err());
    }
}
