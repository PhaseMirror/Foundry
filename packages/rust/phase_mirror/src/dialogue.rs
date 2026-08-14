use serde::{Deserialize, Serialize};

#[derive(Default, Serialize, Deserialize, Clone)]
pub struct DialogueFrame {
    // Placeholder for the actual CNL dialogue frame
    pub utterances: Vec<String>,
}
