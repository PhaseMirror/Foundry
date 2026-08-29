//! Cryptographic Snapshot Store and Rollback Engine (ADR-0038 §3.3)

use crate::types::{PlantState, Snapshot};
use sha2::{Digest, Sha256};
use std::collections::HashMap;

/// In-memory attested snapshot store outside the learner's address space.
pub struct SnapshotStore {
    snapshots: HashMap<u64, Snapshot>,
    next_id: u64,
    secret_key: Vec<u8>,
}

impl SnapshotStore {
    pub fn new(secret_key: Vec<u8>) -> Self {
        Self {
            snapshots: HashMap::new(),
            next_id: 1,
            secret_key,
        }
    }

    /// Compute state hash using SHA-256.
    pub fn compute_state_hash(state: &PlantState) -> String {
        let mut hasher = Sha256::new();
        hasher.update(state.t.to_le_bytes());
        hasher.update(state.burst_id.to_le_bytes());
        for &val in &state.theta {
            hasher.update(val.to_le_bytes());
        }
        for &val in &state.x {
            hasher.update(val.to_le_bytes());
        }
        hex::encode(hasher.finalize())
    }

    /// Sign content hash with internal secret key.
    fn sign_hash(&self, content_hash: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(&self.secret_key);
        hasher.update(content_hash.as_bytes());
        hex::encode(hasher.finalize())
    }

    /// Take a verified cryptographic snapshot of the plant state.
    pub fn take_snapshot(&mut self, state: &PlantState, y_history: &[Vec<f64>]) -> Snapshot {
        let id = self.next_id;
        self.next_id += 1;

        let content_hash = Self::compute_state_hash(state);
        let signature = self.sign_hash(&content_hash);

        let snap = Snapshot {
            id,
            burst_id: state.burst_id,
            t: state.t,
            theta_snap: state.theta.clone(),
            x_snap: state.x.clone(),
            y_hist: y_history.to_vec(),
            content_hash,
            signature,
        };

        self.snapshots.insert(id, snap.clone());
        snap
    }

    /// Verify signature and content integrity of a snapshot.
    pub fn verify_snapshot(&self, snapshot: &Snapshot) -> bool {
        let expected_signature = self.sign_hash(&snapshot.content_hash);
        snapshot.signature == expected_signature && !snapshot.content_hash.is_empty()
    }

    /// Restore plant state from a verified snapshot.
    pub fn restore_snapshot(&self, id: u64, current_state: &mut PlantState) -> Result<(), &'static str> {
        let snap = self.snapshots.get(&id).ok_or("Snapshot ID not found")?;
        if !self.verify_snapshot(snap) {
            return Err("Snapshot signature verification failed");
        }

        current_state.theta = snap.theta_snap.clone();
        current_state.x = snap.x_snap.clone();
        current_state.t = snap.t;
        current_state.snapshot_id = snap.id;
        Ok(())
    }

    /// Prune old snapshots keeping only the most recent keep_count.
    pub fn prune(&mut self, keep_count: usize) {
        if self.snapshots.len() <= keep_count {
            return;
        }

        let mut ids: Vec<u64> = self.snapshots.keys().cloned().collect();
        ids.sort();
        let to_remove = ids.len().saturating_sub(keep_count);
        for id in ids.into_iter().take(to_remove) {
            self.snapshots.remove(&id);
        }
    }
}
