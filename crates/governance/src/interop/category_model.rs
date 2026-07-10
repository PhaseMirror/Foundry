use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};

/// S-01: Governance Category Model — category-theoretic framework for cross-stack interop.

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[repr(u8)]
pub enum StatusLevel {
    /// OK < WARNING < VIOLATION < CRITICAL
    Ok = 0,
    Warning = 1,
    Violation = 2,
    Critical = 3,
}

impl Default for StatusLevel {
    fn default() -> Self {
        StatusLevel::Ok
    }
}

pub fn status_join(a: StatusLevel, b: StatusLevel) -> StatusLevel {
    if a > b { a } else { b }
}

pub fn dcgf_status_to_level(status: &str) -> StatusLevel {
    match status {
        "inactive" => StatusLevel::Ok,
        "watch" => StatusLevel::Warning,
        "active" => StatusLevel::Violation,
        "critical" => StatusLevel::Critical,
        _ => StatusLevel::Ok,
    }
}

pub fn level_to_dcgf_status(level: StatusLevel) -> &'static str {
    match level {
        StatusLevel::Ok => "inactive",
        StatusLevel::Warning => "watch",
        StatusLevel::Violation => "active",
        StatusLevel::Critical => "critical",
    }
}

pub const DCGF_CONSTRAINT_IDS: &[&str] = &[
    "C01", "C02", "C03", "C04", "C05",
    "C06", "C07", "C08", "C09", "C10", "C11",
];

pub fn get_dcgf_constraint_label(id: &str) -> Option<&'static str> {
    match id {
        "C01" => Some("Contested objective function"),
        "C02" => Some("Partial observability"),
        "C03" => Some("Delayed/confounded feedback"),
        "C04" => Some("Distribution shift"),
        "C05" => Some("Strategic behavior/adversaries"),
        "C06" => Some("Implementation capacity limits"),
        "C07" => Some("Goodhart pressure"),
        "C08" => Some("Tail-risk dominance"),
        "C09" => Some("Path dependence/irreversibility"),
        "C10" => Some("Legitimacy/procedural constraints"),
        "C11" => Some("Scalability/coordination thresholds"),
        _ => None,
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Obligation {
    pub obligation_id: String,
    pub label: String,
    pub framework: String,
    pub status: StatusLevel,
}

impl Obligation {
    pub fn new(obligation_id: &str, label: &str, framework: &str) -> Self {
        Self {
            obligation_id: obligation_id.to_string(),
            label: label.to_string(),
            framework: framework.to_string(),
            status: StatusLevel::Ok,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Morphism {
    pub source: String,
    pub target: String,
    pub label: String,
}

impl Morphism {
    pub fn new(source: &str, target: &str, label: &str) -> Self {
        Self {
            source: source.to_string(),
            target: target.to_string(),
            label: label.to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernanceCategory {
    pub name: String,
    pub framework: String,
    pub obligations: HashMap<String, Obligation>,
    pub morphisms: Vec<Morphism>,
}

impl GovernanceCategory {
    pub fn new(name: &str, framework: &str) -> Self {
        Self {
            name: name.to_string(),
            framework: framework.to_string(),
            obligations: HashMap::new(),
            morphisms: Vec::new(),
        }
    }

    pub fn add_obligation(&mut self, obligation: Obligation) {
        self.obligations.insert(obligation.obligation_id.clone(), obligation);
    }

    pub fn add_morphism(&mut self, morphism: Morphism) -> Result<(), String> {
        if !self.obligations.contains_key(&morphism.source) {
            return Err(format!("Source '{}' not in category", morphism.source));
        }
        if !self.obligations.contains_key(&morphism.target) {
            return Err(format!("Target '{}' not in category", morphism.target));
        }
        self.morphisms.push(morphism);
        Ok(())
    }

    fn all_pairs(&self) -> HashSet<(String, String)> {
        let mut pairs = HashSet::new();
        for oid in self.obligations.keys() {
            pairs.insert((oid.clone(), oid.clone()));
        }
        for m in &self.morphisms {
            pairs.insert((m.source.clone(), m.target.clone()));
        }
        pairs
    }

    fn transitive_closure(&self) -> HashSet<(String, String)> {
        let mut pairs = self.all_pairs();
        let mut changed = true;
        while changed {
            changed = false;
            let mut to_add = Vec::new();
            for (a, b) in &pairs {
                for (c, d) in &pairs {
                    if b == c {
                        if !pairs.contains(&(a.clone(), d.clone())) {
                            to_add.push((a.clone(), d.clone()));
                        }
                    }
                }
            }
            if !to_add.is_empty() {
                for pair in to_add {
                    pairs.insert(pair);
                }
                changed = true;
            }
        }
        pairs
    }

    pub fn is_valid_category(&self) -> bool {
        if self.obligations.is_empty() {
            return false;
        }
        for m in &self.morphisms {
            if !self.obligations.contains_key(&m.source) || !self.obligations.contains_key(&m.target) {
                return false;
            }
        }
        let closure = self.transitive_closure();
        let pairs = self.all_pairs();
        for (a, b) in &pairs {
            for (c, d) in &pairs {
                if b == c {
                    if !closure.contains(&(a.clone(), d.clone())) {
                        return false;
                    }
                }
            }
        }
        true
    }

    pub fn obligation_ids(&self) -> HashSet<String> {
        self.obligations.keys().cloned().collect()
    }
}

pub fn build_dcgf_category() -> GovernanceCategory {
    let mut cat = GovernanceCategory::new("DCGF", "dcgf");
    for &cid in DCGF_CONSTRAINT_IDS {
        cat.add_obligation(Obligation::new(
            cid,
            get_dcgf_constraint_label(cid).unwrap_or(""),
            "dcgf",
        ));
    }
    cat
}

pub fn build_eu_ai_act_category() -> GovernanceCategory {
    let mut cat = GovernanceCategory::new("EU AI Act", "eu_ai_act");
    let articles = [
        ("art5", "Art. 5 — Prohibited AI practices"),
        ("art9_2a", "Art. 9(2)(a) — Risk identification"),
        ("art9_2b", "Art. 9(2)(b) — Foreseeable misuse"),
        ("art9_2c", "Art. 9(2)(c) — Emerging risks"),
        ("art9_2d", "Art. 9(2)(d) — Risk measures"),
        ("art9_5", "Art. 9(5) — Residual risk"),
        ("art9_6", "Art. 9(6) — Testing"),
        ("art9_7", "Art. 9(7) — Testing for purpose"),
        ("art10", "Art. 10 — Data governance"),
        ("art11", "Art. 11 — Technical documentation"),
        ("art13", "Art. 13 — Transparency"),
        ("art14", "Art. 14 — Human oversight"),
        ("art15", "Art. 15 — Robustness"),
        ("art72", "Art. 72 — Post-market monitoring"),
    ];
    for (oid, label) in articles {
        cat.add_obligation(Obligation::new(oid, label, "eu_ai_act"));
    }
    let _ = cat.add_morphism(Morphism::new("art9_2a", "art9_5", "risk subset"));
    let _ = cat.add_morphism(Morphism::new("art9_2b", "art9_5", "risk subset"));
    let _ = cat.add_morphism(Morphism::new("art9_2c", "art9_5", "risk subset"));
    let _ = cat.add_morphism(Morphism::new("art9_2d", "art9_5", "risk subset"));
    cat
}

pub fn build_nist_rmf_category() -> GovernanceCategory {
    let mut cat = GovernanceCategory::new("NIST AI RMF", "nist_rmf");
    let subcategories = [
        ("govern_1_1", "GOVERN 1.1 — Policies and procedures"),
        ("govern_2_2", "GOVERN 2.2 — Mechanisms for feedback"),
        ("govern_4_1", "GOVERN 4.1 — Teams"),
        ("govern_5_1", "GOVERN 5.1 — Organizational risk"),
        ("govern_6_1", "GOVERN 6.1 — Acquisition policies"),
        ("govern_6_2", "GOVERN 6.2 — Deployment"),
        ("map_1_6", "MAP 1.6 — Stakeholder engagement"),
        ("map_2_2", "MAP 2.2 — Scientific/technical framing"),
        ("map_2_3", "MAP 2.3 — AI capabilities/limitations"),
        ("map_5_1", "MAP 5.1 — Organizational risk priorities"),
        ("map_5_2", "MAP 5.2 — Scientific/engineering basis"),
        ("measure_2_5", "MEASURE 2.5 — Entity evaluations"),
        ("measure_2_6", "MEASURE 2.6 — System impact"),
        ("manage_3_2", "MANAGE 3.2 — Treatment mechanisms"),
    ];
    for (oid, label) in subcategories {
        cat.add_obligation(Obligation::new(oid, label, "nist_rmf"));
    }
    cat
}

pub fn build_iso_42001_category() -> GovernanceCategory {
    let mut cat = GovernanceCategory::new("ISO 42001", "iso_42001");
    let clauses = [
        ("iso_7_2", "7.2 — Purpose and scope"),
        ("iso_7_3", "7.3 — Governance structure"),
        ("iso_7_4", "7.4 — Resource allocation"),
        ("iso_7_5", "7.5 — Change control"),
        ("iso_8_1", "8.1 — Measurement systems"),
        ("iso_8_2", "8.2 — Evaluation framework"),
        ("iso_8_3", "8.3 — Data management"),
        ("iso_8_4", "8.4 — Threat modeling"),
        ("iso_8_5", "8.5 — Metric governance"),
        ("iso_8_6", "8.6 — Scenario analysis"),
        ("iso_8_7", "8.7 — Federated systems"),
    ];
    for (oid, label) in clauses {
        cat.add_obligation(Obligation::new(oid, label, "iso_42001"));
    }
    cat
}
