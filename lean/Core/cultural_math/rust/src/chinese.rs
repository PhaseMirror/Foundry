//! Chinese Remainder Theorem
//!
//! Solves systems of congruences using the Chinese Remainder Theorem.
//!
//! Specification: result % n1 = a1 % n1 && result % n2 = a2 % n2

/// Chinese Remainder Theorem for two congruences.
///
/// # Arguments
/// * `n1` - First modulus (>= 2)
/// * `n2` - Second modulus (>= 2)
/// * `a1` - First residue
/// * `a2` - Second residue
///
/// # Returns
/// * `x` such that `x % n1 = a1 % n1` and `x % n2 = a2 % n2`
///
/// # Panics
/// Panics if n1 or n2 < 2
pub fn chinese_crt(n1: u64, n2: u64, a1: u64, a2: u64) -> u64 {
    assert!(n1 >= 2, "n1 must be >= 2");
    assert!(n2 >= 2, "n2 must be >= 2");
    
    // Extended Euclidean algorithm: n1*x + n2*y = gcd(n1,n2)
    // For coprime n1, n2: n1*x + n2*y = 1
    // This gives us: n1*x ≡ 1 (mod n2) and n2*y ≡ 1 (mod n1)
    let (_g, x, y) = extended_gcd(n1 as i64, n2 as i64);
    
    // CRT formula: result = (a1 * n2 * y + a2 * n1 * x) % (n1*n2)
    let lcm = n1 * n2;
    let mut result = (a1 as i64 * n2 as i64 * y) % lcm as i64;
    result = (result + (a2 as i64 * n1 as i64 * x) % lcm as i64) % lcm as i64;
    if result < 0 {
        result += lcm as i64;
    }
    
    result as u64
}

/// Extended Euclidean Algorithm
fn extended_gcd(a: i64, b: i64) -> (i64, i64, i64) {
    if a == 0 {
        (b, 0, 1)
    } else {
        let (g, x, y) = extended_gcd(b % a, a);
        (g, y - (b / a) * x, x)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_chinese_crt() {
        let result = chinese_crt(3, 5, 1, 2);
        assert_eq!(result % 3, 1 % 3);
        assert_eq!(result % 5, 2 % 5);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;
    use kani::*;
    
    #[kani::proof]
    fn verify_chinese_crt() {
        let n1: u64 = kani::any();
        let n2: u64 = kani::any();
        let a1: u64 = kani::any();
        let a2: u64 = kani::any();
        
        kani::assume(n1 >= 2 && n1 < 100);
        kani::assume(n2 >= 2 && n2 < 100);
        kani::assume(a1 < 1000);
        kani::assume(a2 < 1000);
        
        let result = chinese_crt(n1, n2, a1, a2);
        assert!(result % n1 == a1 % n1);
        assert!(result % n2 == a2 % n2);
    }
}
