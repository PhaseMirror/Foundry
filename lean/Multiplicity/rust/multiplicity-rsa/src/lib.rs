pub struct RsaPublicKey {
    pub n: u32,
    pub e: u32,
}

pub struct RsaPrivateKey {
    pub n: u32,
    pub d: u32,
}

pub fn mod_pow(mut base: u32, mut exp: u32, modulus: u32) -> u32 {
    if modulus == 1 {
        return 0;
    }
    let mut result = 1;
    base %= modulus;
    while exp > 0 {
        if exp % 2 == 1 {
            result = (result * base) % modulus;
        }
        exp >>= 1;
        base = (base * base) % modulus;
    }
    result
}

pub fn encrypt(pk: &RsaPublicKey, m: u32) -> u32 {
    mod_pow(m, pk.e, pk.n)
}

pub fn decrypt(sk: &RsaPrivateKey, c: u32) -> u32 {
    mod_pow(c, sk.d, sk.n)
}

pub fn extended_gcd(a: i32, b: i32) -> (i32, i32, i32) {
    let mut s = 0;
    let mut old_s = 1;
    let mut r = b;
    let mut old_r = a;

    while r != 0 {
        let quotient = old_r / r;
        let temp_r = r;
        r = old_r - quotient * r;
        old_r = temp_r;

        let temp_s = s;
        s = old_s - quotient * s;
        old_s = temp_s;
    }

    let mut t = 0;
    if b != 0 {
        t = (old_r - old_s * a) / b;
    }

    (old_r, old_s, t)
}

pub fn mod_inverse(a: u32, m: u32) -> Option<u32> {
    let (g, x, _) = extended_gcd(a as i32, m as i32);
    if g != 1 {
        None
    } else {
        Some(((x % m as i32 + m as i32) % m as i32) as u32)
    }
}

pub fn break_rsa(p: u32, q: u32, e: u32) -> Option<RsaPrivateKey> {
    let n = p * q;
    let phi = (p - 1) * (q - 1);
    mod_inverse(e, phi).map(|d| RsaPrivateKey { n, d })
}
