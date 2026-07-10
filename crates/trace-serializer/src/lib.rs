/// Trace serialization with frozen column order for deterministic STARK proving
/// 
/// Spec-defined column order (20 columns):
/// round, step, is_round_start, is_mul, is_square, is_end,
/// a, d, s, bit, acc, base, t_lo, t_hi, q, r, mu_lo, mu_hi, hit_nm1, witness_flag

use serde::{Deserialize, Serialize};
use sha3::{Digest, Keccak256};
use std::io::Write;

/// Column order frozen by spec - NEVER CHANGE THIS ORDER
pub const COLUMN_ORDER: &[&str] = &[
    "round",
    "step",
    "is_round_start",
    "is_mul",
    "is_square",
    "is_end",
    "a",
    "d",
    "s",
    "bit",
    "acc",
    "base",
    "t_lo",
    "t_hi",
    "q",
    "r",
    "mu_lo",
    "mu_hi",
    "hit_nm1",
    "witness_flag",
];

/// Single row in the execution trace
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TraceRow {
    pub round: u64,
    pub step: u64,
    pub is_round_start: u64,  // boolean: 0 or 1
    pub is_mul: u64,          // boolean: 0 or 1
    pub is_square: u64,       // boolean: 0 or 1
    pub is_end: u64,          // boolean: 0 or 1
    pub a: u64,
    pub d: u64,
    pub s: u64,
    pub bit: u64,
    pub acc: u64,
    pub base: u64,
    pub t_lo: u64,
    pub t_hi: u64,
    pub q: u64,
    pub r: u64,
    pub mu_lo: u64,
    pub mu_hi: u64,
    pub hit_nm1: u64,         // boolean: 0 or 1
    pub witness_flag: u64,    // boolean: 0 or 1
}

/// Full execution trace with frozen column order
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecutionTrace {
    pub rows: Vec<TraceRow>,
    pub column_order: Vec<String>,
}

impl ExecutionTrace {
    /// Create new trace with frozen column order
    pub fn new() -> Self {
        Self {
            rows: Vec::new(),
            column_order: COLUMN_ORDER.iter().map(|s| s.to_string()).collect(),
        }
    }

    /// Add a row to the trace
    pub fn push(&mut self, row: TraceRow) {
        self.rows.push(row);
    }

    /// Serialize to JSON with frozen column order
    pub fn to_json(&self) -> anyhow::Result<String> {
        // Use canonical JSON with sorted keys
        let mut map = serde_json::Map::new();
        map.insert("column_order".to_string(), serde_json::json!(self.column_order));
        
        // Serialize rows
        let rows_json: Vec<Vec<u64>> = self.rows.iter().map(|row| {
            vec![
                row.round,
                row.step,
                row.is_round_start,
                row.is_mul,
                row.is_square,
                row.is_end,
                row.a,
                row.d,
                row.s,
                row.bit,
                row.acc,
                row.base,
                row.t_lo,
                row.t_hi,
                row.q,
                row.r,
                row.mu_lo,
                row.mu_hi,
                row.hit_nm1,
                row.witness_flag,
            ]
        }).collect();
        
        map.insert("rows".to_string(), serde_json::json!(rows_json));
        
        Ok(serde_json::to_string_pretty(&map)?)
    }

    /// Serialize to binary format (little-endian u64 values)
    pub fn to_binary(&self) -> anyhow::Result<Vec<u8>> {
        let mut buf = Vec::new();
        
        // Write number of rows (8 bytes)
        buf.write_all(&(self.rows.len() as u64).to_le_bytes())?;
        
        // Write number of columns (8 bytes)
        buf.write_all(&(COLUMN_ORDER.len() as u64).to_le_bytes())?;
        
        // Write each row in column order
        for row in &self.rows {
            buf.write_all(&row.round.to_le_bytes())?;
            buf.write_all(&row.step.to_le_bytes())?;
            buf.write_all(&row.is_round_start.to_le_bytes())?;
            buf.write_all(&row.is_mul.to_le_bytes())?;
            buf.write_all(&row.is_square.to_le_bytes())?;
            buf.write_all(&row.is_end.to_le_bytes())?;
            buf.write_all(&row.a.to_le_bytes())?;
            buf.write_all(&row.d.to_le_bytes())?;
            buf.write_all(&row.s.to_le_bytes())?;
            buf.write_all(&row.bit.to_le_bytes())?;
            buf.write_all(&row.acc.to_le_bytes())?;
            buf.write_all(&row.base.to_le_bytes())?;
            buf.write_all(&row.t_lo.to_le_bytes())?;
            buf.write_all(&row.t_hi.to_le_bytes())?;
            buf.write_all(&row.q.to_le_bytes())?;
            buf.write_all(&row.r.to_le_bytes())?;
            buf.write_all(&row.mu_lo.to_le_bytes())?;
            buf.write_all(&row.mu_hi.to_le_bytes())?;
            buf.write_all(&row.hit_nm1.to_le_bytes())?;
            buf.write_all(&row.witness_flag.to_le_bytes())?;
        }
        
        Ok(buf)
    }

    /// Compute column order hash (for manifest binding)
    pub fn column_order_hash(&self) -> [u8; 32] {
        let order_str = self.column_order.join(",");
        let mut hasher = Keccak256::new();
        hasher.update(order_str.as_bytes());
        hasher.finalize().into()
    }
}

impl Default for ExecutionTrace {
    fn default() -> Self {
        Self::new()
    }
}

/// Binary transcript generator using Keccak256
pub struct TranscriptGenerator {
    hasher: Keccak256,
}

impl TranscriptGenerator {
    pub fn new() -> Self {
        Self {
            hasher: Keccak256::new(),
        }
    }

    /// Absorb trace commitment
    pub fn absorb_trace_commitment(&mut self, commitment: &[u8; 32]) {
        self.hasher.update(commitment);
    }

    /// Absorb challenge value
    pub fn absorb_challenge(&mut self, challenge: &[u8]) {
        self.hasher.update(challenge);
    }

    /// Squeeze challenge bytes
    pub fn squeeze(&mut self, len: usize) -> Vec<u8> {
        let hash = self.hasher.clone().finalize();
        hash[..len.min(32)].to_vec()
    }

    /// Finalize and get transcript hash
    pub fn finalize(self) -> [u8; 32] {
        self.hasher.finalize().into()
    }

    /// Generate transcript from trace
    pub fn generate_transcript(trace_commitment: &[u8; 32]) -> Vec<u8> {
        let mut transcript = Self::new();
        transcript.absorb_trace_commitment(trace_commitment);
        
        // Generate deterministic challenges
        let alpha = transcript.squeeze(32);
        transcript.absorb_challenge(&alpha);
        
        let beta = transcript.squeeze(32);
        transcript.absorb_challenge(&beta);
        
        // Return binary transcript
        let mut result = Vec::new();
        result.extend_from_slice(trace_commitment);
        result.extend_from_slice(&alpha);
        result.extend_from_slice(&beta);
        result
    }
}

impl Default for TranscriptGenerator {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_column_order_frozen() {
        assert_eq!(COLUMN_ORDER.len(), 20);
        assert_eq!(COLUMN_ORDER[0], "round");
        assert_eq!(COLUMN_ORDER[19], "witness_flag");
    }

    #[test]
    fn test_trace_serialization() {
        let mut trace = ExecutionTrace::new();
        
        trace.push(TraceRow {
            round: 0,
            step: 0,
            is_round_start: 1,
            is_mul: 0,
            is_square: 0,
            is_end: 0,
            a: 17,
            d: 1,
            s: 4,
            bit: 0,
            acc: 1,
            base: 2,
            t_lo: 0,
            t_hi: 0,
            q: 0,
            r: 0,
            mu_lo: 0,
            mu_hi: 0,
            hit_nm1: 0,
            witness_flag: 1,
        });

        let json = trace.to_json().unwrap();
        assert!(json.contains("column_order"));
        assert!(json.contains("rows"));
    }

    #[test]
    fn test_binary_serialization() {
        let mut trace = ExecutionTrace::new();
        
        trace.push(TraceRow {
            round: 0,
            step: 0,
            is_round_start: 1,
            is_mul: 0,
            is_square: 1,
            is_end: 0,
            a: 17,
            d: 1,
            s: 4,
            bit: 1,
            acc: 2,
            base: 2,
            t_lo: 34,
            t_hi: 0,
            q: 2,
            r: 0,
            mu_lo: 0,
            mu_hi: 0,
            hit_nm1: 0,
            witness_flag: 1,
        });

        let binary = trace.to_binary().unwrap();
        
        // Header: 8 bytes (num_rows) + 8 bytes (num_cols)
        // Data: 1 row * 20 columns * 8 bytes = 160 bytes
        assert_eq!(binary.len(), 16 + 160);
    }

    #[test]
    fn test_deterministic_hash() {
        let trace1 = ExecutionTrace::new();
        let trace2 = ExecutionTrace::new();
        
        let hash1 = trace1.column_order_hash();
        let hash2 = trace2.column_order_hash();
        
        assert_eq!(hash1, hash2);
    }

    #[test]
    fn test_transcript_generation() {
        let commitment = [0u8; 32];
        let transcript = TranscriptGenerator::generate_transcript(&commitment);
        
        // Should contain commitment + 2 challenges (32 + 32 + 32 = 96 bytes)
        assert_eq!(transcript.len(), 96);
    }
}
