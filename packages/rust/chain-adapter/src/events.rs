use alloy::sol_types::SolEvent;
use alloy::primitives::Log;
use anyhow::Result;

use crate::adapter::ICore::{ExcessiveDrift, XiStateTransition};

pub struct EventParser;

impl EventParser {
    pub fn parse_quantum_proof_verified(log: &Log) -> Result<XiStateTransition> {
        let decoded = XiStateTransition::decode_log(log, true)?;
        Ok(decoded.data)
    }

    pub fn parse_xi_drift_exceeded(log: &Log) -> Result<ExcessiveDrift> {
        let decoded = ExcessiveDrift::decode_log(log, true)?;
        Ok(decoded.data)
    }
}
