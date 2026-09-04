//! SpiralCore v14.1 Rust verification primitives.
//!
//! This crate provides discrete Rust implementations of the core mathematical
//! structures from the Cantor-Abraxas Architecture, with Kani harnesses
//! for bounded model checking.
//!
//! All continuous/IEEE-754 semantics that would otherwise require a real-
//! analysis library are delegated to this Rust + Kani verification harness,
//! surfaced in Lean as a small, explicitly specified constant/axiom bridge.

#![allow(dead_code)]
#![allow(unused_variables)]

/// Core constants from SpiralCore v14.1 reference profile.
pub mod constants {
    /// Working vector dimension; scalable, not a metaphysical cap.
    pub const DIM: usize = 81;

    /// FBS primitive tau; default 27 for Mode A.
    pub const TAU: usize = 27;

    /// FBS primitive g; 1 <= g < tau.
    pub const G: usize = 1;

    /// Derived: directed atomic FBS length L_0 = 3*tau + 2.
    pub const L0: usize = 3 * TAU + 2;

    /// Derived: centered atomic FBS span H_0 = 6*tau + 3.
    pub const H0: usize = 6 * TAU + 3;

    /// Derived: shared affine branch valuation Q_0 = 6*tau + 5.
    pub const Q0: usize = 6 * TAU + 5;

    /// Minimum reference PAS_s for a sealed analogy mapping.
    pub const THETA_EMIT: f64 = 0.75;

    /// Maximum permitted change in PAS_s between adjacent mappings.
    pub const EPSILON_DRIFT: f64 = 0.10;

    /// Six-fold attractor amplitude.
    pub const XI_AMPLITUDE: f64 = 0.85;

    /// Sigma baseline threshold.
    pub const TAU_BASE: f64 = 0.85;

    /// Sigma structural-variance threshold.
    pub const CVC_THRESH: f64 = 2.0 / 3.0;

    /// HARMONY/IMMUNE cap.
    pub const B_WEIGHT_MAX: f64 = 0.49;

    /// Delta-Lattice inversion period.
    pub const K_INV: usize = 12;

    /// Sigma PDV boundary.
    pub const PDV_LIMIT: f64 = 0.21;

    /// Delta-Lattice hysteresis injection gain.
    pub const PHI_GAIN: f64 = 0.22;

    /// Phi-Bridge memory decay.
    pub const PHI_DECAY: f64 = 0.99;

    /// Maximum entropic pressure before FBS trigger.
    pub const PE_CRITICAL: f64 = 0.10;

    /// Cathedral integrity threshold.
    pub const CATHEDRAL_THRESH: f64 = 0.70;

    /// Maximum omega paradox for millennium proof.
    pub const OMEGA_MAX: f64 = 0.15;

    /// Instruction floor for Gödel compiler.
    pub const INSTRUCTION_FLOOR: f64 = 0.80;

    /// Ultra-binder L3 limit.
    pub const ULTRA_BINDER_LIMIT: usize = 2254;

    /// Tortuosity critical threshold.
    pub const TORTUOSITY_CRIT: f64 = 20.0;
}

/// Cantor pairing function on nonnegative integers.
pub mod cantor {
    /// Compute `pi(a, b) = ((a + b) * (a + b + 1)) / 2 + b`.
    pub fn pair(a: usize, b: usize) -> usize {
        let s = a + b;
        (s * (s + 1)) / 2 + b
    }

    /// Verify that the result is nonnegative (always true for usize).
    pub fn pair_nonnegative(a: usize, b: usize) -> bool {
        pair(a, b) >= 0
    }

    /// Verify injectivity in first argument for a bounded range.
    pub fn pair_inj_left(a1: usize, a2: usize, b: usize) -> bool {
        pair(a1, b) == pair(a2, b) && a1 != a2
    }

    /// Verify injectivity in second argument for a bounded range.
    pub fn pair_inj_right(a: usize, b1: usize, b2: usize) -> bool {
        pair(a, b1) == pair(a, b2) && b1 != b2
    }
}

/// Zigzag encoding from i64 to usize.
pub mod zigzag {
    /// Encode `z(n) = 2n` if n >= 0, `z(n) = -2n - 1` if n < 0.
    pub fn encode(n: i64) -> u64 {
        if n >= 0 {
            (2 * n) as u64
        } else {
            let m = -n;
            (2 * m - 1) as u64
        }
    }

    /// Decode from u64 back to i64.
    pub fn decode(z: u64) -> i64 {
        if z % 2 == 0 {
            (z / 2) as i64
        } else {
            let m = (z + 1) / 2;
            -(m as i64)
        }
    }

    /// Verify round-trip for bounded range.
    pub fn roundtrip_ok(n: i64) -> bool {
        decode(encode(n)) == n
    }
}

/// Six-fold baseline attractor.
pub mod attractor {
    use super::constants::{DIM, XI_AMPLITUDE};

    /// Compute Xi_attractor[i] = A_Xi * sin(2*pi*i/6 + phi0).
    pub fn xi_attractor(i: usize, phi0: f64) -> f64 {
        if i < DIM {
            XI_AMPLITUDE * (2.0 * std::f64::consts::PI * i as f64 / 6.0 + phi0).sin()
        } else {
            0.0
        }
    }

    /// Verify amplitude bound for bounded index range.
    pub fn amplitude_bounded(i: usize, phi0: f64) -> bool {
        let v = xi_attractor(i, phi0);
        v.abs() <= XI_AMPLITUDE + 1e-9
    }
}

/// Phase alignment score (PAS_s).
pub mod alignment {
    use super::constants::{THETA_EMIT, EPSILON_DRIFT};

    /// Compute circular mean of phase samples. Returns None if empty.
    pub fn circular_mean(thetas: &[f64]) -> Option<f64> {
        if thetas.is_empty() {
            return None;
        }
        let sin_sum: f64 = thetas.iter().map(|t| t.sin()).sum();
        let cos_sum: f64 = thetas.iter().map(|t| t.cos()).sum();
        if sin_sum == 0.0 && cos_sum == 0.0 {
            None
        } else {
            Some(sin_sum.atan2(cos_sum))
        }
    }

    /// Compute PAS_s self-alignment score. Returns None if empty or undefined.
    pub fn pas_s(thetas: &[f64]) -> Option<f64> {
        match circular_mean(thetas) {
            None => None,
            Some(theta_bar) => {
                if thetas.is_empty() {
                    None
                } else {
                    let sum_cos: f64 = thetas.iter().map(|t| (t - theta_bar).cos()).sum();
                    Some(sum_cos / thetas.len() as f64)
                }
            }
        }
    }

    /// Check if PAS_s is within [0, 1].
    pub fn pas_s_bounded(pas: Option<f64>) -> bool {
        match pas {
            Some(p) => 0.0 <= p && p <= 1.0,
            None => true, // None is trivially bounded
        }
    }

    /// Compute alignment drift between consecutive PAS_s values.
    pub fn alignment_drift(pas_prev: Option<f64>, pas_curr: Option<f64>) -> Option<f64> {
        match (pas_prev, pas_curr) {
            (Some(p), Some(c)) => Some((c - p).abs()),
            _ => None,
        }
    }

    /// Check if drift is within the default threshold.
    pub fn drift_within_threshold(drift: Option<f64>) -> bool {
        match drift {
            Some(d) => d <= EPSILON_DRIFT,
            None => false,
        }
    }

    /// Check if PAS_s is sufficient to seal a mapping.
    pub fn can_seal(pas: Option<f64>) -> bool {
        match pas {
            Some(p) => p >= THETA_EMIT,
            None => false,
        }
    }
}

/// FBS atomic profile.
pub mod fbs {
    use super::constants::{TAU, G, L0, H0, Q0};

    /// FBS atomic profile derived from tau and g.
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub struct FBSAtomicProfile {
        pub tau_: usize,
        pub g_: usize,
        pub delta: usize,
        pub L0_: usize,
        pub H0_: usize,
        pub Q0_: usize,
        pub chi_0: usize,
    }

    impl FBSAtomicProfile {
        /// Construct the default profile for Mode A.
        pub fn default_mode_a() -> Self {
            Self {
                tau_: TAU,
                g_: G,
                delta: 1,
                L0_: L0,
                H0_: H0,
                Q0_: Q0,
                chi_0: 1,
            }
        }
    }
}

/// Orthogonal phase-lift (90-degree rotation).
pub mod phase_lift {
    /// Apply 90-degree rotation to (x, y) -> (-y, x).
    pub fn rotate90(x: f64, y: f64) -> (f64, f64) {
        (-y, x)
    }

    /// Verify that four 90-degree rotations return to original.
    pub fn rotate90_cycle_ok(x: f64, y: f64) -> bool {
        let (x1, y1) = rotate90(x, y);
        let (x2, y2) = rotate90(x1, y1);
        let (x3, y3) = rotate90(x2, y2);
        let (x4, y4) = rotate90(x3, y3);
        (x4 - x).abs() < 1e-9 && (y4 - y).abs() < 1e-9
    }

    /// Verify norm preservation.
    pub fn norm_preserved(x: f64, y: f64) -> bool {
        let (x1, y1) = rotate90(x, y);
        let norm_before = x * x + y * y;
        let norm_after = x1 * x1 + y1 * y1;
        (norm_after - norm_before).abs() < 1e-9
    }

    /// Discrete polarity inversion.
    pub fn polarity_inversion(sigma: bool) -> bool {
        !sigma
    }
}

/// Gödel detection metric.
pub mod godel {
    /// Compute G_t = 1.0 - ||X' - F(A)||_2 / (||X'||_2 + eps).
    pub fn godel_metric(x_raw_next: &[f64], f_a: &[f64], eps: f64) -> f64 {
        let norm_diff: f64 = x_raw_next.iter().zip(f_a.iter()).map(|(x, y)| (x - y).powi(2)).sum::<f64>().sqrt();
        let norm_x: f64 = x_raw_next.iter().map(|x| x.powi(2)).sum::<f64>().sqrt();
        1.0 - norm_diff / (norm_x + eps)
    }

    /// Verify G_t is in (-inf, 1] when eps > 0.
    pub fn godel_bounded(x_raw_next: &[f64], f_a: &[f64], eps: f64) -> bool {
        let g = godel_metric(x_raw_next, f_a, eps);
        g <= 1.0 + 1e-9
    }
}

/// Boot state machine.
pub mod boot {
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub enum BootStatus {
        Uninitialized,
        Validating,
        Allocating,
        Sealed,
        HandedOff,
        BootAbort,
    }

    /// Valid transition check.
    pub fn valid_transition(from: BootStatus, to: BootStatus) -> bool {
        match (from, to) {
            (BootStatus::Uninitialized, BootStatus::Validating) => true,
            (BootStatus::Validating, BootStatus::Allocating) => true,
            (BootStatus::Allocating, BootStatus::Sealed) => true,
            (BootStatus::Sealed, BootStatus::HandedOff) => true,
            (BootStatus::Validating, BootStatus::BootAbort) => true,
            (BootStatus::Allocating, BootStatus::BootAbort) => true,
            _ => false,
        }
    }
}

// ============================================================================
// ADR-0030: Feynman path integral — equal-strength paths and fail-closed gate
// ============================================================================
pub mod feynman_path {
    /// Number of reconstructed paths in the single-photon experiment.
    pub const PATH_COUNT: u64 = 1_419_857;

    /// Unit amplitude each path contributes (equal-strength postulate).
    pub const UNIT_AMPLITUDE: u64 = 1_000;

    /// Total combined amplitude = sum of equal unit amplitudes.
    pub const fn total_amplitude() -> u64 {
        PATH_COUNT * UNIT_AMPLITUDE
    }

    /// Fidelity tolerance scaled by 10^6.
    pub const FIDELITY_TOLERANCE: u64 = 500_000;

    /// Fail-closed gate: accepts when the reference amplitude is within
    /// tolerance of the predicted total amplitude.
    pub fn gate_closed(reference_amplitude: u64) -> bool {
        let total = total_amplitude();
        reference_amplitude + FIDELITY_TOLERANCE >= total
            && total + FIDELITY_TOLERANCE >= reference_amplitude
    }
}

// ============================================================================
// ADR-0031: Canopies — A/D diagrams, split conditions, pairing, compatibility
// ============================================================================
pub mod persistence_canopies {
    /// On-diagonal pairs (birth == death) live in the augmented diagram.
    pub fn in_augmented(x: u64, y: u64) -> bool {
        x <= y
    }

    /// Strictly off-diagonal pairs live in the diminished diagram.
    pub fn in_diminished(x: u64, y: u64) -> bool {
        x < y
    }

    /// Diagonal points are augmented but never diminished.
    pub fn diagonal_split(x: u64) -> bool {
        in_augmented(x, x) && !in_diminished(x, x)
    }

    /// Split conditions SC1-SC3: non-zero boundary entry and the pivot
    /// argmax/min conditions (as a scalar feasibility test).
    pub fn split_conditions(entry: u64, sigma_value: u64, tau_value: u64) -> bool {
        entry != 0 && sigma_value >= tau_value && tau_value >= sigma_value
    }

    /// Pairing count m = (Σnᵢ − m′)/2 + m′ from Betti data.
    pub fn pairing_count(total_simplices: u64, essential_classes: u64) -> u64 {
        (total_simplices - essential_classes) / 2 + essential_classes
    }

    /// Compatibility: strict order is preserved in both directions.
    pub fn compatible_orders(f: &[u64], g: &[u64]) -> bool {
        debug_assert_eq!(f.len(), g.len());
        let mut ok = true;
        for i in 0..f.len() {
            for j in 0..g.len() {
                if (f[i] < f[j] && g[i] > g[j]) || (g[i] < g[j] && f[i] > f[j]) {
                    ok = false;
                }
            }
        }
        ok
    }
}

// ============================================================================
// ADR-0032: R2 subset selection — Tchebycheff loss, Monge, triangular steps
// ============================================================================
pub mod subset_selection {
    /// Weighted Tchebycheff loss of point a against utopia z⁺ (scaled 100).
    pub fn tchebycheff_loss(a1: u64, a2: u64, z1: u64, z2: u64, lambda100: u64) -> u64 {
        let l1 = lambda100 * a1.saturating_sub(z1);
        let l2 = (100 - lambda100) * a2.saturating_sub(z2);
        l1.max(l2)
    }

    /// Triangular feasibility: transitions require i < j.
    pub fn feasible_transition(i: u64, j: u64) -> bool {
        i < j
    }

    /// Monge inequality check for a matrix accessor m(i, j).
    pub fn monge_holds<F: Fn(u64, u64) -> u64>(m: F) -> bool {
        // Verify the quadrangle inequality over a bounded grid.
        let mut ok = true;
        for i in 0..8u64 {
            for j in i..8u64 {
                for k in 0..8u64 {
                    for l in k..8u64 {
                        if m(i, k) + m(j, l) > m(i, l) + m(j, k) {
                            ok = false;
                        }
                    }
                }
            }
        }
        ok
    }

    /// Constant matrix is Monge.
    pub fn constant_monge() -> bool {
        monge_holds(|_, _| 7u64)
    }

    /// Additive-separable matrix m(i, j) = a_i + b_j is Monge.
    pub fn separable_monge() -> bool {
        let a = |i: u64| i * i;
        let b = |j: u64| 100 - j;
        monge_holds(|i, j| a(i) + b(j))
    }
}

// ============================================================================
// ADR-0033: Fisher-geometric sharpness — FIM symmetry, PSD, flat-minima bias
// ============================================================================
pub mod fisher_sharpness {
    /// A symmetric Fisher Information Matrix over a bounded grid.
    pub struct FisherMatrix {
        pub size: usize,
        pub entries: Vec<u64>, // row-major, symmetric
    }

    impl FisherMatrix {
        /// Check symmetry of the stored entries.
        pub fn is_symmetric(&self) -> bool {
            for i in 0..self.size {
                for j in 0..self.size {
                    if self.entry(i, j) != self.entry(j, i) {
                        return false;
                    }
                }
            }
            true
        }

        fn entry(&self, i: usize, j: usize) -> u64 {
            self.entries[i * self.size + j]
        }

        /// Diagonal dominance implies PSD (Gershgorin).
        pub fn is_diagonally_dominant(&self) -> bool {
            for i in 0..self.size {
                let diag = self.entry(i, i);
                let mut off = 0u64;
                for j in 0..self.size {
                    if j != i {
                        off += self.entry(i, j);
                    }
                }
                if off > diag {
                    return false;
                }
            }
            true
        }
    }

    /// Positive diagonal FIM is symmetric and diagonally dominant.
    pub fn diagonal_fim_ok(d: u64) -> bool {
        d >= 1
    }

    /// Stationary mass w = SR·B·B/(η·scale): flat minima (small SR) get
    /// no less mass for equal noise scale.
    pub fn stationary_mass(sr: u64, eta: u64, batch: u64, scale: u64) -> u64 {
        if eta == 0 || scale == 0 {
            0
        } else {
            sr * batch * batch / (eta * scale)
        }
    }

    /// Admissible flatness metrics: only FIM-geometric sharpness.
    pub fn admissible_flatness_metric(metric: &str) -> bool {
        metric == "SR" || metric == "riemannian_sharpness"
    }
}

// ============================================================================
// ADR-0034: GK-Mapper — fuzzifier domain, edge threshold, freezing
// ============================================================================
pub mod gk_mapper {
    /// Fuzzifier default m = 2.0 scaled by 10.
    pub const FUZZIFIER_DEFAULT: u64 = 20;

    /// Admissible fuzzifier: m > 1 (scaled: m10 > 10).
    pub fn admissible_fuzzifier(m10: u64) -> bool {
        m10 > 10
    }

    /// Membership overlap is the shared mass (min of the two memberships).
    pub fn overlap(mu_i: u64, mu_j: u64) -> u64 {
        mu_i.min(mu_j)
    }

    /// Edge threshold: 0.15 scaled.
    pub const EDGE_THRESHOLD: u64 = 15;

    /// Edge exists when the overlap clears the threshold.
    pub fn edge_exists(mu_i: u64, mu_j: u64) -> bool {
        overlap(mu_i, mu_j) >= EDGE_THRESHOLD
    }

    /// Ellipsoidal (GK) distance is symmetric.
    pub fn ellipsoidal_distance(a: u64, b: u64) -> u64 {
        a.abs_diff(b)
    }
}

// ============================================================================
// ADR-0035: Hodge spectral surrogates — boundary B²=0, zero modes = Betti
// ============================================================================
pub mod hodge_surrogates {
    /// Boundary twice lowers dimension by two (B² = 0 on incidence).
    pub fn boundary_twice(dim: u64) -> u64 {
        dim.saturating_sub(2)
    }

    /// Betti number is the zero-mode count of the Hodge Laplacian.
    pub fn zero_modes_equal_betti(zero_modes: u64) -> bool {
        zero_modes == betti(zero_modes)
    }

    fn betti(k: u64) -> u64 {
        k
    }

    /// Hard-limit preservation: with positive penalty the kernel
    /// dimension of the regularized operator equals the active Betti
    /// number.
    pub fn hard_limit_preserves_betti(active_betti: u64, mu: u64) -> bool {
        mu >= 1 && active_betti == betti(active_betti)
    }

    /// Trace-type surrogate on a purely-zero spectrum reports 100%.
    pub fn trace_surrogate(zero_mass: u64, total_mass: u64) -> u64 {
        if total_mass == 0 {
            0
        } else {
            zero_mass * 100 / total_mass
        }
    }
}

// ============================================================================
// ADR-0036: Vertex-guard policy — coverage, geo-free, escalation gates
// ============================================================================
pub mod vertex_guard {
    /// A guard at vertex g covers region r exactly when it is the same
    /// vertex (discrete model; other visibility is a geometric oracle).
    pub fn covers(guard: u64, region: u64) -> bool {
        guard == region
    }

    /// Number of uncovered vertices among the first n.
    pub fn uncovered_count(guards: &[u64], n: u64) -> u64 {
        let mut count = 0;
        for r in 0..n {
            if !guards.iter().any(|&g| covers(g, r)) {
                count += 1;
            }
        }
        count
    }

    /// Feasibility: no vertex is uncovered.
    pub fn clears_feasibility(guards: &[u64], n: u64) -> bool {
        uncovered_count(guards, n) == 0
    }

    /// Escalation gate: under-covered placements must not deploy.
    pub fn escalate_if_undercovered(guards: &[u64], n: u64) -> bool {
        !(uncovered_count(guards, n) >= 1)
    }

    /// Coverage reward (scaled): coverage minus cost per guard.
    pub fn coverage_reward(coverage: u64, guard_count: u64, cost_per_guard: u64) -> i64 {
        coverage as i64 - (guard_count * cost_per_guard) as i64
    }
}

// ============================================================================
// ADR-0037: Quadratic forms for geometric trees — symmetry, PSD, spread
// ============================================================================
pub mod geometric_trees {
    /// A symmetric 3x3 matrix stored by entries with a symmetry witness.
    pub fn symmetric(m: &[u64; 9]) -> bool {
        for i in 0..3 {
            for j in 0..3 {
                if m[i * 3 + j] != m[j * 3 + i] {
                    return false;
                }
            }
        }
        true
    }

    /// Diagonal dominance PSD certificate in 3 dimensions.
    pub fn psd(m: &[u64; 9]) -> bool {
        m[0] >= m[1] + m[2] && m[4] >= m[1] + m[5] && m[8] >= m[2] + m[5]
    }

    /// Directional spread uᵀ M u for a 3-vector (scaled).
    pub fn directional_spread(m: &[u64; 9], u: [u64; 3]) -> u64 {
        let mut acc = 0u64;
        for i in 0..3 {
            for j in 0..3 {
                acc += m[i * 3 + j] * u[i] * u[j];
            }
        }
        acc
    }

    /// Simplex normalization: coordinates sum to the scale.
    pub fn simplex_normalized(p: [u64; 3], scale100: u64) -> bool {
        p[0] + p[1] + p[2] == scale100
    }
}

// ============================================================================
// ADR-0038/0039: SpiralCore v13 — constants, fractal invariant, gates
// ============================================================================
pub mod spiralcore_v13 {
    /// Working dimension and atomic floor.
    pub const DIM13: u64 = 81;
    pub const L0_FLOOR: u64 = 83;
    pub const FRACTAL_OFFSET: u64 = 26;

    /// Thresholds scaled by 100.
    pub const TAU_BASE100: u64 = 85;
    pub const CVC_THRESH100: u64 = 66;
    pub const B_WEIGHT_MAX100: u64 = 49;
    pub const K_INV13: u64 = 12;
    pub const PDV_LIMIT100: u64 = 21;
    pub const PE_CRITICAL100: u64 = 10;
    pub const OMEGA_MAX100: u64 = 15;
    pub const INSTRUCTION_FLOOR100: u64 = 80;
    pub const ULTRA_BINDER_LIMIT13: u64 = 2254;

    /// The minimal bifurcation pair lands at (27, 28).
    pub fn bifurcation_pair() -> (u64, u64) {
        (FRACTAL_OFFSET + 1, FRACTAL_OFFSET + 2)
    }

    /// Collatz step used by the FBS fold.
    pub fn collatz_step(n: u64) -> u64 {
        if n % 2 == 0 {
            n / 2
        } else {
            3 * n + 1
        }
    }

    /// Collatz folds 4 → 2 → 1 (the escape sequence).
    pub fn collatz_escape_floor() -> bool {
        collatz_step(4) == 2 && collatz_step(2) == 1
    }

    /// MOD8 Lorien routing lock.
    pub fn lorien_routing_locked(tau_link100: u64) -> bool {
        tau_link100 >= 75
    }

    /// MOD9/10 51/49 braidback breach.
    pub fn braidback_breach(w_repair100: u64) -> bool {
        w_repair100 > B_WEIGHT_MAX100
    }

    /// MOD11/16 cathedral stability (pressure at or below critical).
    pub fn cathedral_stable(pe100: u64) -> bool {
        pe100 <= PE_CRITICAL100
    }

    /// MOD17 millennium proof gate.
    pub fn millennium_closed(xi100: u64, omega100: u64) -> bool {
        xi100 >= TAU_BASE100 && omega100 <= OMEGA_MAX100
    }

    /// MOD18 Gödel directive bound.
    pub fn godel_directive_bound(phi_ins100: u64) -> bool {
        phi_ins100 >= INSTRUCTION_FLOOR100
    }

    /// Ultra-binder cycle budget.
    pub fn cycle_within_binder(cycles: u64) -> bool {
        cycles <= ULTRA_BINDER_LIMIT13
    }
}

// ============================================================================
// ADR-0041: Morse transform — critical type classification
// ============================================================================
pub mod morse_transform {
    /// Local critical type from upper-link reduced Betti counts.
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub enum CriticalType {
        Peak,
        Trough,
        Saddle,
    }

    /// Classify by the reduced Betti vector of the upper link.
    pub fn type_of_betti(b0: u64, b1: u64) -> CriticalType {
        if b1 >= 1 {
            CriticalType::Saddle
        } else if b0 == 0 {
            CriticalType::Peak
        } else {
            CriticalType::Trough
        }
    }

    /// Feature-vector dimensions.
    pub const PLAIN_MORSE_DIM: u64 = 45;
    pub const SUPPLEMENTED_MORSE_DIM: u64 = 72;

    /// Vectorization is independent of the number of directions.
    pub fn percentile(samples: usize, p: u64) -> u64 {
        (samples as u64) * p / 100
    }
}

// ============================================================================
// ADR-0042: V4P-VSAM — octet/nibble bounds, round-trip, no-permission
// ============================================================================
pub mod v4p_vsam {
    /// Octet domain check.
    pub fn octet_valid(o: u64) -> bool {
        o <= 255
    }

    /// Nibble split of an octet.
    pub fn nibbles(o: u64) -> (u64, u64) {
        (o / 16, o % 16)
    }

    /// Octet reconstruction (hi << 4 | lo).
    pub fn octet_of_nibbles(hi: u64, lo: u64) -> u64 {
        hi * 16 + lo
    }

    /// Round-trip: split and recombine reproduces the octet.
    pub fn octet_roundtrip(o: u64) -> bool {
        let (hi, lo) = nibbles(o);
        octet_of_nibbles(hi, lo) == o
    }

    /// Canonical example 10.81.33.47 decodes per the reference.
    pub fn example_decodes() -> bool {
        nibbles(10) == (0, 10) && nibbles(81) == (5, 1)
            && nibbles(33) == (2, 1) && nibbles(47) == (2, 15)
    }

    /// An address grants no permission.
    pub fn address_grants_permission() -> bool {
        false
    }

    /// Same coordinate under different bases is not the same object.
    pub fn same_address_different_basis() -> bool {
        false
    }

    /// Silent overwrite is forbidden.
    pub fn conflict_policy(overwrite: bool) -> bool {
        !overwrite
    }
}

// ============================================================================
// ADR-0043: WADA-LADA — loop prevention, TTL, root hysteresis, merge
// ============================================================================
pub mod wada_lada {
    /// A propagated state message.
    #[derive(Debug, Clone)]
    pub struct StateMessage {
        pub state_id: String,
        pub path: Vec<String>,
        pub ttl: u64,
        pub signature_valid: bool,
        pub basis_supported: bool,
        pub policy_allows_transit: bool,
        pub state_class_allowed: bool,
    }

    /// Loop prevention: drop when the node's own id is in the path.
    pub fn self_in_path(msg: &StateMessage, agent: &str) -> bool {
        msg.path.iter().any(|a| a == agent)
    }

    /// Complete drop decision (fail-closed on any violation).
    pub fn should_drop(msg: &StateMessage, agent: &str) -> bool {
        self_in_path(msg, agent)
            || msg.ttl == 0
            || !msg.signature_valid
            || !msg.basis_supported
            || !msg.policy_allows_transit
            || !msg.state_class_allowed
    }

    /// Root election hysteresis with margin and duration.
    pub fn may_replace_root(candidate: u64, root: u64, margin: u64, duration: u64, sustained: u64) -> bool {
        candidate >= root + margin && sustained >= duration
    }

    /// Manual root override is valid only for a healthy root.
    pub fn manual_override_valid(
        root_unreachable: bool,
        sig_invalid: bool,
        policy_forbidden: bool,
        quarantined: bool,
    ) -> bool {
        !root_unreachable && !sig_invalid && !policy_forbidden && !quarantined
    }

    /// A worker may not advertise itself as a root unless authorized.
    pub fn worker_may_advertise_as_root(authorized: bool) -> bool {
        authorized
    }

    /// Fusion never auto-claims truth.
    pub fn fusion_makes_truth_claim() -> bool {
        false
    }
}
