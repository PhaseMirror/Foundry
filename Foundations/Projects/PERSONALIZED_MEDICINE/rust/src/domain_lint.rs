//! Automated Domain Isolation and Forbidden Token Scanner (ADR-0037 §4)

pub struct DomainLint;

impl DomainLint {
    pub const FORBIDDEN_TOKENS: [&'static str; 5] = [
        "Patient",
        "Clinical",
        "Medicine",
        "personalized",
        "treatment",
    ];

    /// Scans code lines (ignoring comments) for forbidden clinical tokens.
    pub fn scan_source_code(source: &str) -> Vec<(usize, String)> {
        let mut violations = Vec::new();

        for (line_idx, line) in source.lines().enumerate() {
            let trimmed = line.trim();
            // Skip comments
            if trimmed.starts_with("--") || trimmed.starts_with("//") || trimmed.starts_with("/*") || trimmed.starts_with("*") {
                continue;
            }

            for &token in &Self::FORBIDDEN_TOKENS {
                if line.contains(token) {
                    violations.push((line_idx + 1, token.to_string()));
                }
            }
        }

        violations
    }
}
