use adr_verifier::{AdrRegistry, KernelBoundaryConfig, PhaseMirrorRegistry};
use std::env;
use std::fs;
use std::process;

fn main() {
    let args: Vec<String> = env::args().collect();
    let registry_path = args.get(1).map(|s| s.as_str()).unwrap_or("docs/adr/registry.json");

    let contents = match fs::read_to_string(registry_path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("[ERROR] Failed to read registry file at {}: {}", registry_path, e);
            process::exit(1);
        }
    };

    // Detect whether this is a PML runtime registry (v2.0) or a structural ADR registry.
    let is_pml = serde_json::from_str::<serde_json::Value>(&contents)
        .ok()
        .and_then(|v| v.get("version").and_then(|v| v.as_str()).map(|s| s.starts_with("2.")))
        .unwrap_or(false);

    if is_pml {
        run_boundary_guard(&contents, registry_path);
    } else {
        run_structural_guard(&contents, registry_path);
    }
}

fn run_structural_guard(contents: &str, path: &str) {
    let registry = match AdrRegistry::from_json_str(contents) {
        Ok(r) => r,
        Err(e) => {
            eprintln!("[FATAL] ADR registry JSON parse failure: {}", e);
            process::exit(1);
        }
    };
    match registry.verify_invariants() {
        Ok(()) => {
            println!(
                "[OK] ADR Structural Registry Verified: {} records satisfy all invariants. ({})",
                registry.adrs.len(),
                path,
            );
        }
        Err(e) => {
            eprintln!("[FATAL] ADR Invariant Violation: {}", e);
            process::exit(1);
        }
    }
}

fn run_boundary_guard(contents: &str, path: &str) {
    let registry = match PhaseMirrorRegistry::from_json_str(contents) {
        Ok(r) => r,
        Err(e) => {
            eprintln!("[FATAL] PML registry JSON parse failure: {}", e);
            process::exit(1);
        }
    };
    let config = KernelBoundaryConfig::default();
    match registry.verify_boundary(&config) {
        Ok(()) => {
            println!(
                "[OK] Phase Mirror Boundary Guard: {} plan ADRs, sorry={}, axioms={}, drift={}, open_tensions={}, score={}. ({})",
                registry.plan_adrs.len(),
                registry.lean.sorry_total,
                registry.lean.axioms_postulates,
                registry.manifest.drift,
                registry.tensions.open,
                registry.tensions.total_score,
                path,
            );
        }
        Err(e) => {
            eprintln!("[FATAL] Kernel Boundary Violation: {}", e);
            process::exit(1);
        }
    }
}
