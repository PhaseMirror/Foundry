use serde_json::Value;

pub struct HOXFeedbackCapture {
    feedback_records: Vec<Value>,
}

impl HOXFeedbackCapture {
    pub fn new() -> Self {
        Self {
            feedback_records: Vec::new(),
        }
    }

    pub fn capture(&mut self, decision: Value) {
        if let Some(promoted) = decision.get("promoted").and_then(|v| v.as_bool()) {
            if promoted {
                self.feedback_records.push(decision);
            }
        }
    }

    pub fn get_feedback(&self) -> Vec<Value> {
        self.feedback_records.clone()
    }
}
