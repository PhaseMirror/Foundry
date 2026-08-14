use al_gft_derive::{DerivationPipeline, DerivationWitness, steps, python_bridge};
use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = python_bridge::PythonBridgeConfig {
        python_exe: std::env::var("PYTHON_EXE").unwrap_or_else(|_| "python3".to_string()),
        scripts_dir: PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("python"),
        capture_stderr: true,
    };

    println!("=== AL-GFT Derivation Pipeline ===");
    println!("Python: {}", config.python_exe);
    println!("Scripts: {}", config.scripts_dir.display());
    println!();

    // Run Python-backed steps
    println!("Running Python-backed derivation steps...");
    let python_steps = python_bridge::default_python_steps(config.clone());
    let mut python_witnesses = Vec::new();

    for step in &python_steps {
        println!("  {} ({}) ...", step.step_name(), step.step_id());
        let w = step.to_witness();
        println!("    W1: {}", w.w1_axiom);
        python_witnesses.push(w);
    }

    // Run Rust-native steps
    println!("\nRunning Rust-native derivation steps...");
    let rust_steps: Vec<Box<dyn al_gft_derive::DerivationStep>> = vec![
        Box::new(steps::ActionSpecification::new()),
        Box::new(steps::InfluenceFunctional::new()),
        Box::new(steps::LangevinEquation::new()),
        Box::new(steps::PowerSpectrum::new()),
        Box::new(steps::NullTest::new()),
    ];

    let pipeline = DerivationPipeline::new();
    let witnesses: Vec<DerivationWitness> = rust_steps
        .into_iter()
        .map(|s| {
            println!("  {} -> {}", s.step_name(), s.step_id());
            println!("    W1: {}", s.compute_w1_axiom());
            s.to_witness()
        })
        .collect();

    let mut all_witnesses = python_witnesses;
    all_witnesses.extend(witnesses);

    let c_total = pipeline.composite_hash(&all_witnesses);
    println!("\nComposite ledger hash: {}", c_total);

    // Serialize ledger
    let ledger = pipeline.emit_extended_witness(
        &all_witnesses,
        "W0_EXEC_PIPELINE".to_string(),
        "W2_PHYS_PIPELINE".to_string(),
    );

    let json = serde_json::to_string_pretty(&ledger)?;
    std::fs::write("artifacts/al-gft-derive/derivation_ledger.json", json)?;
    println!("\nLedger written to artifacts/al-gft-derive/derivation_ledger.json");

    Ok(())
}
