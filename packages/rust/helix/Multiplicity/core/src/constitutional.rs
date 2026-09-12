use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;

#[derive(Serialize, Deserialize, Debug)]
pub struct DriftFloor {
    pub delta_c: f64,
    pub classification: String,
    pub provenance_adr: String,
    pub precision_forms: HashMap<String, f64>,
    pub override_policy: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct ArticleII {
    pub drift_floor: DriftFloor,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Articles {
    #[serde(rename = "II")]
    pub ii: ArticleII,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Enforcement {
    pub on_breach: String,
    pub error_codes: HashMap<String, String>,
    pub audit_frequency_ms: Option<u64>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct ConstitutionalParameters {
    pub schema_version: String,
    pub constitution_ref: String,
    pub ratified: String,
    pub supersedes: Option<String>,
    pub articles: Articles,
    pub enforcement: Enforcement,
}

pub struct ConstitutionalRuntime {
    pub parameters: ConstitutionalParameters,
}

impl ConstitutionalRuntime {
    pub fn load<P: AsRef<Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let data = fs::read_to_string(path)?;
        let parameters: ConstitutionalParameters = serde_json::from_str(&data)?;
        Ok(Self { parameters })
    }
}
