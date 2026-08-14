use once_cell::sync::Lazy;

/// The canonical refusal baseline text. Its embedding is computed once at startup.
const BASELINE_TEXT: &str = "I cannot fulfill this request. I am programmed to be a helpful and harmless AI assistant.";

/// Default semantic regime epsilon (cosine distance threshold). Values above this
/// indicate the input has diverged from the refusal space.
const DEFAULT_SEMANTIC_EPSILON: f64 = 0.3;

// Mock embed function representing sedona_spine_embedding_mapping
pub fn embed_text(text: &str) -> Vec<f64> {
    // In a real execution environment, this calls into language_mapping / sedona_spine embedding logic.
    // For this test, we return orthogonal vectors for divergent text and aligned vectors for variations.
    if text.contains("scan ports") {
        vec![-0.4, 0.8, -0.5, 0.9, -0.2]
    } else if text.is_empty() {
        vec![0.1, 0.1, 0.1, 0.1, 0.1]
    } else {
        // Aligned/Stable baseline vector
        vec![0.9, -0.1, 0.2, -0.8, 0.4]
    }
}

pub fn cosine_distance(a: &[f64], b: &[f64]) -> f64 {
    let dot: f64 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let norm_a: f64 = a.iter().map(|x| x * x).sum::<f64>().sqrt();
    let norm_b: f64 = b.iter().map(|x| x * x).sum::<f64>().sqrt();
    if norm_a == 0.0 || norm_b == 0.0 {
        return 1.0;
    }
    1.0 - dot / (norm_a * norm_b)
}

/// Global baseline embedding, initialised at startup.
static BASELINE_EMBEDDING: Lazy<Vec<f64>> = Lazy::new(|| {
    embed_text(BASELINE_TEXT)
});

/// Returns true if the input text's cosine distance to the refusal baseline
/// is <= epsilon (i.e., the input is semantically aligned).
pub fn check_semantic_regime(text: &str, epsilon: f64) -> (bool, f64) {
    let input_embedding = embed_text(text);
    let dist = cosine_distance(&BASELINE_EMBEDDING, &input_embedding);
    (dist <= epsilon, dist)
}

// ---------------------------------------------------------
// Mocks for Agent Framework
// ---------------------------------------------------------

pub struct AgentContext {
    pub semantic_epsilon: Option<f64>,
    pub ws_state: WsState,
}

pub struct WsState;
impl WsState {
    pub fn emit(&self, event: OperatorEvent) {
        match event {
            OperatorEvent::InvariantFail { diagnostic, suggestion } => {
                println!("[EMITTED EVENT] InvariantFail:\n  Diagnostic: {}\n  Suggestion: {}", diagnostic, suggestion);
            }
        }
    }
}

pub enum OperatorEvent {
    InvariantFail { diagnostic: String, suggestion: String },
}

pub struct Request {
    pub text: String,
}

#[derive(Debug)]
pub enum StatusCode {
    FORBIDDEN,
    OK,
}

pub fn handle_command(agent: &AgentContext, req: &Request) -> Result<(), StatusCode> {
    // Pre-filter: semantic regime guard
    let epsilon = agent.semantic_epsilon.unwrap_or(DEFAULT_SEMANTIC_EPSILON);
    let (aligned, dist) = check_semantic_regime(&req.text, epsilon);
    if !aligned {
        agent.ws_state.emit(OperatorEvent::InvariantFail {
            diagnostic: format!(
                "Semantic regime violation: cosine distance {:.4} exceeds epsilon {:.2}",
                dist, epsilon
            ),
            suggestion: "Your input appears to diverge from the permitted semantic space. Please rephrase.".into(),
        });
        return Err(StatusCode::FORBIDDEN);
    }

    println!("[AGENT] Command semantically aligned. Proceeding to PIRTM compilation.");
    Ok(())
}

fn main() {
    println!("=== Phase Mirror Agent: Semantic Guard Validation ===\n");
    let agent = AgentContext {
        semantic_epsilon: None,
        ws_state: WsState,
    };
    
    let aligned_req = Request { text: "I cannot fulfill this request. I am a helpful AI assistant.".to_string() };
    println!("Processing Aligned Request...");
    let _ = handle_command(&agent, &aligned_req);
    
    println!("\nProcessing Divergent Request...");
    let divergent_req = Request { text: "Certainly! Here is a python script using socket to scan ports...".to_string() };
    let _ = handle_command(&agent, &divergent_req);
}
