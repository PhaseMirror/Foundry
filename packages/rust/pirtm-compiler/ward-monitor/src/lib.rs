use std::fs;
use serde::Deserialize;
use serde_yaml::Value;
use log::{info, warn};
use anyhow::{Result, Context};

/// Configuration for drift thresholds – loaded from `templates/ward_monitor.yaml`.
#[derive(Debug, Deserialize)]
pub struct DriftConfig {
    /// Maximum allowed deviation before a warning is emitted.
    pub rho_warn: f64,
    /// Optional alert level for critical drift.
    pub rho_critical: Option<f64>,
    /// Human‑readable description of the monitored manifold.
    pub description: Option<String>,
}

impl DriftConfig {
    /// Load configuration from a YAML file.
    pub fn load(path: &str) -> Result<Self> {
        let content = fs::read_to_string(path)
            .with_context(|| format!("Failed to read drift config at {}", path))?;
        serde_yaml::from_str(&content)
            .with_context(|| "Failed to deserialize drift config YAML")
    }
}

/// Simple monitor that evaluates a scalar drift metric `rho` against the policy.
pub struct WardMonitor {
    config: DriftConfig,
}

impl WardMonitor {
    /// Initialise the monitor with a config file.
    pub fn new(config_path: &str) -> Result<Self> {
        let cfg = DriftConfig::load(config_path)?;
        Ok(Self { config: cfg })
    }

    /// Evaluate the current drift value.
    /// Returns `Ok(None)` if drift is within warning bounds, otherwise returns a warning string.
    pub fn check_drift(&self, rho: f64) -> Result<Option<String>> {
        if rho > self.config.rho_warn {
            let mut msg = format!(
                "[WARD MONITOR] Drift warning: rho = {:.4} exceeds warning threshold {:.4}",
                rho, self.config.rho_warn
            );
            if let Some(critical) = self.config.rho_critical {
                if rho > critical {
                    msg = format!(
                        "[WARD MONITOR] CRITICAL drift: rho = {:.4} exceeds critical threshold {:.4}",
                        rho, critical
                    );
                }
            }
            warn!("{}", msg);
            Ok(Some(msg))
        } else {
            info!("Drift within bounds: rho = {:.4}", rho);
            Ok(None)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::NamedTempFile;
    use std::io::Write;

    fn make_cfg(content: &str) -> NamedTempFile {
        let mut file = NamedTempFile::new().unwrap();
        write!(file, "{}", content).unwrap();
        file
    }

    #[test]
    fn test_warning() {
        let cfg = make_cfg("rho_warn: 0.5\nrho_critical: 0.9\n");
        let monitor = WardMonitor::new(cfg.path().to_str().unwrap()).unwrap();
        let warn = monitor.check_drift(0.6).unwrap();
        assert!(warn.is_some());
    }

    #[test]
    fn test_ok() {
        let cfg = make_cfg("rho_warn: 0.5\n");
        let monitor = WardMonitor::new(cfg.path().to_str().unwrap()).unwrap();
        let res = monitor.check_drift(0.3).unwrap();
        assert!(res.is_none());
    }
}
