use std::path::PathBuf;
use std::path::Path;

#[path = "../../../scripts/adr_integrity.rs"]
mod adr_integrity;

fn main() {
    let dir: PathBuf = ["tree-sitter-pirtm", "src"].iter().collect();

    cc::Build::new()
        .include(&dir)
        .file(dir.join("parser.c"))
        .compile("tree-sitter-pirtm");

    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| ".".to_string());
    let workspace_root = Path::new(&manifest_dir)
        .parent().unwrap() // crates
        .parent().unwrap() // Prime
        .parent().unwrap(); // PhaseMirror root

    if let Err(e) = adr_integrity::verify_adr_integrity(workspace_root) {
        panic!("{}", e);
    }

    println!("cargo:rerun-if-changed=Prime/lean/ADR/.adr-proof-hash");
}
