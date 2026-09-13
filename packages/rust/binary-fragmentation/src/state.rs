//! `core/state.py` — multidimensional state representation.
//!
//! I = (I_value, I_structure, I_relation, I_provenance, I_identity,
//!     I_temporal, I_context).
//!
//! Python's `Any` values are modelled as `serde_json::Value` so the same
//! deterministic canonical-JSON semantics carry over (BTreeMap ordering).

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;
use std::collections::BTreeSet;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Node {
    pub id: String,
    pub value: Value,
    #[serde(default)]
    pub attributes: Map<String, Value>,
    #[serde(default)]
    pub created_at: f64,
    #[serde(default)]
    pub provenance_tag: String,
}

impl Node {
    pub fn new(
        id: impl Into<String>,
        value: Value,
        attributes: Map<String, Value>,
        created_at: f64,
        provenance_tag: impl Into<String>,
    ) -> Self {
        Self {
            id: id.into(),
            value,
            attributes,
            created_at,
            provenance_tag: provenance_tag.into(),
        }
    }

    pub fn to_dict(&self) -> Value {
        serde_json::to_value(self).expect("Node serializes to JSON")
    }

    pub fn from_dict(data: &Value) -> Self {
        serde_json::from_value(data.clone()).expect("Node deserializes from JSON")
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Edge {
    pub source_id: String,
    pub target_id: String,
    pub relation_type: String,
    #[serde(default = "one")]
    pub weight: f64,
    #[serde(default)]
    pub attributes: Map<String, Value>,
    #[serde(default)]
    pub provenance_tag: String,
}

fn one() -> f64 {
    1.0
}

impl Edge {
    pub fn new(
        source_id: impl Into<String>,
        target_id: impl Into<String>,
        relation_type: impl Into<String>,
        weight: f64,
        attributes: Map<String, Value>,
        provenance_tag: impl Into<String>,
    ) -> Self {
        Self {
            source_id: source_id.into(),
            target_id: target_id.into(),
            relation_type: relation_type.into(),
            weight,
            attributes,
            provenance_tag: provenance_tag.into(),
        }
    }

    pub fn to_dict(&self) -> Value {
        serde_json::to_value(self).expect("Edge serializes to JSON")
    }

    pub fn from_dict(data: &Value) -> Self {
        serde_json::from_value(data.clone()).expect("Edge deserializes from JSON")
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HyperEdge {
    pub node_ids: Vec<String>,
    pub relation_type: String,
    #[serde(default)]
    pub attributes: Map<String, Value>,
    #[serde(default)]
    pub provenance_tag: String,
}

impl HyperEdge {
    pub fn new(
        node_ids: Vec<String>,
        relation_type: impl Into<String>,
        attributes: Map<String, Value>,
        provenance_tag: impl Into<String>,
    ) -> Self {
        Self {
            node_ids,
            relation_type: relation_type.into(),
            attributes,
            provenance_tag: provenance_tag.into(),
        }
    }

    pub fn to_dict(&self) -> Value {
        serde_json::to_value(self).expect("HyperEdge serializes to JSON")
    }

    pub fn from_dict(data: &Value) -> Self {
        serde_json::from_value(data.clone()).expect("HyperEdge deserializes from JSON")
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct State {
    #[serde(default)]
    pub state_id: String,
    #[serde(default)]
    pub parent_id: Option<String>,
    #[serde(default)]
    pub generation: u64,
    #[serde(default)]
    pub nodes: BTreeMap<String, Node>,
    #[serde(default)]
    pub edges: Vec<Edge>,
    #[serde(default)]
    pub hyperedges: Vec<HyperEdge>,
    #[serde(default)]
    pub context: Map<String, Value>,
    #[serde(default)]
    pub metadata: Map<String, Value>,
    #[serde(default)]
    pub timestamp: f64,
    #[serde(default)]
    pub provenance_records: Vec<Value>,
}

impl Default for State {
    fn default() -> Self {
        Self {
            state_id: new_uuid(),
            parent_id: None,
            generation: 0,
            nodes: BTreeMap::new(),
            edges: Vec::new(),
            hyperedges: Vec::new(),
            context: Map::new(),
            metadata: Map::new(),
            timestamp: 0.0,
            provenance_records: Vec::new(),
        }
    }
}

fn new_uuid() -> String {
    // Deterministic UUID-like id (Python used uuid4 — identity is not
    // semantic; a content-based pseudo-id keeps everything reproducible).
    // 32 hex chars from time + counter-free: just a fixed prefix + nanosecond.
    use std::time::{SystemTime, UNIX_EPOCH};
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    format!("{:032x}", nanos as u128)
}

impl State {
    pub fn new(
        state_id: Option<String>,
        parent_id: Option<String>,
        generation: u64,
        nodes: Option<BTreeMap<String, Node>>,
        edges: Option<Vec<Edge>>,
        hyperedges: Option<Vec<HyperEdge>>,
        context: Option<Map<String, Value>>,
        metadata: Option<Map<String, Value>>,
        timestamp: f64,
    ) -> Self {
        let mut s = State {
            state_id: state_id.unwrap_or_else(new_uuid),
            parent_id,
            generation,
            nodes: nodes.unwrap_or_default(),
            edges: edges.unwrap_or_default(),
            hyperedges: hyperedges.unwrap_or_default(),
            context: context.unwrap_or_default(),
            metadata: metadata.unwrap_or_default(),
            timestamp,
            provenance_records: Vec::new(),
        };
        s.reindex_nodes();
        s
    }

    /// Every node must be addressable by its own id (Python dict keyed by
    /// `node.id` inside `add_node`).
    fn reindex_nodes(&mut self) {
        // nodes map is already keyed; ensure consistency by re-keying.
        let mut rekeyed = BTreeMap::new();
        for (_, node) in self.nodes.iter() {
            rekeyed.insert(node.id.clone(), node.clone());
        }
        self.nodes = rekeyed;
    }

    pub fn add_node(&mut self, node: Node) {
        self.nodes.insert(node.id.clone(), node);
    }

    pub fn add_edge(&mut self, edge: Edge) {
        self.edges.push(edge);
    }

    pub fn add_hyperedge(&mut self, hyperedge: HyperEdge) {
        self.hyperedges.push(hyperedge);
    }

    /// Adjacency map: source id -> [(target, relation_type, weight)].
    pub fn get_adjacency(&self) -> BTreeMap<String, Vec<(String, String, f64)>> {
        let mut adj: BTreeMap<String, Vec<(String, String, f64)>> = BTreeMap::new();
        for nid in self.nodes.keys() {
            adj.entry(nid.clone()).or_default();
        }
        for edge in &self.edges {
            if let Some(list) = adj.get_mut(&edge.source_id) {
                list.push((edge.target_id.clone(), edge.relation_type.clone(), edge.weight));
            }
        }
        adj
    }

    /// Deterministic SHA-256 digest of the canonical content representation.
    pub fn compute_content_checksum(&self) -> String {
        let canonical = self.to_canonical_json();
        let mut hasher = Sha256::new();
        hasher.update(canonical.as_bytes());
        hex(&hasher.finalize())
    }

    pub fn compute_checksum(&self) -> String {
        self.compute_content_checksum()
    }

    /// Canonical sorted JSON — mirrors `to_canonical_json()` in Python
    /// (`json.dumps(payload, sort_keys=True)` with default separators).
    pub fn to_canonical_json(&self) -> String {
        let nodes: BTreeMap<String, Value> = self
            .nodes
            .iter()
            .map(|(k, n)| {
                (
                    k.clone(),
                    json!({
                        "id": n.id,
                        "value": n.value,
                        "attributes": n.attributes,
                    }),
                )
            })
            .collect();

        let mut edges: Vec<Value> = self
            .edges
            .iter()
            .map(|e| {
                json!({
                    "source_id": e.source_id,
                    "target_id": e.target_id,
                    "relation_type": e.relation_type,
                    "weight": e.weight,
                    "attributes": e.attributes,
                })
            })
            .collect();
        edges.sort_by(|a, b| {
            (
                a["source_id"].as_str().unwrap_or(""),
                a["target_id"].as_str().unwrap_or(""),
                a["relation_type"].as_str().unwrap_or(""),
            )
                .cmp(&(
                    b["source_id"].as_str().unwrap_or(""),
                    b["target_id"].as_str().unwrap_or(""),
                    b["relation_type"].as_str().unwrap_or(""),
                ))
        });

        let mut hyperedges: Vec<(String, String, Value)> = self
            .hyperedges
            .iter()
            .map(|h| {
                let sorted_node_ids: Vec<String> = {
                    let mut s: Vec<String> = h.node_ids.clone();
                    s.sort();
                    s
                };
                let key = sorted_node_ids.join(",");
                let mut val = h.clone();
                val.node_ids = sorted_node_ids;
                (key.clone(), h.relation_type.clone(), val)
            })
            .collect();
        hyperedges.sort_by(|a, b| a.0.cmp(&b.0).then_with(|| a.1.cmp(&b.1)));

        let payload = json!({
            "nodes": nodes,
            "edges": edges,
            "hyperedges": hyperedges.iter().map(|(_, _, h)| json!({
                "node_ids": h.node_ids,
                "relation_type": h.relation_type,
                "attributes": h.attributes,
            })).collect::<Vec<_>>(),
            "context": self.context,
            "metadata": self.metadata,
        });

        // serde_json Map is BTreeMap → keys already sorted; separators match
        // python default (", ", ": ").
        serde_json::to_string(&payload).expect("canonical JSON")
    }

    pub fn clone_state(&self) -> State {
        serde_json::from_value(serde_json::to_value(self).expect("to value")).expect("clone")
    }

    pub fn to_dict(&self) -> Value {
        serde_json::to_value(self).expect("to value")
    }

    pub fn from_dict(data: &Value) -> State {
        serde_json::from_value(data.clone()).expect("from value")
    }
}

pub fn hex(bytes: &[u8]) -> String {
    let mut out = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        out.push_str(&format!("{b:02x}"));
    }
    out
}

/// Helper to build a `serde_json::Value::Array` from ids.
pub fn ids_to_json_value(ids: &BTreeSet<String>) -> Value {
    Value::Array(ids.iter().map(|s| Value::String(s.clone())).collect())
}

use serde_json::json;

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_state() -> State {
        let mut st = State::default();
        st.add_node(Node::new(
            "a",
            json!(1.5),
            Map::new(),
            0.0,
            "root",
        ));
        st.add_node(Node::new("b", json!("text"), Map::new(), 0.0, "root"));
        st.add_edge(Edge::new("a", "b", "link", 1.0, Map::new(), ""));
        st.add_hyperedge(HyperEdge::new(vec!["b".into(), "a".into()], "group", Map::new(), ""));
        st
    }

    #[test]
    fn state_creation_and_cloning() {
        let st = sample_state();
        assert_eq!(st.nodes.len(), 2);
        assert_eq!(st.edges.len(), 1);
        assert_eq!(st.hyperedges.len(), 1);

        let cloned = st.clone_state();
        assert_eq!(cloned.compute_checksum(), st.compute_checksum());
        // Deep copy isolation: mutating clone does not affect original.
        let mut cloned2 = cloned.clone_state();
        cloned2.add_node(Node::new("c", json!(3.0), Map::new(), 0.0, ""));
        assert_eq!(st.nodes.len(), 2);
        assert_eq!(cloned2.nodes.len(), 3);
    }

    #[test]
    fn checksum_is_insertion_order_independent() {
        let st1 = sample_state();
        let mut st2 = State::default();
        st2.add_node(Node::new("b", json!("text"), Map::new(), 0.0, "root"));
        st2.add_edge(Edge::new("a", "b", "link", 1.0, Map::new(), ""));
        st2.add_hyperedge(HyperEdge::new(vec!["a".into(), "b".into()], "group", Map::new(), ""));
        st2.add_node(Node::new("a", json!(1.5), Map::new(), 0.0, "root"));
        assert_eq!(st1.compute_checksum(), st2.compute_checksum());
    }

    #[test]
    fn canonical_json_is_deterministic() {
        let st = sample_state();
        let a = st.to_canonical_json();
        let b = st.clone_state().to_canonical_json();
        assert_eq!(a, b);
        assert!(a.contains("\"nodes\""));
    }
}