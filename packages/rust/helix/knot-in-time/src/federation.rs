use std::collections::HashMap;

pub struct Peer {
    pub drift_score: f64,
    pub authority: String,
    pub recommended_velocity: String,
}

pub struct NodeSync {
    pub peers: HashMap<String, Peer>,
}

pub struct LatticeConsensus {
    pub node_sync: NodeSync,
    pub threshold: f64,
}

impl LatticeConsensus {
    pub fn new(node_sync: NodeSync) -> Self {
        Self {
            node_sync,
            threshold: 0.17,
        }
    }

    pub fn validate_global_drift(&self) -> bool {
        if self.node_sync.peers.is_empty() {
            return true;
        }

        let total_drift: f64 = self.node_sync.peers.values().map(|p| p.drift_score).sum();
        let average_drift = total_drift / self.node_sync.peers.len() as f64;

        average_drift <= self.threshold
    }

    pub fn resolve_velocity(&self, local_velocity: &str) -> String {
        for peer in self.node_sync.peers.values() {
            if peer.authority == "CUSTODIAN_CA_FED" || peer.authority == "POLICY_CA_FED" {
                if peer.recommended_velocity == "STOP" {
                    return "STOP".to_string();
                }
            }
        }
        local_velocity.to_string()
    }
}
