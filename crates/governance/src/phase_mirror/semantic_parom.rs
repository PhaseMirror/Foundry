#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct GFElement {
    pub value: u64,
    pub p: u64,
}

impl GFElement {
    pub fn new(value: u64, p: u64) -> Self {
        Self { value: value % p, p }
    }

    pub fn add(self, other: GFElement) -> Self {
        assert_eq!(self.p, other.p, "Field mismatch");
        Self::new(self.value + other.value, self.p)
    }

    pub fn mul(self, other: GFElement) -> Self {
        assert_eq!(self.p, other.p, "Field mismatch");
        Self::new(self.value * other.value, self.p)
    }

    pub fn inv(self) -> Option<Self> {
        if self.value == 0 {
            return None;
        }
        let (gcd, x, _) = extended_gcd(self.value as i64, self.p as i64);
        if gcd != 1 {
            return None;
        }
        Some(Self::new(((x % self.p as i64 + self.p as i64) % self.p as i64) as u64, self.p))
    }
}

pub fn extended_gcd(a: i64, b: i64) -> (i64, i64, i64) {
    if a == 0 {
        return (b, 0, 1);
    }
    let (gcd, x1, y1) = extended_gcd(b % a, a);
    let x = y1 - (b / a) * x1;
    let y = x1;
    (gcd, x, y)
}

pub fn crt_reconstruct(a: GFElement, b: GFElement) -> GFElement {
    let p = a.p as i64;
    let q = b.p as i64;
    let n = p * q;
    let (_, m1, m2) = extended_gcd(p, q);
    
    // x = (a*q*m2 + b*p*m1) mod n
    let term1 = (a.value as i128 * q as i128 * m2 as i128) % n as i128;
    let term2 = (b.value as i128 * p as i128 * m1 as i128) % n as i128;
    let mut x = (term1 + term2) % n as i128;
    if x < 0 {
        x += n as i128;
    }
    GFElement::new(x as u64, n as u64)
}

pub fn crt_reconstruct_multi(elements: &[GFElement]) -> GFElement {
    if elements.is_empty() {
        panic!("Empty elements");
    }
    let mut result = elements[0];
    for &next_el in &elements[1..] {
        result = crt_reconstruct(result, next_el);
    }
    result
}

pub fn lift_float_to_gfp(value: f64, p: u64) -> GFElement {
    let clamped = value.max(0.0).min(0.999999);
    let mapped = (clamped * p as f64) as u64;
    GFElement::new(mapped, p)
}

pub struct SemanticParom {
    pub primes: Vec<u64>,
    pub product_n: u64,
}

impl SemanticParom {
    pub fn new(primes: Vec<u64>) -> Self {
        let mut product_n = 1;
        for &p in &primes {
            product_n *= p;
        }
        Self { primes, product_n }
    }

    pub fn evolve(&self, input_val: f64) -> (f64, u64) {
        // 1. Lifting
        let residues: Vec<_> = self.primes.iter()
            .map(|&p| lift_float_to_gfp(input_val, p))
            .collect();
        
        // 2. Semantic Transition (Step +1 mod p)
        let evolved: Vec<_> = residues.iter()
            .map(|&r| r.add(GFElement::new(1, r.p)))
            .collect();
        
        // 3. Composite Reconstruction
        let composite = crt_reconstruct_multi(&evolved);
        
        let normalized = composite.value as f64 / self.product_n as f64;
        (normalized, composite.value)
    }
}
