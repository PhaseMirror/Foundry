use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::sync::Arc;
use uuid::Uuid;
use crate::self_modification::kill_switch::KillSwitch;
use crate::self_modification::proposal::{ModificationProposal, ModificationTarget};
use crate::self_modification::watchdog::GovernanceWatchdog;
use crate::self_modification::lobian_guard::enforce_lobian_guard;
use crate::self_modification::validation_gates::{ParameterSnapshot, ModificationLedger};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecutionResult {
    pub status: String, // "committed" | "rolled_back" | "blocked"
    pub proposal_id: String,
    pub pre_snapshot_id: Option<String>,
    pub post_snapshot_id: Option<String>,
    pub reason: String,
    pub watchdog_checks: usize,
}

pub struct SelfModificationDaemon {
    parameters: HashMap<String, Value>,
    ledger: ModificationLedger,
    kill_switch: Arc<KillSwitch>,
    spectral_fn: Option<Arc<dyn Fn(&HashMap<String, Value>) -> f64 + Send + Sync>>,
    watchdog_window: f64,
    safety_threshold: f64,
}

impl SelfModificationDaemon {
    pub fn new(
        initial_parameters: HashMap<String, Value>,
        spectral_fn: Option<Arc<dyn Fn(&HashMap<String, Value>) -> f64 + Send + Sync>>,
        watchdog_window: f64,
        safety_threshold: f64,
    ) -> Self {
        let mut ledger = ModificationLedger::new();
        let genesis = ParameterSnapshot::capture("genesis", &initial_parameters, None);
        ledger.append(genesis, None);

        Self {
            parameters: initial_parameters,
            ledger,
            kill_switch: Arc::new(KillSwitch::new()),
            spectral_fn,
            watchdog_window,
            safety_threshold,
        }
    }

    pub fn get_parameters(&self) -> HashMap<String, Value> {
        self.parameters.clone()
    }

    pub fn get_kill_switch(&self) -> Arc<KillSwitch> {
        self.kill_switch.clone()
    }

    pub fn current_hash(&self) -> String {
        self.ledger.head_hash().unwrap_or_default()
    }

    pub async fn execute(
        &mut self,
        proposal: &ModificationProposal,
        simulation_cleared: bool,
        human_approved: bool,
        boundary_ok: bool,
        legitimacy_ok: bool,
        playbook_ok: bool,
        csl_ok: bool,
    ) -> ExecutionResult {
        // Phase 0: Kill switch
        if self.kill_switch.is_armed() {
            return ExecutionResult {
                status: "blocked".to_string(),
                proposal_id: proposal.proposal_id.clone(),
                pre_snapshot_id: None,
                post_snapshot_id: None,
                reason: format!("Kill switch armed: {}", self.kill_switch.state().reason),
                watchdog_checks: 0,
            };
        }

        // Phase 1: Validation
        if let Err(e) = enforce_lobian_guard(proposal) {
            return ExecutionResult {
                status: "blocked".to_string(),
                proposal_id: proposal.proposal_id.clone(),
                pre_snapshot_id: None,
                post_snapshot_id: None,
                reason: format!("Löbian guard violation: {}", e),
                watchdog_checks: 0,
            };
        }

        if proposal.is_stale(&self.current_hash()) {
            return ExecutionResult {
                status: "blocked".to_string(),
                proposal_id: proposal.proposal_id.clone(),
                pre_snapshot_id: None,
                post_snapshot_id: None,
                reason: "Proposal is stale — snapshot hash mismatch".to_string(),
                watchdog_checks: 0,
            };
        }

        if proposal.requires_human_approval() && !human_approved {
            return ExecutionResult {
                status: "blocked".to_string(),
                proposal_id: proposal.proposal_id.clone(),
                pre_snapshot_id: None,
                post_snapshot_id: None,
                reason: "Human approval required but not provided".to_string(),
                watchdog_checks: 0,
            };
        }

        // Phase 2: Simulation
        if proposal.simulation_required && !simulation_cleared {
            return ExecutionResult {
                status: "blocked".to_string(),
                proposal_id: proposal.proposal_id.clone(),
                pre_snapshot_id: None,
                post_snapshot_id: None,
                reason: "Simulation clearance required but not provided".to_string(),
                watchdog_checks: 0,
            };
        }

        // Phase 3: Gates
        if !boundary_ok || !legitimacy_ok || !playbook_ok || !csl_ok {
            return ExecutionResult {
                status: "blocked".to_string(),
                proposal_id: proposal.proposal_id.clone(),
                pre_snapshot_id: None,
                post_snapshot_id: None,
                reason: "One or more validation gates rejected the proposal".to_string(),
                watchdog_checks: 0,
            };
        }

        // Phase 4: Execution
        let pre_snap_id = format!("pre-{}-{}", proposal.proposal_id, &Uuid::new_v4().to_string()[..8]);
        let pre_snap = ParameterSnapshot::capture(&pre_snap_id, &self.parameters, Some(proposal.proposal_id.clone()));
        self.ledger.append(pre_snap.clone(), Some(proposal.clone()));

        self.apply_delta(proposal);

        let post_snap_id = format!("post-{}-{}", proposal.proposal_id, &Uuid::new_v4().to_string()[..8]);
        let post_snap = ParameterSnapshot::capture(&post_snap_id, &self.parameters, Some(proposal.proposal_id.clone()));

        if self.kill_switch.is_armed() {
            self.revert_to(&pre_snap);
            return ExecutionResult {
                status: "rolled_back".to_string(),
                proposal_id: proposal.proposal_id.clone(),
                pre_snapshot_id: Some(pre_snap_id),
                post_snapshot_id: None,
                reason: "Kill switch armed during execution — rolled back".to_string(),
                watchdog_checks: 0,
            };
        }

        let mut watchdog = GovernanceWatchdog::new(
            &self.kill_switch,
            self.spectral_fn.as_ref().map(|f| {
                let f_clone = f.clone();
                let b: Box<dyn Fn(&HashMap<String, Value>) -> f64 + Send + Sync> = Box::new(move |p| f_clone(p));
                b
            }),
            5.0,
            self.watchdog_window,
            self.safety_threshold,
        );

        let checks = watchdog.run_monitoring(&self.parameters, false).await;

        if !watchdog.all_passed() {
            self.revert_to(&pre_snap);
            return ExecutionResult {
                status: "rolled_back".to_string(),
                proposal_id: proposal.proposal_id.clone(),
                pre_snapshot_id: Some(pre_snap_id),
                post_snapshot_id: None,
                reason: "Watchdog detected spectral radius violation — rolled back".to_string(),
                watchdog_checks: checks.len(),
            };
        }

        self.ledger.append(post_snap, None);
        ExecutionResult {
            status: "committed".to_string(),
            proposal_id: proposal.proposal_id.clone(),
            pre_snapshot_id: Some(pre_snap_id),
            post_snapshot_id: Some(post_snap_id),
            reason: String::new(),
            watchdog_checks: checks.len(),
        }
    }

    fn apply_delta(&mut self, proposal: &ModificationProposal) {
        if proposal.target == ModificationTarget::SourceCode {
            // Source code change logic (simplified)
        } else {
            if let Some(delta_obj) = proposal.proposed_delta.as_object() {
                for (key, value) in delta_obj {
                    self.parameters.insert(key.clone(), value.clone());
                }
            }
        }
    }

    fn revert_to(&mut self, snapshot: &ParameterSnapshot) {
        self.parameters = snapshot.parameters.clone();
    }
}
