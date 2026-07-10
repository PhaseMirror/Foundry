use crate::audit::AuditChain;
use crate::qari::{QARIConfig, QARISession};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionDescriptor {
    pub session_id: String,
    pub config: QARIConfig,
    pub created_at: f64,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AggregatedCertificate {
    pub session_ids: Vec<String>,
    pub individual_certs: Vec<serde_json::Value>, // Using Value for simplicity in aggregation
    pub all_certified: bool,
    pub q_max_global: f64,
    pub margin_min: f64,
    pub aggregate_hash: String,
}

pub struct SessionOrchestrator<'a> {
    sessions: HashMap<String, QARISession<'a>>,
    descriptors: HashMap<String, SessionDescriptor>,
    master_audit: AuditChain,
}

impl<'a> SessionOrchestrator<'a> {
    pub fn new() -> Self {
        Self {
            sessions: HashMap::new(),
            descriptors: HashMap::new(),
            master_audit: AuditChain::new(),
        }
    }

    pub fn register(&mut self, session_id: &str, config: QARIConfig) -> Result<&mut QARISession<'a>, String> {
        if self.sessions.contains_key(session_id) {
            return Err(format!("Session '{}' already registered", session_id));
        }

        let session = QARISession::new(config.clone(), None, None, None);
        self.sessions.insert(session_id.to_string(), session);
        
        let descriptor = SessionDescriptor {
            session_id: session_id.to_string(),
            config,
            created_at: SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs_f64(),
            status: "active".to_string(),
        };
        self.descriptors.insert(session_id.to_string(), descriptor);
        
        Ok(self.sessions.get_mut(session_id).unwrap())
    }

    pub fn get_mut(&mut self, session_id: &str) -> Option<&mut QARISession<'a>> {
        self.sessions.get_mut(session_id)
    }

    pub fn aggregate_certificates(&mut self, session_ids: Option<Vec<String>>, tail_norm: f64) -> Result<AggregatedCertificate, String> {
        let sids = session_ids.unwrap_or_else(|| {
            self.descriptors.iter()
                .filter(|(_, d)| d.status == "active" || d.status == "completed")
                .map(|(sid, _)| sid.clone())
                .collect()
        });

        let mut certs = Vec::new();
        for sid in &sids {
            let session = self.sessions.get_mut(sid).ok_or_else(|| format!("Session '{}' not found", sid))?;
            let cert = session.certify(tail_norm)?;
            certs.push(cert);
        }

        let mut cert_hashes = Vec::new();
        for cert in &certs {
            let canonical = serde_json::to_string(cert).unwrap();
            let mut hasher = Sha256::new();
            hasher.update(canonical.as_bytes());
            cert_hashes.push(hex::encode(hasher.finalize()));
        }

        let mut master_hasher = Sha256::new();
        for h in &cert_hashes {
            master_hasher.update(h.as_bytes());
        }
        let aggregate_hash = hex::encode(master_hasher.finalize());

        let all_certified = certs.iter().all(|c| c.certified);
        let q_max_global = certs.iter().map(|c| c.lipschitz_upper).fold(0.0, f64::max);
        let margin_min = certs.iter().map(|c| c.margin).fold(f64::INFINITY, f64::min);

        let mut payload = HashMap::new();
        payload.insert("type", serde_json::json!("aggregate_certificate"));
        payload.insert("session_ids", serde_json::json!(sids));
        payload.insert("all_certified", serde_json::json!(all_certified));
        payload.insert("aggregate_hash", serde_json::json!(aggregate_hash));
        self.master_audit.append_payload(payload);

        Ok(AggregatedCertificate {
            session_ids: sids,
            individual_certs: certs.iter().map(|c| serde_json::to_value(c).unwrap()).collect(),
            all_certified,
            q_max_global,
            margin_min,
            aggregate_hash,
        })
    }

    pub fn global_summary(&self) -> serde_json::Value {
        let per_session: HashMap<String, serde_json::Value> = self.sessions.iter()
            .map(|(sid, s)| (sid.clone(), s.summary()))
            .collect();
        
        let total_steps: usize = per_session.values()
            .map(|v| v["steps"].as_u64().unwrap_or(0) as usize)
            .sum();
        
        let total_projections: usize = per_session.values()
            .map(|v| v["projected_count"].as_u64().unwrap_or(0) as usize)
            .sum();

        serde_json::json!({
            "total_sessions": self.sessions.len(),
            "active": self.descriptors.values().filter(|d| d.status == "active").count(),
            "completed": self.descriptors.values().filter(|d| d.status == "completed").count(),
            "paused": self.descriptors.values().filter(|d| d.status == "paused").count(),
            "total_steps": total_steps,
            "total_projections": total_projections,
            "master_audit_length": self.master_audit.len(),
            "per_session": per_session,
        })
    }
}
