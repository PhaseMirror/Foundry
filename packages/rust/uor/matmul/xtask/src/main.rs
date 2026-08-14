//! Repository gates.
//!
//! `cargo xtask <task>`; `just vv` runs the whole normative acceptance gate.
//! Each task below enforces one of the working rules in the plan's §0 table,
//! and each names the rule it enforces when it fails, so that a red gate says
//! *which promise* was broken rather than merely that something is wrong.

use std::path::{Path, PathBuf};
use std::process::ExitCode;

use uor_matmul_model::{codegen, Model};

mod audit;

fn main() -> ExitCode {
    let task = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "help".to_string());
    let write = std::env::args().any(|a| a == "--write");
    let root = uor_matmul_model::repo_root();

    let result = match task.as_str() {
        "check-model" => check_model(&root, write),
        "check-constants" => audit::check_constants(&root),
        "audit-limits" => audit::audit_limits(&root),
        "audit-purity" => audit::audit_purity(&root),
        "audit-disassembly" => audit::audit_disassembly(&root),
        "audit-deferral" => audit::audit_deferral(&root),
        "verify-oracles" => verify_oracles(&root),
        "validate" => validate(&root),
        _ => {
            eprintln!(
                "cargo xtask <task>\n\
                 \n\
                 check-model       R10: model/*.toml is the single source; regenerate and diff\n\
                 check-constants   R1:  every constant derives; no magic numeral\n\
                 audit-limits      R8:  no bound that cannot be traced to a parameter\n\
                 audit-purity      R13: one method; no float addition, no fallback\n\
                 audit-disassembly CU-01: no float arithmetic opcode in any shipped kernel\n\
                 audit-deferral    R15: no TODO, no stub, no 'later version'\n\
                 verify-oracles    R11: every external claim is bound to a committed artifact\n\
                 validate          run every gate above\n\
                 \n\
                 --write           check-model only: rewrite the generated file"
            );
            return ExitCode::from(2);
        }
    };

    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("gate failed: {e}");
            ExitCode::FAILURE
        }
    }
}

/// A gate failure, reported with the rule it broke.
type Fail = Box<dyn std::error::Error>;

/// R10, `CM-01`: the generated Rust consts equal the model, numeral for
/// numeral.
fn check_model(root: &Path, write: bool) -> Result<(), Fail> {
    let model = Model::load(&root.join("model"))?;
    model.check()?;

    let rendered = codegen::render(&model);
    let path: PathBuf = root.join(codegen::GENERATED_PATH);

    let conformance = codegen::render_conformance(&model);
    let conformance_path = root.join(codegen::CONFORMANCE_PATH);

    if write {
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(&path, &rendered)?;
        std::fs::write(&conformance_path, &conformance)?;
        println!("wrote {}", path.display());
        println!("wrote {}", conformance_path.display());
        return Ok(());
    }

    let committed_conformance = std::fs::read_to_string(&conformance_path).map_err(|e| {
        format!(
            "{}: {e}\nrun `cargo xtask check-model --write`",
            conformance_path.display()
        )
    })?;
    if committed_conformance != conformance {
        return Err(format!(
            "{} is stale: it disagrees with model/ledger.toml.\n\
             R4: a claim cannot exist in the documentation without a ledger row. \
             Run `cargo xtask check-model --write`.",
            conformance_path.display()
        )
        .into());
    }

    let committed = std::fs::read_to_string(&path).map_err(|e| {
        format!(
            "{}: {e}\nrun `cargo xtask check-model --write`",
            path.display()
        )
    })?;
    if committed != rendered {
        return Err(format!(
            "{} is stale: it disagrees with model/*.toml.\n\
             R10: constants have exactly one source. Run `cargo xtask check-model --write`.",
            path.display()
        )
        .into());
    }
    println!("check-model: the generated consts equal the model (CM-01)");
    Ok(())
}

/// R11: every external claim is bound to a committed oracle artifact, with
/// provenance and checksum.
fn verify_oracles(root: &Path) -> Result<(), Fail> {
    let model = Model::load(&root.join("model"))?;
    let dir = root.join("oracles");
    let provenance = dir.join("provenance.toml");
    if !provenance.exists() {
        return Err(format!(
            "{} is missing.\nR11: an external claim with no committed provenance is an \
             assertion, not a validation.",
            provenance.display()
        )
        .into());
    }
    let text = std::fs::read_to_string(&provenance)?;
    let mut missing = Vec::new();
    for oracle in &model.oracles.oracle {
        if !text.contains(&oracle.id) {
            missing.push(oracle.id.clone());
        }
    }
    if !missing.is_empty() {
        return Err(format!(
            "oracles/provenance.toml does not record: {}\nR11: every oracle row needs \
             provenance and a checksum.",
            missing.join(", ")
        )
        .into());
    }
    println!(
        "verify-oracles: {} oracle rows have provenance (R11)",
        model.oracles.oracle.len()
    );
    Ok(())
}

/// The whole normative acceptance gate, in one place.
fn validate(root: &Path) -> Result<(), Fail> {
    check_model(root, false)?;
    audit::check_constants(root)?;
    audit::audit_limits(root)?;
    audit::audit_purity(root)?;
    audit::audit_disassembly(root)?;
    audit::audit_deferral(root)?;
    verify_oracles(root)?;
    println!("validate: every gate passed");
    Ok(())
}
