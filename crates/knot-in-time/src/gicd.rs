use std::collections::HashMap;

pub struct GicdScanner;

impl GicdScanner {
    pub fn verify_authority(substrate: &HashMap<String, String>) -> Result<(), String> {
        if !substrate.contains_key("authority") || substrate.get("authority").unwrap().is_empty() {
            return Err("Missing authority mapping".to_string());
        }
        Ok(())
    }

    pub fn verify_jurisdiction(substrate: &HashMap<String, String>) -> Result<(), String> {
        let valid_regions = ["ca-central-1", "canadaeast"];
        let region = substrate.get("cloud_region").map(|s| s.as_str()).unwrap_or("");
        if !valid_regions.contains(&region) {
            return Err("Jurisdictional sovereignty violation".to_string());
        }
        Ok(())
    }

    pub fn run_gicd_scan(substrate: &HashMap<String, String>) -> Vec<(String, Result<(), String>)> {
        vec![
            ("Authority Ambiguity".to_string(), Self::verify_authority(substrate)),
            ("Jurisdiction Compliance".to_string(), Self::verify_jurisdiction(substrate)),
        ]
    }
}
