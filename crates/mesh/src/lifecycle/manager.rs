use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash)]
pub enum AgentLifecycleState {
    PendingApproval,
    Provisioned,
    Active,
    Suspended,
    RotatingCredentials,
    Orphaned,
    Decommissioning,
    Decommissioned,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ManagedAgent {
    pub agent_id: String,
    pub name: String,
    pub owner: String,
    pub state: AgentLifecycleState,
}

pub struct LifecycleManager {
    agents: Arc<RwLock<HashMap<String, ManagedAgent>>>,
}

impl LifecycleManager {
    pub fn new() -> Self {
        Self {
            agents: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub fn request_provisioning(&self, name: String, owner: String) -> ManagedAgent {
        let agent_id = format!("agent:{}", Uuid::new_v4().simple());
        let agent = ManagedAgent {
            agent_id: agent_id.clone(),
            name,
            owner,
            state: AgentLifecycleState::Provisioned,
        };
        let mut agents = self.agents.write().unwrap();
        agents.insert(agent_id, agent.clone());
        agent
    }
}
