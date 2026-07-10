use crate::bigint::{BigInt, Modulus};
use serde::Deserialize;
use thiserror::Error;

const BASE_PRIMES: &[u64] = &[2, 3, 5];

#[derive(Debug, Clone, Deserialize)]
pub struct PrattCertificate {
    pub p: String,
    pub factors: Vec<CertificateFactor>,
    pub g: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct CertificateFactor {
    pub q: String,
    #[serde(default = "default_exponent")]
    pub e: u32,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub sub: Option<Box<PrattCertificate>>,
}

fn default_exponent() -> u32 {
    1
}

#[derive(Debug, Error)]
pub enum CertificateError {
    #[error("invalid hex encoding for {field}")]
    InvalidHex { field: &'static str },
    #[error("missing factors for certificate")]
    MissingFactors,
    #[error("modulus must be odd and greater than two")]
    InvalidModulus,
    #[error("witness fails full-order check")]
    WitnessOrder,
    #[error("witness fails factor {0} order check")]
    WitnessFactor(String),
    #[error("factor {0} missing recursive certificate")]
    MissingSub(String),
    #[error("factor recursion failed for {0}")]
    Subcertificate(String, #[source] Box<CertificateError>),
    #[error("factor product mismatch")]
    FactorProductMismatch,
}

impl PrattCertificate {
    pub fn verify(&self) -> Result<(), CertificateError> {
        let p = BigInt::from_hex(&self.p).ok_or(CertificateError::InvalidHex { field: "p" })?;
        let g = BigInt::from_hex(&self.g).ok_or(CertificateError::InvalidHex { field: "g" })?;

        if self.factors.is_empty() {
            return Err(CertificateError::MissingFactors);
        }

        if p.is_zero() || p.is_one() || !p.is_odd() {
            return Err(CertificateError::InvalidModulus);
        }

        let modulus = Modulus::new(p.clone());
        let one = BigInt::one();
        let p_minus_one = p.sub(&one);

        if modulus.pow_mod(&g, &p_minus_one).cmp(&one) != core::cmp::Ordering::Equal {
            return Err(CertificateError::WitnessOrder);
        }

        let mut product = BigInt::one();

        for factor in &self.factors {
            let q = BigInt::from_hex(&factor.q)
                .ok_or(CertificateError::InvalidHex { field: "factors.q" })?;

            let q_pow = q.pow_u(factor.e);
            product = product.mul(&q_pow);

            let exp = p_minus_one
                .div_exact(&q)
                .ok_or_else(|| CertificateError::WitnessFactor(factor.q.clone()))?;

            let check = modulus.pow_mod(&g, &exp);
            if check.is_one() {
                return Err(CertificateError::WitnessFactor(factor.q.clone()));
            }

            if !is_base_prime(&q) {
                let sub = factor
                    .sub
                    .as_ref()
                    .ok_or_else(|| CertificateError::MissingSub(factor.q.clone()))?;
                sub.verify().map_err(|err| {
                    CertificateError::Subcertificate(factor.q.clone(), Box::new(err))
                })?;
            }
        }

        if product.cmp(&p_minus_one) != core::cmp::Ordering::Equal {
            return Err(CertificateError::FactorProductMismatch);
        }

        Ok(())
    }
}

fn is_base_prime(q: &BigInt) -> bool {
    if let Some(value) = q.to_u64() {
        return BASE_PRIMES.contains(&value);
    }
    false
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn verify_small_pratt_certificate() {
        let cert = PrattCertificate {
            p: "0x05".to_string(),
            g: "0x02".to_string(),
            factors: vec![CertificateFactor {
                q: "0x02".to_string(),
                e: 2,
                sub: None,
            }],
        };

        assert!(cert.verify().is_ok());
    }

    #[test]
    fn missing_subcertificate_fails() {
        let cert = PrattCertificate {
            p: "0x17".to_string(),
            g: "0x05".to_string(),
            factors: vec![
                CertificateFactor {
                    q: "0x02".to_string(),
                    e: 1,
                    sub: None,
                },
                CertificateFactor {
                    q: "0x0b".to_string(),
                    e: 1,
                    sub: None,
                },
            ],
        };

        assert!(matches!(
            cert.verify(),
            Err(CertificateError::MissingSub(_))
        ));
    }
}
