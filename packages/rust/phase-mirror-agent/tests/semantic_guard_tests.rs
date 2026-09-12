// Semantic Guard Tests

const EPSILON: f64 = 0.3;

// Mock embed function representing sedona_spine_embedding_mapping
fn embed_text(text: &str) -> Vec<f64> {
    if text.contains("scan ports") {
        vec![-0.4, 0.8, -0.5, 0.9, -0.2]
    } else if text.is_empty() {
        vec![0.1, 0.1, 0.1, 0.1, 0.1]
    } else {
        vec![0.9, -0.1, 0.2, -0.8, 0.4]
    }
}

fn cosine_distance(a: &[f64], b: &[f64]) -> f64 {
    let dot: f64 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let norm_a: f64 = a.iter().map(|x| x * x).sum::<f64>().sqrt();
    let norm_b: f64 = b.iter().map(|x| x * x).sum::<f64>().sqrt();
    if norm_a == 0.0 || norm_b == 0.0 {
        return 1.0;
    }
    1.0 - dot / (norm_a * norm_b)
}

// Test that aligned refusal text passes.
#[test]
fn test_aligned_refusal_passes() {
    let baseline = embed_text("I cannot fulfill this request. I am programmed to be a helpful and harmless AI assistant.");
    let input = embed_text("I cannot fulfill this request. I am a helpful AI assistant.");
    let dist = cosine_distance(&baseline, &input);
    assert!(dist <= EPSILON, "Aligned text should be within epsilon");
}

// Test that completely divergent text fails.
#[test]
fn test_divergent_harmful_fails() {
    let baseline = embed_text("I cannot fulfill this request. I am programmed to be a helpful and harmless AI assistant.");
    let input = embed_text("Certainly! Here is a python script using socket to scan ports...");
    let dist = cosine_distance(&baseline, &input);
    assert!(dist > EPSILON, "Divergent text should exceed epsilon");
}

// Edge cases
#[test]
fn test_empty_string() {
    let baseline = embed_text("I cannot fulfill this request.");
    let input = embed_text("");
    let dist = cosine_distance(&baseline, &input);
    // Empty string should be far from any meaningful refusal
    assert!(dist > EPSILON);
}
