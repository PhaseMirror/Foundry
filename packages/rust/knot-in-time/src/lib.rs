pub mod federation;
pub mod gicd;
pub mod models;
pub mod sovereign_engine;
pub mod xi_system;
use ndarray::{Array2, array};
use num_complex::Complex64;

pub mod authority {
    use std::collections::HashSet;

    #[derive(Debug, PartialEq, Eq)]
    pub enum AuthorityLevel {
        Custodian,
        Policy,
        Advisory,
    }

    pub struct JurisdictionalGuard;

    impl JurisdictionalGuard {
        pub fn verify(authority: &str) -> bool {
            let mut mapping = HashSet::new();
            mapping.extend([
                "CUSTODIAN_CA_FED", "POLICY_CA_FED", "CUSTODIAN_CA_DEFENCE",
                "POLICY_CA_DEFENCE", "CUSTODIAN_CA_PRIVACY", "POLICY_CA_PRIVACY",
                "CUSTODIAN_QC", "POLICY_QC", "CUSTODIAN_INDIGENOUS", "CUSTODIAN_ITAR",
                "CUSTODIAN", "POLICY", "ADVISORY", "FEDERAL_AUDITOR", "SYSADMIN"
            ]);
            mapping.contains(authority)
        }
    }

    pub fn classify_authority(authority: &str) -> AuthorityLevel {
        if authority.starts_with("CUSTODIAN") || authority == "FEDERAL_AUDITOR" || authority == "SYSADMIN" {
            AuthorityLevel::Custodian
        } else if authority.starts_with("POLICY") {
            AuthorityLevel::Policy
        } else {
            AuthorityLevel::Advisory
        }
    }

    pub fn ratify_velocity(model_recommended_velocity: &str, authority: &str, jurisdiction: Option<&str>) -> String {
        let level = classify_authority(authority);

        if jurisdiction == Some("CA-QC") && authority.starts_with("CUSTODIAN") {
            return model_recommended_velocity.to_string();
        }

        match level {
            AuthorityLevel::Custodian => model_recommended_velocity.to_string(),
            AuthorityLevel::Policy => {
                if model_recommended_velocity == "STOP" {
                    "PAUSE".to_string()
                } else {
                    model_recommended_velocity.to_string()
                }
            }
            AuthorityLevel::Advisory => "PAUSE".to_string(),
        }
    }
}

pub struct KnotHamiltonian {
    pub knot_type: String,
    pub omega_z: f64,
    pub omega_fold: f64,
    pub lambda_topo: f64,
    pub gamma: f64,
}

impl KnotHamiltonian {
    pub fn new(knot_type: String) -> Self {
        Self {
            knot_type,
            omega_z: 1.0,
            omega_fold: 0.5,
            lambda_topo: 0.3,
            gamma: 0.1,
        }
    }

    fn get_knot_invariant(&self) -> f64 {
        match self.knot_type.as_str() {
            "0_1" => 1.0,
            "3_1" => 1.4142,
            "4_1" => 2.6180,
            "5_1" => 1.9890,
            "7_1" => 2.2469,
            "9_1" => 2.4940,
            "hopf" => 1.9021,
            _ => 1.0,
        }
    }

    pub fn get_coherence_protection(&self) -> f64 {
        self.get_knot_invariant()
    }

    pub fn get_decoherence_suppression(&self) -> f64 {
        let j_k = self.get_knot_invariant();
        if j_k != 0.0 { 1.0 / j_k } else { 0.0 }
    }

    pub fn get_h_free(&self) -> Array2<Complex64> {
        Complex64::new(self.omega_z / 2.0, 0.0) * array![[Complex64::new(1.0, 0.0), Complex64::new(0.0, 0.0)],
                                                        [Complex64::new(0.0, 0.0), Complex64::new(-1.0, 0.0)]]
    }

    pub fn get_h_fold(&self) -> Array2<Complex64> {
        let sx = array![[Complex64::new(0.0, 0.0), Complex64::new(1.0, 0.0)],
                        [Complex64::new(1.0, 0.0), Complex64::new(0.0, 0.0)]];
        let sy = array![[Complex64::new(0.0, 0.0), Complex64::new(0.0, -1.0)],
                        [Complex64::new(0.0, 1.0), Complex64::new(0.0, 0.0)]];
        Complex64::new(self.omega_fold, 0.0) * (sx + Complex64::new(0.0, 1.0) * self.gamma * sy)
    }

    pub fn get_h_topo(&self) -> Array2<Complex64> {
        Complex64::new(self.lambda_topo * self.get_knot_invariant(), 0.0) * array![[Complex64::new(1.0, 0.0), Complex64::new(0.0, 0.0)],
                                                                                  [Complex64::new(0.0, 0.0), Complex64::new(-1.0, 0.0)]]
    }

    pub fn construct(&self) -> Array2<Complex64> {
        self.get_h_free() + self.get_h_fold() + self.get_h_topo()
    }

    pub fn get_effective_resistance(&self, t: f64, tau: f64) -> f64 {
        let epsilon = 0.1;
        let wobble = epsilon * (2.0 * std::f64::consts::PI * t / tau).sin();
        1.0 + wobble
    }
}

pub struct InvariantRegistry;

impl InvariantRegistry {
    pub fn audit_drift(authority: &str, form: &str, current_drift: f64) -> Result<f64, String> {
        let multiplier = match authority {
            "CUSTODIAN_CA_FED" => 1.0,
            "CUSTODIAN_CA_DEFENCE" => 1.2,
            "CUSTODIAN_ITAR" => 1.5,
            "POLICY_QC" => 1.1,
            _ => 1.0,
        };

        let drift_threshold_max = 0.17;
        let effective_threshold = drift_threshold_max / multiplier;

        if form == "FACT" && current_drift > (effective_threshold * 0.5) {
            return Err("FACT_PRECISION_VIOLATION".to_string());
        }

        if current_drift > effective_threshold {
            return Err("TOPOLOGICAL_DRIFT_EXCEEDED".to_string());
        }

        Ok(effective_threshold - current_drift)
    }
}
