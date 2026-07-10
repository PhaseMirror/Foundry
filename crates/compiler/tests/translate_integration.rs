use std::fs;
use std::process::Command;

#[test]
#[ignore]
fn test_full_pipeline_to_llvm() {
    let source = r#"
let x = Ap(2);
let y = x + 3;
y;
"#;
    let temp_dir = std::env::temp_dir();
    let source_path = temp_dir.join("test.pirtm");
    fs::write(&source_path, source).unwrap();

    let mlir_path = temp_dir.join("test.mlir");
    let ll_path = temp_dir.join("test.ll");
    let exe_path = temp_dir.join("test_bin");

    let status = Command::new("cargo")
        .arg("run")
        .arg("--")
        .arg("compile")
        .arg(source_path.to_str().unwrap())
        .arg("--output")
        .arg(mlir_path.to_str().unwrap())
        .status()
        .unwrap();
    assert!(status.success());

    let status = Command::new("cargo")
        .arg("run")
        .arg("--")
        .arg("translate")
        .arg(mlir_path.to_str().unwrap())
        .arg("--target")
        .arg("llvm")
        .arg("--output")
        .arg(ll_path.to_str().unwrap())
        .status()
        .unwrap();
    assert!(status.success());

    let status = Command::new("clang")
        .arg(ll_path.to_str().unwrap())
        .arg("-o")
        .arg(exe_path.to_str().unwrap())
        .status()
        .unwrap();
    assert!(status.success());

    let output = Command::new(exe_path.to_str().unwrap()).output().unwrap();
    assert!(output.status.success());
}
