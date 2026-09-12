use std::fs;
use std::process::Command;
use std::path::PathBuf;

const SOURCE: &str = r#"
fn add(a: int, b: int) -> int {
    return a + b;
}

fn main() -> int {
    let x = 5;
    let y = 10;
    let z = add(x, y);
    let result = 0;

    if z > 10 {
        result = 1;
    } else {
        result = 0;
    }

    while result < 5 {
        result = result + 1;
    }

    return result;
}
"#;

#[test]
#[ignore]
fn test_end_to_end_imperative() {
    let temp_dir = std::env::temp_dir();
    let source_path = temp_dir.join("test_program.pirtm");
    let mlir_path = temp_dir.join("test_program.mlir");
    let ll_path = temp_dir.join("test_program.ll");
    let exe_path = temp_dir.join("test_program");

    fs::write(&source_path, SOURCE).unwrap();

    let status = Command::new("cargo")
        .arg("run")
        .arg("--")
        .arg("compile")
        .arg(source_path.to_str().unwrap())
        .arg("--output")
        .arg(mlir_path.to_str().unwrap())
        .status()
        .unwrap();
    assert!(status.success(), "Compilation failed");

    let mlir_content = fs::read_to_string(&mlir_path).unwrap();
    assert!(mlir_content.contains("func.func @add"), "Missing add function");
    assert!(mlir_content.contains("func.func @main"), "Missing main function");
    assert!(mlir_content.contains("scf.if"), "Missing scf.if");
    assert!(mlir_content.contains("scf.while"), "Missing scf.while");
    assert!(mlir_content.contains("call @add"), "Missing function call");
    assert!(mlir_content.contains("return"), "Missing return");

    // We do not actually run mlir-translate here unless it's available.
    
    let _ = fs::remove_file(source_path);
    let _ = fs::remove_file(mlir_path);
    let _ = fs::remove_file(ll_path);
    let _ = fs::remove_file(exe_path);
}
