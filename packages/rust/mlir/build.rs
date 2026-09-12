use std::env;

fn main() {
    let llvm_config = env::var("LLVM_CONFIG").unwrap_or_else(|_| "llvm-config".to_string());

    let output = match env::var("CARGO_CFG_TARGET_OS") {
        Ok(os) if os == "linux" => std::process::Command::new(llvm_config)
            .args(&["--libdir"])
            .output(),
        _ => std::process::Command::new(llvm_config)
            .args(&["--libdir"])
            .output(),
    };

    if let Ok(output) = output {
        if let Ok(libdir) = String::from_utf8(output.stdout) {
            let libdir = libdir.trim();
            if std::path::Path::new(libdir).exists() {
                println!("cargo:rustc-link-search=native={}", libdir);
            } else {
                println!("cargo:rustc-link-search=native=/usr/lib64/llvm15/lib");
            }
        } else {
            println!("cargo:rustc-link-search=native=/usr/lib64/llvm15/lib");
        }
    } else {
        println!("cargo:rustc-link-search=native=/usr/lib64/llvm15/lib");
    }

    println!("cargo:rustc-link-lib=mlir-c");
}
