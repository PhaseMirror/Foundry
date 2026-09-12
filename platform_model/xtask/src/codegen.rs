//! The model validation and code generation gate.

use crate::Fail;
use repo_model::{codegen, Model};
use std::io::Cursor;
use std::path::{Path, PathBuf};

fn source_files(root: &Path, relative: &str) -> Result<Vec<(String, Vec<u8>)>, Fail> {
    let source = root.join(relative);
    let mut files = Vec::new();
    for entry in walkdir::WalkDir::new(&source) {
        let entry = entry?;
        if entry.file_type().is_symlink() {
            return Err(format!("SDK model input is a symlink: {}", entry.path().display()).into());
        }
        if entry.file_type().is_file() {
            let path = entry
                .path()
                .strip_prefix(root)?
                .to_string_lossy()
                .replace('\\', "/");
            files.push((path, std::fs::read(entry.path())?));
        }
    }
    Ok(files)
}

fn sdk_inputs(root: &Path) -> Result<Vec<u8>, Fail> {
    let mut files = source_files(root, "stdlib/src")?;
    files.extend(source_files(root, "language")?);
    files.sort_by(|left, right| left.0.as_bytes().cmp(right.0.as_bytes()));
    let mut archive = tar::Builder::new(Vec::new());
    archive.mode(tar::HeaderMode::Deterministic);
    for (path, bytes) in files {
        let path = path
            .strip_prefix("stdlib/src/")
            .map_or(path.clone(), |path| format!("stdlib/{path}"));
        let mut header = tar::Header::new_gnu();
        header.set_size(bytes.len() as u64);
        header.set_mode(0o644);
        header.set_uid(0);
        header.set_gid(0);
        header.set_mtime(0);
        header.set_cksum();
        archive.append_data(&mut header, path, Cursor::new(bytes))?;
    }
    archive.finish()?;
    Ok(archive.into_inner()?)
}

/// Validate that generated documents equal the model registers.
pub fn check_model(root: &Path, write: bool) -> Result<(), Fail> {
    let model = Model::load(&root.join("model"))?;
    model.check()?;

    let conformance = codegen::render_conformance(&model);
    let errors = codegen::render_errors(&model);
    let contracts = codegen::render_contracts(&model);
    let spec = std::fs::read_to_string(root.join("SPEC.md"))?;
    let (spec_body, _) = spec
        .split_once("## Appendix A. Conformance ID Registry")
        .ok_or("SPEC.md has no conformance registry appendix")?;
    let spec = format!("{}{}", spec_body, codegen::render_spec_appendix(&model));
    let conformance_path: PathBuf = root.join(codegen::CONFORMANCE_PATH);
    let errors_path: PathBuf = root.join(codegen::ERRORS_PATH);
    let contracts_path: PathBuf = root.join(codegen::CONTRACTS_PATH);
    let spec_path: PathBuf = root.join("SPEC.md");
    let sdk_inputs_path = root.join("sdk/stdlib-sources.tar");
    let sdk_inputs = sdk_inputs(root)?;

    if write {
        std::fs::write(&conformance_path, &conformance)?;
        std::fs::write(&errors_path, &errors)?;
        std::fs::write(&contracts_path, &contracts)?;
        std::fs::write(&spec_path, &spec)?;
        std::fs::write(&sdk_inputs_path, &sdk_inputs)?;
        println!(
            "wrote {}, {}, {}, {}, and {}",
            conformance_path.display(),
            errors_path.display(),
            contracts_path.display(),
            spec_path.display(),
            sdk_inputs_path.display()
        );
        return Ok(());
    }

    for (path, generated) in [
        (&conformance_path, &conformance),
        (&errors_path, &errors),
        (&contracts_path, &contracts),
    ] {
        let committed = std::fs::read_to_string(path)
            .map_err(|error| format!("{}: {error}\nrun `just codegen`", path.display()))?;
        if committed != **generated {
            return Err(format!(
                "{} is stale: it disagrees with model/*.toml (R1). Run `just codegen`.",
                path.display()
            )
            .into());
        }
    }
    let committed_spec = std::fs::read_to_string(&spec_path)?;
    if committed_spec != spec {
        return Err(format!(
            "{} has a stale conformance appendix; run `just codegen`.",
            spec_path.display()
        )
        .into());
    }
    if std::fs::read(&sdk_inputs_path)
        .map_err(|error| format!("{}: {error}; run `just codegen`", sdk_inputs_path.display()))?
        != sdk_inputs
    {
        return Err(format!(
            "{} is stale; run `just codegen`.",
            sdk_inputs_path.display()
        )
        .into());
    }

    let tests = repo_conformance::workspace_test_names(root);
    let report = repo_conformance::check_honesty(root, &tests)?;
    if !report.is_clean() {
        return Err(format!(
            "the honesty meta-gate failed inside validate-model:\n\n{}",
            report.violations.join("\n\n")
        )
        .into());
    }

    crate::audit::audit_no_handwritten_lean(root)?;
    crate::audit::audit_no_unsafe(root)?;

    println!(
        "validate-model: documents current, {} ids, {} codes, meta-gate and audits clean (R1)",
        model.ids.id.len(),
        model.errors.error.len()
    );
    Ok(())
}
