// crates/sigma/build.rs
use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let out_dir = PathBuf::from(env::var("OUT_DIR")?);
    let lean_root = PathBuf::from("../../lean");

    // --- Watch only the Lean sources that affect the generated structs ---
    // This prevents spurious rebuilds when unrelated Lean files change.
    println!("cargo:rerun-if-changed={}", lean_root.join("lakefile.toml").display());
    // E.g. ExportThresholds.lean if it exists, or just the lean directory for now.
    println!("cargo:rerun-if-changed={}", lean_root.display());

    // --- Feature: lean-gen (enabled by default) ---
    #[cfg(feature = "lean-gen")]
    {
        println!("cargo:info=Lean generation enabled – running Lean Meta...");

        // Ensure OUT_DIR exists.
        fs::create_dir_all(&out_dir)?;

        // Invoke the Lean Meta generator.
        let status = Command::new("lake")
            .args([
                "exe",
                "export_thresholds",
                "--out-dir",
                &out_dir.to_string_lossy(),
            ])
            .current_dir(&lean_root)
            .status();

        // If the lake command fails or doesn't exist, we don't necessarily want to fail
        // the whole build if the user doesn't have the export_thresholds script yet.
        // For production, we would fail. Let's fail if status isn't success, but handle
        // error gracefully if `lake` isn't found.
        match status {
            Ok(s) if !s.success() => {
                // Return error if it fails
                // But for now, since it might not be implemented, we just warn and fallback to writing a dummy file?
                // The prompt says "handles all errors explicitly and fails the build cleanly"
                return Err(
                    "Lean Meta generation (export_thresholds) failed.\n\
                     Ensure Lean 4 and `lake` are installed, and the Lean project builds.\n\
                     Hint: run `lake build` in ../../lean to test manually."
                        .into(),
                );
            }
            Err(e) => {
                return Err(format!("Failed to run lake: {}", e).into());
            }
            _ => {}
        }

        println!("cargo:info=✅ Lean generation succeeded – written to {}", out_dir.display());
    }

    // --- Fallback: feature disabled -> use checked-in version ---
    #[cfg(not(feature = "lean-gen"))]
    {
        let fallback_path = PathBuf::from("src/generated/thresholds.rs");
        if !fallback_path.exists() {
            return Err(
                "Feature 'lean-gen' is disabled, but the fallback file \
                 `src/generated/thresholds.rs` is missing.\n\
                 Either check it into the repository or enable the 'lean-gen' feature."
                    .into(),
            );
        }

        fs::create_dir_all(&out_dir)?;
        fs::copy(&fallback_path, out_dir.join("thresholds.rs"))?;
        println!("cargo:info=Using checked-in generated thresholds.rs (lean-gen disabled).");
    }

    Ok(())
}
