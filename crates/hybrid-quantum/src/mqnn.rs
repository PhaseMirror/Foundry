use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuditState {
    pub dimension: usize,
    pub amplitudes: Vec<num_complex::Complex64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MultiplicityLayer {
    pub input_dim: usize,
    pub output_dim: usize,
    pub weights: Vec<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HSECReport {
    pub fidelity: f64,
    pub threshold: f64,
    pub passed: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MQNNWitness {
    pub qudit_output_hash: [u8; 32],
    pub classical_output_hash: [u8; 32],
    pub hsec_report: HSECReport,
    pub timestamp: i64,
}

#[derive(Debug, thiserror::Error)]
pub enum DecoherenceError {
    #[error("HSEC detected decoherence: fidelity {fidelity} < threshold {threshold}")]
    DecoherenceDetected { fidelity: f64, threshold: f64 },
    #[error("dimension mismatch: qudit {qdim} vs classical {cdim}")]
    DimensionMismatch { qdim: usize, cdim: usize },
}

pub struct MQNN {
    multiplicity_layer: MultiplicityLayer,
    hsec_threshold: f64,
}

fn compute_fidelity(state: &QuditState) -> f64 {
    state.amplitudes.iter().map(|c| c.norm_sqr()).sum::<f64>().sqrt()
}

fn extract_classical_embedding(state: &QuditState) -> Vec<f64> {
    state.amplitudes.iter().map(|c| c.norm()).collect()
}

impl MQNN {
    pub fn new(layer: MultiplicityLayer, threshold: f64) -> Self {
        Self {
            multiplicity_layer: layer,
            hsec_threshold: threshold,
        }
    }

    pub fn forward(
        &self,
        qudit_state: &QuditState,
        classical_input: &[f64],
    ) -> Result<Vec<f64>, DecoherenceError> {
        let _hsec_report = self.apply_hsec(qudit_state)?;
        let qudit_output = extract_classical_embedding(qudit_state);
        if qudit_output.len() != classical_input.len() {
            return Err(DecoherenceError::DimensionMismatch {
                qdim: qudit_output.len(),
                cdim: classical_input.len(),
            });
        }
        let combined: Vec<f64> = qudit_output.iter()
            .zip(classical_input.iter())
            .map(|(q, c)| q * c)
            .collect();
        Ok(combined)
    }

    pub fn apply_hsec(&self, state: &QuditState) -> Result<HSECReport, DecoherenceError> {
        let fidelity = compute_fidelity(state);
        if fidelity < self.hsec_threshold {
            return Err(DecoherenceError::DecoherenceDetected {
                fidelity,
                threshold: self.hsec_threshold,
            });
        }
        Ok(HSECReport { fidelity, threshold: self.hsec_threshold, passed: true })
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_hsec_sound() {
        let mqnn = MQNN::new(MultiplicityLayer {
            input_dim: 2,
            output_dim: 2,
            weights: vec![0.5, 0.5, 0.5, 0.5],
        }, 0.99);

        let amplitudes = vec![
            num_complex::Complex64::new(kani::any(), kani::any()),
            num_complex::Complex64::new(kani::any(), kani::any()),
        ];
        
        let state = QuditState {
            dimension: 2,
            amplitudes,
        };
        
        let fidelity = compute_fidelity(&state);
        kani::assume(fidelity >= 0.0 && fidelity <= 1.0);
        
        let res = mqnn.apply_hsec(&state);
        if fidelity < 0.99 {
            kani::assert(res.is_err(), "HSEC should detect decoherence below threshold");
        } else {
            kani::assert(res.is_ok(), "HSEC should pass above threshold");
        }
    }
}
