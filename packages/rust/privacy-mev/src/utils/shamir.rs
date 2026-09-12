use rand::Rng;

pub const PRIME: u128 = 170141183460469231731687303715884105727; // 2^127 - 1

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq, Eq)]
pub struct Share {
    pub x: u128,
    pub y: u128,
}

#[inline]
pub fn add_mod(a: u128, b: u128) -> u128 {
    let mut sum = a + b;
    if sum >= PRIME {
        sum -= PRIME;
    }
    sum
}

#[inline]
pub fn sub_mod(a: u128, b: u128) -> u128 {
    if a >= b {
        a - b
    } else {
        a + PRIME - b
    }
}

/// Bitwise double-width multiplication and reduction modulo 2^127 - 1
pub fn mul_mod(a: u128, b: u128) -> u128 {
    let a0 = a as u64;
    let a1 = (a >> 64) as u64;
    let b0 = b as u64;
    let b1 = (b >> 64) as u64;

    let z0 = (a0 as u128) * (b0 as u128);
    let z1 = (a0 as u128) * (b1 as u128);
    let z2 = (a1 as u128) * (b0 as u128);
    let z3 = (a1 as u128) * (b1 as u128);

    let carry1 = z0 >> 64;
    let val0 = z0 as u64;

    let sum1 = (z1 as u64) + (z2 as u64) + carry1;
    let val1 = sum1 as u64;
    let carry2 = (sum1 >> 64) + (z1 >> 64) + (z2 >> 64);

    let sum2 = (z3 as u64) + carry2;
    let val2 = sum2 as u64;
    let carry3 = (sum2 >> 64) + (z3 >> 64);
    let val3 = carry3 as u64;

    let x_lo = (val0 as u128) | (((val1 as u128) & 0x7FFFFFFFFFFFFFFF) << 64);
    let x_hi = ((val1 as u128) >> 63) | ((val2 as u128) << 1) | ((val3 as u128) << 65);

    let mut sum = x_lo + x_hi;
    sum = (sum & 0x7FFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF) + (sum >> 127);
    if sum >= PRIME {
        sum -= PRIME;
    }
    sum
}

pub fn pow_mod(mut base: u128, mut exp: u128) -> u128 {
    let mut res = 1;
    base = base % PRIME;
    while exp > 0 {
        if exp & 1 == 1 {
            res = mul_mod(res, base);
        }
        base = mul_mod(base, base);
        exp >>= 1;
    }
    res
}

pub fn inv_mod(a: u128) -> u128 {
    // Fermat's Little Theorem since PRIME is prime
    pow_mod(a, PRIME - 2)
}

pub struct ShamirSecretSharing;

impl ShamirSecretSharing {
    pub fn split(secret: u128, n: usize, k: usize) -> Result<Vec<Share>, anyhow::Error> {
        split(secret, n, k)
    }

    pub fn combine(shares: &[Share]) -> Result<u128, anyhow::Error> {
        combine(shares)
    }
}

/// Splits a secret into n shares, requiring k to reconstruct.
pub fn split(secret: u128, n: usize, k: usize) -> Result<Vec<Share>, anyhow::Error> {
    if k > n {
        return Err(anyhow::anyhow!("Threshold k cannot be greater than total shares n"));
    }
    if secret >= PRIME {
        return Err(anyhow::anyhow!("Secret cannot be larger than the Prime field size"));
    }

    let mut rng = rand::thread_rng();
    let mut coeffs = vec![secret];
    for _ in 1..k {
        let val: u128 = rng.gen();
        coeffs.push(val % PRIME);
    }

    let mut shares = Vec::with_capacity(n);
    for i in 1..=n {
        let x = i as u128;
        let y = evaluate_polynomial(&coeffs, x);
        shares.push(Share { x, y });
    }

    Ok(shares)
}

/// Reconstructs the secret (f(0)) using Lagrange Interpolation.
pub fn combine(shares: &[Share]) -> Result<u128, anyhow::Error> {
    if shares.is_empty() {
        return Err(anyhow::anyhow!("No shares provided"));
    }
    let mut secret = 0;

    for i in 0..shares.len() {
        let xi = shares[i].x;
        let yi = shares[i].y;

        let mut numerator = 1;
        let mut denominator = 1;

        for j in 0..shares.len() {
            if i == j {
                continue;
            }
            let xj = shares[j].x;

            // L_i(0) = product( (0 - xj) / (xi - xj) )
            let diff = sub_mod(0, xj);
            numerator = mul_mod(numerator, diff);

            let diff_denom = sub_mod(xi, xj);
            denominator = mul_mod(denominator, diff_denom);
        }

        let lagrange_poly = mul_mod(numerator, inv_mod(denominator));
        let term = mul_mod(yi, lagrange_poly);
        secret = add_mod(secret, term);
    }

    Ok(secret)
}

fn evaluate_polynomial(coeffs: &[u128], x: u128) -> u128 {
    let mut result = 0;
    let mut x_pow = 1;
    for &coeff in coeffs {
        let term = mul_mod(coeff, x_pow);
        result = add_mod(result, term);
        x_pow = mul_mod(x_pow, x);
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_modular_arithmetic() {
        // Test basic addition, subtraction, multiplication, power, inversion
        let a = 12345678901234567890u128;
        let b = 98765432109876543210u128;
        
        let sum = add_mod(a, b);
        assert_eq!(sub_mod(sum, a), b);
        assert_eq!(sub_mod(sum, b), a);

        let prod = mul_mod(a, b);
        let inv_b = inv_mod(b);
        assert_eq!(mul_mod(prod, inv_b), a);
    }

    #[test]
    fn test_shamir_split_combine() {
        let secret = 42u128;
        let n = 5;
        let k = 3;
        
        let shares = split(secret, n, k).unwrap();
        assert_eq!(shares.len(), n);

        // Reconstruct with any k shares
        let subset1 = &shares[0..3];
        let recovered1 = combine(subset1).unwrap();
        assert_eq!(recovered1, secret);

        let subset2 = vec![shares[0].clone(), shares[2].clone(), shares[4].clone()];
        let recovered2 = combine(&subset2).unwrap();
        assert_eq!(recovered2, secret);
    }
}
