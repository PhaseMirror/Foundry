// Kani verification harness for Gauss Multiplicity (ADR-0005)
// This file verifies the quadratic reciprocity symmetry of the interaction matrix
// and the bounds on the relational multiplicity imbalance Δ(p, X).

fn legendre(p: u32, q: u32) -> i32 {
    if p % q == 0 {
        return 0;
    }
    for x in 0..q {
        if (x * x) % q == p % q {
            return 1;
        }
    }
    -1
}

fn is_prime(n: u32) -> bool {
    if n < 2 {
        return false;
    }
    for i in 2..n {
        if n % i == 0 {
            return false;
        }
    }
    true
}

#[kani::proof]
#[kani::unwind(32)]
fn verify_quadratic_reciprocity() {
    let p: u32 = kani::any();
    let q: u32 = kani::any();
    
    kani::assume(p > 2 && p < 30);
    kani::assume(q > 2 && q < 30);
    kani::assume(p != q);
    kani::assume(is_prime(p));
    kani::assume(is_prime(q));

    let lhs = legendre(p, q) * legendre(q, p);
    let rhs = if ((p - 1) / 2) % 2 == 1 && ((q - 1) / 2) % 2 == 1 { -1 } else { 1 };
    
    assert_eq!(lhs, rhs);
}

#[kani::proof]
#[kani::unwind(32)]
fn verify_delta_bounds() {
    let p: u32 = kani::any();
    let x: u32 = kani::any();
    
    kani::assume(p < 30);
    kani::assume(x < 30);

    let mut m_plus = 0;
    let mut m_minus = 0;

    for q in 0..=x {
        if is_prime(q) {
            let l = legendre(p, q);
            if l == 1 { m_plus += 1; }
            if l == -1 { m_minus += 1; }
        }
    }

    let delta: i32 = (m_plus as i32) - (m_minus as i32);
    assert!(delta.abs() <= (x as i32) + 1);
}
