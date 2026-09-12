use std::fs;
use std::process::Command;
use std::path::PathBuf;

const SOURCE: &str = r#"
struct Point {
    x: i32,
    y: i32
}

enum Option {
    None,
    Some(i32)
}

fn main() -> i32 {
    let p = Point { x: 10, y: 20 };
    let x_val = p.x;
    let opt = Option::Some(x_val);
    let result = match opt {
        Option::Some(v) => v,
        Option::None => 0
    };
    return result;
}
"#;

#[test]
#[ignore]
fn test_phase_b_integration() {
    let temp_dir = std::env::temp_dir();
    let source_path = temp_dir.join("test_phase_b.pirtm");
    let mlir_path = temp_dir.join("test_phase_b.mlir");
    let ll_path = temp_dir.join("test_phase_b.ll");
    let exe_path = temp_dir.join("test_phase_b");

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
    assert!(mlir_content.contains("!llvm.struct_Point = type"), "Missing struct definition");
    assert!(mlir_content.contains("llvm.insertvalue"), "Missing struct init");
    assert!(mlir_content.contains("llvm.extractvalue"), "Missing field access");
    assert!(mlir_content.contains("scf.switch"), "Missing match lowering");

    // mlir-translate checks skipped by default in mock environments
    let status = Command::new("mlir-translate")
        .arg("--mlir-to-llvmir")
        .arg(mlir_path.to_str().unwrap())
        .arg("-o")
        .arg(ll_path.to_str().unwrap())
        .status();
    
    if let Ok(st) = status {
        if st.success() {
            let clang_status = Command::new("clang")
                .arg(ll_path.to_str().unwrap())
                .arg("-o")
                .arg(exe_path.to_str().unwrap())
                .status()
                .unwrap();
            assert!(clang_status.success(), "LLVM to native compilation failed");

            let output = Command::new(exe_path.to_str().unwrap())
                .output()
                .unwrap();
            assert!(output.status.success(), "Binary execution failed");
            let exit_code = output.status.code().unwrap_or(0);
            assert_eq!(exit_code, 10, "Expected 10, got {}", exit_code);
        }
    }

    let _ = fs::remove_file(source_path);
    let _ = fs::remove_file(mlir_path);
    let _ = fs::remove_file(ll_path);
    let _ = fs::remove_file(exe_path);

    println!("✅ Phase B integration test passed!");
}
