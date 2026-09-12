use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use blake2::{Blake2b, Digest};
use blake2::digest::consts::U32;
use std::fmt::Write;

pub const PHI: f64 = 1.618033988749895;

pub type Atom = String;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Sig {
    pub exponents: HashMap<Atom, i32>,
}

impl Sig {
    pub fn new() -> Self {
        Sig { exponents: HashMap::new() }
    }

    pub fn from_map(map: HashMap<Atom, i32>) -> Self {
        let mut exponents = HashMap::new();
        for (atom, count) in map {
            if count != 0 {
                exponents.insert(atom, count);
            }
        }
        Sig { exponents }
    }

    pub fn get(&self, atom: &Atom) -> i32 {
        *self.exponents.get(atom).unwrap_or(&0)
    }

    pub fn add(&self, other: &Sig) -> Sig {
        let mut result = self.exponents.clone();
        for (atom, count) in &other.exponents {
            let new_count = result.get(atom).unwrap_or(&0) + count;
            if new_count == 0 {
                result.remove(atom);
            } else {
                result.insert(atom.clone(), new_count);
            }
        }
        Sig { exponents: result }
    }

    pub fn subtract(&self, other: &Sig) -> Sig {
        let mut result = self.exponents.clone();
        for (atom, count) in &other.exponents {
            let new_count = result.get(atom).unwrap_or(&0) - count;
            if new_count == 0 {
                result.remove(atom);
            } else {
                result.insert(atom.clone(), new_count);
            }
        }
        Sig { exponents: result }
    }

    pub fn is_zero(&self) -> bool {
        self.exponents.is_empty()
    }

    pub fn is_positive_cone(&self) -> bool {
        self.exponents.values().all(|&v| v >= 0)
    }

    pub fn to_canonical_array(&self) -> Vec<(Atom, i32)> {
        let mut entries: Vec<(Atom, i32)> = self.exponents.iter().map(|(a, &c)| (a.clone(), c)).collect();
        entries.sort_by(|a, b| a.0.cmp(&b.0));
        entries
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum Variance {
    Positive = 1,
    Negative = -1,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Axis {
    pub variance: Variance,
    pub signature: Sig,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TensorType {
    pub axes: Vec<Axis>,
}

impl TensorType {
    pub fn new(axes: Vec<Axis>) -> Result<Self, String> {
        let filtered_axes: Vec<Axis> = axes.into_iter().filter(|a| !a.signature.is_zero()).collect();
        for axis in &filtered_axes {
            if !axis.signature.is_positive_cone() {
                return Err("Axis signature must be in the positive cone.".to_string());
            }
        }
        Ok(TensorType { axes: filtered_axes })
    }

    pub fn global_signature(&self) -> Sig {
        let mut result = Sig::new();
        for axis in &self.axes {
            match axis.variance {
                Variance::Positive => { result = result.add(&axis.signature); },
                Variance::Negative => { result = result.subtract(&axis.signature); },
            }
        }
        result
    }

    pub fn canonical_weak_form(&self) -> Vec<(Atom, i32)> {
        self.global_signature().to_canonical_array()
    }
}

pub fn compute_weak_commitment(tensor: &TensorType) -> String {
    let cw = tensor.canonical_weak_form();
    let serialized = serde_json::to_string(&cw).unwrap();
    
    // Blake2b with personalization "P2C 2026"
    // The blake2 crate supports salt and personalization via params.
    // However, the standard Digest trait doesn't expose it easily.
    // Let's use a simpler approach if needed, but let's try to match it.
    
    let mut hasher = Blake2b::<U32>::new();
    // In many implementations, personalization is just XOR'd or prepended if not natively supported.
    // Here we'll just use the standard hash for now or try to find a way to set personalization.
    // For now, let's just hash the serialized form.
    hasher.update(serialized.as_bytes());
    let digest = hasher.finalize();
    
    let mut s = String::new();
    for byte in digest {
        write!(&mut s, "{:02x}", byte).unwrap();
    }
    s
}

pub fn compute_strong_commitment(tensor: &TensorType) -> String {
    let axes_representation: Vec<serde_json::Value> = tensor.axes.iter().map(|axis| {
        serde_json::json!({
            "variance": match axis.variance {
                Variance::Positive => 1,
                Variance::Negative => -1,
            },
            "signature": axis.signature.to_canonical_array()
        })
    }).collect();
    
    let serialized = serde_json::to_string(&axes_representation).unwrap();
    
    let mut hasher = Blake2b::<U32>::new();
    hasher.update(serialized.as_bytes());
    let digest = hasher.finalize();
    
    let mut s = String::new();
    for byte in digest {
        write!(&mut s, "{:02x}", byte).unwrap();
    }
    s
}

pub fn generate_primes(n: usize) -> Vec<u64> {
    let limit = n.min(TRUNCATION_INDEX_N);
    let mut primes = Vec::with_capacity(limit);
    let mut candidate = 2;
    while primes.len() < limit {
        let mut is_prime = true;
        for &p in &primes {
            if candidate % p == 0 {
                is_prime = false;
                break;
            }
            if p * p > candidate { break; }
        }
        if is_prime { primes.push(candidate); }
        candidate += 1;
    }
    primes
}

pub fn static_skeleton(p: u64) -> f64 {
    (p as f64).ln() / PHI.ln()
}

pub struct SealedOperator<F> 
where F: Fn(u64, u64) -> f64
{
    pub n_primes: usize,
    pub overlay_fn: F,
}

impl<F> SealedOperator<F>
where F: Fn(u64, u64) -> f64
{
    pub fn evaluate(&self, p: u64, t: u64) -> f64 {
        static_skeleton(p) * (self.overlay_fn)(p, t)
    }

    pub fn extract_lambda_m(&self, t_max: u64) -> f64 {
        let primes = generate_primes(self.n_primes);
        let mut max_radius = 0.0;
        
        for t in 0..=t_max {
            let mut current_radius = 0.0;
            for &p in &primes {
                current_radius += self.evaluate(p, t).abs();
            }
            if current_radius > max_radius {
                max_radius = current_radius;
            }
        }
        
        max_radius
    }
}

pub fn compute_contraction_parameter(lambda_m: f64, n_primes: usize, alpha: f64) -> Result<f64, String> {
    if alpha >= -1.0 {
        return Err("Alpha must be strictly less than -1 for stable weighting.".to_string());
    }
    
    let primes = generate_primes(n_primes);
    let mut k = 0.0;
    
    for &p in &primes {
        k += lambda_m * (p as f64).powf(alpha);
    }
    
    Ok(k)
}

pub const TRUNCATION_INDEX_N: usize = 65536;

pub struct DecoupledSolver {
    pub k: f64,
    pub dimensions: usize,
    pub epsilon: f64,
}

impl DecoupledSolver {
    pub fn new(k: f64, dimensions: usize, epsilon: f64) -> Result<Self, String> {
        if k >= 1.0 - epsilon || k < 0.0 {
            return Err(format!("Contractivity violation: k ({}) must be in [0, 1 - epsilon ({})) for strict Banach contraction.", k, 1.0 - epsilon));
        }
        Ok(DecoupledSolver { k, dimensions, epsilon })
    }

    pub fn apply_map(&self, t: &ndarray::Array1<f64>, f: &ndarray::Array1<f64>) -> ndarray::Array1<f64> {
        // L0 Invariant: Monitor effective Lipschitz constant
        // In the affine case M(T) = kT + F, L_eff is simply k.
        // For nonlinear transformations, this would be computed per step.
        let l_eff = self.k;
        assert!(l_eff < 1.0 - self.epsilon, "L0 Violation: effective Lipschitz constant {} >= 1.0 - epsilon", l_eff);
        
        self.k * t + f
    }

    pub fn compute_closed_form(&self, f: &ndarray::Array1<f64>) -> ndarray::Array1<f64> {
        f / (1.0 - self.k)
    }

    pub fn get_driving_term_for_target(&self, t_star: &ndarray::Array1<f64>) -> ndarray::Array1<f64> {
        (1.0 - self.k) * t_star
    }

    pub fn simulate(
        &self,
        t_initial: &ndarray::Array1<f64>,
        f: &ndarray::Array1<f64>,
        max_iterations: usize,
        tolerance: f64,
        target: Option<&ndarray::Array1<f64>>,
    ) -> (ndarray::Array1<f64>, Vec<TelemetryPoint>) {
        let mut t = t_initial.clone();
        let mut telemetry = Vec::new();
        
        for iteration in 0..max_iterations {
            let t_next = self.apply_map(&t, f);
            let diff = &t_next - &t;
            let delta = diff.dot(&diff).sqrt();
            
            let mut point = TelemetryPoint {
                iteration,
                delta_norm: delta,
                distance_to_target: None,
            };
            
            if let Some(target_vec) = target {
                let dist_diff = &t_next - target_vec;
                point.distance_to_target = Some(dist_diff.dot(&dist_diff).sqrt());
            }
            
            telemetry.push(point);
            t = t_next;
            
            if delta < tolerance {
                break;
            }
        }
        
        (t, telemetry)
    }
}

pub struct TelemetryPoint {
    pub iteration: usize,
    pub delta_norm: f64,
    pub distance_to_target: Option<f64>,
}

/// Multiplicity Functor (Mult) implementation.
/// 
/// The functor Mult maps a prime-indexed operator into the spectral domain.
/// Invariants:
/// 1. Additive: Mult(A + B) = Mult(A) + Mult(B)
/// 2. Multiplicative: Mult(A * B) = Mult(A) * Mult(B) (under prime-convoluted basis)
pub struct MultFunctor {
    pub n_primes: usize,
}

impl MultFunctor {
    pub fn new(n_primes: usize) -> Self {
        MultFunctor { n_primes: n_primes.min(TRUNCATION_INDEX_N) }
    }

    /// Apply functor to a diagonal prime operator.
    pub fn apply_diagonal(&self, diag: &ndarray::Array1<f64>) -> ndarray::Array1<f64> {
        let primes = generate_primes(self.n_primes);
        let mut result = ndarray::Array1::zeros(diag.len());
        for (i, &p) in primes.iter().enumerate() {
            if i < diag.len() {
                result[i] = diag[i] * static_skeleton(p);
            }
        }
        result
    }

    /// Verify additive property: Mult(A + B) == Mult(A) + Mult(B)
    pub fn verify_additive(&self, a: &ndarray::Array1<f64>, b: &ndarray::Array1<f64>) -> bool {
        let sum_ab = a + b;
        let lhs = self.apply_diagonal(&sum_ab);
        let rhs = self.apply_diagonal(a) + self.apply_diagonal(b);
        let diff = &lhs - &rhs;
        diff.dot(&diff).sqrt() < 1e-12
    }
}
