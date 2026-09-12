use std::path::{Path, PathBuf};
use std::fs;
use std::process::Command;
use tempfile::TempDir;
use walkdir::WalkDir;

pub struct GatePSimulator {
    pub workspace_root: PathBuf,
    pub default_tests: Vec<String>,
}

impl GatePSimulator {
    pub fn new(workspace_root: PathBuf) -> Self {
        Self {
            workspace_root,
            default_tests: vec![
                "src/multiplicity_core/tests/test_harness_properties.py".to_string()
            ],
        }
    }

    pub fn simulate_change(&self, file_path: &str, new_content: &str) -> Result<(bool, String), String> {
        let temp_dir = TempDir::new().map_err(|e| format!("Failed to create temp dir: {}", e))?;
        let temp_path = temp_dir.path();

        // 1. Clone workspace
        self.clone_workspace(temp_path)?;

        // 2. Apply proposed change
        let target_file = temp_path.join(file_path);
        if !target_file.exists() {
            return Err(format!("Target file does not exist in workspace: {}", file_path));
        }

        fs::write(&target_file, new_content).map_err(|e| format!("Failed to apply change: {}", e))?;

        // 3. Run Invariant Tests
        let mut test_results = Vec::new();
        let mut all_passed = true;

        for test_script in &self.default_tests {
            let (res_ok, output) = self.run_test(temp_path, test_script);
            test_results.push(format!("Test {}: {}\n{}", test_script, if res_ok { "PASS" } else { "FAIL" }, output));
            if !res_ok {
                all_passed = false;
            }
        }

        let report = test_results.join("\n");
        Ok((all_passed, report))
    }

    fn clone_workspace(&self, target_dir: &Path) -> Result<(), String> {
        let essential_dirs = vec!["src", "packages", "governance"];
        
        for dname in essential_dirs {
            let s = self.workspace_root.join(dname);
            let d = target_dir.join(dname);
            if s.exists() {
                self.copy_dir_recursive(&s, &d)?;
            }
        }

        // Also copy top-level files like pyproject.toml if needed
        for entry in fs::read_dir(&self.workspace_root).map_err(|e| e.to_string())? {
            let entry = entry.map_err(|e| e.to_string())?;
            let path = entry.path();
            if path.is_file() {
                if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
                    if ["py", "toml", "txt"].contains(&ext) {
                        fs::copy(&path, target_dir.join(path.file_name().unwrap())).map_err(|e| e.to_string())?;
                    }
                }
            }
        }

        Ok(())
    }

    fn copy_dir_recursive(&self, src: &Path, dst: &Path) -> Result<(), String> {
        fs::create_dir_all(dst).map_err(|e| e.to_string())?;
        for entry in WalkDir::new(src) {
            let entry = entry.map_err(|e| e.to_string())?;
            let path = entry.path();
            let rel_path = path.strip_prefix(src).map_err(|e| e.to_string())?;
            let target_path = dst.join(rel_path);

            if path.is_dir() {
                fs::create_dir_all(target_path).map_err(|e| e.to_string())?;
            } else {
                // Ignore patterns
                let filename = path.file_name().and_then(|s| s.to_str()).unwrap_or("");
                if filename.contains("__pycache__") || filename.ends_with(".pyc") || filename.ends_with(".log") {
                    continue;
                }
                fs::copy(path, target_path).map_err(|e| e.to_string())?;
            }
        }
        Ok(())
    }

    fn run_test(&self, workspace: &Path, test_path: &str) -> (bool, String) {
        let output = Command::new("python3")
            .arg(test_path)
            .current_dir(workspace)
            .env("PYTHONPATH", format!("{}/src:{}/packages/pirtm:{}", workspace.display(), workspace.display(), std::env::var("PYTHONPATH").unwrap_or_default()))
            .output();

        match output {
            Ok(out) => {
                let stdout = String::from_utf8_lossy(&out.stdout).to_string();
                let stderr = String::from_utf8_lossy(&out.stderr).to_string();
                (out.status.success(), format!("{}{}", stdout, stderr))
            }
            Err(e) => (false, format!("Execution error: {}", e)),
        }
    }
}
