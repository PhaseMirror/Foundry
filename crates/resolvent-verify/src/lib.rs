// Core matrix / kernel / Hamiltonian machinery and the diagnostic, shared by
// the `resolvent_verify` (Kani identity proof + sanity check) and
// `resolvent_scan` (parameter-sweep diagnostic) binaries.
//
// No mathlib is used: this is plain Rust + Kani. See `main.rs` for the Kani
// proofs and the honest discussion of the expansion's validity.

pub mod basis_data;

/// Universal Multiplicity Constant, defined as the sup norm of the Xi_simple
/// kernel over the 256-state basis: Λ_m = ||Xi_simple||_∞ ≈ 108. Normalizing
/// the interaction by Λ_m turns the perturbation strength from κγ·||Xi|| (O(1))
/// into κγ·1, so the first-order truncation is a small perturbation.
///
/// The value 108.0 equals `lambda_m_exact()` computed from `basis_data`; the
/// two are asserted equal in `diagnose` so a basis change is caught.
pub const LAMBDA_M: f64 = 108.0;

/// Exact sup norm of Xi_simple over the real 256-state basis (used to validate
/// `LAMBDA_M` and as the principled normalization constant).
pub fn lambda_m_exact() -> f64 {
    let mut m = 0.0;
    for i in 0..basis_data::N_STATES {
        for j in 0..basis_data::N_STATES {
            let v = xi_simple(&basis_data::VALS[i], &basis_data::VALS[j]).abs();
            if v > m {
                m = v;
            }
        }
    }
    m
}

#[derive(Clone, Copy, Debug)]
pub struct Matrix<const N: usize> {
    pub e: [[f64; N]; N],
}

impl<const N: usize> Matrix<N> {
    pub fn zeros() -> Self {
        Self { e: [[0.0; N]; N] }
    }

    pub fn identity() -> Self {
        let mut m = Self::zeros();
        for i in 0..N {
            m.e[i][i] = 1.0;
        }
        m
    }

    pub fn add(&self, o: &Self) -> Self {
        let mut m = Self::zeros();
        for i in 0..N {
            for j in 0..N {
                m.e[i][j] = self.e[i][j] + o.e[i][j];
            }
        }
        m
    }

    pub fn sub(&self, o: &Self) -> Self {
        let mut m = Self::zeros();
        for i in 0..N {
            for j in 0..N {
                m.e[i][j] = self.e[i][j] - o.e[i][j];
            }
        }
        m
    }

    pub fn scale(&self, s: f64) -> Self {
        let mut m = Self::zeros();
        for i in 0..N {
            for j in 0..N {
                m.e[i][j] = s * self.e[i][j];
            }
        }
        m
    }

    pub fn mul(&self, o: &Self) -> Self {
        let mut m = Self::zeros();
        for i in 0..N {
            for j in 0..N {
                let mut acc = 0.0;
                for k in 0..N {
                    acc += self.e[i][k] * o.e[k][j];
                }
                m.e[i][j] = acc;
            }
        }
        m
    }

    pub fn trace(&self) -> f64 {
        let mut s = 0.0;
        for i in 0..N {
            s += self.e[i][i];
        }
        s
    }

    /// Max absolute entry (the sup norm on N x N matrices).
    pub fn sup_norm(&self) -> f64 {
        let mut m = 0.0;
        for i in 0..N {
            for j in 0..N {
                let a = self.e[i][j].abs();
                if a > m {
                    m = a;
                }
            }
        }
        m
    }

    pub fn approx_eq(&self, o: &Self, eps: f64) -> bool {
        for i in 0..N {
            for j in 0..N {
                if (self.e[i][j] - o.e[i][j]).abs() > eps {
                    return false;
                }
            }
        }
        true
    }

    /// Gauss-Jordan inverse with partial pivoting. Returns None if singular.
    pub fn inv(&self) -> Option<Self> {
        let mut a = *self;
        let mut inv = Self::identity();
        for col in 0..N {
            let mut piv = col;
            let mut mx = a.e[col][col].abs();
            for r in (col + 1)..N {
                let v = a.e[r][col].abs();
                if v > mx {
                    mx = v;
                    piv = r;
                }
            }
            if mx < 1e-12 {
                return None;
            }
            if piv != col {
                a.e.swap(col, piv);
                inv.e.swap(col, piv);
            }
            let d = a.e[col][col];
            for k in 0..N {
                a.e[col][k] /= d;
                inv.e[col][k] /= d;
            }
            for r in 0..N {
                if r != col {
                    let f = a.e[r][col];
                    if f != 0.0 {
                        for k in 0..N {
                            a.e[r][k] -= f * a.e[col][k];
                            inv.e[r][k] -= f * inv.e[col][k];
                        }
                    }
                }
            }
        }
        Some(inv)
    }
}

// ---------------------------------------------------------------------------
// Kernels
// ---------------------------------------------------------------------------

pub fn gcd(mut a: usize, mut b: usize) -> usize {
    while b != 0 {
        let t = b;
        b = a % b;
        a = t;
    }
    a
}

pub fn log_n(n: usize) -> f64 {
    if n <= 1 {
        0.0
    } else {
        (n as f64).ln()
    }
}

/// Exponential window W(i,j) = exp(-(log n_i - log n_j)^2 / (2 sigma^2)).
pub fn w(li: f64, lj: f64, sigma: f64) -> f64 {
    let d = li - lj;
    (-(d * d) / (2.0 * sigma * sigma)).exp()
}

/// gcd kernel K_gcd(i,j) = ln(gcd(n_i, n_j)) (0 if coprime).
pub fn k_gcd(ni: usize, nj: usize) -> f64 {
    let g = gcd(ni, nj);
    if g <= 1 {
        0.0
    } else {
        (g as f64).ln()
    }
}

/// Xi_simple(i,j) = (sum min(v_i, v_j))^2 - sum (min(v_i, v_j))^2.
pub fn xi_simple(vi: &[u32], vj: &[u32]) -> f64 {
    let alphas: Vec<f64> = vi
        .iter()
        .zip(vj.iter())
        .map(|(a, b)| (*a.min(b)) as f64)
        .collect();
    let s: f64 = alphas.iter().sum();
    let ssq: f64 = alphas.iter().map(|x| x * x).sum();
    s * s - ssq
}

// ---------------------------------------------------------------------------
// Hamiltonian / interaction builders (generic over basis size N)
// ---------------------------------------------------------------------------

pub fn build_h0<const N: usize>(nums: &[usize; N]) -> Matrix<N> {
    let mut m = Matrix::<N>::zeros();
    for i in 0..N {
        m.e[i][i] = log_n(nums[i]);
    }
    m
}

pub fn build_h1<const N: usize>(
    nums: &[usize; N],
    _vals: &[[u32; 4]; N],
    kappa: f64,
    sigma: f64,
) -> Matrix<N> {
    let mut m = build_h0(nums);
    for i in 0..N {
        for j in 0..N {
            let li = log_n(nums[i]);
            let lj = log_n(nums[j]);
            m.e[i][j] += kappa * k_gcd(nums[i], nums[j]) * w(li, lj, sigma);
        }
    }
    m
}

/// V2 = kappa*gamma * (Xi_simple .* W), normalized by LAMBDA_M when `normalize`.
pub fn build_v2<const N: usize>(
    nums: &[usize; N],
    vals: &[[u32; 4]; N],
    kappa: f64,
    gamma: f64,
    sigma: f64,
    normalize: bool,
) -> Matrix<N> {
    let scale = if normalize { 1.0 / LAMBDA_M } else { 1.0 };
    let mut m = Matrix::<N>::zeros();
    for i in 0..N {
        for j in 0..N {
            let li = log_n(nums[i]);
            let lj = log_n(nums[j]);
            m.e[i][j] = kappa * gamma * xi_simple(&vals[i], &vals[j]) * scale * w(li, lj, sigma);
        }
    }
    m
}

/// M = (Xi_simple .* W) without the kappa*gamma prefactor (used for the bound).
pub fn build_m<const N: usize>(
    nums: &[usize; N],
    vals: &[[u32; 4]; N],
    sigma: f64,
) -> Matrix<N> {
    let mut m = Matrix::<N>::zeros();
    for i in 0..N {
        for j in 0..N {
            let li = log_n(nums[i]);
            let lj = log_n(nums[j]);
            m.e[i][j] = xi_simple(&vals[i], &vals[j]) * w(li, lj, sigma);
        }
    }
    m
}

pub fn build_h2<const N: usize>(
    nums: &[usize; N],
    vals: &[[u32; 4]; N],
    kappa: f64,
    gamma: f64,
    sigma: f64,
    normalize: bool,
) -> Matrix<N> {
    let mut m = build_h1(nums, vals, kappa, sigma);
    let v2 = build_v2(nums, vals, kappa, gamma, sigma, normalize);
    m = m.add(&v2);
    m
}

/// fo(z) = sum_i 1/(z - log n_i) + kappa*gamma sum_i Xi_simple(i,i)/(z - log n_i)^2.
pub fn first_order_trace<const N: usize>(
    nums: &[usize; N],
    vals: &[[u32; 4]; N],
    z: f64,
    kappa: f64,
    gamma: f64,
) -> f64 {
    let mut s = 0.0;
    for i in 0..N {
        let ln = log_n(nums[i]);
        let d = z - ln;
        s += 1.0 / d + kappa * gamma * xi_simple(&vals[i], &vals[i]) / (d * d);
    }
    s
}

// ---------------------------------------------------------------------------
// Diagnostic for the 256-state real basis
// ---------------------------------------------------------------------------

#[derive(Debug)]
pub struct Diagnostics {
    pub z: f64,
    pub kappa: f64,
    pub gamma: f64,
    pub sigma: f64,
    pub normalize: bool,
    /// Tr[(zI - H2)^-1].
    pub tr_r2: f64,
    /// R0-based first-order trace: sum 1/(z-log n) + kappa*gamma sum Xi/(z-log n)^2.
    pub fo: f64,
    /// CORRECT first-order expansion, around R1: Tr(R1) + Tr(R1 V2 R1).
    pub fo_r1: f64,
    /// Tr(R2) - fo (the quantity the paper's formula claims is O((kappa*gamma)^2)).
    pub error_fo: f64,
    /// O(kappa) correction dropped by the simplified formula: Tr(R1)-Tr(R0) + ...
    pub v1_part: f64,
    /// Genuine O(||V2||^2) remainder: Tr(R1 V2 R2 V2 R1) = Tr(R2) - fo_r1.
    pub rem_kg: f64,
    pub sup_v2: f64,
    pub sup_m: f64,
    /// Conservative sup-norm proxy for ||R1 V2||: N * ||R1|| * ||V2||.
    pub r1v2_proxy: f64,
    pub kg2: f64,
    /// Loose sup-norm bound (kappa*gamma)^2 * C on |rem_kg|.
    pub loose_bound: f64,
}

pub fn diagnose(kappa: f64, gamma: f64, sigma: f64, z: f64, normalize: bool) -> Diagnostics {
    // Guard: LAMBDA_M must equal the exact sup norm of Xi_simple for this basis.
    debug_assert!((lambda_m_exact() - LAMBDA_M).abs() < 1e-9);

    let nums = basis_data::NUMBERS;
    let vals = basis_data::VALS;
    const N: usize = basis_data::N_STATES;

    let h0 = build_h0(&nums);
    let h1 = build_h1(&nums, &vals, kappa, sigma);
    let h2 = build_h2(&nums, &vals, kappa, gamma, sigma, normalize);

    let r0 = (Matrix::<N>::identity().scale(z).sub(&h0))
        .inv()
        .expect("R0 invertible");
    let r1 = (Matrix::<N>::identity().scale(z).sub(&h1))
        .inv()
        .expect("R1 invertible");
    let r2 = (Matrix::<N>::identity().scale(z).sub(&h2))
        .inv()
        .expect("R2 invertible");

    let tr_r2 = r2.trace();
    let fo = first_order_trace(&nums, &vals, z, kappa, gamma);
    let error_fo = tr_r2 - fo;

    let v2 = build_v2(&nums, &vals, kappa, gamma, sigma, normalize);
    let r0v2r0 = r0.mul(&v2).mul(&r0);
    let r1v2r1 = r1.mul(&v2).mul(&r1);
    let v1_part = (r1.trace() - r0.trace()) + (r1v2r1.trace() - r0v2r0.trace());

    let fo_r1 = r1.trace() + r1v2r1.trace();
    let rem_kg = r1
        .mul(&v2)
        .mul(&r2)
        .mul(&v2)
        .mul(&r1)
        .trace();

    let m = build_m(&nums, &vals, sigma);
    let n = N as f64;
    let sup_v2 = v2.sup_norm();
    let c = n.powi(5) * r1.sup_norm().powi(2) * r2.sup_norm() * sup_v2.powi(2);
    let kg2 = (kappa * gamma) * (kappa * gamma);
    let r1v2_proxy = n * r1.sup_norm() * sup_v2;

    Diagnostics {
        z,
        kappa,
        gamma,
        sigma,
        normalize,
        tr_r2,
        fo,
        fo_r1,
        error_fo,
        v1_part,
        rem_kg,
        sup_v2,
        sup_m: m.sup_norm(),
        r1v2_proxy,
        kg2,
        loose_bound: kg2 * c,
    }
}
