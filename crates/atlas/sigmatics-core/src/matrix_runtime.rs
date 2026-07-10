use crate::Rational;

// The execution matrix size as defined by legacy 48x256 requirements
pub const ROWS: usize = 48;
pub const COLS: usize = 256;
pub const INDEX_SIZE: usize = ROWS * COLS; // 12,288

// Subgroup (Z/2)^11 constants
pub const NUM_ORBITS: usize = 6;
pub const ORBIT_SIZE: usize = 2048; // 2^11

#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub enum ValidationStage {
    Assert,
    Eval,
    Audit,
    Check,
}

#[derive(Debug, Clone)]
pub struct MatrixRuntime {
    // Exact integer tensor layout using Rational backend
    pub data: Vec<Vec<Rational>>,
    pub stage: ValidationStage,
}

impl MatrixRuntime {
    pub fn new() -> Self {
        Self {
            data: vec![vec![Rational::new(0, 1); COLS]; ROWS],
            stage: ValidationStage::Assert,
        }
    }

    /// Pack (page, byte) into (orbit, index) for the (Z/2)^11 action.
    /// Orbit r = p3 * 2 + p2_high ∈ {0..5}
    /// Index = (p2_low << 8) | b ∈ {0..2047}
    pub fn pack(p: usize, b: usize) -> (usize, usize) {
        let p2 = p % 16;
        let p3 = p / 16;
        let p2_high = (p2 >> 3) & 1;
        let p2_low = p2 & 7;
        
        let orbit = p3 * 2 + p2_high;
        let index = (p2_low << 8) | b;
        (orbit, index)
    }

    /// Unpack (orbit, index) into (page, byte).
    pub fn unpack(orbit: usize, index: usize) -> (usize, usize) {
        let p3 = orbit / 2;
        let p2_high = orbit % 2;
        let p2_low = (index >> 8) & 7;
        let b = index & 0xFF;
        
        let p2 = (p2_high << 3) | p2_low;
        let p = p3 * 16 + p2;
        (p, b)
    }

    /// Apply (Z/2)^11 action: u acts as bitwise XOR on the 11-bit index.
    pub fn act_u(&self, p: usize, b: usize, u: u16) -> (usize, usize) {
        let (orbit, index) = Self::pack(p, b);
        let index_new = index ^ (u as usize & 0x7FF);
        Self::unpack(orbit, index_new)
    }

    /// Transitions the runtime through the totality check lifecycle.
    pub fn transition_stage(&mut self, next: ValidationStage) -> Result<(), String> {
        match (self.stage, next) {
            (ValidationStage::Assert, ValidationStage::Eval) => {
                self.stage = ValidationStage::Eval;
                Ok(())
            }
            (ValidationStage::Eval, ValidationStage::Audit) => {
                self.stage = ValidationStage::Audit;
                Ok(())
            }
            (ValidationStage::Audit, ValidationStage::Check) => {
                self.stage = ValidationStage::Check;
                Ok(())
            }
            _ => Err(format!("Invalid stage transition from {:?} to {:?}", self.stage, next)),
        }
    }

    /// Map a compiled Sigmatics expression to a fixed matrix location.
    /// This ensures no hidden drift in the execution phase.
    pub fn map_expression_to_layout(&mut self, row: usize, col: usize, expr: crate::parser::Expr) -> Result<(), String> {
        if self.stage != ValidationStage::Eval {
            return Err("Expression mapping only allowed in Eval stage".to_string());
        }
        
        if row >= ROWS || col >= COLS {
            return Err("Index out of matrix bounds".to_string());
        }
        
        // Mapping logic: evaluating AST expr directly into the matrix cell
        match expr {
            crate::parser::Expr::Class(id) => {
                self.data[row][col] = Rational::new(id as i64, 1);
                Ok(())
            }
            _ => Err("Complex expression mapping not yet implemented".to_string()),
        }
    }

    /// Converts the rational matrix to a scaled integer tensor for execution.
    pub fn to_scaled_tensor(&self, q: i64) -> Vec<Vec<i64>> {
        self.data.iter()
            .map(|row| row.iter().map(|val| val.to_scaled_int(q)).collect())
            .collect()
    }

    /// Computes a SHA-256 hash of the current matrix state for ledger anchoring.
    pub fn compute_root_hash(&self) -> String {
        use sha2::{Digest, Sha256};
        let mut hasher = Sha256::new();
        for row in &self.data {
            for val in row {
                hasher.update(val.num.to_be_bytes());
                hasher.update(val.den.to_be_bytes());
            }
        }
        hex::encode(hasher.finalize())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::parser::Expr;

    #[test]
    fn test_pack_unpack_bijection() {
        for p in 0..ROWS {
            for b in 0..COLS {
                let (orbit, index) = MatrixRuntime::pack(p, b);
                let (p_new, b_new) = MatrixRuntime::unpack(orbit, index);
                assert_eq!(p, p_new, "Page mismatch at p={}, b={}", p, b);
                assert_eq!(b, b_new, "Byte mismatch at p={}, b={}", p, b);
            }
        }
    }

    #[test]
    fn test_orbit_partition() {
        let mut all_coords = std::collections::HashSet::new();
        for r in 0..NUM_ORBITS {
            for idx in 0..ORBIT_SIZE {
                let (p, b) = MatrixRuntime::unpack(r, idx);
                assert!(p < ROWS);
                assert!(b < COLS);
                assert!(all_coords.insert((p, b)), "Duplicate coord: ({}, {})", p, b);
            }
        }
        assert_eq!(all_coords.len(), INDEX_SIZE);
    }

    #[test]
    fn test_act_u_involutive() {
        let runtime = MatrixRuntime::new();
        let p = 17;
        let b = 42;
        let u = 0x555; // Some bits
        
        let (p1, b1) = runtime.act_u(p, b, u);
        let (p2, b2) = runtime.act_u(p1, b1, u);
        
        assert_eq!(p, p2);
        assert_eq!(b, b2);
    }

    #[test]
    fn test_stage_transitions() {
        let mut runtime = MatrixRuntime::new();
        assert_eq!(runtime.stage, ValidationStage::Assert);
        
        assert!(runtime.transition_stage(ValidationStage::Eval).is_ok());
        assert_eq!(runtime.stage, ValidationStage::Eval);
        
        assert!(runtime.transition_stage(ValidationStage::Audit).is_ok());
        assert_eq!(runtime.stage, ValidationStage::Audit);
        
        assert!(runtime.transition_stage(ValidationStage::Check).is_ok());
        assert_eq!(runtime.stage, ValidationStage::Check);
        
        // Invalid transition
        assert!(runtime.transition_stage(ValidationStage::Assert).is_err());
    }

    #[test]
    fn test_mapping_gate() {
        let mut runtime = MatrixRuntime::new();
        let expr = Expr::Class(21);
        
        // Fails in Assert stage
        assert!(runtime.map_expression_to_layout(0, 0, expr.clone()).is_err());
        
        runtime.transition_stage(ValidationStage::Eval).unwrap();
        assert!(runtime.map_expression_to_layout(0, 0, expr).is_ok());
    }

    #[test]
    fn test_scaled_tensor() {
        let mut runtime = MatrixRuntime::new();
        runtime.transition_stage(ValidationStage::Eval).unwrap();
        runtime.map_expression_to_layout(0, 0, Expr::Class(10)).unwrap();
        
        let scaled = runtime.to_scaled_tensor(1000);
        assert_eq!(scaled[0][0], 10000);
        assert_eq!(scaled[0][1], 0);
    }
}

impl Default for MatrixRuntime {
    fn default() -> Self {
        Self::new()
    }
}
