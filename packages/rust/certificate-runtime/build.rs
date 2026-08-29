fn main() {
    // Compile the C stub into a static library.
    let src = "../../../native_libs/certificate_core.c";
    let out_dir = std::env::var("OUT_DIR").unwrap();
    let lib_path = std::path::Path::new(&out_dir).join("libcertificate_core.a");
    // Use the cc crate via rustc script (requires it in build-dependencies, but we can call gcc directly)
    // Simpler: invoke the system C compiler.
    let status = std::process::Command::new("gcc")
        .args(&[src, "-c", "-fPIC", "-o", "certificate_core.o"])
        .status()
        .expect("failed to compile C stub");
    assert!(status.success(), "gcc compile failed");
    let status = std::process::Command::new("ar")
        .args(&["rcs", lib_path.to_str().unwrap(), "certificate_core.o"])
        .status()
        .expect("failed to create static lib");
    assert!(status.success(), "ar command failed");
    // Tell Cargo where to find the library.
    println!("cargo:rustc-link-search=native={}", out_dir);
    println!("cargo:rustc-link-lib=static=certificate_core");
}
