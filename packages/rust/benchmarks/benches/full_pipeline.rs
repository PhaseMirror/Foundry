use criterion::{criterion_group, criterion_main, Criterion};
use std::fs;
use std::process::Command;

fn full_pipeline_benchmark(c: &mut Criterion) {
    let temp_dir = std::env::temp_dir();
    let source_path = temp_dir.join("bench.pirtm");
    let mlir_path = temp_dir.join("bench.mlir");
    let ll_path = temp_dir.join("bench.ll");

    let source = "let x = Ap(2); let y = x + 3; y; ".repeat(10_000);
    fs::write(&source_path, source).unwrap();

    c.bench_function("full pipeline 10k stmts to LLVM", |b| {
        b.iter(|| {
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
        })
    });

    let _ = fs::remove_file(source_path);
    let _ = fs::remove_file(mlir_path);
    let _ = fs::remove_file(ll_path);
}

criterion_group!(benches, full_pipeline_benchmark);
criterion_main!(benches);
