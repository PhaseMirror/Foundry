use serde::{Deserialize, Serialize};
use sigma::{SigmaKernel, StateTransition, Thresholds, PolicyEngine, WitnessLedger};
use std::sync::Mutex;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum SwarmRpcError {
    #[error("Parse Error: Invalid JSON-RPC")]
    ParseError,
    #[error("Method Not Found")]
    MethodNotFound,
    #[error("L_eff Dissonance Trap: Agent proposed a transition exceeding threshold (proposed: {0}, max: {1})")]
    LeffViolation(f64, f64),
}

/// JSON-RPC 2.0 Request Schema
#[derive(Serialize, Deserialize)]
pub struct RpcRequest {
    pub jsonrpc: String,
    pub method: String,
    pub params: Option<StateTransition>,
    pub id: String,
}

/// JSON-RPC 2.0 Response Schema
#[derive(Debug, Serialize, Deserialize)]
pub struct RpcResponse {
    pub jsonrpc: String,
    pub result: Option<String>,
    pub error: Option<String>,
    pub id: String,
}

pub struct SwarmAgentNode {
    pub node_id: String,
    pub l_eff_max: f64,
    pub tau_r: f64,
    pub kernel: Mutex<SigmaKernel>,
}

impl SwarmAgentNode {
    pub fn new(node_id: &str, l_eff_max: f64) -> Self {
        let thresholds = Thresholds::default();
        let engine = PolicyEngine::new();
        let ledger = WitnessLedger::new("state/archivum/witnesses.jsonl");
        let kernel = Mutex::new(SigmaKernel::new(engine, ledger, thresholds.clone()));
        
        Self {
            node_id: node_id.to_string(),
            l_eff_max,
            tau_r: thresholds.tau_r,
            kernel,
        }
    }

    /// Load thresholds from Lean export artifact.
    pub fn from_lean_export(node_id: &str, thresholds_path: &str) -> Result<Self, SwarmRpcError> {
        let thresholds = Thresholds::from_json_file(thresholds_path)
            .map_err(|_| SwarmRpcError::ParseError)?;
        let engine = PolicyEngine::new();
        let ledger = WitnessLedger::new("state/archivum/witnesses.jsonl");
        let kernel = Mutex::new(SigmaKernel::new(engine, ledger, thresholds.clone()));
        
        Ok(Self {
            node_id: node_id.to_string(),
            l_eff_max: thresholds.max_l_eff,
            tau_r: thresholds.tau_r,
            kernel,
        })
    }

    /// Handles incoming Swarm RPC negotiations through the governed Sigma Kernel
    pub fn handle_request(&self, payload: &str) -> Result<RpcResponse, SwarmRpcError> {
        let req: RpcRequest = serde_json::from_str(payload).map_err(|_| SwarmRpcError::ParseError)?;

        if req.method == "negotiate_transition" {
            if let Some(params) = req.params {
                let mut kernel = self.kernel.lock().expect("kernel mutex");
                let transition = StateTransition {
                    id: params.id.clone(),
                    r_sc: params.r_sc,
                    l_eff: params.l_eff,
                };
                
                match kernel.evaluate(transition) {
                    Ok(block) => {
                        return Ok(RpcResponse {
                            jsonrpc: "2.0".to_string(),
                            result: Some(format!("{{\"transition_id\":\"{}\",\"ratified\":true,\"pweh_hash\":\"N/A\"}}", block.transition_id)),
                            error: None,
                            id: req.id,
                        });
                    }
                    Err(_) => {
                        return Err(SwarmRpcError::LeffViolation(params.l_eff, self.l_eff_max));
                    }
                }
            }
        }
        
        Err(SwarmRpcError::MethodNotFound)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_negotiation() {
        let agent = SwarmAgentNode::new("agent-001", 1.0);
        let payload = r#"{
            "jsonrpc": "2.0",
            "method": "negotiate_transition",
            "params": {
                "id": "tx-swarm-1",
                "r_sc": 47.06998778,
                "l_eff": 0.5
            },
            "id": "1"
        }"#;

        let response = agent.handle_request(payload).unwrap();
        assert!(response.result.unwrap().contains("ratified"));
    }

    #[test]
    fn test_leff_violation_trap() {
        let agent = SwarmAgentNode::new("agent-001", 1.0);
        let payload = r#"{
            "jsonrpc": "2.0",
            "method": "negotiate_transition",
            "params": {
                "id": "tx-swarm-bad",
                "r_sc": 47.0699,
                "l_eff": 1.5
            },
            "id": "2"
        }"#;

        let error = agent.handle_request(payload).unwrap_err();
        match error {
            SwarmRpcError::LeffViolation(proposed, max) => {
                assert_eq!(proposed, 1.5);
                assert_eq!(max, 1.0);
            }
            _ => panic!("Expected LeffViolation"),
        }
    }

    #[test]
    fn test_from_lean_export() {
        let json = r#"{
            "tau_r": 47.06998778,
            "max_l_eff": 0.9,
            "rpi_upper": 7,
            "lambda1_positive": true,
            "atlas_signature": [10, 14],
            "contractivity_margin": 0.01
        }"#;
        std::fs::write("/tmp/test_thresholds.json", json).unwrap();
        let agent = SwarmAgentNode::from_lean_export("agent-lean", "/tmp/test_thresholds.json").unwrap();
        assert_eq!(agent.l_eff_max, 0.9);
        assert_eq!(agent.tau_r, 47.06998778);
    }
}
pub mod raft;
