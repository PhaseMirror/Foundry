//! `core/provenance.py` — append-only causal lineage tracking.

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ProvenanceRecord {
    pub state_id: String,
    pub parent_state_id: Option<String>,
    pub operator: String,
    pub timestamp: f64,
    pub parameters: Map<String, Value>,
    pub info_removed: Map<String, Value>,
    pub info_added: Map<String, Value>,
    pub checksum_before: String,
    pub checksum_after: String,
    pub reversible: bool,
    pub reversibility_notes: String,
}

impl ProvenanceRecord {
    pub fn new(
        state_id: impl Into<String>,
        parent_state_id: Option<String>,
        operator: impl Into<String>,
        parameters: Map<String, Value>,
        info_removed: Map<String, Value>,
        info_added: Map<String, Value>,
        checksum_before: impl Into<String>,
        checksum_after: impl Into<String>,
        reversible: bool,
        reversibility_notes: impl Into<String>,
    ) -> Self {
        Self {
            state_id: state_id.into(),
            parent_state_id,
            operator: operator.into(),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_secs_f64())
                .unwrap_or(0.0),
            parameters,
            info_removed,
            info_added,
            checksum_before: checksum_before.into(),
            checksum_after: checksum_after.into(),
            reversible,
            reversibility_notes: reversibility_notes.into(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ProvenanceLedger {
    pub records: Vec<ProvenanceRecord>,
}

impl ProvenanceLedger {
    pub fn new() -> Self {
        Self {
            records: Vec::new(),
        }
    }

    pub fn append(&mut self, record: ProvenanceRecord) {
        self.records.push(record);
    }

    /// Trace the causal chain from `state_id` back to the root, newest first.
    pub fn get_history(&self, state_id: &str) -> Vec<ProvenanceRecord> {
        let mut history = Vec::new();
        let mut current: Option<String> = Some(state_id.to_string());
        while let Some(cid) = current {
            let found = self.records.iter().find(|r| r.state_id == cid);
            match found {
                Some(record) => {
                    history.push(record.clone());
                    current = record.parent_state_id.clone();
                }
                None => break,
            }
        }
        history
    }

    /// Fraction of irreversible records (0.0 if no records).
    pub fn compute_irreversibility_score(&self) -> f64 {
        if self.records.is_empty() {
            return 0.0;
        }
        let irreversible = self.records.iter().filter(|r| !r.reversible).count();
        irreversible as f64 / self.records.len() as f64
    }

    pub fn to_dict_list(&self) -> Vec<Value> {
        self.records
            .iter()
            .map(|r| serde_json::to_value(r).expect("serialize"))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn record(id: &str, parent: Option<&str>, reversible: bool) -> ProvenanceRecord {
        ProvenanceRecord::new(
            id,
            parent.map(str::to_string),
            "Op",
            Map::new(),
            Map::new(),
            Map::new(),
            "b",
            "a",
            reversible,
            "",
        )
    }

    #[test]
    fn history_traces_backward_chain() {
        let mut ledger = ProvenanceLedger::new();
        ledger.append(record("s1", None, true));
        ledger.append(record("s2", Some("s1"), true));
        ledger.append(record("s3", Some("s2"), false));

        let history = ledger.get_history("s3");
        assert_eq!(history.len(), 3);
        assert_eq!(history[0].state_id, "s3");
        assert_eq!(history[1].state_id, "s2");
        assert_eq!(history[2].state_id, "s1");
    }

    #[test]
    fn irreversibility_score_is_fraction() {
        let mut ledger = ProvenanceLedger::new();
        assert_eq!(ledger.compute_irreversibility_score(), 0.0);
        ledger.append(record("s1", None, true));
        ledger.append(record("s2", Some("s1"), false));
        assert!((ledger.compute_irreversibility_score() - 0.5).abs() < 1e-12);
    }
}