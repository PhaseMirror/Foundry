use pirtm_stdlib::prelude::*;
use pirtm_registry::{Registry, RegistryReceipt};
use pirtm_dist::{Distributor, InstallReceipt};
use pirtm_invariants::PhaseMirrorInvariants;
use std::fs::OpenOptions;
use std::io::Write;
use chrono::Utc;
use serde::Serialize;
use sha2::{Sha256, Digest};

pub mod cnl;

#[derive(Serialize, Debug)]
pub struct WorkflowReceipt {
    pub package_name: String,
    pub timestamp: String,
    pub publish_status: String,
    pub install_status: String,
    pub run_status: String,
    pub overall_status: String,
    pub pweh: String,
}

pub struct WorkflowOrchestrator;

impl WorkflowOrchestrator {
    /// Executes the full end-to-end governed workflow: Validate -> Publish -> Install -> Run
    pub fn deploy_application(name: &str, word: &MOCWord) -> Result<WorkflowReceipt, String> {
        let mut pweh_hasher = Sha256::new();
        pweh_hasher.update(word.to_string().as_bytes());
        let pweh = format!("{:x}", pweh_hasher.finalize());

        // 1. REPL / Design Time Validation (Invariants)
        if let Err(e) = PhaseMirrorInvariants::enforce_all(word) {
            let msg = format!("Workflow Aborted: REPL Validation Failed - {}", e);
            Self::log_workflow(name, &msg, &pweh);
            return Err(msg);
        }

        // 2. Governed Publish to Registry
        let registry_receipt = match Registry::publish(name, word) {
            Ok(receipt) => receipt,
            Err(e) => {
                let msg = format!("Workflow Aborted: Publish Failed - {}", e);
                Self::log_workflow(name, &msg, &pweh);
                return Err(msg);
            }
        };

        // 3. Governed Distribution / Install
        let install_receipt = match Distributor::install(name, word) {
            Ok(receipt) => receipt,
            Err(e) => {
                let msg = format!("Workflow Aborted: Install Failed - {}", e);
                Self::log_workflow(name, &msg, &pweh);
                return Err(msg);
            }
        };

        // 4. Runtime Execution Environment
        let (c, r1, r2, r3) = EvalNF::evaluate(word);
        let rsc = Resonance::calculate(r1, r2, r3);
        let run_status = format!("EXECUTED: c={:.4}, Rsc={:.4}", c, rsc);

        let final_receipt = WorkflowReceipt {
            package_name: name.to_string(),
            timestamp: Utc::now().to_rfc3339(),
            publish_status: registry_receipt.status,
            install_status: install_receipt.status,
            run_status: run_status.clone(),
            overall_status: "SUCCESS".to_string(),
            pweh: pweh.clone(),
        };

        Self::log_workflow(name, "SUCCESS", &pweh);
        Ok(final_receipt)
    }

    fn log_workflow(name: &str, status: &str, pweh: &str) {
        if let Ok(mut file) = OpenOptions::new().create(true).append(true).open("workflow_ledger.jsonl") {
            let entry = serde_json::json!({
                "package_name": name,
                "timestamp": Utc::now().to_rfc3339(),
                "status": status,
                "pweh": pweh,
                "stage": "END_TO_END"
            });
            let _ = writeln!(file, "{}", entry.to_string());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_full_lawful_workflow() {
        let ensemble = Ap(2) + Ap(3);
        let result = WorkflowOrchestrator::deploy_application("lawful_app", &ensemble);
        assert!(result.is_ok());
        let receipt = result.unwrap();
        assert_eq!(receipt.overall_status, "SUCCESS");
        assert_eq!(receipt.publish_status, "PUBLISHED");
        assert_eq!(receipt.install_status, "INSTALLED");
        assert!(receipt.run_status.contains("EXECUTED"));
    }
    
    #[test]
    fn test_workflow_halt_on_invariants() {
        let ensemble = Ap(1); // Fails Phase Mirror immediately
        let result = WorkflowOrchestrator::deploy_application("unlawful_app", &ensemble);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("REPL Validation Failed"));
    }
}
