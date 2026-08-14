// Manages the transition from Hologram compute atoms to L0 prime gates.
// Mandated by ADR-019 (Projection & Mapping)

use anyhow::{Result, bail};
use pirtm_compiler::ace::{DynamicOperator, FixedPoint, verify_stability, SCALE_BASE};

pub struct HologramAdapter {
    pub current_thickness: u64,
}

impl HologramAdapter {
    /// Gatekeeper: Validates vGPU operator launch against RSL v5 constraints.
    /// Maps compute atom (Hologram) -> prime-indexed gate (Goldilocks).
    pub fn validate_and_seal(&self, atom_id: u8, output_thickness: u64, input_thickness: u64) -> Result<()> {
        // 1. ADR-019 Enforcement: Pre-seal contractivity check (MP-01)
        if output_thickness > input_thickness {
            bail!("[Constitutional Gate] REJECT: Multiplicity Inflation ({} > {})", 
                  output_thickness, input_thickness);
        }

        // 2. Integration with PIRTM-lang Phase C: ACE Invariant Checks
        // We treat the current transition as a dynamic operator with norm proportional to thickness ratio
        let norm = if input_thickness > 0 {
            FixedPoint::from_rational(output_thickness as i64, input_thickness as i64)
        } else {
            FixedPoint(0)
        };

        let op = DynamicOperator {
            signature: pirtm_compiler::types::Sig::new(), // Initial empty signature
            norm,
        };

        // Use a standard governance constant c = 0.05 (represented as SCALE_BASE * 5 / 100)
        let governance_c = FixedPoint(SCALE_BASE * 5 / 100);

        verify_stability(&[op], governance_c)
            .map_err(|e| anyhow::anyhow!("[Constitutional Gate] ACE Stability Violation: {}", e))?;
        
        println!("[Constitutional Gate] ADMITTED: Prime Gate P_{} sealed at thickness {}.", atom_id, output_thickness);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_and_seal_stable() {
        let adapter = HologramAdapter { current_thickness: 100 };
        // Output 90, Input 100 -> Norm 0.9.
        // Gov C 0.05 -> Total 0.95 < 1.0 (PASS)
        let result = adapter.validate_and_seal(1, 90, 100);
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_and_seal_unstable() {
        let adapter = HologramAdapter { current_thickness: 100 };
        // Output 100, Input 100 -> Norm 1.0.
        // Gov C 0.05 -> Total 1.05 >= 1.0 (FAIL)
        let result = adapter.validate_and_seal(1, 100, 100);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Stability Violation"));
    }

    #[test]
    fn test_validate_and_seal_inflation_veto() {
        let adapter = HologramAdapter { current_thickness: 100 };
        // Output 110, Input 100 -> Inflation (FAIL)
        let result = adapter.validate_and_seal(1, 110, 100);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Multiplicity Inflation"));
    }
}
