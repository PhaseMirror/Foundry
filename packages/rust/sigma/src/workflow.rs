use anyhow::Result;
use crate::transition::{State, TransitionRecord};
pub use multiplicity_common::task::{Workflow, Task};
use async_trait::async_trait;

#[async_trait]
pub trait WorkflowRunner {
    async fn run(&self, state: &mut State) -> Result<TransitionRecord>;
}

#[async_trait]
impl WorkflowRunner for Workflow {
    async fn run(&self, _state: &mut State) -> Result<TransitionRecord> {
        // Run tasks and update state
        Ok(TransitionRecord {
            id: "tx-placeholder".to_string(),
            workflow_name: self.name.clone(),
            status: "completed".to_string(),
        })
    }
}
