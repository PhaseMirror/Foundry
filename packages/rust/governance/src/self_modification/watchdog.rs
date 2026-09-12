use std::time::{SystemTime, UNIX_EPOCH, Duration};
use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use crate::self_modification::kill_switch::KillSwitch;

/// R-05: Governance Watchdog — Post-Execution Spectral Verification.

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WatchdogCheck {
    pub timestamp: f64,
    pub spectral_radius: f64,
    pub threshold: f64,
    pub passed: bool,
}

pub struct GovernanceWatchdog<'a> {
    kill_switch: &'a KillSwitch,
    spectral_fn: Box<dyn Fn(&HashMap<String, Value>) -> f64 + Send + Sync>,
    pub check_interval: f64,
    pub monitor_window: f64,
    pub safety_threshold: f64,
    checks: Vec<WatchdogCheck>,
}

impl<'a> GovernanceWatchdog<'a> {
    pub fn new(
        kill_switch: &'a KillSwitch,
        spectral_fn: Option<Box<dyn Fn(&HashMap<String, Value>) -> f64 + Send + Sync>>,
        check_interval: f64,
        monitor_window: f64,
        safety_threshold: f64,
    ) -> Self {
        Self {
            kill_switch,
            spectral_fn: spectral_fn.unwrap_or_else(|| Box::new(|_| 0.0)),
            check_interval,
            monitor_window,
            safety_threshold,
            checks: Vec::new(),
        }
    }

    pub fn verify_once(&mut self, parameters: &HashMap<String, Value>) -> WatchdogCheck {
        let radius = (self.spectral_fn)(parameters);
        let passed = radius < self.safety_threshold;
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs_f64();
        
        let check = WatchdogCheck {
            timestamp: now,
            spectral_radius: radius,
            threshold: self.safety_threshold,
            passed,
        };
        self.checks.push(check.clone());

        if !passed {
            self.kill_switch.arm_halt(&format!(
                "Watchdog: spectral radius {:.6} >= threshold {:.6}",
                radius, self.safety_threshold
            ));
        }

        check
    }

    #[cfg(feature = "coupling")]
    pub async fn run_monitoring(
        &mut self,
        parameters: &HashMap<String, Value>,
        real_time: bool,
    ) -> Vec<WatchdogCheck> {
        let n_checks = (self.monitor_window / self.check_interval).max(1.0) as usize;
        let mut results = Vec::new();

        for _ in 0..n_checks {
            let check = self.verify_once(parameters);
            results.push(check.clone());
            if !check.passed {
                break;
            }
            if real_time {
                tokio::time::sleep(std::time::Duration::from_secs_f64(self.check_interval)).await;
            }
        }

        results
    }

    pub fn all_passed(&self) -> bool {
        !self.checks.is_empty() && self.checks.iter().all(|c| c.passed)
    }

    pub fn get_checks(&self) -> Vec<WatchdogCheck> {
        self.checks.clone()
    }
}
