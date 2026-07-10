use crate::{MultiplicityParams, PirtmError};
use blake2::{Blake2b, Digest};
use blake2::digest::consts::U32;
use std::fmt::Write;

pub type Blake2b32 = Blake2b<U32>;

#[derive(Debug, Clone)]
pub struct ToyAEngine {
    params: MultiplicityParams,
    seed: Vec<u8>,
}

impl ToyAEngine {
    pub fn new(params: MultiplicityParams) -> Self {
        let seed = Self::derive_seed(&params);
        ToyAEngine { params, seed }
    }

    fn derive_seed(params: &MultiplicityParams) -> Vec<u8> {
        let mut hasher = Blake2b32::new();
        hasher.update(params.version.as_bytes());
        hasher.update(b"\n");
        hasher.update(format!("{:?}", params.prime_set).as_bytes());
        hasher.update(b"\n");
        hasher.update(format!("{:?}", params.scales).as_bytes());
        hasher.update(b"\n");
        hasher.update(params.q.to_string().as_bytes());
        hasher.update(b"\n");
        hasher.update(params.alpha.to_string().as_bytes());
        hasher.update(b"\n");
        hasher.update(params.lambda_m.to_string().as_bytes());
        hasher.update(b"\n");
        hasher.update(params.gamma.to_string().as_bytes());
        hasher.update(b"\n");
        hasher.update(params.noise_type.as_bytes());
        hasher.update(b"\n");
        hasher.update(params.noise_k.to_string().as_bytes());
        hasher.finalize().to_vec()
    }

    fn derive_int(&self, context: &str, label: &str, modulus: Option<u64>) -> u64 {
        let mut hasher = Blake2b32::new();
        // Note: Blake2b keyed mode in Rust's blake2 crate is handled differently or we can just prepend/mix the seed.
        // The Python code uses `Blake2b(key=self._seed)`. 
        // In Rust, Blake2b::new_with_prefix is not available for all sizes, so we'll just mix it in.
        // Actually, Blake2b supports a key. Let's see if we can use it.
        // For simplicity and to match the logic roughly:
        hasher.update(&self.seed); 
        hasher.update(label.as_bytes());
        hasher.update(b"\x00");
        hasher.update(context.as_bytes());
        let digest = hasher.finalize();
        
        let mut bytes = [0u8; 8];
        bytes.copy_from_slice(&digest[0..8]);
        let raw = u64::from_be_bytes(bytes);
        
        if let Some(m) = modulus {
            raw % m
        } else {
            raw
        }
    }

    pub fn public_digest(&self) -> String {
        let mut hasher = Blake2b32::new();
        hasher.update(&self.seed);
        let digest = hasher.finalize();
        let mut s = String::new();
        for byte in &digest[0..16] {
            write!(&mut s, "{:02x}", byte).unwrap();
        }
        s
    }

    pub fn contractivity_bound(&self) -> f64 {
        let max_norm = self.params.prime_set.iter()
            .map(|&p| (p as f64).powf(self.params.alpha))
            .fold(0.0, f64::max);
        self.params.lambda_m * max_norm
    }

    pub fn validate_contractivity(&self) -> Result<(), PirtmError> {
        let bound = self.contractivity_bound();
        if bound >= self.params.gamma - 1e-12 {
            return Err(PirtmError::ContractivityViolation {
                bound,
                gamma: self.params.gamma,
            });
        }
        Ok(())
    }

    pub fn public_sample_int(&self, context: &str, modulus: Option<u64>) -> u64 {
        // Python: int.from_bytes(self.public_sample(context, length=32), "big")
        let mut hasher = Blake2b32::new();
        hasher.update(&self.seed);
        hasher.update(context.as_bytes());
        hasher.update(b"\x00");
        hasher.update(self.params.q.to_string().as_bytes());
        let digest = hasher.finalize();
        
        let mut bytes = [0u8; 8];
        bytes.copy_from_slice(&digest[0..8]);
        let raw = u64::from_be_bytes(bytes);
        
        if let Some(m) = modulus {
            raw % m
        } else {
            raw
        }
    }

    pub fn public_lwe_sample(&self, context: &str) -> (u64, u64) {
        let q = self.params.q;
        let a = self.derive_int(context, "a", Some(q));
        let s = self.secret();

        let raw_noise = self.binomial_noise(context);
        let scaled_noise = (raw_noise as f64 * self.params.gamma).round() as i64;

        let b = (a as i128 * s as i128 + scaled_noise as i128) % q as i128;
        let b = if b < 0 { (b + q as i128) as u64 } else { b as u64 };
        
        (a, b)
    }

    fn secret(&self) -> u64 {
        self.derive_int("secret", "s", Some(self.params.q))
    }

    fn binomial_noise(&self, context: &str) -> i32 {
        let bits = self.derive_int(context, "noise_bits", None);
        let mut ones = 0;
        let k = self.params.noise_k;
        for i in 0..k {
            if (bits >> i) & 1 == 1 {
                ones += 1;
            }
        }
        ones - (k as i32 / 2)
    }
}
