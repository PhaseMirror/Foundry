//! WardMonitor: Runtime drift detection for Governance‑as‑Compilation.
//!
//! Monitors manifold drift (ρ) and liquidity pool drift (δ) against
//! thresholds defined in ADR‑003. Applies Zeno‑Finton corrective gain
//! and triggers a deterministic kill‑switch if invariants are violated.

use serde::{Deserialize, Serialize};
use serde_json::json;
use std::time::{Duration, Instant};

// Local telemetry recording for monitor events
fn record_event(name: &str, payload: serde_json::Value) {
    println!("AUDIT EVENT: {} - {}", name, payload);
}

// ──────────────────────────────────────────────────────────────
//  Configuration
// ──────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct MonitorConfig {
    pub rho_warn: f64,
    pub rho_halt: f64,
    pub delta_max: f64,
    pub kappa0: f64,
    pub alpha: f64,
    pub poll_interval_ms: u64,
}

impl Default for MonitorConfig {
    fn default() -> Self {
        Self {
            rho_warn: 0.85,
            rho_halt: 1.0,
            delta_max: 1e-4,
            kappa0: 1.0,
            alpha: 0.1,
            poll_interval_ms: 100,
        }
    }
}

// ──────────────────────────────────────────────────────────────
//  Manifold State
// ──────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ManifoldState {
    pub rho: f64,
    pub delta: f64,
    pub lambda_l_product: f64,
    pub timestamp: u64,
}

pub trait ManifoldStateProvider {
    fn fetch_state(&self) -> Result<ManifoldState, String>;
}

// ──────────────────────────────────────────────────────────────
//  Zeno‑Finton Controller
// ──────────────────────────────────────────────────────────────

pub struct ZenoController {
    config: MonitorConfig,
    start_time: Instant,
    kappa_current: f64,
}

impl ZenoController {
    pub fn new(config: &MonitorConfig) -> Self {
        Self {
            config: config.clone(),
            start_time: Instant::now(),
            kappa_current: config.kappa0,
        }
    }

    pub fn compute_kappa(&mut self) -> f64 {
        let elapsed = self.start_time.elapsed().as_secs_f64();
        self.kappa_current = self.config.kappa0 * (-self.config.alpha * elapsed).exp();
        self.kappa_current
    }

    pub fn apply_gain(&mut self, raw_rho: f64) -> f64 {
        let kappa = self.compute_kappa();
        let attenuated = raw_rho * (1.0 - kappa).max(0.0);
        attenuated.max(0.0)
    }
}

// ──────────────────────────────────────────────────────────────
//  WardMonitor Engine
// ──────────────────────────────────────────────────────────────

pub struct WardMonitor<P: ManifoldStateProvider> {
    config: MonitorConfig,
    provider: P,
    zeno: ZenoController,
    running: bool,
}

impl<P: ManifoldStateProvider> WardMonitor<P> {
    pub fn new(config: MonitorConfig, provider: P) -> Self {
        let zeno = ZenoController::new(&config);
        Self {
            config,
            provider,
            zeno,
            running: true,
        }
    }

    pub fn step(&mut self) -> Result<MonitorAction, String> {
        let state = self.provider.fetch_state()?;

        if state.lambda_l_product >= 1.0 {
            record_event(
                "monitor_stability_violation",
                json!({
                    "lambda_l_product": state.lambda_l_product,
                    "threshold": 1.0,
                    "timestamp": state.timestamp,
                }),
            );
            return Ok(MonitorAction::Kill(
                "Finton stability violation: λₚ·Lₚ ≥ 1".to_string(),
            ));
        }

        if state.delta >= self.config.delta_max {
            record_event(
                "monitor_delta_violation",
                json!({
                    "delta": state.delta,
                    "delta_max": self.config.delta_max,
                    "timestamp": state.timestamp,
                }),
            );
            return Ok(MonitorAction::Kill(format!(
                "Liquidity pool drift exceeded: δ = {}",
                state.delta
            )));
        }

        let raw_rho = state.rho;
        let attenuated_rho = self.zeno.apply_gain(raw_rho);

        record_event(
            "monitor_metrics",
            json!({
                "rho_raw": raw_rho,
                "rho_attenuated": attenuated_rho,
                "kappa": self.zeno.kappa_current,
                "delta": state.delta,
                "lambda_l_product": state.lambda_l_product,
                "timestamp": state.timestamp,
            }),
        );

        if attenuated_rho >= self.config.rho_halt {
            record_event(
                "monitor_halt",
                json!({
                    "rho": attenuated_rho,
                    "rho_halt": self.config.rho_halt,
                }),
            );
            return Ok(MonitorAction::Kill(format!(
                "Halt threshold exceeded: ρ = {}",
                attenuated_rho
            )));
        }

        if attenuated_rho >= self.config.rho_warn {
            record_event(
                "monitor_warning",
                json!({
                    "rho": attenuated_rho,
                    "rho_warn": self.config.rho_warn,
                }),
            );
        }

        Ok(MonitorAction::Continue)
    }

    pub fn run(mut self) -> Result<(), String> {
        let interval = Duration::from_millis(self.config.poll_interval_ms);

        while self.running {
            match self.step() {
                Ok(MonitorAction::Continue) => {
                    std::thread::sleep(interval);
                }
                Ok(MonitorAction::Kill(reason)) => {
                    eprintln!("💀 WardMonitor kill‑switch triggered: {}", reason);
                    record_event("monitor_kill_switch", json!({ "reason": reason }));
                    std::process::exit(1);
                }
                Err(e) => {
                    eprintln!("❌ Monitor step error: {}", e);
                    record_event("monitor_error", json!({ "error": e }));
                    std::process::exit(1);
                }
            }
        }

        Ok(())
    }

    pub fn stop(&mut self) {
        self.running = false;
    }
}

// ──────────────────────────────────────────────────────────────
//  Actions
// ──────────────────────────────────────────────────────────────

#[derive(Debug, PartialEq)]
pub enum MonitorAction {
    Continue,
    Kill(String),
}

// ──────────────────────────────────────────────────────────────
//  Mock Provider (for testing)
// ──────────────────────────────────────────────────────────────

pub struct MockStateProvider {
    states: Vec<ManifoldState>,
    index: std::cell::Cell<usize>,
}

impl MockStateProvider {
    pub fn new(states: Vec<ManifoldState>) -> Self {
        Self {
            states,
            index: std::cell::Cell::new(0),
        }
    }
}

impl ManifoldStateProvider for MockStateProvider {
    fn fetch_state(&self) -> Result<ManifoldState, String> {
        let i = self.index.get();
        if i >= self.states.len() {
            return Ok(self.states.last().unwrap().clone());
        }
        let state = self.states[i].clone();
        self.index.set(i + 1);
        Ok(state)
    }
}

// ──────────────────────────────────────────────────────────────
//  Real File-Backed Provider (Operationalizes the monitor)
// ──────────────────────────────────────────────────────────────

pub struct FileStateProvider {
    pub file_path: std::path::PathBuf,
}

impl FileStateProvider {
    pub fn new<P: AsRef<std::path::Path>>(path: P) -> Self {
        Self {
            file_path: path.as_ref().to_path_buf(),
        }
    }
}

impl ManifoldStateProvider for FileStateProvider {
    fn fetch_state(&self) -> Result<ManifoldState, String> {
        let content = std::fs::read_to_string(&self.file_path)
            .map_err(|e| format!("Failed to read state file {:?}: {}", self.file_path, e))?;
        let state: ManifoldState = serde_json::from_str(&content)
            .map_err(|e| format!("Failed to parse state JSON: {}", e))?;
        Ok(state)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::SystemTime;

    fn mock_state(rho: f64, delta: f64, lambda_l_product: f64) -> ManifoldState {
        let timestamp = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_secs();
        ManifoldState {
            rho,
            delta,
            lambda_l_product,
            timestamp,
        }
    }

    #[test]
    fn test_zeno_compute_kappa_decays() {
        let config = MonitorConfig::default();
        let mut zeno = ZenoController::new(&config);
        let k1 = zeno.compute_kappa();
        std::thread::sleep(Duration::from_millis(100));
        let k2 = zeno.compute_kappa();
        assert!(k2 < k1);
    }

    #[test]
    fn test_monitor_continues_on_normal_state() {
        let mut config = MonitorConfig::default();
        config.kappa0 = 0.0;
        let state = mock_state(0.5, 5e-5, 0.9);
        let provider = MockStateProvider::new(vec![state]);
        let mut monitor = WardMonitor::new(config, provider);

        let action = monitor.step().unwrap();
        assert_eq!(action, MonitorAction::Continue);
    }

    #[test]
    fn test_monitor_kills_on_rho_halt() {
        let mut config = MonitorConfig::default();
        config.kappa0 = 0.0;
        let state = mock_state(1.2, 5e-5, 0.9);
        let provider = MockStateProvider::new(vec![state]);
        let mut monitor = WardMonitor::new(config, provider);

        let action = monitor.step().unwrap();
        match action {
            MonitorAction::Kill(reason) => assert!(reason.contains("Halt threshold exceeded")),
            _ => panic!("Expected Kill"),
        }
    }

    #[test]
    fn test_monitor_kills_on_delta_violation() {
        let mut config = MonitorConfig::default();
        config.kappa0 = 0.0;
        let state = mock_state(0.5, 1e-3, 0.9);
        let provider = MockStateProvider::new(vec![state]);
        let mut monitor = WardMonitor::new(config, provider);

        let action = monitor.step().unwrap();
        match action {
            MonitorAction::Kill(reason) => {
                assert!(reason.contains("Liquidity pool drift exceeded"))
            }
            _ => panic!("Expected Kill"),
        }
    }

    #[test]
    fn test_monitor_kills_on_lambda_l_product() {
        let mut config = MonitorConfig::default();
        config.kappa0 = 0.0;
        let state = mock_state(0.5, 5e-5, 1.1);
        let provider = MockStateProvider::new(vec![state]);
        let mut monitor = WardMonitor::new(config, provider);

        let action = monitor.step().unwrap();
        match action {
            MonitorAction::Kill(reason) => assert!(reason.contains("Finton stability violation")),
            _ => panic!("Expected Kill"),
        }
    }

    #[test]
    fn test_monitor_warning_does_not_kill() {
        let mut config = MonitorConfig::default();
        config.kappa0 = 0.0;
        let state = mock_state(0.9, 5e-5, 0.9);
        let provider = MockStateProvider::new(vec![state]);
        let mut monitor = WardMonitor::new(config, provider);

        let action = monitor.step().unwrap();
        assert_eq!(action, MonitorAction::Continue);
    }
}
