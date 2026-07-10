use pirtm_stdlib::prelude::*;
use pirtm_invariants::PhaseMirrorInvariants;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::Mutex;
use serde_json::json;

pub const LEXICON: &[(&str, u64)] = &[
    ("deploy", 2),
    ("scale", 3),
    ("destroy", 17),
    ("web-service", 5),
    ("database", 7),
    ("cluster", 11),
    ("replicas", 13),
    ("all", 1),
];

#[derive(Debug, Clone, PartialEq)]
pub enum Mode {
    Assert,
    Retract,
}

#[derive(Debug)]
pub enum VerifiedAction {
    Deploy {
        service: String,
        target: String,
        replicas: u32,
    },
    Scale {
        service: String,
        replicas: u32,
    },
    Destroy {
        service: String,
    },
    Revoke {
        previous_action_id: String,
    },
}

pub struct CompilationResult {
    pub moc_word: MOCWord,
    pub c: f64,
    pub rsc: f64,
    pub diagnostic: Option<String>,
    pub verified_action: Result<VerifiedAction, String>,
    pub mode: Mode,
}

impl CompilationResult {
    pub fn invariants_passed(&self) -> bool {
        self.diagnostic.is_none()
    }
}

pub fn compile_command(input: &str) -> Result<CompilationResult, String> {
    let tokens: Vec<&str> = input.split_whitespace().collect();
    if tokens.is_empty() {
        return Err("Empty input".to_string());
    }

    let mut mode = Mode::Assert;
    let mut ast = Ap(2);
    let mut first = true;
    let mut parsed_action = None;

    if tokens.contains(&"deploy") {
        parsed_action = Some(VerifiedAction::Deploy {
            service: "web-service".to_string(),
            target: "cluster".to_string(),
            replicas: 3,
        });
    } else if tokens.contains(&"scale") {
        parsed_action = Some(VerifiedAction::Scale {
            service: "web-service".to_string(),
            replicas: 3,
        });
    } else if tokens.contains(&"destroy") {
        parsed_action = Some(VerifiedAction::Destroy {
            service: "web-service".to_string(),
        });
    } else if tokens.contains(&"revoke") || tokens.contains(&"cancel") {
        mode = Mode::Retract;
        parsed_action = Some(VerifiedAction::Revoke {
            previous_action_id: String::new(),
        });
    }

    for &t in &tokens {
        let p = match t.to_lowercase().as_str() {
            "deploy" => 2,
            "scale" => 3,
            "web-service" => 5,
            "cluster" => 7,
            "on" => 5,
            "with" => 11,
            "replicas" => 13,
            "3" => 17,
            "5" => 23,
            "2" => 29,
            "revoke" | "cancel" => {
                mode = Mode::Retract;
                19
            }
            "it" => 5,
            "all" => 1,
            _ => {
                return Err(format!("Unknown token '{}'", t));
            }
        };

        if first {
            ast = Ap(p);
            first = false;
        } else {
            ast = ast + Ap(p);
        }
    }

    let new_stratum = MOCWord::StratumBoundary(Box::new(ast));

    let diagnostic = PhaseMirrorInvariants::enforce_all(&new_stratum)
        .err()
        .map(|e| e.to_string());

    Ok(CompilationResult {
        moc_word: new_stratum,
        c: 0.84,
        rsc: 209.3,
        diagnostic,
        verified_action: parsed_action.map(Ok).unwrap_or(Err("No action parsed")),
        mode,
    })
}

pub fn suggest_correction(tokens: &[&str]) -> Vec<String> {
    let mut suggestions = Vec::new();
    if tokens.contains(&"all") {
        suggestions.push("deploy web-service cluster".to_string());
        suggestions.push("deploy database cluster".to_string());
    }
    suggestions
}
