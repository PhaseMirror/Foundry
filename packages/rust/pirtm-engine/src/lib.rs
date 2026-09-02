pub mod loader;
pub mod telemetry;
pub mod ffi;
pub mod monitor;
pub mod harmonia;
pub mod spectral;

use std::path::{Path, PathBuf};
use serde_json::json;
use sha2::{Sha256, Digest};
use std::process::{Command, Stdio};
use std::io::Write;
pub use spectral::{Ensemble, EnsembleContractivityReceipt, check_small_gain, validate_and_certify};

#[derive(Debug, Default)]
pub struct RuntimeConfig {
    pub dry_run: bool,
    pub jid_enabled: bool,
    pub ledger_enabled: bool,
    pub enforce_bounds: bool,
    pub input_args: Vec<String>,
}

pub struct ExecutionReceipt {
    pub return_code: i32,
    pub stdout: String,
    pub stderr: String,
    pub metrics: telemetry::TelemetryMetrics,
    pub contractivity_hash: String,
}

pub struct Runtime {
    pub config: RuntimeConfig,
    mlir_path: Option<PathBuf>,
}

impl Runtime {
    pub fn new(config: RuntimeConfig) -> Self {
        Self {
            config,
            mlir_path: None,
        }
    }

    /// Load an ensemble configuration from a JSON file.
    pub fn load_ensemble(&self, path: &Path) -> Result<Ensemble, Box<dyn std::error::Error>> {
        let content = std::fs::read_to_string(path)?;
        let ensemble: Ensemble = serde_json::from_str(&content)?;
        Ok(ensemble)
    }

    pub fn validate_ensemble(&self, ensemble: &Ensemble) -> Result<EnsembleContractivityReceipt, String> {
        let cert = spectral::validate_and_certify(ensemble, 1e-6)?;
        println!(
            "AUDIT EVENT: ensemble_validated - {}",
            json!({
                "ensemble_name": cert.ensemble_name,
                "dimension": cert.dimension,
                "spectral_radius": cert.spectral_radius,
                "is_stable": cert.is_stable,
                "receipt_hash": cert.hash,
            })
        );
        Ok(cert)
    }

    pub fn load(&mut self, mlir_path: &Path) -> Result<(), Box<dyn std::error::Error>> {
        self.mlir_path = Some(mlir_path.to_path_buf());
        Ok(())
    }

    pub fn run(&mut self) -> Result<ExecutionReceipt, Box<dyn std::error::Error>> {
        if self.config.dry_run {
            let metrics = telemetry::simulate_telemetry_collection();
            let hash = if self.config.ledger_enabled {
                let mut hasher = Sha256::new();
                let data = format!("{:?}", metrics);
                hasher.update(data);
                format!("{:x}", hasher.finalize())
            } else {
                "no-ledger".to_string()
            };

            let mut stdout_buf = String::new();
            if !self.config.input_args.is_empty() {
                stdout_buf.push_str(&format!("Simulated output for input: {}\n", self.config.input_args.join(" ")));
            }
            return Ok(ExecutionReceipt {
                return_code: 0,
                stdout: stdout_buf,
                stderr: String::new(),
                metrics,
                contractivity_hash: hash,
            });
        }

        let mlir_path = self.mlir_path.as_ref().ok_or("No module loaded")?;
        
        let ll_path = mlir_path.with_extension("ll");
        let obj_path = mlir_path.with_extension("o");
        let bin_path = mlir_path.with_extension("bin");

        let mlir_status = Command::new("mlir-translate")
            .arg("--mlir-to-llvmir")
            .arg(mlir_path)
            .arg("-o")
            .arg(&ll_path)
            .status()?;
        
        if !mlir_status.success() {
            return Err(format!("mlir-translate failed with status: {}", mlir_status).into());
        }

        let llc_status = Command::new("llc")
            .arg("-filetype=obj")
            .arg(&ll_path)
            .arg("-o")
            .arg(&obj_path)
            .status()?;

        if !llc_status.success() {
            return Err(format!("llc failed with status: {}", llc_status).into());
        }

        let clang_status = Command::new("clang")
            .arg(&obj_path)
            .arg("-o")
            .arg(&bin_path)
            .status()?;

        if !clang_status.success() {
            return Err(format!("clang failed with status: {}", clang_status).into());
        }

        let output = Command::new(&bin_path)
            .args(&self.config.input_args)
            .output()?;

        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        let return_code = output.status.code().unwrap_or(-1);

        let metrics = telemetry::collect_execution_metrics(stdout.len(), stderr.len(), return_code);

        let hash = if self.config.ledger_enabled {
            let mut hasher = Sha256::new();
            let data = format!("{:?}", metrics);
            hasher.update(data);
            format!("{:x}", hasher.finalize())
        } else {
            "no-ledger".to_string()
        };

        Ok(ExecutionReceipt {
            return_code,
            stdout,
            stderr,
            metrics,
            contractivity_hash: hash,
        })
    }
}

