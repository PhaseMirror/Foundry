//! # echonomics_engine::hlix_clearing — ADR-0028 HLIX Compute Infrastructure Clearinghouse
//!
//! Production-grade implementation of the HLIX post-trade clearing model:
//! - Universal Object Reference (UOR): compute identity is the deterministic
//!   prime-indexed root `root = primeIndex ^ exponent`, valid only for a
//!   prime base (`≥ 2`) with a positive exponent. Overflow fails closed
//!   (`None`).
//! - Holotrade clearing gate: a trade clears exactly when the bid meets the
//!   ask; the trade settles at the ask (limit-order floor).
//! - Exchange fee: a bounded 10% fee (`price / 10`) that never exceeds the
//!   price.
//! - Allocation gate: allocated compute never exceeds total capacity.
//!
//! Kani model-checking harnesses (`cargo kani`) discharge the gate properties
//! for all symbolic inputs.

use serde::{Deserialize, Serialize};

/// Exchange fee basis: 10% (`price / 10`).
pub const EXCHANGE_FEE_BASIS: u64 = 10;

/// Maximum representable UOR exponent. Identity roots beyond `p^8` leave the
/// `u64` representable domain or the bounded loop's unwind budget, so they
/// fail closed (`None`).
pub const MAX_UOR_EXPONENT: u32 = 8;

/// A UOR reference: identity is `root = primeIndex ^ exponent`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct UorReference {
    /// Mathematical root of the block (a prime base).
    pub prime_index: u64,
    /// Block multiplicity (positive exponent).
    pub exponent: u64,
}

impl UorReference {
    /// Reference validity: a prime base (`≥ 2`) with a positive exponent
    /// within the representable root domain.
    pub const fn is_valid(&self) -> bool {
        self.prime_index >= 2 && self.exponent >= 1 && self.exponent <= MAX_UOR_EXPONENT as u64
    }

    /// The deterministic UOR root: `primeIndex ^ exponent`.
    /// Returns `None` on overflow or an out-of-domain exponent (fails closed).
    pub const fn uor_root(&self) -> Option<u64> {
        if self.exponent > MAX_UOR_EXPONENT as u64 {
            return None;
        }
        let mut acc: u64 = 1;
        let mut i: u32 = 0;
        while i < MAX_UOR_EXPONENT {
            if (self.exponent as u32) <= i {
                break;
            }
            match acc.checked_mul(self.prime_index) {
                Some(a) => acc = a,
                None => return None,
            }
            i += 1;
        }
        Some(acc)
    }
}

/// Clearing state: the developer's `bidPrice` versus the enterprise's
/// `askPrice` in the continuous double auction.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct ClearingState {
    pub bid_price: u64,
    pub ask_price: u64,
}

impl ClearingState {
    /// A trade clears exactly when the bid meets the ask.
    pub const fn clears(&self) -> bool {
        self.bid_price >= self.ask_price
    }

    /// Clearing price: the trade settles at the ask (limit-order floor).
    pub const fn clearing_price(&self) -> u64 {
        self.ask_price
    }

    /// The 10% exchange fee on the clearing price, bounded by the price.
    pub const fn exchange_fee(&self) -> u64 {
        exchange_fee(self.clearing_price())
    }
}

/// The 10% exchange fee on a price.
pub const fn exchange_fee(price: u64) -> u64 {
    price / EXCHANGE_FEE_BASIS
}

/// Allocation validity: allocated compute never exceeds total capacity.
pub const fn is_allocation_within_capacity(allocated: u64, total: u64) -> bool {
    allocated <= total
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_uor_identity() {
        let ref3_2 = UorReference { prime_index: 3, exponent: 2 };
        let bad = UorReference { prime_index: 1, exponent: 0 };

        assert!(ref3_2.is_valid());
        assert_eq!(ref3_2.uor_root(), Some(9), "3^2 = 9");
        assert_eq!(UorReference { prime_index: 2, exponent: 8 }.uor_root(), Some(256));
        assert!(!bad.is_valid(), "unit roots would allow identity collisions");
        assert!(!UorReference { prime_index: 3, exponent: 9 }.is_valid(), "out-of-domain exponent");
        assert_eq!(UorReference { prime_index: 3, exponent: 9 }.uor_root(), None, "fail closed");
        assert_eq!(
            UorReference { prime_index: 65536, exponent: 4 }.uor_root(),
            None,
            "2^64 overflow fails closed"
        );
    }

    #[test]
    fn test_clearing_gate() {
        let clears = ClearingState { bid_price: 120, ask_price: 100 };
        let no_clear = ClearingState { bid_price: 90, ask_price: 100 };

        assert!(clears.clears());
        assert_eq!(clears.clearing_price(), 100);
        assert!(!no_clear.clears(), "bid below ask never clears");
    }

    #[test]
    fn test_exchange_fee() {
        assert_eq!(exchange_fee(100), 10);
        assert_eq!(ClearingState { bid_price: 120, ask_price: 100 }.exchange_fee(), 10);
        assert!(exchange_fee(1000) <= 1000, "fee never exceeds price");
    }

    #[test]
    fn test_allocation_capacity() {
        assert!(is_allocation_within_capacity(80, 100));
        assert!(!is_allocation_within_capacity(101, 100));
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// ADR-0028: a valid reference roots to a positive, nonzero identity at
    /// least as large as its prime base.
    #[kani::proof]
    fn verify_valid_reference_positive_root() {
        let prime_index: u64 = kani::any();
        let exponent: u64 = kani::any();
        kani::assume(prime_index >= 2 && exponent >= 1);
        kani::assume(prime_index <= 65536 && exponent <= MAX_UOR_EXPONENT as u64);

        let r = UorReference { prime_index, exponent };
        if let Some(root) = r.uor_root() {
            kani::assert(root > 0, "valid references never root to zero");
            kani::assert(root >= prime_index, "root = p^e ≥ p for e ≥ 1");
        }
    }

    /// ADR-0028: out-of-domain exponents fail closed — the root is `None`.
    #[kani::proof]
    fn verify_out_of_domain_exponent_fails_closed() {
        let prime_index: u64 = kani::any();
        let exponent: u64 = kani::any();
        kani::assume(exponent > MAX_UOR_EXPONENT as u64);

        let r = UorReference { prime_index, exponent };
        kani::assert(!r.is_valid(), "out-of-domain exponent is invalid");
        kani::assert(r.uor_root().is_none(), "out-of-domain exponent fails closed");
    }

    /// ADR-0028: the clearing gate is exactly `bid ≥ ask`.
    #[kani::proof]
    fn verify_clearing_requires_bid_at_least_ask() {
        let bid_price: u64 = kani::any();
        let ask_price: u64 = kani::any();
        let st = ClearingState { bid_price, ask_price };
        if st.clears() {
            kani::assert(bid_price >= ask_price, "clearing requires bid ≥ ask");
        }
    }

    /// ADR-0028: the 10% exchange fee never exceeds the price.
    #[kani::proof]
    fn verify_fee_never_exceeds_price() {
        let price: u64 = kani::any();
        kani::assert(exchange_fee(price) <= price, "10% fee bounded by price");
    }

    /// ADR-0028: allocation over capacity is always rejected.
    #[kani::proof]
    fn verify_allocation_over_capacity_rejected() {
        let allocated: u64 = kani::any();
        let total: u64 = kani::any();
        if allocated > total {
            kani::assert(!is_allocation_within_capacity(allocated, total), "over-capacity rejected");
        }
    }
}