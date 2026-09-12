use crate::{
    bigint::{BigInt, LIMB_BITS},
    certificate::{CertificateError, PrattCertificate},
    miller_rabin::miller_rabin_64,
    support::support_window,
};
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RequestedMode {
    MillerRabin,
    Certificate,
    Auto,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct VerificationOutcome {
    pub mode_used: UsedMode,
    pub is_prime: bool,
    pub estimated_rows: usize,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UsedMode {
    MillerRabin,
    Certificate,
}

#[derive(Debug)]
pub enum VerificationError {
    UnsupportedForMillerRabin,
    CertificateMissing,
    CertificateInvalid(CertificateError),
    NeedCertificate {
        estimated_rows: usize,
        row_budget: usize,
    },
    CertificateExceedsWindow {
        estimated_rows: usize,
        row_budget: usize,
    },
}

pub fn verify_primality(
    n: &BigInt,
    cert: Option<&PrattCertificate>,
    mode: RequestedMode,
) -> Result<VerificationOutcome, VerificationError> {
    let row_budget = support_window().max_trace_rows;
    match mode {
        RequestedMode::MillerRabin => run_miller_rabin(n, row_budget),
        RequestedMode::Certificate => run_certificate(n, cert, row_budget),
        RequestedMode::Auto => run_auto(n, cert, row_budget),
    }
}

fn run_miller_rabin(
    n: &BigInt,
    row_budget: usize,
) -> Result<VerificationOutcome, VerificationError> {
    let bits = n.bit_length();
    let estimate = estimate_mr_rows(bits);
    if estimate > row_budget {
        return Err(VerificationError::NeedCertificate {
            estimated_rows: estimate,
            row_budget,
        });
    }

    let n_u64 = n
        .to_u64()
        .ok_or(VerificationError::UnsupportedForMillerRabin)?;
    let result = miller_rabin_64(n_u64);
    Ok(VerificationOutcome {
        mode_used: UsedMode::MillerRabin,
        is_prime: result.is_prime,
        estimated_rows: estimate,
    })
}

fn run_certificate(
    n: &BigInt,
    cert: Option<&PrattCertificate>,
    row_budget: usize,
) -> Result<VerificationOutcome, VerificationError> {
    let certificate = cert.ok_or(VerificationError::CertificateMissing)?;
    certificate
        .verify()
        .map_err(VerificationError::CertificateInvalid)?;
    let estimate = estimate_pratt_rows(n.bit_length(), certificate);
    if estimate > row_budget {
        return Err(VerificationError::CertificateExceedsWindow {
            estimated_rows: estimate,
            row_budget,
        });
    }
    Ok(VerificationOutcome {
        mode_used: UsedMode::Certificate,
        is_prime: true,
        estimated_rows: estimate,
    })
}

fn run_auto(
    n: &BigInt,
    cert: Option<&PrattCertificate>,
    row_budget: usize,
) -> Result<VerificationOutcome, VerificationError> {
    let bits = n.bit_length();
    let mr_estimate = estimate_mr_rows(bits);
    let threshold = (row_budget as f64 * 0.9) as usize;

    if mr_estimate <= threshold {
        return run_miller_rabin(n, row_budget);
    }

    if let Some(certificate) = cert {
        certificate
            .verify()
            .map_err(VerificationError::CertificateInvalid)?;
        let pratt_rows = estimate_pratt_rows(bits, certificate);
        if pratt_rows > row_budget {
            return Err(VerificationError::CertificateExceedsWindow {
                estimated_rows: pratt_rows,
                row_budget,
            });
        }
        return Ok(VerificationOutcome {
            mode_used: UsedMode::Certificate,
            is_prime: true,
            estimated_rows: pratt_rows,
        });
    }

    Err(VerificationError::NeedCertificate {
        estimated_rows: mr_estimate,
        row_budget,
    })
}

fn estimate_mr_rows(bits: usize) -> usize {
    let limbs = limb_count(bits);
    let mul_cost = limbs * limbs * 2;
    let exp_mults = 64usize.saturating_mul(bits.max(1));
    saturating_mul(mul_cost, exp_mults)
}

fn estimate_pratt_rows(bits: usize, cert: &PrattCertificate) -> usize {
    let limbs = limb_count(bits);
    let mul_cost = limbs * limbs;
    let factor_count = count_pratt_factors(cert);
    let exp_mults = bits.max(1).saturating_mul(1 + factor_count);
    saturating_mul(mul_cost, exp_mults)
}

fn limb_count(bits: usize) -> usize {
    (bits + (LIMB_BITS - 1)) / LIMB_BITS
}

fn count_pratt_factors(cert: &PrattCertificate) -> usize {
    let mut total = 0usize;
    for factor in &cert.factors {
        total = total.saturating_add(factor.e as usize);
        if let Some(sub) = &factor.sub {
            total = total.saturating_add(count_pratt_factors(sub));
        }
    }
    total
}

fn saturating_mul(a: usize, b: usize) -> usize {
    let prod = (a as u128) * (b as u128);
    prod.min(usize::MAX as u128) as usize
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn auto_mode_uses_mr_for_small_inputs() {
        let candidate = BigInt::from_u64(17);
        let outcome = verify_primality(&candidate, None, RequestedMode::Auto).unwrap();
        assert!(matches!(outcome.mode_used, UsedMode::MillerRabin));
    }

    #[test]
    fn auto_mode_requests_certificate_when_rows_exceed_budget() {
        let candidate = BigInt::from_hex(concat!(
            "0x",
            "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
            "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
        ))
        .unwrap();
        assert!(candidate.bit_length() > 500);
        let err = verify_primality(&candidate, None, RequestedMode::Auto).unwrap_err();
        assert!(matches!(err, VerificationError::NeedCertificate { .. }));
    }
}
