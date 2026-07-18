use ndarray::{Array1, Array2};
use num_complex::Complex;

/// Computes the largest singular value (operator norm) of a real matrix using Power Iteration.
pub fn power_iteration(mat: &Array2<f64>, max_iter: usize, tol: f64) -> f64 {
    let dim = mat.nrows();
    let mut vec = Array1::<f64>::from_elem(dim, 1.0 / (dim as f64).sqrt());
    
    // We compute the largest eigenvalue of A^T A
    // M = mat.t() @ mat
    let mat_t = mat.t();
    
    let mut lambda = 0.0;
    
    for _ in 0..max_iter {
        // v_next = M * vec = mat^T * (mat * vec)
        let tmp = mat.dot(&vec);
        let mut v_next = mat_t.dot(&tmp);
        
        // norm
        let norm = v_next.dot(&v_next).sqrt();
        if norm < 1e-15 {
            break;
        }
        
        v_next /= norm;
        
        // Rayliegh quotient
        let tmp2 = mat.dot(&v_next);
        let new_lambda = v_next.dot(&mat_t.dot(&tmp2));
        
        if (new_lambda - lambda).abs() < tol {
            lambda = new_lambda;
            break;
        }
        lambda = new_lambda;
        vec = v_next;
    }
    
    lambda.sqrt()
}

/// Builds the discrete Fourier transform matrix F of dimension d
pub fn build_dft_matrix(d: usize) -> Array2<Complex<f64>> {
    let mut f = Array2::zeros((d, d));
    let scale = 1.0 / (d as f64).sqrt();
    let w = std::f64::consts::PI * 2.0 / (d as f64);
    
    for j in 0..d {
        for k in 0..d {
            let angle = -w * (j as f64) * (k as f64);
            f[[j, k]] = Complex::new(angle.cos() * scale, angle.sin() * scale);
        }
    }
    f
}

/// Builds the prime operator U_p = F^* D_p F
pub fn build_fourier_prime_operator(p: usize, d: usize, f: &Array2<Complex<f64>>) -> Array2<Complex<f64>> {
    // F^*
    let mut f_star = Array2::zeros((d, d));
    for j in 0..d {
        for k in 0..d {
            f_star[[j, k]] = f[[k, j]].conj();
        }
    }
    
    // D_p F
    let mut dp_f = Array2::zeros((d, d));
    for j in 0..d {
        let angle = std::f64::consts::PI * 2.0 * (j as f64) / (p as f64);
        let phase = Complex::new(angle.cos(), angle.sin());
        for k in 0..d {
            dp_f[[j, k]] = phase * f[[j, k]];
        }
    }
    
    // U_p = F^* (D_p F)
    let mut u_p = Array2::zeros((d, d));
    for j in 0..d {
        for k in 0..d {
            let mut sum = Complex::new(0.0, 0.0);
            for m in 0..d {
                sum += f_star[[j, m]] * dp_f[[m, k]];
            }
            u_p[[j, k]] = sum;
        }
    }
    
    u_p
}

/// Computes the aggregate operator Xi = Re(sum w_p U_p)
pub fn compute_xi(weights: &[f64], u_ops: &[Array2<Complex<f64>>]) -> Array2<f64> {
    let d = u_ops[0].nrows();
    let mut xi = Array2::zeros((d, d));
    
    for (w, u) in weights.iter().zip(u_ops.iter()) {
        for j in 0..d {
            for k in 0..d {
                xi[[j, k]] += w * u[[j, k]].re;
            }
        }
    }
    
    xi
}

/// Computes the operator norm F = ||Xi||_op
pub fn compute_f(weights: &[f64], u_ops: &[Array2<Complex<f64>>]) -> f64 {
    let xi = compute_xi(weights, u_ops);
    power_iteration(&xi, 1000, 1e-10)
}

/// PMRO Weight Optimizer
/// Uses a random search gradient-free approach to minimize F while adhering to bounds
pub fn optimize_weights_random_search(u_ops: &[Array2<Complex<f64>>], initial_w: &[f64], iterations: usize) -> Vec<f64> {
    use std::time::{SystemTime, UNIX_EPOCH};
    let mut current_w = initial_w.to_vec();
    let mut best_w = current_w.clone();
    let mut best_f = compute_f(&best_w, u_ops);
    
    // Very simple pseudo-random generator
    let seed = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_micros() as u64;
    let mut state = seed;
    let mut rand_float = || -> f64 {
        state ^= state << 13;
        state ^= state >> 17;
        state ^= state << 5;
        (state % 1000000) as f64 / 1000000.0
    };
    
    let mut temp = 0.5;
    
    for _ in 0..iterations {
        // Perturb weights
        let mut next_w = current_w.clone();
        for i in 0..next_w.len() {
            next_w[i] += (rand_float() - 0.5) * temp;
        }
        
        // Enforce bounds: ||w||^2 <= 5 and ||w|| >= 0.5
        let norm_sq: f64 = next_w.iter().map(|x| x * x).sum();
        if norm_sq > 5.0 {
            let scale = (5.0 / norm_sq).sqrt();
            for w in next_w.iter_mut() {
                *w *= scale;
            }
        } else if norm_sq < 0.25 {
            let scale = (0.25 / norm_sq).sqrt();
            for w in next_w.iter_mut() {
                *w *= scale;
            }
        }
        
        let f_val = compute_f(&next_w, u_ops);
        if f_val < best_f {
            best_f = f_val;
            best_w = next_w.clone();
            current_w = next_w;
        } else {
            // Simulated annealing acceptance
            let accept_prob = ((best_f - f_val) / temp).exp();
            if rand_float() < accept_prob {
                current_w = next_w;
            }
        }
        
        temp *= 0.99;
    }
    
    best_w
}
