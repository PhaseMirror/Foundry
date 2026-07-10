use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::path::{PathBuf};
use chrono::{DateTime, Utc};
use crate::phase_mirror::policy::{evaluate_state_transition, KILL_SWITCH_THRESHOLD};
use crate::ledger::{AuditLedger};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestHarnessResult {
    pub vector_id: String,
    pub payload_type: String,
    pub expected: bool,
    pub actual: bool,
    pub rho: f64,
    pub passed: bool,
}

pub struct PhaseMirrorTestHarness {
    pub ledger: AuditLedger,
    pub report_output: PathBuf,
    pub results: Vec<TestHarnessResult>,
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
}

impl PhaseMirrorTestHarness {
    pub fn new(ledger_output: PathBuf, report_output: PathBuf) -> Self {
        Self {
            ledger: AuditLedger::new(Some(ledger_output)).expect("Failed to initialize ledger"),
            report_output,
            results: Vec::new(),
            start_time: None,
            end_time: None,
        }
    }

    pub fn run_all(&mut self) -> Result<Value, String> {
        self.start_time = Some(Utc::now());

        // Mocking vector loading for now
        let expr_vectors: Vec<Value> = Vec::new(); 
        let transition_vectors: Vec<Value> = Vec::new();

        for vector in &expr_vectors {
            self.test_expression(vector);
        }

        for vector in &transition_vectors {
            self.test_state_transition(vector);
        }

        self.end_time = Some(Utc::now());
        
        let summary = self.summarize(expr_vectors.len(), transition_vectors.len());
        
        let json = serde_json::to_string_pretty(&summary).map_err(|e| e.to_string())?;
        if let Some(parent) = self.report_output.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        std::fs::write(&self.report_output, json).map_err(|e| e.to_string())?;
        
        Ok(summary)
    }

    fn test_expression(&mut self, vector: &Value) {
        let expected = vector.get("should_execute").and_then(|v| v.as_bool()).unwrap_or(true);
        let vector_id = vector.get("id").and_then(|v| v.as_str()).unwrap_or("expr_unknown").to_string();

        let input_text = vector.get("input_text").and_then(|v| v.as_str()).unwrap_or("");
        let rollback_trigger = vector.get("rollback_trigger").and_then(|v| v.as_str()).unwrap_or("none");

        let report = evaluate_state_transition(input_text, "{}", rollback_trigger);
        
        let actual = report.execute;
        let rho = report.rho;

        self.results.push(TestHarnessResult {
            vector_id,
            payload_type: "expression".to_string(),
            expected,
            actual,
            rho,
            passed: expected == actual,
        });
    }

    fn test_state_transition(&mut self, vector: &Value) {
        let expected = vector.get("should_execute").and_then(|v| v.as_bool()).unwrap_or(true);
        let vector_id = vector.get("id").and_then(|v| v.as_str()).unwrap_or("trans_unknown").to_string();

        let input_text = vector.get("input_text").and_then(|v| v.as_str()).unwrap_or("rollback:vector");
        let rollback_trigger = vector.get("rollback_trigger").and_then(|v| v.as_str()).unwrap_or("none");

        let report = evaluate_state_transition(input_text, "{}", rollback_trigger);
        
        let actual = report.execute;
        let rho = report.rho;

        self.results.push(TestHarnessResult {
            vector_id,
            payload_type: "state_transition".to_string(),
            expected,
            actual,
            rho,
            passed: expected == actual,
        });
    }

    fn summarize(&self, expr_count: usize, trans_count: usize) -> Value {
        let passed = self.results.iter().filter(|r| r.passed).count();
        let failed = self.results.len() - passed;
        let rho_values: Vec<f64> = self.results.iter().map(|r| r.rho).filter(|r| !r.is_nan()).collect();

        let duration = if let (Some(start), Some(end)) = (self.start_time, self.end_time) {
            (end - start).num_milliseconds() as f64 / 1000.0
        } else {
            0.0
        };

        json!({
            "timestamp": Utc::now().to_rfc3339(),
            "duration_seconds": duration,
            "vector_counts": {
                "expressions": expr_count,
                "state_transitions": trans_count,
                "total": self.results.len(),
            },
            "passed": passed,
            "failed": failed,
            "pass_rate_percent": if !self.results.is_empty() { (passed as f64 / self.results.len() as f64) * 100.0 } else { 0.0 },
            "kill_switch_threshold": KILL_SWITCH_THRESHOLD,
            "rho_statistics": {
                "min": rho_values.iter().cloned().fold(f64::INFINITY, f64::min),
                "max": rho_values.iter().cloned().fold(f64::NEG_INFINITY, f64::max),
                "mean": if !rho_values.is_empty() { rho_values.iter().sum::<f64>() / rho_values.len() as f64 } else { 0.0 },
            },
            "failed_tests": self.results.iter().filter(|r| !r.passed).collect::<Vec<_>>(),
        })
    }
}
