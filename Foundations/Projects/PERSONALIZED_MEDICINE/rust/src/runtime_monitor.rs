//! Runtime Monitor and Incident Revocation Policy (ADR-0037 §5)

use crate::toy_fixture::ToyFixture;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum MonitorStatus {
    Nominal,
    Violated { expected: i64, actual: i64 },
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MonitorEvent {
    pub step: usize,
    pub y_in: i64,
    pub u_in: i64,
    pub y_out: i64,
    pub status: MonitorStatus,
}

pub struct RuntimeMonitor {
    pub history: Vec<MonitorEvent>,
    pub is_sealed: bool,
}

impl RuntimeMonitor {
    pub fn new() -> Self {
        Self {
            history: Vec::new(),
            is_sealed: true,
        }
    }

    /// Process a monitored update step: y_{t+1} = 4 y_t + u_t.
    pub fn process_update(&mut self, y: i64, u: i64, actual_output: i64) -> bool {
        let expected = ToyFixture::f10(y, u);
        let status = if expected == actual_output {
            MonitorStatus::Nominal
        } else {
            self.is_sealed = false;
            MonitorStatus::Violated {
                expected,
                actual: actual_output,
            }
        };

        let is_ok = status == MonitorStatus::Nominal;
        self.history.push(MonitorEvent {
            step: self.history.len(),
            y_in: y,
            u_in: u,
            y_out: actual_output,
            status,
        });

        is_ok
    }
}
