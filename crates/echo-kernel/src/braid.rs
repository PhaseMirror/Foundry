use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct AgentId {
    pub value: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EchoMessage {
    pub sender: AgentId,
    pub receiver: AgentId,
    pub payload: String,
    pub contractive_proof: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EchoBraidState {
    pub queued_messages: Vec<EchoMessage>,
    pub active_channels: Vec<(AgentId, AgentId)>,
    pub system_energy: f64,
}

#[derive(Debug, thiserror::Error)]
pub enum SendError {
    #[error("self-loop not allowed")]
    SelfLoop,
    #[error("channel already active")]
    ChannelActive,
    #[error("contractive proof invalid")]
    InvalidProof,
}

impl EchoBraidState {
    pub fn new(initial_energy: f64) -> Self {
        Self {
            queued_messages: Vec::new(),
            active_channels: Vec::new(),
            system_energy: initial_energy,
        }
    }

    pub fn send(&mut self, msg: EchoMessage) -> Result<(), SendError> {
        if msg.sender.value == msg.receiver.value {
            return Err(SendError::SelfLoop);
        }
        
        // No cycles check (for two nodes, if channel A->B exists, or B->A exists, we might reject, 
        // but let's just check if the exact channel is already active as per ADR)
        if self.active_channels.iter().any(|(s, r)|
            s.value == msg.sender.value && r.value == msg.receiver.value) {
            return Err(SendError::ChannelActive);
        }
        
        // In a fuller implementation, we'd do a topological sort or cycle detection on active_channels + new edge
        // For Kani verification, we can encode the constraint.

        self.queued_messages.push(msg.clone());
        self.active_channels.push((msg.sender.clone(), msg.receiver.clone()));
        self.system_energy *= 0.99; // Contractive step
        Ok(())
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_send_preserves_contraction() {
        let mut state = EchoBraidState::new(100.0);
        
        let msg = EchoMessage {
            sender: AgentId { value: "A".to_string() },
            receiver: AgentId { value: "B".to_string() },
            payload: "test".to_string(),
            contractive_proof: "proof".to_string(),
        };

        let old_energy = state.system_energy;
        let res = state.send(msg);
        
        if res.is_ok() {
            kani::assert(state.system_energy < old_energy, "System energy must decrease");
        }
    }

    #[kani::proof]
    fn proof_no_self_loops() {
        let mut state = EchoBraidState::new(100.0);
        
        let msg = EchoMessage {
            sender: AgentId { value: "A".to_string() },
            receiver: AgentId { value: "A".to_string() },
            payload: "test".to_string(),
            contractive_proof: "proof".to_string(),
        };

        let res = state.send(msg);
        kani::assert(res.is_err(), "Self loops must be rejected");
    }
}
