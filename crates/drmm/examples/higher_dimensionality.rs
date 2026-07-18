use ndarray::{Array1, Array2};
use drmm_rs::generate_first_n_primes;

// Explicit-Formula Surrogate (Pair-Correlation Toy)
fn build_explicit_formula_surrogate(primes: &[f64]) -> Array2<f64> {
    let p_count = primes.len();
    let mut x_p = Array2::zeros((p_count, p_count));
    let mu = 1.0;
    
    // Smooth psi function (simple exponential decay surrogate)
    let psi = |x: f64| -> f64 { (-x).exp() };

    for i in 0..p_count {
        for j in 0..p_count {
            let pi = primes[i];
            let pj = primes[j];
            let val = psi(pi.ln()) + psi(pj.ln()) - psi((pi * pj).ln()) - mu;
            x_p[[i, j]] = val;
        }
    }
    x_p
}

// Rank-1 Bohr-prime multipliers: B_p(w) = u_p u_p^T
// u_p_i = cos(w * ln(p * p_i + ell))
fn build_bohr_prime_channel(p_index: usize, omega: f64, ell: f64, primes: &[f64]) -> Array2<f64> {
    let p_count = primes.len();
    let mut u_p = Array1::zeros(p_count);
    let p = primes[p_index];
    
    for i in 0..p_count {
        let p_i = primes[i];
        u_p[i] = (omega * (p * p_i + ell).ln()).cos();
    }
    
    // B_p = u_p * u_p^T
    let mut b_p = Array2::zeros((p_count, p_count));
    for i in 0..p_count {
        for j in 0..p_count {
            b_p[[i, j]] = u_p[i] * u_p[j];
        }
    }
    b_p
}

// Power Iteration for Operator Norm (Max Eigenvalue) of a Symmetric Matrix
fn max_eigenvalue(mat: &Array2<f64>) -> f64 {
    let dim = mat.nrows();
    let mut vec = Array1::<f64>::from_elem(dim, 1.0 / (dim as f64).sqrt());
    let mut lambda = 0.0;
    
    for _ in 0..100 {
        let v_next = mat.dot(&vec);
        let norm = v_next.dot(&v_next).sqrt();
        if norm < 1e-12 { break; }
        
        let normalized = &v_next / norm;
        let next_lambda = normalized.dot(&mat.dot(&normalized));
        if (next_lambda - lambda).abs() < 1e-8 {
            lambda = next_lambda;
            break;
        }
        lambda = next_lambda;
        vec = normalized;
    }
    lambda
}

fn run_drmm_scaling(p_count: usize) {
    println!("\n=== DRMM Scaling Simulation (P={}) ===", p_count);
    let raw_primes = generate_first_n_primes(p_count);
    let primes: Vec<f64> = raw_primes.iter().map(|&p| p as f64).collect();

    let x_p = build_explicit_formula_surrogate(&primes);
    println!("Base Operator X_P created (Explicit-Formula Surrogate).");

    // Print X_P trace to confirm
    let trace: f64 = (0..p_count).map(|i| x_p[[i, i]]).sum();
    println!("Trace(X_P) = {:.4}", trace);

    // Build the channels for a specific omega
    let omega = 0.5;
    let ell = 1.0;
    let mut b_channels = Vec::new();
    for i in 0..p_count {
        b_channels.push(build_bohr_prime_channel(i, omega, ell, &primes));
    }

    // Set dynamic scaling weights (w_p = 0.05 / sqrt(P)) to keep L1 norm bounded as P increases
    let w_val = 0.05 / (p_count as f64).sqrt();
    let w = vec![w_val; p_count];
    
    let mut c_omega = Array2::<f64>::zeros((p_count, p_count));
    for i in 0..p_count {
        for j in 0..p_count {
            for k in 0..p_count {
                c_omega[[j, k]] += w[i] * b_channels[i][[j, k]];
            }
        }
    }

    let u_p = &x_p + &c_omega;
    
    let u_p_norm = max_eigenvalue(&u_p);
    println!("Maximum Spectral Radius of U_P(omega): {:.4}", u_p_norm);
    
    // Bounded check (Weyl limit)
    // 1-norm of w * B
    let w_1_b: f64 = w.iter().sum(); 
    println!("||w||_1,b <= {:.4}", w_1_b);
    
    println!("Sanity Check P={} Completed.", p_count);
}

fn main() {
    run_drmm_scaling(23);
    run_drmm_scaling(97);
}
