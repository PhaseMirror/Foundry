use crate::certify::AceCertificate;
use crate::gate::GatedOutput;
use crate::types::{MonitorRecord, Status, StepInfo};
use serde::{Deserialize, Serialize};
use std::collections::VecDeque;
use std::fs::OpenOptions;
use std::io::Write;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryEvent {
    pub timestamp: f64,
    pub event_type: String,
    pub step_index: i64,
    pub payload: serde_json::Value,
    pub source: String,
    pub version: String,
}

impl TelemetryEvent {
    pub fn new(event_type: &str, step_index: i64, payload: serde_json::Value) -> Self {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs_f64();
        Self {
            timestamp,
            event_type: event_type.to_string(),
            step_index,
            payload,
            source: "pirtm-rs".to_string(),
            version: "0.2.0".to_string(),
        }
    }
}

pub struct Monitor {
    records: VecDeque<MonitorRecord>,
    max_len: usize,
}

impl Monitor {
    pub fn new(max_len: usize) -> Self {
        Self {
            records: VecDeque::with_capacity(max_len),
            max_len,
        }
    }

    pub fn push(&mut self, info: StepInfo, status: Option<Status>) -> MonitorRecord {
        let record = MonitorRecord {
            step: info.step,
            info,
            status,
        };
        if self.records.len() >= self.max_len {
            self.records.pop_front();
        }
        self.records.push_back(record.clone());
        record
    }

    pub fn summary(&self) -> serde_json::Value {
        if self.records.is_empty() {
            return serde_json::json!({"steps": 0, "max_q": 0.0, "converged": false});
        }
        let max_q = self.records.iter().map(|r| r.info.q).fold(0.0, f64::max);
        let converged = self.records.back().and_then(|r| r.status.as_ref()).map(|s| s.converged).unwrap_or(false);
        serde_json::json!({
            "steps": self.records.len(),
            "max_q": max_q,
            "converged": converged,
        })
    }

    pub fn last(&self) -> Option<&MonitorRecord> {
        self.records.back()
    }
}

pub trait TelemetrySink: Send + Sync {
    fn emit(&self, event: &TelemetryEvent);
    fn flush(&self) {}
    fn close(&self) {}
}

pub struct NullSink;
impl TelemetrySink for NullSink {
    fn emit(&self, _event: &TelemetryEvent) {}
}

pub struct MemorySink {
    events: Arc<Mutex<VecDeque<TelemetryEvent>>>,
    max_events: usize,
}

impl MemorySink {
    pub fn new(max_events: usize) -> Self {
        Self {
            events: Arc::new(Mutex::new(VecDeque::with_capacity(max_events))),
            max_events,
        }
    }

    pub fn query(&self, event_type: Option<&str>) -> Vec<TelemetryEvent> {
        let events = self.events.lock().unwrap();
        if let Some(et) = event_type {
            events.iter().filter(|e| e.event_type == et).cloned().collect()
        } else {
            events.iter().cloned().collect()
        }
    }
}

impl TelemetrySink for MemorySink {
    fn emit(&self, event: &TelemetryEvent) {
        let mut events = self.events.lock().unwrap();
        if events.len() >= self.max_events {
            events.pop_front();
        }
        events.push_back(event.clone());
    }
}

pub struct FileSink {
    path: PathBuf,
}

impl FileSink {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }
}

impl TelemetrySink for FileSink {
    fn emit(&self, event: &TelemetryEvent) {
        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.path)
            .unwrap();
        let json = serde_json::to_string(event).unwrap();
        writeln!(file, "{}", json).unwrap();
    }

    fn flush(&self) {
        // In this implementation, we open/close on each emit, so flush is implicit.
        // For higher performance, we could keep the file open.
    }
}

pub struct TelemetryBus {
    pub sinks: Vec<Box<dyn TelemetrySink>>,
}

impl TelemetryBus {
    pub fn new(sinks: Vec<Box<dyn TelemetrySink>>) -> Self {
        Self { sinks }
    }

    pub fn emit_step(&self, step_index: usize, info: &StepInfo) {
        let event = TelemetryEvent::new(
            "step",
            step_index as i64,
            serde_json::to_value(info).unwrap(),
        );
        self.dispatch(&event);
    }

    pub fn emit_gate(&self, step_index: usize, output: &GatedOutput) {
        let event = TelemetryEvent::new(
            "gate",
            step_index as i64,
            serde_json::json!({
                "emitted": output.emitted,
                "policy_applied": output.policy_applied,
                "suppression_reason": output.suppression_reason,
                "q": output.info.q,
            }),
        );
        self.dispatch(&event);
    }

    pub fn emit_certificate(&self, cert: &AceCertificate) {
        let event = TelemetryEvent::new(
            "certificate",
            -1,
            serde_json::json!({
                "certified": cert.certified,
                "margin": cert.margin,
                "tail_bound": cert.tail_bound,
                "details": cert.details,
            }),
        );
        self.dispatch(&event);
    }

    pub fn emit_alert(&self, name: &str, detail: serde_json::Value) {
        let mut payload = detail.as_object().cloned().unwrap_or_default();
        payload.insert("alert_name".to_string(), serde_json::Value::String(name.to_string()));
        let event = TelemetryEvent::new(
            "alert",
            -1,
            serde_json::Value::Object(payload),
        );
        self.dispatch(&event);
    }

    fn dispatch(&self, event: &TelemetryEvent) {
        for sink in &self.sinks {
            sink.emit(event);
        }
    }

    pub fn flush(&self) {
        for sink in &self.sinks {
            sink.flush();
        }
    }

    pub fn close(&self) {
        for sink in &self.sinks {
            sink.close();
        }
    }
}
