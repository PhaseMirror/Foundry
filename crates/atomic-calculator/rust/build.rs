use std::env;
use std::fs;
use std::path::Path;

fn main() {
    println!("cargo:rerun-if-changed=../../../lean/SNAPKITTY/SnapKitty/Core.lean");
    
    let out_dir = env::var_os("OUT_DIR").unwrap_or_else(|| std::ffi::OsString::from("src"));
    let dest_path = Path::new(&out_dir).join("bounds.rs");
    
    // In a real implementation, this would parse Core.lean to extract exact constants.
    // Here we emit the constants mapped from SnapKitty.Math definitions.
    let generated_code = r#"
pub const THERMAL_WINDOW_LO_SUB: u64 = 8000;
pub const THERMAL_WINDOW_HI_ADD: u64 = 12000;
pub const ENTROPY_H_MAX_SCALED: u64 = 60000;
pub const CHEMICAL_ACCURACY_THRESHOLD_MHA_SCALED: u64 = 150000;
pub const SQD_B_DEFAULT: u64 = 50;
pub const SQD_LAMBDA_GUARD_SCALED: u64 = 20000;
pub const SQD_MAX_WEIGHT: u64 = 2;
pub const SCALE: u64 = 10000;
"#;
    fs::write(&dest_path, generated_code).unwrap();
}
