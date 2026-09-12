//! LLM drafting assist — strictly off the ALP execution path (ADR-101).
//!
//! An LLM may *propose* policy text, but its output is never admissible.
//! It must be re-normalized through the CNL compiler before it can become
//! an ALP contract. [`LlmDraft::normalize`] is the only sanctioned bridge
//! from an LLM token stream into the contract plane; it routes through
//! [`crate::cnl::CnlCompiler`] and never returns an action directly.
//!
//! Structural proof: `normalize(draft) == CnlCompiler::parse(to_cnl(draft.raw))`
//! (cf. `proof_llm_normalize_routes_through_cnl`).

use crate::cnl::{CnlCompiler, CnlError};
use crate::AlpPolicy;
use serde::{Deserialize, Serialize};

/// An untrusted natural-language draft produced by an LLM.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LlmDraft {
    pub raw: String,
}

impl LlmDraft {
    /// The ONLY sanctioned bridge from LLM output into the contract plane.
    ///
    /// Deterministic framing strip ([`LlmDraft::to_cnl`]) followed by the
    /// CNL compiler. There is no alternate admission channel.
    pub fn normalize(&self) -> Result<AlpPolicy, CnlError> {
        let cnl = self.to_cnl();
        CnlCompiler::parse(&cnl)
    }

    /// Deterministic framing strip: extract the fenced CNL block (if any), then
    /// reduce it to the region beginning at the first `policy` header. Total
    /// function (never panics, never fails) — this is what keeps `normalize`
    /// pure.
    pub fn to_cnl(&self) -> String {
        let region = extract_fenced_region(&self.raw).unwrap_or_else(|| self.raw.clone());
        let mut started = false;
        let mut kept: Vec<&str> = Vec::new();
        for line in region.lines() {
            if !started && line.trim().starts_with("policy") {
                started = true;
            }
            if started {
                kept.push(line);
            }
        }
        if started {
            kept.join("\n")
        } else {
            region.trim().to_string()
        }
    }
}

/// Extract the first ``` fenced block's inner content. Returns `None` when the
/// draft has no code fence (treated as plain CNL).
fn extract_fenced_region(s: &str) -> Option<String> {
    let mut inside = false;
    let mut out = String::with_capacity(s.len());
    for line in s.lines() {
        let t = line.trim_start();
        if t.starts_with("```") {
            if inside {
                return Some(out);
            }
            inside = true;
            continue;
        }
        if inside {
            out.push_str(line);
            out.push('\n');
        }
    }
    if inside {
        Some(out)
    } else {
        None
    }
}
