//! pirtm-telemetry: Edge sensor ingestion and Genius v2 R(t) resonance functional
//! for Citizen Gardens physical hardware nodes.

use num_rational::Ratio;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

/// Maximum admissible state drift per observation interval (Delta_max = 1 - lambda = 0.03)
pub const MAX_ADMISSIBLE_DRIFT: Ratio<i64> = Ratio::new_raw(3, 100);

/// Telemetry reading from local Citizen Gardens edge sensors, stored in exact Rational64
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct GardenTelemetry {
    /// Soil moisture ratio in [0, 1]
    pub soil_moisture: (i64, i64),
    /// Normalized ambient temperature ratio in [0, 1]
    pub ambient_temp_norm: (i64, i64),
    /// Solar irradiance ratio in [0, 1]
    pub solar_norm: (i64, i64),
    /// Civic participation pulse ratio in [0, 1]
    pub civic_pulse: (i64, i64),
}

impl GardenTelemetry {
    pub fn new(moisture: (i64, i64), temp: (i64, i64), solar: (i64, i64), civic: (i64, i64)) -> Self {
        Self {
            soil_moisture: moisture,
            ambient_temp_norm: temp,
            solar_norm: solar,
            civic_pulse: civic,
        }
    }
}

/// Sealed CRMF event envelope containing verified R(t) metrics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SealedResonanceReceipt {
    pub timestamp: String,
    pub r_t_ratio: (i64, i64),
    pub drift_ratio: (i64, i64),
    pub is_contractive: bool,
    pub seal_hash: String,
    pub poseidon_commitment: String,
}

/// Genius v2 Practice Model for Citizen Gardens Local Nodes
pub struct GeniusV2PracticeModel {
    last_r_t: Option<Ratio<i64>>,
    weights: [Ratio<i64>; 4],
}

impl Default for GeniusV2PracticeModel {
    fn default() -> Self {
        Self::new()
    }
}

impl GeniusV2PracticeModel {
    pub fn new() -> Self {
        // Equal weighting: 1/4 each (exact rational sum = 1)
        let quarter = Ratio::new(1, 4);
        Self {
            last_r_t: None,
            weights: [quarter, quarter, quarter, quarter],
        }
    }

    /// Compute the localized resonance functional R(t) using exact rational arithmetic
    pub fn compute_resonance(&self, telemetry: &GardenTelemetry) -> Ratio<i64> {
        let m = Ratio::new(telemetry.soil_moisture.0, telemetry.soil_moisture.1);
        let t = Ratio::new(telemetry.ambient_temp_norm.0, telemetry.ambient_temp_norm.1);
        let s = Ratio::new(telemetry.solar_norm.0, telemetry.solar_norm.1);
        let c = Ratio::new(telemetry.civic_pulse.0, telemetry.civic_pulse.1);

        self.weights[0] * m + self.weights[1] * t + self.weights[2] * s + self.weights[3] * c
    }

    /// Ingest telemetry, evaluate contractivity drift, and produce a sealed CRMF receipt
    pub fn ingest_telemetry(&mut self, telemetry: &GardenTelemetry) -> Result<SealedResonanceReceipt, String> {
        let r_t = self.compute_resonance(telemetry);

        let drift = if let Some(last) = self.last_r_t {
            if r_t >= last { r_t - last } else { last - r_t }
        } else {
            Ratio::new(0, 1)
        };

        let is_contractive = drift <= MAX_ADMISSIBLE_DRIFT;
        if !is_contractive {
            return Err(format!(
                "SIG_GOV_KILL: Drift violation in R(t): drift {}/{} > MAX {}/{}",
                drift.numer(), drift.denom(),
                MAX_ADMISSIBLE_DRIFT.numer(), MAX_ADMISSIBLE_DRIFT.denom()
            ));
        }

        self.last_r_t = Some(r_t);

        let timestamp = chrono::Utc::now().to_rfc3339();
        let payload = format!("{}:{}/{}:{}/{}", timestamp, r_t.numer(), r_t.denom(), drift.numer(), drift.denom());
        
        let mut hasher = Sha256::new();
        hasher.update(payload.as_bytes());
        let seal_hash = hex::encode(hasher.finalize());
        let poseidon_commitment = format!("pos2_{}", &seal_hash[..32]);

        Ok(SealedResonanceReceipt {
            timestamp,
            r_t_ratio: (*r_t.numer(), *r_t.denom()),
            drift_ratio: (*drift.numer(), *drift.denom()),
            is_contractive,
            seal_hash,
            poseidon_commitment,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rational_resonance_calculation() {
        let model = GeniusV2PracticeModel::new();
        let telemetry = GardenTelemetry::new(
            (60, 100), // 0.60
            (80, 100), // 0.80
            (70, 100), // 0.70
            (90, 100), // 0.90
        );

        let r_t = model.compute_resonance(&telemetry);
        // (0.6 + 0.8 + 0.7 + 0.9) / 4 = 3.0 / 4 = 0.75 = 75/100 = 3/4
        assert_eq!(r_t, Ratio::new(3, 4));
    }

    #[test]
    fn test_telemetry_drift_contractivity_pass() {
        let mut model = GeniusV2PracticeModel::new();
        let t1 = GardenTelemetry::new((50, 100), (50, 100), (50, 100), (50, 100));
        let res1 = model.ingest_telemetry(&t1);
        assert!(res1.is_ok());

        // Slight adjustment: drift = 0.01 <= 0.03 (PASS)
        let t2 = GardenTelemetry::new((54, 100), (50, 100), (50, 100), (50, 100));
        let res2 = model.ingest_telemetry(&t2);
        assert!(res2.is_ok());
        let receipt = res2.unwrap();
        assert!(receipt.is_contractive);
        assert_eq!(receipt.drift_ratio, (1, 100)); // 0.01
    }

    #[test]
    fn test_telemetry_drift_tripwire_rejects() {
        let mut model = GeniusV2PracticeModel::new();
        let t1 = GardenTelemetry::new((20, 100), (20, 100), (20, 100), (20, 100));
        let _ = model.ingest_telemetry(&t1);

        // Huge jump: from 0.20 to 0.80 -> drift = 0.60 > 0.03 (REJECT)
        let t2 = GardenTelemetry::new((80, 100), (80, 100), (80, 100), (80, 100));
        let res2 = model.ingest_telemetry(&t2);
        assert!(res2.is_err());
        assert!(res2.unwrap_err().contains("SIG_GOV_KILL"));
    }
}
