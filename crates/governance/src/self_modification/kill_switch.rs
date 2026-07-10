use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};

/// R-04: Kill Switch — Independent Safety Override.

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KillSwitchState {
    pub armed: bool,
    pub mode: Option<String>, // "halt" | "revert" | None
    pub reason: String,
    pub revert_target_id: Option<String>,
}

pub struct KillSwitch {
    armed: AtomicBool,
    mode: Mutex<Option<String>>,
    revert_target_id: Mutex<Option<String>>,
    halt_reason: Mutex<String>,
    audit_log: Mutex<Vec<Value>>,
}

impl KillSwitch {
    pub fn new() -> Self {
        Self {
            armed: AtomicBool::new(false),
            mode: Mutex::new(None),
            revert_target_id: Mutex::new(None),
            halt_reason: Mutex::new(String::new()),
            audit_log: Mutex::new(Vec::new()),
        }
    }

    pub fn arm_halt(&self, reason: &str) {
        *self.mode.lock().unwrap() = Some("halt".to_string());
        *self.halt_reason.lock().unwrap() = reason.to_string();
        *self.revert_target_id.lock().unwrap() = None;
        self.armed.store(true, Ordering::SeqCst);
        
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs_f64();
        self.audit_log.lock().unwrap().push(json!({
            "event": "kill_switch_armed_halt",
            "reason": reason,
            "timestamp": now,
        }));
    }

    pub fn arm_revert(&self, snapshot_id: &str, reason: &str) {
        *self.mode.lock().unwrap() = Some("revert".to_string());
        *self.halt_reason.lock().unwrap() = reason.to_string();
        *self.revert_target_id.lock().unwrap() = Some(snapshot_id.to_string());
        self.armed.store(true, Ordering::SeqCst);

        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs_f64();
        self.audit_log.lock().unwrap().push(json!({
            "event": "kill_switch_armed_revert",
            "snapshot_id": snapshot_id,
            "reason": reason,
            "timestamp": now,
        }));
    }

    pub fn is_armed(&self) -> bool {
        self.armed.load(Ordering::SeqCst)
    }

    pub fn state(&self) -> KillSwitchState {
        KillSwitchState {
            armed: self.is_armed(),
            mode: self.mode.lock().unwrap().clone(),
            reason: self.halt_reason.lock().unwrap().clone(),
            revert_target_id: self.revert_target_id.lock().unwrap().clone(),
        }
    }

    pub fn disarm(&self, human_token: &str) -> Result<(), String> {
        if human_token.is_empty() {
            return Err("Kill switch disarm requires a non-empty human token.".to_string());
        }
        self.armed.store(false, Ordering::SeqCst);
        *self.mode.lock().unwrap() = None;
        *self.halt_reason.lock().unwrap() = String::new();
        *self.revert_target_id.lock().unwrap() = None;

        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs_f64();
        self.audit_log.lock().unwrap().push(json!({
            "event": "kill_switch_disarmed",
            "timestamp": now,
        }));
        Ok(())
    }

    pub fn get_audit_log(&self) -> Vec<Value> {
        self.audit_log.lock().unwrap().clone()
    }
}
