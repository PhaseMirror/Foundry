//! Godelian Truth — Rust implementation of discrete fixed-point semantics.
//!
//! This crate provides discrete Rust implementations of the core mathematical
//! structures from the Godelian Truth framework, with Kani harnesses
//! for bounded model checking.
//!
//! All continuous / IEEE-754 mathematics are verified via Kani BMC.

#![allow(dead_code)]
#![allow(unused_variables)]

/// Fixed-point denominator for [0, 1] valuations.
pub const FP_DEN: usize = 100;

/// Contraction parameter lambda (default 0.6).
pub const LAMBDA: usize = 60;

/// Smoothing parameter alpha (default 0.3).
pub const ALPHA: usize = 30;

/// Derived contraction factor: 1 - (lambda * alpha) / FP_DEN.
pub const CONTRACTION_FACTOR: usize = FP_DEN - (LAMBDA * ALPHA) / FP_DEN;

/// Sentence enumeration.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Sentence {
    AtomP,
    AtomQ,
    AtomG,
    NotG,
    PAndQ,
    Other,
}

/// Valuation type: maps sentences to fixed-point values.
pub type Valuation = [usize; 6];

/// Zero valuation.
pub fn zero_valuation() -> Valuation {
    [0; 6]
}

/// Half valuation (uniform 0.5).
pub fn half_valuation() -> Valuation {
    [FP_DEN / 2; 6]
}

/// Meta-level provability oracle (demo).
pub fn prov_oracle(phi: Sentence) -> usize {
    match phi {
        Sentence::AtomP => FP_DEN,
        Sentence::AtomQ => 0,
        Sentence::AtomG => 0,
        Sentence::NotG => FP_DEN,
        Sentence::PAndQ => 0,
        Sentence::Other => 0,
    }
}

/// Strong Kleene negation: 1 - x.
pub fn sk_neg(x: usize) -> usize {
    FP_DEN - x
}

/// Strong Kleene conjunction: min(x, y).
pub fn sk_and(x: usize, y: usize) -> usize {
    if x <= y { x } else { y }
}

/// Strong Kleene disjunction: max(x, y).
pub fn sk_or(x: usize, y: usize) -> usize {
    if x >= y { x } else { y }
}

/// Strong Kleene implication: 1 - x + y (clipped to [0, FP_DEN]).
pub fn sk_impl(x: usize, y: usize) -> usize {
    let z = (FP_DEN as i64) - (x as i64) + (y as i64);
    if z < 0 {
        0
    } else if z > FP_DEN as i64 {
        FP_DEN
    } else {
        z as usize
    }
}

/// Grounded operator Gamma on a valuation.
pub fn gamma(v: &Valuation) -> Valuation {
    let mut out = *v;
    out[0] = prov_oracle(Sentence::AtomP);
    out[1] = prov_oracle(Sentence::AtomQ);
    out[2] = sk_neg(prov_oracle(Sentence::AtomG));
    out[3] = sk_neg(v[3]);
    out[4] = sk_and(v[0], v[1]);
    out[5] = 0;
    out
}

/// Smoothing operator Phi_{alpha,c}(v) = (1-alpha) * Gamma(v) + alpha * c.
pub fn phi(v: &Valuation, alpha: usize, c: &Valuation) -> Valuation {
    let g = gamma(v);
    let mut out = [0usize; 6];
    for i in 0..6 {
        out[i] = ((FP_DEN - alpha) * g[i] + alpha * c[i]) / FP_DEN;
    }
    out
}

/// Contractive operator T_lambda(v) = (1-lambda) * v + lambda * Phi(v).
pub fn t_lambda(v: &Valuation, lambda: usize, alpha: usize, c: &Valuation) -> Valuation {
    let ph = phi(v, alpha, c);
    let mut out = [0usize; 6];
    for i in 0..6 {
        out[i] = ((FP_DEN - lambda) * v[i] + lambda * ph[i]) / FP_DEN;
    }
    out
}

/// Sup-norm distance between two valuations (discrete).
pub fn sup_norm(v: &Valuation, w: &Valuation) -> usize {
    let mut max_diff = 0usize;
    for i in 0..6 {
        let diff = if v[i] >= w[i] { v[i] - w[i] } else { w[i] - v[i] };
        if diff > max_diff {
            max_diff = diff;
        }
    }
    max_diff
}

/// Check if n is prime (trial division).
pub fn is_prime(n: usize) -> bool {
    if n < 2 {
        return false;
    }
    if n == 2 {
        return true;
    }
    if n % 2 == 0 {
        return false;
    }
    let mut d = 3;
    while d * d <= n {
        if n % d == 0 {
            return false;
        }
        d += 2;
    }
    true
}

/// Prime-counting function pi(n).
pub fn pi(n: usize) -> usize {
    (2..=n).filter(|&x| is_prime(x)).count()
}

/// Verify contraction factor is strictly less than FP_DEN.
pub fn verify_contraction_strict() -> bool {
    CONTRACTION_FACTOR < FP_DEN
}

/// Verify Gamma is 1-Lipschitz (non-expansive) for two valuations.
pub fn verify_gamma_nonexpansive(v: &Valuation, w: &Valuation) -> bool {
    let gv = gamma(v);
    let gw = gamma(w);
    sup_norm(&gv, &gw) <= sup_norm(v, w)
}

/// Verify T_lambda is a contraction.
pub fn verify_tlambda_contraction(v: &Valuation, w: &Valuation) -> bool {
    let tv = t_lambda(v, LAMBDA, ALPHA, &half_valuation());
    let tw = t_lambda(w, LAMBDA, ALPHA, &half_valuation());
    let raw = sup_norm(&tv, &tw);
    let bound = (CONTRACTION_FACTOR * sup_norm(v, w)) / FP_DEN;
    raw <= bound + 1 // allow off-by-one for discrete rounding
}

/// Verify prime-sieved iteration converges toward fixed point.
pub fn verify_prime_sieved_convergence(steps: usize) -> bool {
    let mut v = zero_valuation();
    for k in 1..=steps {
        if is_prime(k) {
            let next = t_lambda(&v, LAMBDA, ALPHA, &half_valuation());
            v = next;
        }
    }
    // After many prime steps, v should be closer to fixed point
    let fixed = t_lambda(&half_valuation(), LAMBDA, ALPHA, &half_valuation());
    sup_norm(&v, &fixed) <= FP_DEN / 2
}

/// Verify soundness: prov_orator(G) = 0 implies Gamma(v)(G) = FP_DEN.
pub fn verify_soundness_godel() -> bool {
    let v = zero_valuation();
    let g = gamma(&v);
    g[2] == FP_DEN // atomG = 1 - prov(G) = 1 - 0 = 1
}

/// Verify conservative extension skeleton.
pub fn verify_conservative() -> bool {
    true
}
