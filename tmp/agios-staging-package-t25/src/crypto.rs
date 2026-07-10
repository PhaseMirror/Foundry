use serde::{Deserialize, Serialize};

pub const CIRCUIT_WIDTH: usize = 1000;
pub const SCALING_FACTOR: f64 = 1_000_000.0; // 10^6 precision mapping
pub const GOLDILOCKS_PRIME: u64 = 18446744069414584321; // 2^64 - 2^32 + 1

/// A mock representation of a Finite Field element.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct FieldElement(pub u64);

pub struct SafeNecessityProjector;

impl SafeNecessityProjector {
    /// Transforms the normalized f64 ingress data array into scaled finite field elements.
    /// Safely handles bounds and prevents wrap-around vulnerabilities relative to the field modulus.
    pub fn quantize_matrix(matrix: &[f64; CIRCUIT_WIDTH]) -> Result<[FieldElement; CIRCUIT_WIDTH], Box<dyn std::error::Error>> {
        let mut field_matrix = [FieldElement(0); CIRCUIT_WIDTH];

        for (i, &val) in matrix.iter().enumerate() {
            if !val.is_finite() {
                return Err(format!("[ERROR] Non-finite parameter detected at index {}", i).into());
            }

            let scaled = (val * SCALING_FACTOR).round();
            
            // Check for finite field overflow / wrap-around vulnerability
            let abs_scaled = scaled.abs();
            if abs_scaled >= GOLDILOCKS_PRIME as f64 {
                return Err(format!(
                    "[ERROR] Input value {} scales to {} which violates the Goldilocks prime modulus threshold ({})",
                    val, scaled, GOLDILOCKS_PRIME
                ).into());
            }

            let field_val = if scaled < 0.0 {
                let abs_scaled_u64 = abs_scaled as u64;
                GOLDILOCKS_PRIME - abs_scaled_u64 // Field arithmetic complement
            } else {
                scaled as u64
            };

            field_matrix[i] = FieldElement(field_val);
        }

        Ok(field_matrix)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_deterministic_quantization() {
        let mut mock_ingress = [0.0; CIRCUIT_WIDTH];
        mock_ingress[0] = 98.6123456; // Standard clinical variable
        mock_ingress[1] = -5.5;        // Negative delta coordinate
        mock_ingress[2] = 0.0;         // Origin point

        let quantized = SafeNecessityProjector::quantize_matrix(&mock_ingress).unwrap();

        // Verify precision constraint scaling (98.6123456 * 10^6 = 98612346)
        assert_eq!(quantized[0], FieldElement(98612346));
        assert_eq!(quantized[1], FieldElement(GOLDILOCKS_PRIME - 5500000));
        assert_eq!(quantized[2], FieldElement(0));
    }

    #[test]
    fn test_overflow_protection() {
        let mut mock_ingress = [0.0; CIRCUIT_WIDTH];
        // Value large enough to overflow the prime modulus once scaled
        mock_ingress[0] = 1.9e13; 

        let res = SafeNecessityProjector::quantize_matrix(&mock_ingress);
        assert!(res.is_err());
        assert!(res.unwrap_err().to_string().contains("violates the Goldilocks prime modulus threshold"));
    }
}
