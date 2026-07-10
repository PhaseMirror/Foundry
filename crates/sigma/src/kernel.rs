use anyhow::Result;
use crate::workflow::{Workflow, WorkflowRunner};
use crate::transition::{State, TransitionRecord};
use multiplicity_common::GitLedger;
use std::sync::Arc;
use tokio::sync::Mutex;

pub struct SigmaKernel {
    pub ledger: Arc<GitLedger>,
    pub current_state: Arc<Mutex<State>>,
}

impl SigmaKernel {
    pub fn new(ledger: GitLedger) -> Self {
        Self {
            ledger: Arc::new(ledger),
            current_state: Arc::new(Mutex::new(State::default())),
        }
    }

    pub async fn execute_workflow(&self, workflow: Workflow) -> Result<TransitionRecord> {
        tracing::info!("Executing workflow: {}", workflow.name);
        
        let mut state = self.current_state.lock().await;
        let record = workflow.run(&mut state).await?;
        
        // Record transition in ledger if needed
        self.ledger.commit_proposal(
            &format!("sig-{}", record.id),
            serde_json::to_value(&record)?,
            &format!("Sigma transition: {}", workflow.name)
        )?;
        
        Ok(record)
    }
}
