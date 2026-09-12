use serde::Deserialize;
use std::collections::HashMap;

#[derive(Debug, Deserialize, Clone)]
pub struct EnsembleManifest {
    pub ensemble: EnsembleMeta,
    pub governance: GovernanceMeta,
    pub dependencies: Option<HashMap<String, DependencyMeta>>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct EnsembleMeta {
    pub name: String,
    pub version: String,
    pub prime_index: u64,
    pub description: Option<String>,
    pub authors: Option<Vec<String>>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct GovernanceMeta {
    pub spectral_radius: f64,
    pub epsilon: Option<f64>,
    pub contractivity_receipt: String,
    pub ledger_anchor: Option<String>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct DependencyMeta {
    pub version: String,
    pub spectral_max: f64,
    pub prime_index: Option<u64>,
}

impl EnsembleManifest {
    pub fn parse(content: &str) -> Result<Self, String> {
        toml::from_str(content).map_err(|e| format!("Failed to parse manifest: {}", e))
    }

    pub fn validate(&self, validator: &crate::AdmissibilityValidator) -> Result<(), String> {
        validator.validate_prime(self.ensemble.prime_index)?;
        if self.governance.spectral_radius >= 1.0 {
            return Err("Spectral radius must be < 1.0 for contractivity".to_string());
        }
        if let Some(deps) = &self.dependencies {
            let mut total_radius = self.governance.spectral_radius;
            for dep in deps.values() {
                total_radius += dep.spectral_max;
            }
            if total_radius >= 1.0 {
                return Err(format!(
                    "Total spectral radius {} exceeds contractivity bound 1.0",
                    total_radius
                ));
            }
        }
        Ok(())
    }
}
