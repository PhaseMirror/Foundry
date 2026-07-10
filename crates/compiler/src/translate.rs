//! MLIR translation utilities for lowering to LLVM IR and WebAssembly.
//! Uses `mlir-translate` from the LLVM toolchain.

use std::path::Path;
use std::process::{Command, Stdio};

/// Translation target.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Target {
    Llvm,
    Wasm,
}

impl Target {
    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "llvm" => Some(Target::Llvm),
            "wasm" => Some(Target::Wasm),
            _ => None,
        }
    }

    pub fn translate_flag(&self) -> &'static str {
        match self {
            Target::Llvm => "--mlir-to-llvmir",
            Target::Wasm => "--mlir-to-wasm",
        }
    }
}

pub fn translate_mlir(
    input: &Path,
    target: Target,
    _output: Option<&Path>,
) -> Result<Option<String>, String> {
    if !input.exists() {
        return Err(format!("Input file not found: {}", input.display()));
    }

    let translate_cmd = "mlir-translate";
    let flag = target.translate_flag();

    let output_text = Command::new(translate_cmd)
        .arg(flag)
        .arg(input.to_str().unwrap())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn mlir-translate: {}", e))?
        .wait_with_output()
        .map_err(|e| format!("Failed to wait for mlir-translate: {}", e))?;

    if !output_text.status.success() {
        let stderr = String::from_utf8_lossy(&output_text.stderr);
        return Err(format!("mlir-translate failed:\nstderr: {}", stderr));
    }

    Ok(Some(
        String::from_utf8_lossy(&output_text.stdout).to_string(),
    ))
}
