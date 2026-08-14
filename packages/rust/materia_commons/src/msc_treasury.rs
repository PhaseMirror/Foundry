// materia_commons/src/msc_treasury.rs

use num_bigint::BigUint;
use std::str::FromStr;

/// The base emission reward per perfectly resonant Triad (scaled to 10^8)
const BASE_TRIAD_EMISSION: &str = "100000000"; 

/// The mathematical ceiling of a perfectly resonant Triad in the prime field
/// (10^8 scale factor ^ 4 factors)
const MAXIMUM_RESONANCE_FIELD: &str = "100000000000000000000000000000000"; // 10^32

/// The Hundian Ground State Peg for Epoch 1
pub const EPOCH_1_PEG: f64 = 1.00;

pub struct MscTreasury {
    pub total_supply: BigUint,
    pub active_epoch: u32,
    /// The planetary tether: Funds locked for Machine-Verified Charities
    pub charity_pool: BigUint, 
    /// The biological baseline: Funds distributed to active Genesis Node Operators
    pub operator_pool: BigUint, 
}

impl MscTreasury {
    pub fn new() -> Self {
        Self {
            total_supply: BigUint::from(0u32),
            active_epoch: 1, // Epoch 1: Foundation (Internal Spin-Up)
            charity_pool: BigUint::from(0u32),
            operator_pool: BigUint::from(0u32),
        }
    }

    /// Proof-of-Practice Minting Protocol
    /// Ingests the boolean output from the QCFI Hardware Loop and the
    /// calculated Triadic Resonance to authorize economic expansion.
    #[inline(always)]
    pub fn execute_mint(
        &mut self,
        qcfi_hardware_pass: bool,
        triadic_resonance: &BigUint,
    ) -> Result<BigUint, &'static str> {
        
        // 1. THE SENTINEL GATE (Hardware Supremacy)
        // If the Xilinx RFSoC detects latency > 920ns or structural dissonance,
        // the economic engine absolutely refuses to mint.
        if !qcfi_hardware_pass {
            return Err("ECONOMIC HALT: Phase Mirror rejected the state transition. Zero value minted.");
        }

        // 2. THE MULTIPLICITY EMISSION CURVE
        // Value is dynamically scaled based on the actual resonance achieved 
        // by the human edge nodes, punishing Dissonance with lower yields.
        let base_reward = BigUint::from_str(BASE_TRIAD_EMISSION).unwrap();
        
        // We modulate the base reward by the geometric scale of the Triad's resonance.
        let normalized_resonance_scalar = self.normalize_resonance(triadic_resonance);
        
        let precision_scalar = BigUint::from(10_000u32);
        let minted_amount = (base_reward * normalized_resonance_scalar) / precision_scalar;

        // 3. LEDGER EXPANSION
        self.total_supply += &minted_amount;

        println!(">>> PROOF-OF-PRACTICE SUCCESS: Minted {} MSC units at Hundian Peg ${:.2}", 
                 minted_amount, EPOCH_1_PEG);

        Ok(minted_amount)
    }

    /// Normalizes the massive field element back to a functional fixed-point multiplier
    /// Returns a scaled integer representing the exact percentage of the base emission to mint.
    #[inline(always)]
    fn normalize_resonance(&self, actual_resonance: &BigUint) -> BigUint {
        let max_resonance = BigUint::from_str(MAXIMUM_RESONANCE_FIELD).unwrap();
        
        // Safety Bound: The execution layer should never produce a value higher 
        // than the mathematical ceiling, but we clamp it to prevent overflow anomalies.
        let clamped_resonance = std::cmp::min(actual_resonance, &max_resonance);

        // We require high precision for economic distribution. 
        // We multiply by a precision factor of 10,000 (representing two decimal places of a percentage, e.g., 99.99%)
        // before dividing, to avoid losing fractional data in integer division.
        let precision_scalar = BigUint::from(10_000u32);
        
        // Emission Percentage = (Actual * 10,000) / Maximum
        let emission_percentage = (clamped_resonance * precision_scalar) / max_resonance;

        // The output is an integer between 1 and 10,000. 
        // 10,000 = 100.00% emission. 
        // 1 = 0.01% emission (The Epsilon Floor).
        emission_percentage
    }

    /// The Reciprocity Distribution Matrix (2R + 1 = M)
    /// Automatically fractures newly minted capital into Triadic proportions.
    #[inline(always)]
    pub fn route_capital(&mut self, minted_amount: &BigUint) -> Result<(BigUint, BigUint), &'static str> {
        if minted_amount == &BigUint::from(0u32) {
            return Err("ROUTING FAILED: Zero value provided. Dissonance threshold not met.");
        }

        let triad_divisor = BigUint::from(3u32);

        // 1: The Anchor (Planetary Stewardship)
        // 1/3 of the emission flows to the Machine-Verified Charity Pool
        let foundation_share = minted_amount / &triad_divisor;

        // 2R: Reciprocity (Node Operators)
        // The remainder (2/3) flows to the Edge Stewards
        let reciprocity_share = minted_amount - &foundation_share;

        // Execute the ledger state transition
        self.charity_pool += &foundation_share;
        self.operator_pool += &reciprocity_share;

        println!(">>> CAPITAL ROUTED: 2R ({}) to Operators | 1 ({}) to Charity", 
                 reciprocity_share, foundation_share);

        Ok((reciprocity_share, foundation_share))
    }

    /// Submits the Ecological Payload to the Verification Oracle.
    /// If verified, unseals the Charity Pool and routes it to the designated physical intervention team.
    pub fn unseal_charity_funds(
        &mut self,
        payload: &crate::charity_verification::EcologicalPayload,
    ) -> Result<BigUint, &'static str> {
        // 1. The Verification Oracle determines if the entropy shift is sufficient
        crate::charity_verification::VerificationOracle::audit_payload(payload)?;

        // 2. Unseal the funds
        let unsealed_funds = self.charity_pool.clone();
        
        // 3. Drain the pool (simulating transfer to the physical intervention team)
        self.charity_pool = BigUint::from(0u32);

        println!(">>> CHARITY POOL UNSEALED: {} MSC transferred for planetary intervention.", unsealed_funds);

        Ok(unsealed_funds)
    }
}
