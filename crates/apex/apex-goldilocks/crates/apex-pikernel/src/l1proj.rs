use ndarray::Array1;
use num_rational::Ratio;
use num_traits::{Zero, One, Signed};

pub type Rational = Ratio<i128>;

/// Project vector v onto weighted ℓ₁ ball {x : Σ w_i|x_i| ≤ τ}.
/// Uses bisection with exact rational arithmetic.
pub fn project_weighted_l1_ball(
    v: &Array1<Rational>,
    w: &Array1<Rational>,
    tau: Rational,
    maxit: usize
) -> (Array1<Rational>, Rational) {
    let dim = v.len();
    assert_eq!(v.len(), w.len(), "v and w must have same shape");

    // Check if already inside the ball
    let mut current_norm = Rational::zero();
    for i in 0..dim {
        current_norm = current_norm + (w[i] * v[i].abs());
    }

    if current_norm <= tau {
        return (v.clone(), Rational::zero());
    }

    // Bisection search for λ
    let mut lam_lo = Rational::zero();
    let mut lam_hi = Rational::zero();
    // Initialize lam_hi to max(|v_i| / w_i)
    for i in 0..dim {
        let val = v[i].abs() / w[i];
        if val > lam_hi {
            lam_hi = val;
        }
    }

    let mut lam = Rational::zero();
    for _ in 0..maxit {
        lam = (lam_lo + lam_hi) / Ratio::from_integer(2);
        
        let mut x = Array1::zeros(dim);
        let mut val = Rational::zero();
        for i in 0..dim {
            let threshold = lam * w[i];
            let abs_v = v[i].abs();
            if abs_v > threshold {
                x[i] = v[i].signum() * (abs_v - threshold);
            } else {
                x[i] = Rational::zero();
            }
            val = val + (w[i] * x[i].abs());
        }

        if val == tau {
            return (x, lam);
        } else if val > tau {
            lam_lo = lam;
        } else {
            lam_hi = lam;
        }
    }

    // Return best approximation (lam_hi)
    let mut x = Array1::zeros(dim);
    for i in 0..dim {
        let threshold = lam_hi * w[i];
        let abs_v = v[i].abs();
        if abs_v > threshold {
            x[i] = v[i].signum() * (abs_v - threshold);
        } else {
            x[i] = Rational::zero();
        }
    }
    (x, lam_hi)
}
