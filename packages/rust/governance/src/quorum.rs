use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::{HashMap, HashSet};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CouncilMember {
    pub id: String,
    pub roles: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VotingRules {
    pub standard: StandardRules,
    pub critical: StandardRules,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StandardRules {
    pub threshold: usize,
    #[serde(default)]
    pub required_roles: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CouncilRegistry {
    pub members: Vec<CouncilMember>,
    pub voting_rules: VotingRules,
}

pub const L0_ADRS: &[&str] = &["ADR-AGI-001", "ADR-AGI-002", "ADR-AGI-003", "ADR-AGI-004"];

pub fn validate_quorum(
    ledger: &HashMap<String, Value>,
    council: &CouncilRegistry,
) -> (bool, Vec<String>) {
    let mut member_roles = HashMap::new();
    for m in &council.members {
        member_roles.insert(m.id.clone(), m.roles.clone());
    }

    let required_threshold = council.voting_rules.standard.threshold;
    let mut signed_adrs: HashMap<String, HashSet<String>> = HashMap::new();

    for entry in ledger.values() {
        let notes = entry.get("governance_notes").and_then(|v| v.as_str()).unwrap_or("");
        let signers = entry.get("signers").and_then(|v| v.as_array())
            .map(|a| a.iter().filter_map(|s| s.as_str().map(|ss| ss.to_string())).collect::<Vec<_>>())
            .unwrap_or_default();
        
        let immutable_files = entry.get("immutable_files").and_then(|v| v.as_array());

        for &adr in L0_ADRS {
            let mut match_found = notes.contains(adr);
            if !match_found && immutable_files.is_some() {
                for file in immutable_files.unwrap() {
                    if let Some(path) = file.get("path").and_then(|v| v.as_str()) {
                        if path.contains(adr) {
                            match_found = true;
                            break;
                        }
                    }
                }
            }

            if match_found {
                let set = signed_adrs.entry(adr.to_string()).or_default();
                for s in signers.iter() {
                    set.insert(s.clone());
                }
            }
        }
    }

    let mut all_passed = true;
    let mut messages = Vec::new();

    for &adr in L0_ADRS {
        let signers = signed_adrs.get(adr);
        let signer_count = signers.map(|s| s.len()).unwrap_or(0);
        
        messages.push(format!("Checking {}:", adr));
        
        if signer_count < required_threshold {
            messages.push(format!("  ❌ FAILED: Quorum not met ({} < {})", signer_count, required_threshold));
            all_passed = false;
        } else {
            messages.push(format!("  ✅ Quorum met ({} >= {})", signer_count, required_threshold));
        }

        let has_safety = if let Some(s_set) = signers {
            s_set.iter().any(|s| member_roles.get(s).map(|r| r.contains(&"safety".to_string())).unwrap_or(false))
        } else {
            false
        };

        if !has_safety {
            messages.push("  ❌ FAILED: Missing mandatory Safety Lead signature".to_string());
            all_passed = false;
        } else {
            messages.push("  ✅ Safety Lead signature verified".to_string());
        }
    }

    (all_passed, messages)
}
