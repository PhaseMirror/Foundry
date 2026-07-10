//! OpenQASM 2.0 Parser
//!
//! Provides a lightweight parser to ingest standard OpenQASM quantum circuits
//! and transform them into `LogicGate` arrays for synthesis by the topological compiler.

use crate::LogicGate;
use std::fmt;

/// Errors that can occur during OpenQASM parsing.
#[derive(Debug, PartialEq, Eq)]
pub enum QasmError {
    /// The theta parameter expression is malformed.
    MalformedTheta(String),
    /// A qubit index is malformed.
    MalformedIndex(String),
}

impl fmt::Display for QasmError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::MalformedTheta(msg) => write!(f, "Malformed theta expression: {}", msg),
            Self::MalformedIndex(msg) => write!(f, "Malformed qubit index: {}", msg),
        }
    }
}

impl std::error::Error for QasmError {}

/// An extremely lightweight, structural OpenQASM 2.0 parser.
pub struct QasmParser;

impl QasmParser {
    /// Parses an OpenQASM 2.0 string into a sequence of `LogicGate`s.
    pub fn parse(qasm: &str) -> Result<Vec<LogicGate>, QasmError> {
        let mut circuit = Vec::new();

        for line in qasm.lines() {
            let line = line.trim();
            if line.is_empty()
                || line.starts_with("//")
                || line.starts_with("OPENQASM")
                || line.starts_with("include")
                || line.starts_with("qreg")
                || line.starts_with("creg")
            {
                continue;
            }

            // Remove trailing semicolon
            let line = line.trim_end_matches(';');
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.is_empty() {
                continue;
            }

            let gate_str = parts[0];
            let args_str = if parts.len() > 1 {
                parts[1..].join("")
            } else {
                String::new()
            };

            // Parse argument indices (e.g. "q[0],q[1]" -> [0, 1])
            let mut indices = Vec::new();
            if !args_str.is_empty() {
                for s in args_str.split(',') {
                    let s = s.trim();
                    let start = s
                        .find('[')
                        .ok_or_else(|| QasmError::MalformedIndex(s.to_string()))?;
                    let end = s
                        .find(']')
                        .ok_or_else(|| QasmError::MalformedIndex(s.to_string()))?;
                    let idx = s[start + 1..end]
                        .parse()
                        .map_err(|_| QasmError::MalformedIndex(s.to_string()))?;
                    indices.push(idx);
                }
            }

            // Match parameterized gates e.g. rx(pi/2)
            if let Some(paren_idx) = gate_str.find('(') {
                let base_gate = &gate_str[..paren_idx];
                let param_str = &gate_str[paren_idx + 1..gate_str.len() - 1];
                let theta = Self::parse_theta(param_str)?;

                if let Some(&q) = indices.first() {
                    match base_gate {
                        "rx" => circuit.push(LogicGate::Rx(q, theta)),
                        "ry" => circuit.push(LogicGate::Ry(q, theta)),
                        "rz" => circuit.push(LogicGate::Rz(q, theta)),
                        _ => {}
                    }
                }
            } else {
                // Match discrete gates
                match gate_str {
                    "h" => {
                        if let Some(&q) = indices.first() {
                            circuit.push(LogicGate::Hadamard(q));
                        }
                    }
                    "x" => {
                        if let Some(&q) = indices.first() {
                            circuit.push(LogicGate::PauliX(q));
                        }
                    }
                    "t" => {
                        if let Some(&q) = indices.first() {
                            circuit.push(LogicGate::TGate(q));
                        }
                    }
                    "cx" | "cnot" if indices.len() == 2 => {
                        circuit.push(LogicGate::CNot(indices[0], indices[1]));
                    }
                    _ => {}
                }
            }
        }

        Ok(circuit)
    }

    /// Evaluates a symbolic theta expression (e.g., "pi/2", "1.57")
    fn parse_theta(expr: &str) -> Result<f64, QasmError> {
        let expr = expr.trim();
        if expr.contains("pi") {
            let mult = if expr.starts_with("pi") {
                1.0
            } else {
                let p = expr.split('*').next().unwrap_or("1.0");
                p.parse()
                    .map_err(|_| QasmError::MalformedTheta(expr.to_string()))?
            };

            let div = if expr.contains('/') {
                let d = expr.split('/').nth(1).unwrap_or("1.0");
                d.parse()
                    .map_err(|_| QasmError::MalformedTheta(expr.to_string()))?
            } else {
                1.0
            };

            Ok(mult * core::f64::consts::PI / div)
        } else {
            expr.parse()
                .map_err(|_| QasmError::MalformedTheta(expr.to_string()))
        }
    }
}
