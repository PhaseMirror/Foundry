use std::collections::HashMap;
use nalgebra::DVector;

#[derive(Debug, Clone)]
pub struct ViolationBroadcast {
    pub agent_id: String,
    pub sector_violations: Vec<u64>, // List of prime sectors with violations
}

pub struct SocialAxis {
    pub coupling_matrix: HashMap<(String, String), f64>, // w_ij
    pub lineage_floors: HashMap<String, f64>, // Lineage ID -> weight floor
    pub social_tolerance: HashMap<Vec<u64>, usize>, // Repertoires verified by k agents
    
    // ADR-008: Social Autoimmune Monitoring
    pub registry_centroid: DVector<f64>,
    pub epoch_baseline_centroid: DVector<f64>,
    pub consensus_suspended: bool,
    pub drift_epsilon: f64,
    pub total_patterns: f64,
}

impl SocialAxis {
    pub fn new(dim: usize) -> Self {
        Self {
            coupling_matrix: HashMap::new(),
            lineage_floors: HashMap::new(),
            social_tolerance: HashMap::new(),
            registry_centroid: DVector::zeros(dim),
            epoch_baseline_centroid: DVector::zeros(dim),
            consensus_suspended: false,
            drift_epsilon: 0.1, // Lipschiz-bounded social drift threshold
            total_patterns: 0.0,
        }
    }

    /// Mechanism 1: Cytokine Broadcast
    pub fn compute_social_shift(
        &self,
        local_violations: &[u64],
        neighbors: &[ViolationBroadcast],
        agent_id: &str,
    ) -> Vec<f64> {
        let mut social_tone: HashMap<u64, f64> = HashMap::new();
        for &p in local_violations {
            *social_tone.entry(p).or_insert(0.0) += 1.0;
        }
        for broadcast in neighbors {
            let weight = self.coupling_matrix.get(&(agent_id.to_string(), broadcast.agent_id.clone())).unwrap_or(&0.1);
            for &p in &broadcast.sector_violations {
                *social_tone.entry(p).or_insert(0.0) += weight;
            }
        }
        social_tone.values().cloned().collect()
    }

    /// Mechanism 2: Lineage Dominance (Clonal Expansion)
    pub fn clonal_expansion(&mut self, lineage_id: &str, success_count: usize) {
        if success_count >= 3 {
            let floor = self.lineage_floors.entry(lineage_id.to_string()).or_insert(0.05);
            *floor = (*floor + 0.01).min(0.2);
            println!("Clonal Expansion: Lineage {} floor increased to {:.2}", lineage_id, floor);
        }
    }

    /// Mechanism 3: Social Tolerance Registry (Consensus-Gated + ADR-008 Monitoring)
    pub fn certify_social_pattern(&mut self, residue_fingerprint: Vec<u64>, agent_id: &str) -> bool {
        if self.consensus_suspended {
            println!("Consensus Suspended (ADR-008): Manual review required for Agent {}", agent_id);
            return false;
        }

        // Update Centroid
        self.update_centroid(&residue_fingerprint);

        let entry = self.social_tolerance.entry(residue_fingerprint).or_insert(0);
        *entry += 1;
        
        // k-of-n consensus (k=3)
        if *entry >= 3 {
            println!("Social Tolerance Certified for fingerprint by Agent {}", agent_id);
            return true;
        }
        false
    }

    fn update_centroid(&mut self, fingerprint: &[u64]) {
        let dim = self.registry_centroid.len();
        let mut fp_vec = DVector::zeros(dim);
        for (i, &v) in fingerprint.iter().enumerate().take(dim) {
            fp_vec[i] = v as f64;
        }

        // Running average update
        self.total_patterns += 1.0;
        let n = self.total_patterns;
        self.registry_centroid = (&self.registry_centroid * (n - 1.0) + &fp_vec) / n;

        // Check for Drift from Epoch Baseline (ADR-008 Trigger)
        let total_drift = (&self.registry_centroid - &self.epoch_baseline_centroid).norm();
        if n > 1.0 && total_drift > self.drift_epsilon {
            println!("SOCIAL AUTOIMMUNE TRIGGER: Total Centroid drift {:.4} exceeds epsilon", total_drift);
            self.consensus_suspended = true;
        }
    }

    pub fn start_new_epoch(&mut self) {
        self.consensus_suspended = false;
        self.epoch_baseline_centroid = self.registry_centroid.clone();
    }
}
