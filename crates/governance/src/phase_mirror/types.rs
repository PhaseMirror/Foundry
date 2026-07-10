use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PIRTMExpr {
    pub data: Vec<u8>,
}

impl PIRTMExpr {
    pub fn new(data: Vec<u8>) -> Result<Self, String> {
        if data.is_empty() {
            return Err("PIRTMExpr data cannot be empty".to_string());
        }
        if data.len() < 8 {
            return Err("PIRTMExpr data too short (< 8 bytes)".to_string());
        }
        if &data[0..4] == &[0, 0, 0, 0] {
             return Err("PIRTMExpr data has invalid magic bytes".to_string());
        }
        if serde_json::from_slice::<serde_json::Value>(&data).is_ok() {
            return Err("PIRTMExpr data cannot be JSON; use StateSnapshot for snapshots".to_string());
        }
        Ok(Self { data })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct StateSnapshot {
    pub data: Vec<u8>,
    pub snapshot_id: String,
}

impl StateSnapshot {
    pub fn new(data: Vec<u8>, snapshot_id: String) -> Result<Self, String> {
        if data.is_empty() {
            return Err("StateSnapshot data cannot be empty".to_string());
        }
        if snapshot_id.is_empty() {
            return Err("StateSnapshot snapshot_id cannot be empty".to_string());
        }
        let _ : serde_json::Value = serde_json::from_slice(&data)
            .map_err(|e| format!("StateSnapshot data must be valid JSON: {}", e))?;
        Ok(Self { data, snapshot_id })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct EnforcementBits {
    #[serde(default = "default_true")]
    pub r: bool,
    #[serde(default = "default_true")]
    pub c: bool,
    #[serde(default = "default_true")]
    pub s: bool,
    #[serde(default = "default_true")]
    pub b: bool,
    #[serde(default = "default_true")]
    pub v: bool,
    #[serde(default = "default_true")]
    pub t: bool,
    #[serde(default = "default_true")]
    pub m: bool,
    #[serde(default = "default_false")]
    pub p_bad: bool,
}

fn default_true() -> bool { true }
fn default_false() -> bool { false }

impl EnforcementBits {
    pub fn new() -> Self {
        Self {
            r: true, c: true, s: true, b: true, v: true, t: true, m: true, p_bad: false
        }
    }

    pub fn legitimacy(&self) -> bool {
        self.r && self.c && self.s && self.b && self.v && self.m && !self.p_bad
    }
}

impl Default for EnforcementBits {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExpressionPayload {
    pub input_text: String,
    pub output_expr: PIRTMExpr,
    #[serde(default = "default_none")]
    pub rollback_trigger: String,
}

fn default_none() -> String { "none".to_string() }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StateTransitionPayload {
    pub input_text: String,
    pub snapshot: StateSnapshot,
    pub enforcement_bits: EnforcementBits,
    #[serde(default = "default_none")]
    pub rollback_trigger: String,
    pub governance_version: Option<String>,
    #[serde(default)]
    pub twin_desynced: bool,
    #[serde(default)]
    pub stale_base_disabled: bool,
    #[serde(default)]
    pub boundary_absent: bool,
}

impl StateTransitionPayload {
    pub fn from_snapshot(input_text: String, snapshot: StateSnapshot, rollback_trigger: String) -> Self {
        let payload: HashMap<String, serde_json::Value> = serde_json::from_slice(&snapshot.data).unwrap_or_default();
        
        let bits_raw = payload.get("enforcement_bits").and_then(|v| v.as_object());
        let bits = if let Some(b) = bits_raw {
            EnforcementBits {
                r: b.get("R").and_then(|v| v.as_bool()).unwrap_or(true),
                c: b.get("C").and_then(|v| v.as_bool()).unwrap_or(true),
                s: b.get("S").and_then(|v| v.as_bool()).unwrap_or(true),
                b: b.get("B").and_then(|v| v.as_bool()).unwrap_or(true),
                v: b.get("V").and_then(|v| v.as_bool()).unwrap_or(true),
                t: b.get("T").and_then(|v| v.as_bool()).unwrap_or(true),
                m: b.get("M").and_then(|v| v.as_bool()).unwrap_or(true),
                p_bad: b.get("P_bad").and_then(|v| v.as_bool()).unwrap_or(false),
            }
        } else {
            EnforcementBits::new()
        };

        let governance_version = payload.get("governance_version").and_then(|v| v.as_str()).map(|s| s.to_string());
        let twin_desynced = payload.get("twin_desynced").and_then(|v| v.as_bool()).unwrap_or(false);
        let stale_base_disabled = !bits.s;
        let boundary_absent = !bits.b;

        Self {
            input_text,
            snapshot,
            enforcement_bits: bits,
            rollback_trigger,
            governance_version,
            twin_desynced,
            stale_base_disabled,
            boundary_absent,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum PhaseMirrorPayload {
    Expression(ExpressionPayload),
    StateTransition(StateTransitionPayload),
}
