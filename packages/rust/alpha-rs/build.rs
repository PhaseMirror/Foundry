use std::env;
use std::process::Command;

fn main() {
    println!("cargo:rerun-if-changed=../../../lean/AlphaFunction/AlphaFunction.lean");

    let lean_sysroot = Command::new("lean")
        .arg("--print-prefix")
        .output()
        .expect("Failed to execute lean")
        .stdout;
    let lean_sysroot = String::from_utf8(lean_sysroot).unwrap();
    let lean_sysroot = lean_sysroot.trim();

    println!("cargo:rustc-link-search=native={}/lib/lean", lean_sysroot);
    println!("cargo:rustc-link-search=native={}/lib", lean_sysroot);
    println!("cargo:rustc-link-arg=-Wl,-rpath,{}/lib/lean", lean_sysroot);
    println!("cargo:rustc-link-lib=dylib=leanshared");

    let manifest_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    println!("cargo:rustc-link-search=native={}/../../../lean/.lake/build/lib", manifest_dir);
    println!("cargo:rustc-link-lib=static=adr__scaffold_AlphaFunction");
}
