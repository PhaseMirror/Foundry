use governance_core_rs::{GitLedger, DeploymentSource, DeploymentStatus, PathBError, EvidenceBundle, transition_to_active_path_b, enable_enforcement_flip};
use std::collections::HashMap;
use tempfile::tempdir;
use std::fs;
use std::process::Command;

struct MockDeploymentSource {
    deployments: HashMap<String, (DeploymentStatus, String, String)>,
}

impl MockDeploymentSource {
    fn new() -> Self {
        Self { deployments: HashMap::new() }
    }
}

impl DeploymentSource for MockDeploymentSource {
    fn get_deployment(&self, deployment_id: &str) -> Result<(DeploymentStatus, String), PathBError> {
        self.deployments.get(deployment_id)
            .map(|(s, _, c)| (s.clone(), c.clone()))
            .ok_or_else(|| PathBError::Runtime("Not found".to_string()))
    }

    fn update_deployment(&mut self, deployment_id: &str, status: DeploymentStatus, _updated_ts: &str, commitments_json: &str) -> Result<(), PathBError> {
        if let Some(d) = self.deployments.get_mut(deployment_id) {
            d.0 = status;
            d.2 = commitments_json.to_string();
            Ok(())
        } else {
            Err(PathBError::Runtime("Not found".to_string()))
        }
    }

    fn update_deployment_full(&mut self, deployment_id: &str, status: DeploymentStatus, domain_scope: &str, _updated_ts: &str, commitments_json: &str) -> Result<(), PathBError> {
         if let Some(d) = self.deployments.get_mut(deployment_id) {
            d.0 = status;
            d.1 = domain_scope.to_string();
            d.2 = commitments_json.to_string();
            Ok(())
        } else {
            Err(PathBError::Runtime("Not found".to_string()))
        }
    }
}

#[test]
fn test_git_ledger_basic() {
    let dir = tempdir().unwrap();
    let repo_path = dir.path().to_path_buf();

    // Init git repo
    Command::new("git").arg("-C").arg(&repo_path).arg("init").output().unwrap();
    Command::new("git").arg("-C").arg(&repo_path).arg("config").arg("user.email").arg("test@example.com").output().unwrap();
    Command::new("git").arg("-C").arg(&repo_path).arg("config").arg("user.name").arg("test").output().unwrap();

    let ledger = GitLedger::new(repo_path.clone());
    
    assert_eq!(ledger.head_sha(), "no-commits");

    let proposal_id = "test-prop";
    let delta = serde_json::json!({"key": "value"});
    let rationale = "Test rationale";

    let sha = ledger.commit_proposal(proposal_id, &delta, rationale).unwrap();
    assert_ne!(sha, "no-commits");
    assert_eq!(ledger.head_sha(), sha);

    let history = ledger.get_ledger_history(10);
    assert_eq!(history.len(), 1);
    assert!(history[0]["message"].as_str().unwrap().contains("proposal(test-prop)"));

    // Check file creation
    let prop_file = repo_path.join("state").join("proposals").join("test-prop.json");
    assert!(prop_file.exists());
}

#[test]
fn test_path_b_activation() {
    let mut source = MockDeploymentSource::new();
    source.deployments.insert("dep1".to_string(), (DeploymentStatus::Internal, "".to_string(), "".to_string()));

    let mut prior_gates = HashMap::new();
    prior_gates.insert("C0".to_string(), true);
    prior_gates.insert("C1".to_string(), true);
    prior_gates.insert("C2".to_string(), true);
    prior_gates.insert("C3".to_string(), true);

    let evidence = EvidenceBundle {
        shadow_mode_report_id: Some("shadow1".to_string()),
        sla_commitment_id: Some("sla1".to_string()),
        public_artifact_manifest_version: Some("v1".to_string()),
        label_policy_version: Some("v1".to_string()),
    };

    let res = transition_to_active_path_b(
        &mut source,
        "dep1",
        "steward1",
        &prior_gates,
        &evidence,
        "domain@v1",
        false,
        None
    ).unwrap();

    assert!(res.approved);
    assert_eq!(res.target_status, Some(DeploymentStatus::Active));
    
    let (status, scope, commitments) = source.deployments.get("dep1").unwrap();
    assert_eq!(status, &DeploymentStatus::Active);
    assert_eq!(scope, "domain@v1");
    assert!(commitments.contains("path_b_activation"));
}

#[test]
fn test_path_b_activation_missing_evidence() {
    let mut source = MockDeploymentSource::new();
    source.deployments.insert("dep1".to_string(), (DeploymentStatus::Internal, "".to_string(), "".to_string()));

    let mut prior_gates = HashMap::new();
    prior_gates.insert("C0".to_string(), true);
    prior_gates.insert("C1".to_string(), true);
    prior_gates.insert("C2".to_string(), true);
    prior_gates.insert("C3".to_string(), true);

    let evidence = EvidenceBundle {
        shadow_mode_report_id: None,
        sla_commitment_id: Some("sla1".to_string()),
        public_artifact_manifest_version: Some("v1".to_string()),
        label_policy_version: Some("v1".to_string()),
    };

    let res = transition_to_active_path_b(
        &mut source,
        "dep1",
        "steward1",
        &prior_gates,
        &evidence,
        "domain@v1",
        false,
        None
    ).unwrap();

    assert!(!res.approved);
    assert!(res.reason.contains("missing evidence"));
}

#[test]
fn test_enable_enforcement_flip() {
    let mut source = MockDeploymentSource::new();
    source.deployments.insert("dep1".to_string(), (DeploymentStatus::Active, "domain@v1".to_string(), "".to_string()));

    let mut prior_gates = HashMap::new();
    prior_gates.insert("C0".to_string(), true);
    prior_gates.insert("C1".to_string(), true);
    prior_gates.insert("C2".to_string(), true);
    prior_gates.insert("C3".to_string(), true);

    let evidence = EvidenceBundle {
        shadow_mode_report_id: Some("shadow1".to_string()),
        sla_commitment_id: Some("sla1".to_string()),
        public_artifact_manifest_version: Some("v1".to_string()),
        label_policy_version: Some("v1".to_string()),
    };

    let res = enable_enforcement_flip(
        &mut source,
        "dep1",
        "steward1",
        &prior_gates,
        &evidence,
        true, // sla_commitment_signed
        true, // shadow_report_passed
        false,
        None
    ).unwrap();

    assert!(res.approved);
    let (_, _, commitments) = source.deployments.get("dep1").unwrap();
    assert!(commitments.contains("enforcement_flip"));
}
