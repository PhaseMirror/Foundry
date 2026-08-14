//! Python SymPy bridge for the AL-GFT derivation engine.
//!
//! This module provides utilities to invoke the Python symbolic derivation
//! scripts, capture their JSON output, and convert it into `DerivationWitness`
//! objects. It also supports loading JSON directly from disk for offline
//! verification.

use super::*;
use std::process::Command;
use std::path::PathBuf;

#[derive(Debug, thiserror::Error)]
pub enum BridgeError {
    #[error("Python script execution failed: {0}")]
    ScriptFailed(String),
    #[error("JSON parse error: {0}")]
    JsonParse(#[from] serde_json::Error),
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

pub type Result<T> = std::result::Result<T, BridgeError>;

/// Configuration for the Python bridge.
#[derive(Debug, Clone)]
pub struct PythonBridgeConfig {
    /// Path to the Python executable (default: `python3`).
    pub python_exe: String,
    /// Root directory containing the `python/` step scripts.
    pub scripts_dir: PathBuf,
    /// Whether to capture stderr.
    pub capture_stderr: bool,
}

impl Default for PythonBridgeConfig {
    fn default() -> Self {
        Self {
            python_exe: "python3".to_string(),
            scripts_dir: PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("python"),
            capture_stderr: true,
        }
    }
}

/// A `DerivationStep` implemented by a Python SymPy script.
pub struct PythonDerivationStep {
    step_id: &'static str,
    step_name: &'static str,
    script_name: &'static str,
    config: PythonBridgeConfig,
    expression_tree: std::sync::OnceLock<serde_json::Value>,
    symbolic_hash: std::sync::OnceLock<String>,
    assumptions: std::sync::OnceLock<Vec<String>>,
    transformation_rules: std::sync::OnceLock<Vec<String>>,
}

impl std::fmt::Debug for PythonDerivationStep {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("PythonDerivationStep")
            .field("step_id", &self.step_id)
            .field("step_name", &self.step_name)
            .field("script_name", &self.script_name)
            .finish()
    }
}

impl PythonDerivationStep {
    pub fn new(
        step_id: &'static str,
        step_name: &'static str,
        script_name: &'static str,
        config: PythonBridgeConfig,
    ) -> Self {
        Self {
            step_id,
            step_name,
            script_name,
            config,
            expression_tree: std::sync::OnceLock::new(),
            symbolic_hash: std::sync::OnceLock::new(),
            assumptions: std::sync::OnceLock::new(),
            transformation_rules: std::sync::OnceLock::new(),
        }
    }

    /// Execute the Python script and return the parsed JSON output.
    pub fn run_script(&self) -> Result<serde_json::Value> {
        let script_path = self.config.scripts_dir.join(self.script_name);
        let output = Command::new(&self.config.python_exe)
            .arg(&script_path)
            .output()
            .map_err(|e| BridgeError::ScriptFailed(e.to_string()))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(BridgeError::ScriptFailed(format!(
                "{} exited with {}: {}",
                script_path.display(),
                output.status,
                stderr
            )));
        }

        let stdout = String::from_utf8(output.stdout)
            .map_err(|e| BridgeError::ScriptFailed(e.to_string()))?;
        let json: serde_json::Value = serde_json::from_str(&stdout)?;
        Ok(json)
    }

    /// Load expression tree from a JSON file (offline mode).
    pub fn load_from_file(path: &std::path::Path) -> Result<serde_json::Value> {
        let text = std::fs::read_to_string(path)?;
        let json: serde_json::Value = serde_json::from_str(&text)?;
        Ok(json)
    }
}

impl DerivationStep for PythonDerivationStep {
    fn step_id(&self) -> &'static str { self.step_id }
    fn step_name(&self) -> &'static str { self.step_name }

    fn expression_tree(&self) -> serde_json::Value {
        self.expression_tree
            .get_or_init(|| self.run_script().expect("python script failed"))
            .clone()
    }

    fn assumptions(&self) -> Vec<String> {
        let tree = self.expression_tree();
        self.assumptions
            .get_or_init(|| {
                tree.get("assumptions")
                    .and_then(|v| v.as_array())
                    .map(|arr| arr.iter().filter_map(|v| v.as_str().map(String::from)).collect())
                    .unwrap_or_default()
            })
            .clone()
    }

    fn transformation_rules(&self) -> Vec<String> {
        let tree = self.expression_tree();
        self.transformation_rules
            .get_or_init(|| {
                tree.get("transformation_rules")
                    .and_then(|v| v.as_array())
                    .map(|arr| arr.iter().filter_map(|v| v.as_str().map(String::from)).collect())
                    .unwrap_or_default()
            })
            .clone()
    }

    fn symbolic_hash(&self) -> &str {
        let _ = self.expression_tree(); // ensure loaded
        self.symbolic_hash
            .get_or_init(|| {
                let tree = self.expression_tree();
                tree.get("symbolic_hash")
                    .and_then(|v| v.as_str())
                    .expect("symbolic_hash present in python output")
                    .to_string()
            })
            .as_str()
    }
}

/// Construct the five default Python-backed derivation steps.
pub fn default_python_steps(config: PythonBridgeConfig) -> Vec<Box<dyn DerivationStep>> {
    vec![
        Box::new(PythonDerivationStep::new(
            "step1_action",
            "Action Specification",
            "step1_action.py",
            config.clone(),
        )),
        Box::new(PythonDerivationStep::new(
            "step2_influence",
            "Influence Functional",
            "step2_influence.py",
            config.clone(),
        )),
        Box::new(PythonDerivationStep::new(
            "step3_langevin",
            "Langevin Equation",
            "step3_langevin.py",
            config.clone(),
        )),
        Box::new(PythonDerivationStep::new(
            "step4_power_spectrum",
            "Power Spectrum Solution",
            "step4_power_spectrum.py",
            config.clone(),
        )),
        Box::new(PythonDerivationStep::new(
            "step5_null_test",
            "Validation & Null Test",
            "step5_null_test.py",
            config,
        )),
    ]
}
