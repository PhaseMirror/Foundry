use std::fs;
use std::process::Command;
use tempfile::tempdir;

#[test]
fn test_compile_to_mlir_file() {
    // Set up a temporary directory
    let tmp = tempdir().expect("failed to create temp dir");
    let source_path = tmp.path().join("test.pirtm");
    let output_path = tmp.path().join("out.mlir");

    // Write a simple source program
    fs::write(&source_path, "Ap(2) + 3").expect("failed to write source");

    // Run the compiler CLI
    let status = Command::new("cargo")
        .arg("run")
        .arg("--")
        .arg("compile")
        .arg(source_path.to_str().unwrap())
        .arg("--output")
        .arg(output_path.to_str().unwrap())
        .status()
        .expect("failed to execute cargo");

    assert!(status.success(), "CLI returned non‑zero exit code");

    // Verify the output file exists and contains expected MLIR text
    let mlir = fs::read_to_string(&output_path).expect("failed to read mlir output");
    assert!(
        mlir.contains("pirtm.operator_atom"),
        "MLIR missing operator_atom"
    );
    // Ap(2) produces prime_index = 2, and the binary adds another operator_atom
    assert!(
        mlir.contains("prime_index = 2"),
        "MLIR missing correct prime_index for Ap(2)"
    );
}
