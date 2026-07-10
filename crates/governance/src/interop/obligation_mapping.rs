use crate::interop::category_model::{DCGF_CONSTRAINT_IDS, StatusLevel};
use std::collections::{HashMap, HashSet};

/// S-02: Obligation Mapping — monotone mapping registry (external → DCGF).

pub const EU_AI_ACT_RISK_TIERS: &[(&str, StatusLevel)] = &[
    ("minimal", StatusLevel::Ok),
    ("limited", StatusLevel::Warning),
    ("high", StatusLevel::Violation),
    ("unacceptable", StatusLevel::Critical),
];

pub const NIST_RISK_TIERS: &[(&str, StatusLevel)] = &[
    ("low", StatusLevel::Ok),
    ("moderate", StatusLevel::Warning),
    ("high", StatusLevel::Violation),
    ("critical", StatusLevel::Critical),
];

pub const ISO_RISK_TIERS: &[(&str, StatusLevel)] = &[
    ("informational", StatusLevel::Ok),
    ("advisory", StatusLevel::Warning),
    ("mandatory", StatusLevel::Violation),
    ("critical", StatusLevel::Critical),
];

pub fn get_framework_risk_tiers(framework: &str) -> Option<&'static [(&'static str, StatusLevel)]> {
    match framework {
        "eu_ai_act" => Some(EU_AI_ACT_RISK_TIERS),
        "nist_rmf" => Some(NIST_RISK_TIERS),
        "iso_42001" => Some(ISO_RISK_TIERS),
        _ => None,
    }
}

pub fn verify_monotone(tiers: &[(&str, StatusLevel)]) -> bool {
    for i in 1..tiers.len() {
        if tiers[i].1 < tiers[i - 1].1 {
            return false;
        }
    }
    true
}

pub fn map_external_status(framework: &str, tier: &str) -> Result<StatusLevel, String> {
    let tiers = get_framework_risk_tiers(framework).ok_or_else(|| format!("Unknown framework: {}", framework))?;
    for (name, level) in tiers {
        if *name == tier {
            return Ok(*level);
        }
    }
    Err(format!("Unknown risk tier '{}' for framework {}", tier, framework))
}

#[derive(Debug, Clone, PartialEq)]
pub struct ObligationMapping {
    pub external_id: String,
    pub framework: String,
    pub dcgf_constraint_id: String,
    pub confidence: f64,
    pub label: String,
}

impl ObligationMapping {
    pub fn new(external_id: &str, framework: &str, dcgf_constraint_id: &str, confidence: f64) -> Result<Self, String> {
        if !(0.0..=1.0).contains(&confidence) {
            return Err(format!("Confidence must be in [0, 1], got {}", confidence));
        }
        if !DCGF_CONSTRAINT_IDS.contains(&dcgf_constraint_id) {
            return Err(format!("Invalid DCGF constraint: {}", dcgf_constraint_id));
        }
        Ok(Self {
            external_id: external_id.to_string(),
            framework: framework.to_string(),
            dcgf_constraint_id: dcgf_constraint_id.to_string(),
            confidence,
            label: String::new(),
        })
    }
}

pub struct MappingRegistry {
    mappings: HashMap<(String, String), ObligationMapping>,
}

impl MappingRegistry {
    pub fn new() -> Self {
        Self {
            mappings: HashMap::new(),
        }
    }

    pub fn register(&mut self, mapping: ObligationMapping) {
        let key = (mapping.framework.clone(), mapping.external_id.clone());
        self.mappings.insert(key, mapping);
    }

    pub fn lookup(&self, framework: &str, external_id: &str) -> Option<&ObligationMapping> {
        self.mappings.get(&(framework.to_string(), external_id.to_string()))
    }

    pub fn lookup_by_dcgf(&self, dcgf_id: &str) -> Vec<&ObligationMapping> {
        self.mappings.values().filter(|m| m.dcgf_constraint_id == dcgf_id).collect()
    }

    pub fn frameworks(&self) -> HashSet<String> {
        self.mappings.values().map(|m| m.framework.clone()).collect()
    }

    pub fn all_mappings(&self) -> Vec<&ObligationMapping> {
        self.mappings.values().collect()
    }

    pub fn coverage(&self) -> HashMap<String, bool> {
        let covered: HashSet<String> = self.mappings.values().map(|m| m.dcgf_constraint_id.clone()).collect();
        let mut coverage = HashMap::new();
        for &cid in DCGF_CONSTRAINT_IDS {
            coverage.insert(cid.to_string(), covered.contains(cid));
        }
        coverage
    }

    pub fn verify_coverage(&self) -> (bool, Vec<String>) {
        let cov = self.coverage();
        let missing: Vec<String> = cov.iter().filter(|&(_, &ok)| !ok).map(|(cid, _)| cid.clone()).collect();
        (missing.is_empty(), missing)
    }

    pub fn verify_confidence(&self, min_conf: f64) -> (bool, Vec<&ObligationMapping>) {
        let below: Vec<&ObligationMapping> = self.mappings.values().filter(|m| m.confidence < min_conf).collect();
        (below.is_empty(), below)
    }

    pub fn count(&self) -> usize {
        self.mappings.len()
    }

    pub fn count_by_framework(&self) -> HashMap<String, usize> {
        let mut counts = HashMap::new();
        for m in self.mappings.values() {
            *counts.entry(m.framework.clone()).or_insert(0) += 1;
        }
        counts
    }
}

const CANONICAL_TABLE: &[(&str, &str, f64, &str, f64, &str, f64)] = &[
    ("C01", "art9_2a",  0.95, "govern_1_1",  0.90, "iso_7_2", 0.90),
    ("C02", "art9_2b",  0.80, "map_2_2",     0.85, "iso_8_1", 0.80),
    ("C03", "art9_2c",  0.65, "map_5_1",     0.70, "iso_8_2", 0.65),
    ("C04", "art10",    0.85, "map_2_3",     0.80, "iso_8_3", 0.80),
    ("C05", "art5",     0.95, "map_5_2",     0.90, "iso_8_4", 0.90),
    ("C06", "art9_6",   0.80, "govern_6_1",  0.75, "iso_7_4", 0.80),
    ("C07", "art9_7",   0.65, "measure_2_5", 0.70, "iso_8_5", 0.65),
    ("C08", "art9_5",   0.80, "measure_2_6", 0.85, "iso_8_6", 0.80),
    ("C09", "art9_2d",  0.90, "manage_3_2",  0.90, "iso_7_5", 0.95),
    ("C10", "art14",    0.95, "govern_4_1",  0.90, "iso_7_3", 0.95),
    ("C11", "art11",    0.80, "govern_6_2",  0.80, "iso_8_7", 0.85),
];

pub fn build_canonical_registry() -> MappingRegistry {
    let mut reg = MappingRegistry::new();
    for &(dcgf_id, eu_id, eu_c, nist_id, nist_c, iso_id, iso_c) in CANONICAL_TABLE {
        reg.register(ObligationMapping::new(eu_id, "eu_ai_act", dcgf_id, eu_c).unwrap());
        reg.register(ObligationMapping::new(nist_id, "nist_rmf", dcgf_id, nist_c).unwrap());
        reg.register(ObligationMapping::new(iso_id, "iso_42001", dcgf_id, iso_c).unwrap());
    }
    reg
}
