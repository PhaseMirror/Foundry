use serde_json::Value;

pub struct HOXEscalationRecovery {
    escalations: Vec<Value>,
}

impl HOXEscalationRecovery {
    pub fn new() -> Self {
        Self {
            escalations: Vec::new(),
        }
    }

    pub fn escalate(&mut self, event: Value) {
        self.escalations.push(event);
    }

    pub fn get_escalations(&self) -> Vec<Value> {
        self.escalations.clone()
    }
}
