//! Complete verified Lean to LCNF to allocation-free Rust execution chain.

use crate::config::ProjectConfig;
use crate::controller::{BuildRequest, BuildResult, Controller, VerifyRequest, VerifyResult};
use crate::error::PrismError;
use crate::holo::canonical::{content_id, decode_canonical, encode_value};
use fs4::fs_std::FileExt;
use lexlean::{Engine, Selection, VerifyRequest as LexVerifyRequest};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use std::collections::{BTreeMap, BTreeSet};
use std::fs::{File, OpenOptions};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

const CHILD_OUTPUT_LIMIT: usize = 16_777_216;
const CHILD_TIMEOUT_SECONDS: &str = "300";
const ROOTS_SOURCE: &str = include_str!("../model/runtime-roots.toml");
const EXECUTION_CORPUS_SOURCE: &str = include_str!("../model/execution-corpus.toml");
const ALLOCATION_COUNTER_SOURCE: &str = include_str!("prod_alloc_counter.rs.inc");
const HOLOGRAM_ORACLE_SOURCE: &[u8] = include_bytes!("../vendor/hologram-live.tar");
const HOLOGRAM_ORACLE_SOURCE_SHA256: &str =
    "caf5c34ef2b21d58c1aa12acf81cb13ace1adaffb3c69a641f54f490ed61cf66";
const HOLOGRAM_ORACLE_CARGO: &[u8] = include_bytes!("embedded/hologram-oracle.Cargo.toml");
const HOLOGRAM_ORACLE_LOCK: &[u8] = include_bytes!("embedded/hologram-oracle.Cargo.lock");
const HOLOGRAM_ORACLE_MAIN: &[u8] = include_bytes!("embedded/hologram-oracle.main.rs");
const ELAN_PROXY_SHA256: &str = "840179e70803ef373c2ec53342d6a45ea7d022533e4145489fc1278b4f716385";
const RUSTUP_PROXY_SHA256: &str =
    "20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c";
const TIMEOUT_SHA256: &str = "5ef0eaaaa4220593add7716aad74da927ca3bb10605e964330de64fecc3ef15e";

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct RuntimeRoots {
    spec: String,
    lean_module: String,
    ir_module: String,
    roots: Vec<String>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct ExecutionCorpus {
    spec: String,
    strategy: String,
    seed: String,
    case_count: u64,
    value_domain: String,
    exhaustive: ExhaustiveCorpus,
    property: PropertyCorpus,
    oracle: Vec<ExecutionOracle>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct ExhaustiveCorpus {
    max_length: usize,
    value_max: u64,
    all_below_bound: u64,
    case_count: u64,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct PropertyCorpus {
    case_count: usize,
    max_length: usize,
    all_below_bound: u64,
    generated_value_modulus: u64,
    shrink_result: String,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct ExecutionOracle {
    function: String,
    theorem: String,
    runtime_root: bool,
}

fn execution_corpus(roots: &RuntimeRoots) -> Result<(ExecutionCorpus, String), PrismError> {
    let corpus: ExecutionCorpus = toml::from_str(EXECUTION_CORPUS_SOURCE)
        .map_err(|error| PrismError::new("PP9001", format!("execution corpus: {error}")))?;
    let corpus_sha256 = format!("{:x}", Sha256::digest(EXECUTION_CORPUS_SOURCE.as_bytes()));
    let width = corpus
        .exhaustive
        .value_max
        .checked_add(1)
        .ok_or_else(|| PrismError::new("PP9001", "execution corpus value range overflows"))?;
    let mut list_count = 0_u64;
    let mut width_power = 1_u64;
    for length in 0..=corpus.exhaustive.max_length {
        list_count = list_count
            .checked_add(width_power)
            .ok_or_else(|| PrismError::new("PP9001", "execution corpus size overflows"))?;
        if length != corpus.exhaustive.max_length {
            width_power = width_power
                .checked_mul(width)
                .ok_or_else(|| PrismError::new("PP9001", "execution corpus size overflows"))?;
        }
    }
    let exhaustive_cases = list_count;
    let property_cases = u64::try_from(corpus.property.case_count)
        .map_err(|_| PrismError::new("PP9001", "execution property count overflows"))?;
    let expected_cases = exhaustive_cases
        .checked_add(property_cases)
        .ok_or_else(|| PrismError::new("PP9001", "execution corpus size overflows"))?;
    let functions = corpus
        .oracle
        .iter()
        .map(|oracle| oracle.function.as_str())
        .collect::<Vec<_>>();
    let runtime_functions = corpus
        .oracle
        .iter()
        .filter(|oracle| oracle.runtime_root)
        .map(|oracle| oracle.function.as_str())
        .collect::<BTreeSet<_>>();
    let roots_set = roots
        .roots
        .iter()
        .map(String::as_str)
        .collect::<BTreeSet<_>>();
    let theorem_set = corpus
        .oracle
        .iter()
        .map(|oracle| oracle.theorem.as_str())
        .collect::<BTreeSet<_>>();
    if corpus.spec != "prismpm/execution-corpus/1"
        || corpus.strategy != "exhaustive-v1+lcg-v1"
        || corpus.seed != "5eedcafef00dbeef"
        || corpus.value_domain != "u64"
        || corpus.exhaustive.max_length != 3
        || corpus.exhaustive.value_max != 3
        || corpus.exhaustive.all_below_bound != 4
        || corpus.exhaustive.case_count != exhaustive_cases
        || corpus.property.case_count != 512
        || corpus.property.max_length != 16
        || corpus.property.all_below_bound != 10
        || corpus.property.generated_value_modulus != 20
        || corpus.property.shrink_result != "not-applicable-passed"
        || corpus.case_count != expected_cases
        || corpus.oracle.is_empty()
        || functions.windows(2).any(|pair| pair[0] >= pair[1])
        || theorem_set.len() != corpus.oracle.len()
        || runtime_functions != roots_set
        || corpus.oracle.iter().any(|oracle| {
            !oracle.function.starts_with("PrismPM.Foundation.Holo.")
                || !oracle.theorem.starts_with("PrismPM.Foundation.Holo.")
        })
    {
        return Err(PrismError::new(
            "PP9001",
            "execution corpus model is not canonical or internally consistent",
        ));
    }
    Ok((corpus, corpus_sha256))
}

#[derive(Debug, Serialize)]
pub(crate) struct ProcessRecord {
    pub(crate) tool: String,
    pub(crate) argv: Vec<String>,
    pub(crate) executable_sha256: String,
    pub(crate) exit_code: i32,
    pub(crate) stdout: String,
    pub(crate) stderr: String,
}

pub(crate) fn executable(name: &str) -> Result<PathBuf, PrismError> {
    let path =
        std::env::var_os("PATH").ok_or_else(|| PrismError::new("PP5008", "PATH is unavailable"))?;
    for directory in std::env::split_paths(&path) {
        let candidate = directory.join(name);
        if candidate.is_file() {
            let resolved = candidate.canonicalize().map_err(|error| {
                PrismError::new("PP5008", format!("{}: {error}", candidate.display()))
            })?;
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                let mode = std::fs::metadata(&resolved)
                    .map_err(|error| {
                        PrismError::new("PP5008", format!("{}: {error}", resolved.display()))
                    })?
                    .permissions()
                    .mode();
                if mode & 0o111 == 0 {
                    return Err(PrismError::new(
                        "PP5008",
                        format!("required executable {name} is not executable"),
                    ));
                }
            }
            let expected = match name {
                "lake" | "lean" => Some(ELAN_PROXY_SHA256),
                "rustc" | "rustfmt" => Some(RUSTUP_PROXY_SHA256),
                "timeout" => Some(TIMEOUT_SHA256),
                _ => None,
            };
            if let Some(expected) = expected {
                let observed = format!(
                    "{:x}",
                    Sha256::digest(std::fs::read(&resolved).map_err(|error| {
                        PrismError::new("PP5008", format!("{}: {error}", resolved.display()))
                    })?)
                );
                if observed != expected {
                    return Err(PrismError::new(
                        "PP5008",
                        format!("required executable {name} has an unpinned digest"),
                    ));
                }
            }
            return Ok(candidate);
        }
    }
    Err(PrismError::new(
        "PP5008",
        format!("required executable {name} is unavailable"),
    ))
}

struct Toolchain {
    lake: PathBuf,
    rustfmt: PathBuf,
    rustc: PathBuf,
    records: Vec<ProcessRecord>,
}

fn preflight_toolchain(
    cwd: &Path,
    replacements: &[(&Path, &str)],
) -> Result<Toolchain, PrismError> {
    let lake = executable("lake")?;
    let lean = executable("lean")?;
    let rustfmt = executable("rustfmt")?;
    let rustc = executable("rustc")?;
    let timeout = executable("timeout")?;
    let no_env = BTreeMap::new();
    let specifications = [
        (
            "lean-version",
            lean.as_path(),
            vec!["--version".to_owned()],
            "Lean (version 4.32.1, x86_64-unknown-linux-gnu, commit f054605aea4b840552cca2e725580bffd1e1b704, Release)\n",
        ),
        (
            "lake-version",
            lake.as_path(),
            vec!["--version".to_owned()],
            "Lake version 5.0.0-src+f054605 (Lean version 4.32.1)\n",
        ),
        (
            "rustfmt-version",
            rustfmt.as_path(),
            vec!["--version".to_owned()],
            "rustfmt 1.9.0-stable (8bab26f4f6 2026-07-14)\n",
        ),
    ];
    let mut records = Vec::new();
    for (name, program, args, expected) in specifications {
        let record = run_process(name, program, &args, cwd, &no_env, replacements, "PP5008")?;
        if record.stdout != expected || !record.stderr.is_empty() {
            return Err(PrismError::new(
                "PP5008",
                format!("{name} did not report the pinned version"),
            ));
        }
        records.push(record);
    }
    let rustc_record = run_process(
        "rustc-version",
        &rustc,
        &["--version".to_owned(), "--verbose".to_owned()],
        cwd,
        &no_env,
        replacements,
        "PP5008",
    )?;
    for exact in [
        "commit-hash: 8bab26f4f68e0e26f0bb7960be334d5b520ea452",
        "host: x86_64-unknown-linux-gnu",
        "release: 1.97.1",
    ] {
        if !rustc_record.stdout.lines().any(|line| line == exact) {
            return Err(PrismError::new(
                "PP5008",
                "rustc-version did not report the pinned version",
            ));
        }
    }
    if !rustc_record.stderr.is_empty() {
        return Err(PrismError::new(
            "PP5008",
            "rustc-version wrote unexpected diagnostics",
        ));
    }
    records.push(rustc_record);
    let timeout_record = run_process(
        "timeout-version",
        &timeout,
        &["--version".to_owned()],
        cwd,
        &no_env,
        replacements,
        "PP5008",
    )?;
    if !timeout_record
        .stdout
        .starts_with("timeout (GNU coreutils) 9.1\n")
        || !timeout_record.stderr.is_empty()
    {
        return Err(PrismError::new(
            "PP5008",
            "timeout-version did not report the pinned version",
        ));
    }
    records.push(timeout_record);
    Ok(Toolchain {
        lake,
        rustfmt,
        rustc,
        records,
    })
}

fn normalized(value: &str, replacements: &[(&Path, &str)]) -> String {
    let mut out = value.to_owned();
    for (path, token) in replacements {
        out = out.replace(&path.to_string_lossy().replace('\\', "/"), token);
        out = out.replace(path.to_string_lossy().as_ref(), token);
    }
    out
}

fn stable_success_output(tool: &str, value: String) -> String {
    let had_final_newline = value.ends_with('\n');
    let mut value = value
        .lines()
        .map(|line| {
            if let Some((prefix, duration)) = line.rsplit_once(" in ") {
                if duration
                    .strip_suffix('s')
                    .is_some_and(|seconds| seconds.parse::<f64>().is_ok())
                {
                    return format!("{prefix} in <DURATION>");
                }
            }
            line.to_owned()
        })
        .collect::<Vec<_>>()
        .join("\n");
    if had_final_newline {
        value.push('\n');
    }
    if tool == "hologram-oracle-build" {
        return String::new();
    }
    if tool == "hologram-oracle" {
        return value
            .lines()
            .find(|line| line.starts_with('{'))
            .map_or_else(String::new, |line| format!("{line}\n"));
    }
    if !matches!(
        tool,
        "lake-build-generated" | "lean4-prod-build" | "prod-export"
    ) {
        return value;
    }
    let mut lines = value
        .lines()
        .map(|line| {
            let mut line = line.to_owned();
            for prefix in ["✔ [", "⚠ ["] {
                if line.starts_with(prefix) {
                    if let Some((_, message)) = line.split_once("] ") {
                        line = format!("{} {message}", &prefix[..prefix.len() - 2]);
                    }
                    break;
                }
            }
            if line.contains("Built ") {
                if let Some((prefix, suffix)) = line.rsplit_once(" (") {
                    if suffix.ends_with(')') {
                        return format!("{prefix} (<DURATION>)");
                    }
                }
            }
            line
        })
        .collect::<Vec<_>>();
    lines.sort();
    if lines.is_empty() {
        String::new()
    } else {
        format!("{}\n", lines.join("\n"))
    }
}

fn run_hologram_oracle(
    controller: &Controller,
    build_root: &Path,
    holo_path: &Path,
    model_path: &Path,
    wasm_path: &Path,
) -> Result<Vec<ProcessRecord>, PrismError> {
    if format!("{:x}", Sha256::digest(HOLOGRAM_ORACLE_SOURCE)) != HOLOGRAM_ORACLE_SOURCE_SHA256 {
        return Err(PrismError::new(
            "PP5301",
            "pinned Hologram Live oracle source checksum changed",
        ));
    }
    let work = tempfile::Builder::new()
        .prefix("prismpm-hologram-oracle-")
        .tempdir()
        .map_err(|error| PrismError::new("PP5301", format!("Hologram oracle: {error}")))?;
    let upstream = work.path().join("hologram-live");
    let harness = work.path().join("harness");
    std::fs::create_dir(&upstream)
        .and_then(|()| std::fs::create_dir(&harness))
        .map_err(|error| PrismError::new("PP5301", format!("Hologram oracle: {error}")))?;
    tar::Archive::new(std::io::Cursor::new(HOLOGRAM_ORACLE_SOURCE))
        .unpack(&upstream)
        .map_err(|error| PrismError::new("PP5301", format!("Hologram oracle source: {error}")))?;
    write(&harness.join("Cargo.toml"), HOLOGRAM_ORACLE_CARGO)?;
    write(&harness.join("Cargo.lock"), HOLOGRAM_ORACLE_LOCK)?;
    write(&harness.join("src/main.rs"), HOLOGRAM_ORACLE_MAIN)?;

    let cargo = executable("cargo")?;
    let replacements = [
        (controller.root.as_path(), "$PROJECT"),
        (build_root, "$BUILD"),
        (work.path(), "$ORACLE_WORK"),
    ];
    let mut env = BTreeMap::new();
    env.insert("CARGO_NET_OFFLINE".to_owned(), "true".to_owned());
    env.insert(
        "CARGO_TARGET_DIR".to_owned(),
        controller
            .root
            .join("target/hologram-oracle")
            .to_string_lossy()
            .into_owned(),
    );
    let build = run_process(
        "hologram-oracle-build",
        &cargo,
        &[
            "build".to_owned(),
            "--manifest-path".to_owned(),
            harness.join("Cargo.toml").to_string_lossy().into_owned(),
            "--locked".to_owned(),
            "--offline".to_owned(),
        ],
        &harness,
        &env,
        &replacements,
        "PP5301",
    )?;
    let run = run_process(
        "hologram-oracle",
        &cargo,
        &[
            "run".to_owned(),
            "--manifest-path".to_owned(),
            harness.join("Cargo.toml").to_string_lossy().into_owned(),
            "--locked".to_owned(),
            "--offline".to_owned(),
            "--".to_owned(),
            holo_path.to_string_lossy().into_owned(),
            model_path.to_string_lossy().into_owned(),
            wasm_path.to_string_lossy().into_owned(),
        ],
        &harness,
        &env,
        &replacements,
        "PP5301",
    )?;
    let report: Value = serde_json::from_str(run.stdout.trim())
        .map_err(|error| PrismError::new("PP5301", format!("Hologram oracle report: {error}")))?;
    if report.get("schema").and_then(Value::as_str) != Some("prismpm/hologram-oracle/1")
        || report.get("footer_verified").and_then(Value::as_bool) != Some(true)
    {
        return Err(PrismError::new(
            "PP5301",
            "pinned Hologram oracle did not return complete acceptance",
        ));
    }
    Ok(vec![build, run])
}

fn pipe<R: Read>(mut reader: R, limit: usize) -> std::io::Result<Vec<u8>> {
    let mut saved = Vec::new();
    let mut buffer = [0_u8; 8192];
    loop {
        let count = reader.read(&mut buffer)?;
        if count == 0 {
            break;
        }
        if saved.len() <= limit {
            let remaining = limit.saturating_add(1).saturating_sub(saved.len());
            saved.extend_from_slice(&buffer[..count.min(remaining)]);
        }
    }
    Ok(saved)
}

pub(crate) fn run_process(
    tool: &str,
    program: &Path,
    args: &[String],
    cwd: &Path,
    extra_env: &BTreeMap<String, String>,
    replacements: &[(&Path, &str)],
    failure_code: &'static str,
) -> Result<ProcessRecord, PrismError> {
    run_process_limited(
        tool,
        program,
        args,
        cwd,
        extra_env,
        replacements,
        failure_code,
        CHILD_TIMEOUT_SECONDS,
        CHILD_OUTPUT_LIMIT,
    )
}

#[allow(clippy::too_many_arguments)]
fn run_process_limited(
    tool: &str,
    program: &Path,
    args: &[String],
    cwd: &Path,
    extra_env: &BTreeMap<String, String>,
    replacements: &[(&Path, &str)],
    failure_code: &'static str,
    timeout_seconds: &str,
    output_limit: usize,
) -> Result<ProcessRecord, PrismError> {
    let timeout = executable("timeout")?;
    let program_bytes =
        std::fs::read(program).or_else(|_| program.canonicalize().and_then(std::fs::read));
    let executable_sha256 = format!(
        "{:x}",
        Sha256::digest(program_bytes.map_err(|error| {
            PrismError::new("PP5008", format!("{}: {error}", program.display()))
        })?)
    );
    let mut command = Command::new(timeout);
    command
        .arg("--signal=TERM")
        .arg("--kill-after=5")
        .arg(timeout_seconds)
        .arg(program)
        .args(args)
        .current_dir(cwd)
        .env_clear()
        .env("LC_ALL", "C")
        .env("LANG", "C")
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    for key in ["PATH", "ELAN_HOME", "RUSTUP_HOME", "CARGO_HOME"] {
        if let Some(value) = std::env::var_os(key) {
            command.env(key, value);
        }
    }
    for (key, value) in extra_env {
        command.env(key, value);
    }
    let mut child = command
        .spawn()
        .map_err(|error| PrismError::new("PP5008", format!("start {tool}: {error}")))?;
    let stdout = child
        .stdout
        .take()
        .ok_or_else(|| PrismError::new("PP9001", "child stdout pipe is missing"))?;
    let stderr = child
        .stderr
        .take()
        .ok_or_else(|| PrismError::new("PP9001", "child stderr pipe is missing"))?;
    let stdout_thread = std::thread::spawn(move || pipe(stdout, output_limit));
    let stderr_thread = std::thread::spawn(move || pipe(stderr, output_limit));
    let status = child
        .wait()
        .map_err(|error| PrismError::new(failure_code, format!("wait for {tool}: {error}")))?;
    let stdout = stdout_thread
        .join()
        .map_err(|_| PrismError::new("PP9001", "stdout reader terminated"))?
        .map_err(|error| PrismError::new(failure_code, format!("read stdout: {error}")))?;
    let stderr = stderr_thread
        .join()
        .map_err(|_| PrismError::new("PP9001", "stderr reader terminated"))?
        .map_err(|error| PrismError::new(failure_code, format!("read stderr: {error}")))?;
    if stdout.len() > output_limit || stderr.len() > output_limit {
        return Err(PrismError::new(
            "PP5007",
            format!("{tool} output limit exceeded"),
        ));
    }
    let exit_code = status.code().unwrap_or(128);
    let stdout = normalized(&String::from_utf8_lossy(&stdout), replacements);
    let stderr = normalized(&String::from_utf8_lossy(&stderr), replacements);
    if matches!(exit_code, 124 | 137) {
        return Err(PrismError::new("PP5007", format!("{tool} timed out")));
    }
    if !status.success() {
        return Err(PrismError::new(
            failure_code,
            format!("{tool} exited {exit_code}: stdout={stdout:?}; stderr={stderr:?}"),
        ));
    }
    let stdout = stable_success_output(tool, stdout);
    let stderr = stable_success_output(tool, stderr);
    Ok(ProcessRecord {
        tool: tool.to_owned(),
        argv: args
            .iter()
            .map(|arg| normalized(arg, replacements))
            .collect(),
        executable_sha256,
        exit_code,
        stdout,
        stderr,
    })
}

fn write(path: &Path, bytes: &[u8]) -> Result<(), PrismError> {
    let parent = path
        .parent()
        .ok_or_else(|| PrismError::new("PP4002", "staged file has no parent"))?;
    std::fs::create_dir_all(parent)
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", parent.display())))?;
    let mut file = File::create(path)
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", path.display())))?;
    file.write_all(bytes)
        .and_then(|()| file.sync_all())
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", path.display())))
}

fn hash_file(path: &Path) -> Result<String, PrismError> {
    Ok(format!(
        "{:x}",
        Sha256::digest(std::fs::read(path).map_err(|error| {
            PrismError::new("PP4002", format!("{}: {error}", path.display()))
        })?)
    ))
}

fn harness(
    model: &crate::holo::model_document::ModelDocument,
    corpus: &ExecutionCorpus,
    corpus_sha256: &str,
) -> String {
    let indexes = model
        .architecture
        .components
        .iter()
        .map(|row| row.index.to_string())
        .collect::<Vec<_>>()
        .join(",");
    let endpoints = model
        .architecture
        .edges
        .iter()
        .flat_map(|row| [row.from_index, row.to_index])
        .map(|value| value.to_string())
        .collect::<Vec<_>>()
        .join(",");
    let risk_asset_links = model
        .security
        .risks
        .iter()
        .map(|row| row.asset_index.to_string())
        .collect::<Vec<_>>()
        .join(",");
    let risk_threat_links = model
        .security
        .risks
        .iter()
        .map(|row| row.threat_index.to_string())
        .collect::<Vec<_>>()
        .join(",");
    let control_links = model
        .security
        .controls
        .iter()
        .map(|row| row.risk_index.to_string())
        .collect::<Vec<_>>()
        .join(",");
    let viewpoint_stakeholder_links = model
        .architecture
        .viewpoints
        .iter()
        .map(|row| row.stakeholder_index.to_string())
        .collect::<Vec<_>>()
        .join(",");
    let viewpoint_concern_links = model
        .architecture
        .viewpoints
        .iter()
        .map(|row| row.concern_index.to_string())
        .collect::<Vec<_>>()
        .join(",");
    let viewpoint_model_kind_links = model
        .architecture
        .viewpoints
        .iter()
        .map(|row| row.model_kind_index.to_string())
        .collect::<Vec<_>>()
        .join(",");
    let quality_characteristic_links = model
        .quality
        .subcharacteristics
        .iter()
        .map(|row| row.characteristic_index)
        .map(|value| value.to_string())
        .collect::<Vec<_>>()
        .join(",");
    let quality_subcharacteristic_links = model
        .quality
        .requirements
        .iter()
        .map(|row| row.subcharacteristic_index.to_string())
        .collect::<Vec<_>>()
        .join(",");
    let quality_requirement_links = model
        .quality
        .measures
        .iter()
        .map(|row| row.requirement_index.to_string())
        .collect::<Vec<_>>()
        .join(",");
    format!(
        r#"#![allow(dead_code, non_snake_case)]
use prod_alloc_counter::{{activity, CountingAllocator}};
use std::sync::atomic::{{AtomicUsize, Ordering}};

#[global_allocator]
static GLOBAL: CountingAllocator = CountingAllocator;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ComputeError {{ AddOverflow, MulOverflow, ShiftExponentTooLarge, ShiftOverflow, PowExponentTooLarge, PowOverflow, OutputTooSmall }}
include!("generated.rs");

static BEFORE: AtomicUsize = AtomicUsize::new(0);
fn begin() {{ BEFORE.store(activity(), Ordering::SeqCst); }}
fn end() -> bool {{ activity() == BEFORE.load(Ordering::SeqCst) }}
fn fail(code: i32) -> ! {{ std::process::exit(code) }}
fn main() {{
    let component_indexes: &[u64] = &[{indexes}];
    let endpoints: &[u64] = &[{endpoints}];
    let risk_asset_links: &[u64] = &[{risk_asset_links}];
    let risk_threat_links: &[u64] = &[{risk_threat_links}];
    let control_links: &[u64] = &[{control_links}];
    let viewpoint_stakeholder_links: &[u64] = &[{viewpoint_stakeholder_links}];
    let viewpoint_concern_links: &[u64] = &[{viewpoint_concern_links}];
    let viewpoint_model_kind_links: &[u64] = &[{viewpoint_model_kind_links}];
    let quality_characteristic_links: &[u64] = &[{quality_characteristic_links}];
    let quality_subcharacteristic_links: &[u64] = &[{quality_subcharacteristic_links}];
    let quality_requirement_links: &[u64] = &[{quality_requirement_links}];
    begin(); let a = validateComponentIndexes(component_indexes); if !end() || a != Ok(true) {{ fail(10); }}
    begin(); let b = validateEdgeEndpoints({component_count}, endpoints); if !end() || !b {{ fail(11); }}
    begin(); let c1 = validateRiskLinks({asset_count}, risk_asset_links); if !end() || !c1 {{ fail(12); }}
    begin(); let c2 = validateRiskLinks({threat_count}, risk_threat_links); if !end() || !c2 {{ fail(12); }}
    begin(); let d = validateControlLinks({risk_count}, control_links); if !end() || !d {{ fail(13); }}
    begin(); let e1 = validateViewpointLinks({stakeholder_count}, viewpoint_stakeholder_links); if !end() || !e1 {{ fail(14); }}
    begin(); let e2 = validateViewpointLinks({concern_count}, viewpoint_concern_links); if !end() || !e2 {{ fail(14); }}
    begin(); let e3 = validateViewpointLinks({model_kind_count}, viewpoint_model_kind_links); if !end() || !e3 {{ fail(14); }}
    begin(); let f1 = validateQualityLinks({characteristic_count}, quality_characteristic_links); if !end() || !f1 {{ fail(15); }}
    begin(); let f2 = validateQualityLinks({subcharacteristic_count}, quality_subcharacteristic_links); if !end() || !f2 {{ fail(15); }}
    begin(); let f3 = validateQualityLinks({requirement_count}, quality_requirement_links); if !end() || !f3 {{ fail(15); }}
    begin(); let g = validateFlattenedBounds({component_count}, component_indexes); if !end() || !g {{ fail(16); }}
    let profile = StandardsProfile {{ architectureEdition: 2022, applicationSecurityEdition: 2011, controlEdition: 2017, riskEdition: 2022, qualityEdition: 2023 }};
    begin(); let p = validateExactStandardsProfile(profile); if !end() || !p {{ fail(17); }}
    begin(); let bad = validateEdgeEndpoints({component_count}, &[{component_count}]); if !end() || bad {{ fail(18); }}
    begin(); let overflow = allConsecutive(u64::MAX, &[u64::MAX]); if !end() || overflow != Err(ComputeError::AddOverflow) {{ fail(19); }}
    let mut canonical = [0u64; 3];
    begin(); let written = canonicalIndexes(0, 3, &mut canonical); if !end() || written != Ok(3) || canonical != [0, 1, 2] {{ fail(23); }}
    let mut too_small = [0u64; 0];
    begin(); let exhausted = canonicalIndexes(0, 1, &mut too_small); if !end() || exhausted != Err(ComputeError::OutputTooSmall) {{ fail(24); }}

    let mut corpus = 0u64;
    let mut values = [0u64; 16];
    for len in 0usize..={exhaustive_max_length} {{
        let total = {exhaustive_width}usize.pow(len as u32);
        for encoded in 0..total {{
            let mut cursor = encoded;
            for slot in values.iter_mut().take(len) {{ *slot = (cursor % {exhaustive_width}) as u64; cursor /= {exhaustive_width}; }}
            let slice = &values[..len];
            let expected_below = slice.iter().all(|value| *value < {exhaustive_bound});
            begin(); let observed = allBelow({exhaustive_bound}, slice); if !end() || observed != expected_below {{ fail(20); }}
            begin(); let observed = validateEdgeEndpoints({exhaustive_bound}, slice); if !end() || observed != expected_below {{ fail(25); }}
            begin(); let observed = validateRiskLinks({exhaustive_bound}, slice); if !end() || observed != expected_below {{ fail(26); }}
            begin(); let observed = validateControlLinks({exhaustive_bound}, slice); if !end() || observed != expected_below {{ fail(27); }}
            begin(); let observed = validateViewpointLinks({exhaustive_bound}, slice); if !end() || observed != expected_below {{ fail(28); }}
            begin(); let observed = validateQualityLinks({exhaustive_bound}, slice); if !end() || observed != expected_below {{ fail(29); }}
            begin(); let observed = validateFlattenedBounds({exhaustive_bound}, slice); if !end() || observed != expected_below {{ fail(30); }}
            let expected_consecutive = slice.iter().enumerate().all(|(index, value)| *value == index as u64);
            begin(); let observed = validateComponentIndexes(slice); if !end() || observed != Ok(expected_consecutive) {{ fail(21); }}
            let start = (encoded % 2) as u64;
            let mut output = [0u64; 16];
            begin(); let observed = canonicalIndexes(start, len as u64, &mut output[..len]); if !end() || observed != Ok(len) {{ fail(31); }}
            if output[..len].iter().enumerate().any(|(index, value)| *value != start + index as u64) {{ fail(32); }}
            let mut candidate = StandardsProfile {{ architectureEdition: 2022, applicationSecurityEdition: 2011, controlEdition: 2017, riskEdition: 2022, qualityEdition: 2023 }};
            if encoded != 0 {{ match encoded % 5 {{ 0 => candidate.architectureEdition = 0, 1 => candidate.applicationSecurityEdition = 0, 2 => candidate.controlEdition = 0, 3 => candidate.riskEdition = 0, _ => candidate.qualityEdition = 0 }} }}
            begin(); let observed = validateExactStandardsProfile(candidate); if !end() || observed != (encoded == 0) {{ fail(33); }}
            corpus += 1;
        }}
    }}
    let mut seed = 0x{seed}u64;
    for case in 0usize..{property_cases} {{
        seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        let len = if case == {last_property_case} {{ {property_max_length}usize }} else {{ (seed as usize) % {property_length_width} }};
        for (index, slot) in values.iter_mut().take(len).enumerate() {{
            seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            *slot = if case == {last_property_case} && index == 0 {{ u64::MAX }} else {{ seed % {property_value_modulus} }};
        }}
        let slice = &values[..len];
        let expected = slice.iter().all(|value| *value < {property_bound});
        begin(); let observed = validateFlattenedBounds({property_bound}, slice); if !end() || observed != expected {{ fail(22); }}
        begin(); let observed = allBelow({property_bound}, slice); if !end() || observed != expected {{ fail(34); }}
        begin(); let observed = validateEdgeEndpoints({property_bound}, slice); if !end() || observed != expected {{ fail(35); }}
        begin(); let observed = validateRiskLinks({property_bound}, slice); if !end() || observed != expected {{ fail(36); }}
        begin(); let observed = validateControlLinks({property_bound}, slice); if !end() || observed != expected {{ fail(37); }}
        begin(); let observed = validateViewpointLinks({property_bound}, slice); if !end() || observed != expected {{ fail(38); }}
        begin(); let observed = validateQualityLinks({property_bound}, slice); if !end() || observed != expected {{ fail(39); }}
        let expected_consecutive = slice.iter().enumerate().all(|(index, value)| *value == index as u64);
        begin(); let observed = validateComponentIndexes(slice); if !end() || observed != Ok(expected_consecutive) {{ fail(40); }}
        corpus += 1;
    }}
    println!("{{{{\"bounds\":{{{{\"max_length\":{property_max_length},\"value_domain\":\"{value_domain}\"}}}},\"case_count\":{{}},\"corpus_sha256\":\"{corpus_sha256}\",\"no_allocation\":true,\"no_panic\":true,\"schema\":\"prismpm/execution-evidence/1\",\"seed\":\"{seed}\",\"shrink_result\":\"{shrink_result}\",\"status\":\"passed\",\"strategy\":\"{strategy}\"}}}}", corpus);
}}
"#,
        indexes = indexes,
        endpoints = endpoints,
        risk_asset_links = risk_asset_links,
        risk_threat_links = risk_threat_links,
        control_links = control_links,
        viewpoint_stakeholder_links = viewpoint_stakeholder_links,
        viewpoint_concern_links = viewpoint_concern_links,
        viewpoint_model_kind_links = viewpoint_model_kind_links,
        quality_characteristic_links = quality_characteristic_links,
        quality_subcharacteristic_links = quality_subcharacteristic_links,
        quality_requirement_links = quality_requirement_links,
        component_count = model.architecture.components.len(),
        asset_count = model.security.assets.len(),
        threat_count = model.security.threats.len(),
        risk_count = model.security.risks.len(),
        stakeholder_count = model.architecture.stakeholders.len(),
        concern_count = model.architecture.concerns.len(),
        model_kind_count = model.architecture.model_kinds.len(),
        characteristic_count = model.quality.characteristics.len(),
        subcharacteristic_count = model.quality.subcharacteristics.len(),
        requirement_count = model.quality.requirements.len(),
        exhaustive_max_length = corpus.exhaustive.max_length,
        exhaustive_width = corpus.exhaustive.value_max + 1,
        exhaustive_bound = corpus.exhaustive.all_below_bound,
        seed = corpus.seed.as_str(),
        property_cases = corpus.property.case_count,
        property_length_width = corpus.property.max_length + 1,
        last_property_case = corpus.property.case_count - 1,
        property_value_modulus = corpus.property.generated_value_modulus,
        property_bound = corpus.property.all_below_bound,
        property_max_length = corpus.property.max_length,
        value_domain = corpus.value_domain.as_str(),
        corpus_sha256 = corpus_sha256,
        strategy = corpus.strategy.as_str(),
        shrink_result = corpus.property.shrink_result.as_str(),
    )
}

fn exact_array(value: &Value, key: &str) -> Result<Vec<String>, PrismError> {
    value
        .get(key)
        .and_then(Value::as_array)
        .ok_or_else(|| PrismError::new("PP5004", format!("coverage field {key} is missing")))?
        .iter()
        .map(|value| {
            value
                .as_str()
                .map(str::to_owned)
                .ok_or_else(|| PrismError::new("PP5004", "coverage array is malformed"))
        })
        .collect()
}

fn validate_lexlean_declarations(
    value: &Value,
    snapshot: &Value,
    corpus: &ExecutionCorpus,
) -> Result<(), PrismError> {
    let declarations = value
        .get("declarations")
        .and_then(Value::as_array)
        .ok_or_else(|| PrismError::new("PP4004", "LexLean declaration audit is absent"))?;
    let modules = snapshot
        .get("modules")
        .and_then(Value::as_array)
        .ok_or_else(|| PrismError::new("PP4004", "LexLean snapshot modules are absent"))?;
    let mut expected = BTreeMap::new();
    for module in modules {
        let lean_module = module
            .get("lean_module")
            .and_then(Value::as_str)
            .ok_or_else(|| PrismError::new("PP4004", "snapshot Lean module is absent"))?;
        let module_declarations = module
            .get("declarations")
            .and_then(Value::as_array)
            .ok_or_else(|| PrismError::new("PP4004", "snapshot declarations are absent"))?;
        for declaration in module_declarations {
            let lean_name = declaration
                .get("lean_name")
                .and_then(Value::as_str)
                .ok_or_else(|| PrismError::new("PP4004", "snapshot declaration name is absent"))?;
            let full_name = format!("{lean_module}.{lean_name}");
            if full_name.starts_with("PrismPM.")
                && expected.insert(full_name.clone(), declaration).is_some()
            {
                return Err(PrismError::new(
                    "PP4004",
                    format!("duplicate snapshot declaration {full_name}"),
                ));
            }
        }
    }
    if expected.is_empty() {
        return Err(PrismError::new(
            "PP5003",
            "LexLean snapshot contains no Prism declarations",
        ));
    }
    let mut audited = BTreeSet::new();
    for declaration in declarations {
        let name = declaration
            .get("name")
            .and_then(Value::as_str)
            .ok_or_else(|| PrismError::new("PP4004", "LexLean declaration name is absent"))?;
        if name.starts_with("PrismPM.") {
            let snapshot_declaration = expected.get(name).ok_or_else(|| {
                PrismError::new(
                    "PP5003",
                    format!("axiom audit names undeclared Prism declaration {name}"),
                )
            })?;
            if !audited.insert(name.to_owned()) {
                return Err(PrismError::new(
                    "PP5003",
                    format!("duplicate axiom audit for Prism declaration {name}"),
                ));
            }
            let observed = declaration
                .get("observed")
                .and_then(Value::as_array)
                .ok_or_else(|| {
                    PrismError::new("PP4004", format!("axiom audit is absent for {name}"))
                })?;
            if observed.iter().any(|axiom| axiom.as_str().is_none()) {
                return Err(PrismError::new(
                    "PP4004",
                    format!("axiom audit is malformed for {name}"),
                ));
            }
            if declaration.get("result").and_then(Value::as_str) != Some("ok") {
                return Err(PrismError::new(
                    "PP5003",
                    format!("Prism declaration {name} failed its axiom policy audit"),
                ));
            }
            if declaration.get("policy") != snapshot_declaration.get("axiom_policy") {
                return Err(PrismError::new(
                    "PP5003",
                    format!("Prism declaration {name} audit policy differs from its snapshot"),
                ));
            }
            if snapshot_declaration.get("kind").and_then(Value::as_str) == Some("theorem")
                && !observed.is_empty()
            {
                return Err(PrismError::new(
                    "PP5003",
                    format!("Prism theorem {name} has a nonempty axiom audit"),
                ));
            }
            let observed_names = observed
                .iter()
                .map(|axiom| axiom.as_str().expect("validated axiom name"))
                .collect::<Vec<_>>();
            let policy_kind = declaration
                .pointer("/policy/kind")
                .and_then(Value::as_str)
                .ok_or_else(|| {
                    PrismError::new("PP4004", format!("axiom policy kind is absent for {name}"))
                })?;
            let policy_names = declaration
                .pointer("/policy/axioms")
                .and_then(Value::as_array)
                .ok_or_else(|| {
                    PrismError::new(
                        "PP4004",
                        format!("axiom policy names are absent for {name}"),
                    )
                })?
                .iter()
                .map(|axiom| {
                    axiom.as_str().ok_or_else(|| {
                        PrismError::new("PP4004", format!("axiom policy is malformed for {name}"))
                    })
                })
                .collect::<Result<Vec<_>, _>>()?;
            let permitted = match policy_kind {
                "none" => policy_names.is_empty() && observed_names.is_empty(),
                "exact" => observed_names == policy_names,
                "allow" => observed_names
                    .iter()
                    .all(|axiom| policy_names.contains(axiom)),
                _ => false,
            };
            if !permitted {
                return Err(PrismError::new(
                    "PP5003",
                    format!("Prism declaration {name} has an unapproved axiom audit"),
                ));
            }
        }
    }
    if audited.len() != expected.len() {
        let missing = expected
            .keys()
            .find(|name| !audited.contains(*name))
            .expect("unequal declaration sets have a missing member");
        return Err(PrismError::new(
            "PP5003",
            format!("Prism declaration {missing} has no axiom audit"),
        ));
    }
    for oracle in &corpus.oracle {
        let audit = declarations.iter().find(|declaration| {
            declaration.get("name").and_then(Value::as_str) == Some(oracle.theorem.as_str())
        });
        if !audit.is_some_and(|declaration| {
            declaration
                .get("observed")
                .and_then(Value::as_array)
                .is_some_and(Vec::is_empty)
                && declaration.pointer("/policy/kind").and_then(Value::as_str) == Some("none")
        }) {
            return Err(PrismError::new(
                "PP5003",
                format!(
                    "execution oracle theorem {} has no exact empty axiom audit",
                    oracle.theorem
                ),
            ));
        }
    }
    Ok(())
}

fn validate_coverage(value: &Value, roots: &[String]) -> Result<(), PrismError> {
    let object = value
        .as_object()
        .ok_or_else(|| PrismError::new("PP5004", "coverage is not an object"))?;
    if object.keys().map(String::as_str).collect::<Vec<_>>()
        != [
            "erased_proof_dependencies",
            "external_calls",
            "included_definitions",
            "opaque_nodes",
            "requested_roots",
            "unsupported_types",
        ]
    {
        return Err(PrismError::new(
            "PP5004",
            "named export coverage has the wrong fields",
        ));
    }
    let included = exact_array(value, "included_definitions")?;
    let included_set = included.iter().collect::<std::collections::BTreeSet<_>>();
    if exact_array(value, "requested_roots")? != roots
        || included.len() != included_set.len()
        || included.windows(2).any(|pair| pair[0] >= pair[1])
        || roots
            .iter()
            .any(|root| included.binary_search(root).is_err())
        || !exact_array(value, "erased_proof_dependencies")?.is_empty()
        || !exact_array(value, "opaque_nodes")?.is_empty()
        || !exact_array(value, "external_calls")?.is_empty()
        || !exact_array(value, "unsupported_types")?.is_empty()
    {
        return Err(PrismError::new(
            "PP5004",
            "named export coverage is unacceptable",
        ));
    }
    Ok(())
}

fn parse_kernel(text: &str) -> Result<prod_ir::Module, PrismError> {
    let (remaining, module) = prod_ir::parser::parse_module(text)
        .map_err(|_| PrismError::new("PP5004", "kernel.ir is malformed"))?;
    if !remaining.trim().is_empty() {
        return Err(PrismError::new("PP5004", "kernel.ir has trailing syntax"));
    }
    Ok(module)
}

fn validate_execution(
    value: &Value,
    corpus: &ExecutionCorpus,
    corpus_sha256: &str,
) -> Result<(), PrismError> {
    let object = value
        .as_object()
        .ok_or_else(|| PrismError::new("PP5006", "execution evidence is not an object"))?;
    let keys = object.keys().map(String::as_str).collect::<Vec<_>>();
    let bounds_keys = value
        .get("bounds")
        .and_then(Value::as_object)
        .map(|bounds| bounds.keys().map(String::as_str).collect::<Vec<_>>());
    if keys
        != [
            "bounds",
            "case_count",
            "corpus_sha256",
            "no_allocation",
            "no_panic",
            "schema",
            "seed",
            "shrink_result",
            "status",
            "strategy",
        ]
        || bounds_keys.as_deref() != Some(&["max_length", "value_domain"])
        || value.get("schema").and_then(Value::as_str) != Some("prismpm/execution-evidence/1")
        || value.get("status").and_then(Value::as_str) != Some("passed")
        || value.get("no_allocation").and_then(Value::as_bool) != Some(true)
        || value.get("no_panic").and_then(Value::as_bool) != Some(true)
        || value.get("case_count").and_then(Value::as_u64) != Some(corpus.case_count)
        || value.get("corpus_sha256").and_then(Value::as_str) != Some(corpus_sha256)
        || value.get("seed").and_then(Value::as_str) != Some(corpus.seed.as_str())
        || value.get("strategy").and_then(Value::as_str) != Some(corpus.strategy.as_str())
        || value.get("shrink_result").and_then(Value::as_str)
            != Some(corpus.property.shrink_result.as_str())
        || value.pointer("/bounds/max_length").and_then(Value::as_u64)
            != u64::try_from(corpus.property.max_length).ok()
        || value
            .pointer("/bounds/value_domain")
            .and_then(Value::as_str)
            != Some(corpus.value_domain.as_str())
    {
        return Err(PrismError::new(
            "PP5006",
            "execution evidence is incomplete or noncanonical",
        ));
    }
    Ok(())
}

fn publish(
    output_root: &Path,
    attestation_id: &str,
    files: &[(String, Vec<u8>)],
) -> Result<(), PrismError> {
    std::fs::create_dir_all(output_root).map_err(|error| {
        PrismError::new("PP4002", format!("{}: {error}", output_root.display()))
    })?;
    let lock_path = output_root.join(".prismpm.lock");
    let lock = OpenOptions::new()
        .create(true)
        .truncate(false)
        .write(true)
        .open(&lock_path)
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", lock_path.display())))?;
    lock.lock_exclusive()
        .map_err(|error| PrismError::new("PP4002", format!("verification lock: {error}")))?;
    let parent = output_root.join("verified");
    std::fs::create_dir_all(&parent)
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", parent.display())))?;
    let destination = parent.join(attestation_id);
    if destination.exists() {
        let expected_paths = files
            .iter()
            .map(|(relative, _)| relative.as_str())
            .collect::<std::collections::BTreeSet<_>>();
        let mut expected_directories = std::collections::BTreeSet::new();
        for relative in &expected_paths {
            let mut parent = Path::new(relative).parent();
            while let Some(path) = parent.filter(|path| !path.as_os_str().is_empty()) {
                expected_directories.insert(path.to_string_lossy().replace('\\', "/"));
                parent = path.parent();
            }
        }
        let mut observed_paths = std::collections::BTreeSet::new();
        let mut observed_directories = std::collections::BTreeSet::new();
        for entry in walkdir::WalkDir::new(&destination).min_depth(1) {
            let entry = entry.map_err(|error| {
                PrismError::new("PP4002", format!("verified artifact walk: {error}"))
            })?;
            if entry.file_type().is_symlink() {
                return Err(PrismError::new(
                    "PP4001",
                    "verified artifact contains a symlink",
                ));
            }
            if entry.file_type().is_file() {
                let relative = entry
                    .path()
                    .strip_prefix(&destination)
                    .map_err(|_| PrismError::new("PP9001", "verified artifact path escaped"))?
                    .to_string_lossy()
                    .replace('\\', "/");
                observed_paths.insert(relative);
            } else if entry.file_type().is_dir() {
                observed_directories.insert(
                    entry
                        .path()
                        .strip_prefix(&destination)
                        .map_err(|_| PrismError::new("PP9001", "verified directory path escaped"))?
                        .to_string_lossy()
                        .replace('\\', "/"),
                );
            } else {
                return Err(PrismError::new(
                    "PP4001",
                    "verified artifact contains a non-file entry",
                ));
            }
        }
        if observed_paths
            .iter()
            .map(String::as_str)
            .collect::<std::collections::BTreeSet<_>>()
            != expected_paths
            || observed_directories != expected_directories
        {
            return Err(PrismError::new(
                "PP4001",
                "verified artifact set differs from its manifest",
            ));
        }
        for (relative, expected) in files {
            let path = destination.join(relative);
            if !std::fs::symlink_metadata(&path)
                .map(|metadata| metadata.file_type().is_file())
                .unwrap_or(false)
            {
                return Err(PrismError::new(
                    "PP4001",
                    "verified artifact is not a regular file",
                ));
            }
            let observed = std::fs::read(path)
                .map_err(|_| PrismError::new("PP4002", "verified artifact is missing"))?;
            if &observed != expected {
                return Err(PrismError::new("PP4001", "verified artifact was modified"));
            }
        }
        return Ok(());
    }
    let staging_parent = output_root.join(".verify-staging");
    std::fs::create_dir_all(&staging_parent)
        .map_err(|error| PrismError::new("PP4002", format!("staging: {error}")))?;
    let staging = tempfile::Builder::new()
        .prefix("verify-")
        .tempdir_in(staging_parent)
        .map_err(|error| PrismError::new("PP4002", format!("staging: {error}")))?;
    for (relative, bytes) in files {
        write(&staging.path().join(relative), bytes)?;
    }
    File::open(staging.path())
        .and_then(|file| file.sync_all())
        .map_err(|error| PrismError::new("PP4002", format!("verification fsync: {error}")))?;
    std::fs::rename(staging.path(), &destination)
        .map_err(|error| PrismError::new("PP4002", format!("verification publish: {error}")))?;
    File::open(parent)
        .and_then(|file| file.sync_all())
        .map_err(|error| PrismError::new("PP4002", format!("verified fsync: {error}")))?;
    drop(lock);
    Ok(())
}

fn verify_application_build_closure(build_root: &Path, manifest: &Value) -> Result<(), PrismError> {
    let rows = manifest
        .get("files")
        .and_then(Value::as_array)
        .ok_or_else(|| PrismError::new("PP4004", "application build file manifest is absent"))?;
    let mut expected = BTreeMap::new();
    for row in rows {
        let path = row
            .get("path")
            .and_then(Value::as_str)
            .ok_or_else(|| PrismError::new("PP4004", "application artifact path is absent"))?;
        if path == "manifest.json"
            || Path::new(path).is_absolute()
            || Path::new(path)
                .components()
                .any(|component| !matches!(component, std::path::Component::Normal(_)))
        {
            return Err(PrismError::new(
                "PP4004",
                format!("application artifact path is invalid: {path}"),
            ));
        }
        let length = row
            .get("byte_length")
            .and_then(Value::as_u64)
            .ok_or_else(|| PrismError::new("PP4004", "application artifact size is absent"))?;
        let digest = row
            .get("sha256")
            .and_then(Value::as_str)
            .ok_or_else(|| PrismError::new("PP4004", "application artifact hash is absent"))?;
        if digest.len() != 64
            || !digest
                .bytes()
                .all(|byte| byte.is_ascii_hexdigit() && !byte.is_ascii_uppercase())
            || expected
                .insert(path.to_owned(), (length, digest.to_owned()))
                .is_some()
        {
            return Err(PrismError::new(
                "PP4004",
                "application artifact row is invalid or duplicated",
            ));
        }
    }
    let mut observed = BTreeSet::new();
    for entry in walkdir::WalkDir::new(build_root).min_depth(1) {
        let entry = entry.map_err(|error| {
            PrismError::new("PP4002", format!("application artifact walk: {error}"))
        })?;
        if entry.file_type().is_symlink()
            || (!entry.file_type().is_file() && !entry.file_type().is_dir())
        {
            return Err(PrismError::new(
                "PP4001",
                "application artifact closure contains a symlink or special file",
            ));
        }
        if !entry.file_type().is_file() {
            continue;
        }
        let path = entry
            .path()
            .strip_prefix(build_root)
            .map_err(|_| PrismError::new("PP9001", "application artifact path escaped"))?
            .to_string_lossy()
            .replace('\\', "/");
        if path == "manifest.json" {
            continue;
        }
        let (length, digest) = expected.get(&path).ok_or_else(|| {
            PrismError::new("PP4001", format!("undeclared application artifact: {path}"))
        })?;
        let bytes = std::fs::read(entry.path()).map_err(|error| {
            PrismError::new("PP4002", format!("{}: {error}", entry.path().display()))
        })?;
        if bytes.len() as u64 != *length || format!("{:x}", Sha256::digest(&bytes)) != *digest {
            return Err(PrismError::new(
                "PP4001",
                format!("application artifact does not match its manifest: {path}"),
            ));
        }
        observed.insert(path);
    }
    if observed.len() != expected.len() || expected.keys().any(|path| !observed.contains(path)) {
        return Err(PrismError::new(
            "PP4001",
            "application artifact closure is incomplete",
        ));
    }
    Ok(())
}

fn copy_application_package(build_root: &Path, destination: &Path) -> Result<(), PrismError> {
    let source = build_root.join("cargo/package");
    for entry in walkdir::WalkDir::new(&source).min_depth(1) {
        let entry = entry
            .map_err(|error| PrismError::new("PP4002", format!("generated package: {error}")))?;
        let relative = entry
            .path()
            .strip_prefix(&source)
            .map_err(|_| PrismError::new("PP9001", "generated package path escaped"))?;
        let target = destination.join(relative);
        if entry.file_type().is_dir() {
            std::fs::create_dir_all(&target).map_err(|error| {
                PrismError::new("PP4002", format!("{}: {error}", target.display()))
            })?;
        } else if entry.file_type().is_file() && !entry.file_type().is_symlink() {
            write(
                &target,
                &std::fs::read(entry.path()).map_err(|error| {
                    PrismError::new("PP4002", format!("{}: {error}", entry.path().display()))
                })?,
            )?;
        } else {
            return Err(PrismError::new(
                "PP4001",
                "generated package contains a symlink or special file",
            ));
        }
    }
    Ok(())
}

fn application_harness(
    application: &crate::holo::model_document::ApplicationModel,
) -> Result<String, PrismError> {
    let crate_name = application.cargo_name.replace('-', "_");
    let entry = application
        .entry_root
        .rsplit('.')
        .next()
        .ok_or_else(|| PrismError::new("PP2001", "application entry root is malformed"))?;
    let vectors = application
        .acceptance_vectors
        .iter()
        .enumerate()
        .map(|(index, vector)| {
            format!(
                "    assert_eq!({crate_name}::{entry}(vec!{:?}), vec!{:?}, \"acceptance vector {index}\");\n",
                vector.request, vector.response
            )
        })
        .collect::<String>();
    Ok(format!("fn main() {{\n{vectors}}}\n"))
}

#[allow(clippy::too_many_arguments)]
fn run_application(
    controller: &Controller,
    config: &ProjectConfig,
    build: BuildResult,
    model: crate::holo::model_document::ModelDocument,
    model_bytes: Vec<u8>,
    build_manifest: Value,
    build_root: &Path,
    lex_attestation: Vec<u8>,
    lex_attestation_id: String,
    mut processes: Vec<ProcessRecord>,
) -> Result<VerifyResult, PrismError> {
    let application = model.application.as_ref().ok_or_else(|| {
        PrismError::new(
            "PP9001",
            "application verification received a non-application model",
        )
    })?;
    verify_application_build_closure(build_root, &build_manifest)?;
    let holo_path = build_root.join(format!("{}.holo", application.name));
    let holo = std::fs::read(&holo_path)
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", holo_path.display())))?;
    crate::holo::archive::validate_application(&holo)?;
    let wasm_path = build_root.join(format!(
        "core-wasm/{}_core_wasm.wasm",
        application.cargo_name.replace('-', "_")
    ));
    processes.extend(run_hologram_oracle(
        controller,
        build_root,
        &holo_path,
        &build_root.join("model.prism.json"),
        &wasm_path,
    )?);
    let wasm_tools = executable("wasm-tools")?;
    let no_env = BTreeMap::new();
    let replacements = [
        (controller.root.as_path(), "$PROJECT"),
        (build_root, "$BUILD"),
    ];
    processes.push(run_process(
        "core-wasm-validate",
        &wasm_tools,
        &[
            "validate".to_owned(),
            wasm_path.to_string_lossy().into_owned(),
        ],
        build_root,
        &no_env,
        &replacements,
        "PP5101",
    )?);
    let printed = run_process(
        "core-wasm-inspect",
        &wasm_tools,
        &["print".to_owned(), wasm_path.to_string_lossy().into_owned()],
        build_root,
        &no_env,
        &replacements,
        "PP5101",
    )?;
    if printed.stdout.contains("(import ")
        || !printed.stdout.contains("(export \"memory\"")
        || !printed.stdout.contains("(export \"holo_alloc\"")
        || !printed.stdout.contains("(export \"holo_run\"")
    {
        return Err(PrismError::new(
            "PP5103",
            "Core-Wasm imports or exports disagree with the closed guest ABI",
        ));
    }
    processes.push(printed);

    let work = tempfile::Builder::new()
        .prefix("prismpm-application-verify-")
        .tempdir()
        .map_err(|error| PrismError::new("PP4002", format!("application verification: {error}")))?;
    let package_root = work.path().join("package");
    std::fs::create_dir(&package_root)
        .map_err(|error| PrismError::new("PP4002", format!("package staging: {error}")))?;
    copy_application_package(build_root, &package_root)?;
    let crate_path = build_root.join(format!(
        "cargo/{}-{}.crate",
        application.cargo_name, application.cargo_version
    ));
    let crate_bytes = std::fs::read(&crate_path)
        .map_err(|error| PrismError::new("PP4102", format!("generated crate: {error}")))?;
    let cargo_home =
        crate::application_build::application_cargo_home(work.path(), application, &crate_bytes)?;
    let mut cargo_env = BTreeMap::new();
    cargo_env.insert(
        "CARGO_HOME".to_owned(),
        cargo_home.to_string_lossy().into_owned(),
    );
    cargo_env.insert("CARGO_NET_OFFLINE".to_owned(), "true".to_owned());
    let cargo = executable("cargo")?;
    let app_replacements = [
        (controller.root.as_path(), "$PROJECT"),
        (build_root, "$BUILD"),
        (work.path(), "$VERIFY_WORK"),
    ];
    for (tool, args) in [
        (
            "application-package-test",
            vec!["test", "--locked", "--offline"],
        ),
        (
            "application-package-no-std",
            vec!["check", "--locked", "--offline", "--no-default-features"],
        ),
    ] {
        processes.push(run_process(
            tool,
            &cargo,
            &args.into_iter().map(str::to_owned).collect::<Vec<_>>(),
            &package_root,
            &cargo_env,
            &app_replacements,
            "PP4102",
        )?);
    }

    let consumer = work.path().join("consumer");
    std::fs::create_dir(&consumer)
        .map_err(|error| PrismError::new("PP4002", format!("consumer staging: {error}")))?;
    write(
        &consumer.join("Cargo.toml"),
        format!(
            "[package]\nname = \"prismpm-application-consumer\"\nversion = \"0.0.0\"\nedition = \"2021\"\npublish = false\n\n[dependencies]\n{} = {{ version = \"={}\", default-features = false, features = [\"std\"] }}\n",
            application.cargo_name, application.cargo_version
        )
        .as_bytes(),
    )?;
    write(
        &consumer.join("src/main.rs"),
        application_harness(application)?.as_bytes(),
    )?;
    processes.push(run_process(
        "application-consumer-lock",
        &cargo,
        &["generate-lockfile".to_owned(), "--offline".to_owned()],
        &consumer,
        &cargo_env,
        &app_replacements,
        "PP4103",
    )?);
    let execution = run_process(
        "application-generated-rust-corpus",
        &cargo,
        &[
            "run".to_owned(),
            "--locked".to_owned(),
            "--offline".to_owned(),
        ],
        &consumer,
        &cargo_env,
        &app_replacements,
        "PP6003",
    )?;
    processes.push(execution);

    let browser = build_root.join("view/browser");
    let expected_browser = [
        "app.css",
        "app.js",
        "index.html",
        &format!("{}.js", application.cargo_name.replace('-', "_")),
        &format!("{}_bg.wasm", application.cargo_name.replace('-', "_")),
        "provenance.json",
    ];
    let observed_browser = std::fs::read_dir(&browser)
        .map_err(|error| PrismError::new("PP5203", format!("browser output: {error}")))?
        .map(|entry| {
            entry
                .map_err(|error| PrismError::new("PP5203", error.to_string()))
                .and_then(|entry| {
                    if entry
                        .file_type()
                        .map_err(|error| PrismError::new("PP5203", error.to_string()))?
                        .is_file()
                    {
                        Ok(entry.file_name().to_string_lossy().into_owned())
                    } else {
                        Err(PrismError::new(
                            "PP5203",
                            "browser output contains a non-file",
                        ))
                    }
                })
        })
        .collect::<Result<BTreeSet<_>, _>>()?;
    if observed_browser != expected_browser.into_iter().map(str::to_owned).collect() {
        return Err(PrismError::new(
            "PP5203",
            "browser production file closure is not exact",
        ));
    }

    let identities: Value = serde_json::from_slice(
        &std::fs::read(build_root.join("application/holo-identities.json"))
            .map_err(|error| PrismError::new("PP3014", format!("Holo identities: {error}")))?,
    )
    .map_err(|error| PrismError::new("PP3014", format!("Holo identities: {error}")))?;
    let process_value = serde_json::to_value(&processes)
        .map_err(|error| PrismError::new("PP9001", error.to_string()))?;
    let acceptance = json!({
        "application": application.name,
        "artifact_closure": "verified",
        "browser_projection": "verified",
        "build_id": build.build_id,
        "cargo_package": {"name":application.cargo_name,"sha256":format!("{:x}",Sha256::digest(&crate_bytes)),"version":application.cargo_version},
        "core_wasm": {"sha256":hash_file(&wasm_path)?,"status":"verified"},
        "holo": identities,
        "hologram_oracle": "verified",
        "lexlean_attestation_id": lex_attestation_id,
        "modeled_vectors": application.acceptance_vectors.len(),
        "schema": "prismpm/application-acceptance/1",
        "source_id": build.source_id,
        "status": "verified"
    });
    let acceptance_bytes = encode_value(&acceptance)?;
    let manifest = json!({
        "acceptance_sha256": format!("{:x}", Sha256::digest(&acceptance_bytes)),
        "build_id": build.build_id,
        "lexlean_attestation_sha256": format!("{:x}", Sha256::digest(&lex_attestation)),
        "model_sha256": format!("{:x}", Sha256::digest(&model_bytes)),
        "processes": process_value,
        "schema": "prismpm/application-verification-manifest/1"
    });
    let manifest_bytes = encode_value(&manifest)?;
    let attestation_id = content_id(&manifest_bytes);
    let files = vec![
        ("application-acceptance.json".to_owned(), acceptance_bytes),
        ("lexlean-attestation.json".to_owned(), lex_attestation),
        ("manifest.json".to_owned(), manifest_bytes),
    ];
    let output_root = config.output_root(&controller.root)?;
    publish(&output_root, &attestation_id, &files)?;
    Ok(VerifyResult {
        schema: "prismpm/verify-result/1".to_owned(),
        attestation_id: attestation_id.clone(),
        build_id: build.build_id,
        verified_root: format!("{}/verified/{attestation_id}", config.build_root),
    })
}

pub(crate) fn run(
    controller: &Controller,
    request: VerifyRequest,
) -> Result<VerifyResult, PrismError> {
    let build = controller.build(BuildRequest {
        config_path: request.config_path.clone(),
    })?;
    let (config, _) = ProjectConfig::load(&controller.root, request.config_path.as_deref())?;
    let project_path = config.lexlean_path(&controller.root)?;
    let project_path = camino::Utf8PathBuf::from_path_buf(project_path)
        .map_err(|_| PrismError::new("PP1001", "LexLean path is not UTF-8"))?;
    let project_root = project_path
        .parent()
        .ok_or_else(|| PrismError::new("PP1001", "LexLean project path has no parent"))?;
    let preflight_replacements = [(controller.root.as_path(), "$PROJECT")];
    let toolchain = preflight_toolchain(project_root.as_std_path(), &preflight_replacements)?;
    let lex_engine = Engine::load(&project_path).map_err(|error| {
        PrismError::from_lexlean(
            "PP5001",
            "LexLean verify load failed",
            error,
            config.limits.max_diagnostics,
        )
    })?;
    let lex_verified = lex_engine
        .verify(LexVerifyRequest {
            selection: Selection::Entrypoints,
        })
        .map_err(|error| {
            PrismError::from_lexlean(
                "PP5001",
                "LexLean verification failed",
                error,
                config.limits.max_diagnostics,
            )
        })?;
    let lex_attestation_path = lex_verified.root.join("attestation.json");
    let lex_attestation = std::fs::read(lex_attestation_path.as_std_path())
        .map_err(|error| PrismError::new("PP4002", format!("LexLean attestation: {error}")))?;
    let lex_value: Value = serde_json::from_slice(&lex_attestation)
        .map_err(|error| PrismError::new("PP4004", format!("LexLean attestation: {error}")))?;
    let mut canonical_attestation = encode_value(&lex_value)
        .map_err(|error| PrismError::new("PP4004", format!("LexLean attestation: {error}")))?;
    canonical_attestation.push(b'\n');
    if canonical_attestation != lex_attestation {
        return Err(PrismError::new(
            "PP4004",
            "LexLean attestation is not canonical JSON",
        ));
    }
    if lex_value.get("status").and_then(Value::as_str) != Some("verified") {
        return Err(PrismError::new(
            "PP5002",
            "LexLean attestation is not verified",
        ));
    }
    let output_root = config.output_root(&controller.root)?;
    let build_root = output_root.join("build").join(&build.build_id);
    let model_bytes = std::fs::read(build_root.join("model.prism.json"))
        .map_err(|error| PrismError::new("PP4002", format!("model.prism.json: {error}")))?;
    let model = decode_canonical(&model_bytes)?;
    let lex_snapshot: Value = serde_json::from_slice(
        &std::fs::read(build_root.join("lexlean/snapshot.json"))
            .map_err(|error| PrismError::new("PP4002", format!("LexLean snapshot: {error}")))?,
    )
    .map_err(|error| PrismError::new("PP4004", format!("LexLean snapshot: {error}")))?;
    let build_manifest: Value = serde_json::from_slice(
        &std::fs::read(build_root.join("manifest.json"))
            .map_err(|error| PrismError::new("PP4002", format!("Prism manifest: {error}")))?,
    )
    .map_err(|error| PrismError::new("PP4004", format!("Prism manifest: {error}")))?;
    let lex_attestation_id = lex_verified.attestation_id.to_string();
    if lex_value.get("attestation_id").and_then(Value::as_str) != Some(lex_attestation_id.as_str())
        || lex_value.get("source_id").and_then(Value::as_str) != Some(build.source_id.as_str())
        || lex_value.get("semantic_id").and_then(Value::as_str) != Some(build.semantic_id.as_str())
        || lex_value
            .pointer("/lexlean/compiler_semantics")
            .and_then(Value::as_str)
            != Some(model.provenance.compiler_semantics_id.as_str())
        || lex_value.get("build_id").and_then(Value::as_str)
            != build_manifest
                .pointer("/inputs/lexlean_build_id")
                .and_then(Value::as_str)
    {
        return Err(PrismError::new(
            "PP4001",
            "LexLean attestation identities do not match the Prism build",
        ));
    }
    let roots: RuntimeRoots = toml::from_str(ROOTS_SOURCE)
        .map_err(|error| PrismError::new("PP9001", format!("runtime roots: {error}")))?;
    if roots.spec != "prismpm/runtime-roots/1"
        || roots.roots.is_empty()
        || roots.roots.windows(2).any(|rows| rows[0] >= rows[1])
    {
        return Err(PrismError::new("PP9001", "runtime roots are not canonical"));
    }
    let (corpus, corpus_sha256) = execution_corpus(&roots)?;
    if model.application.is_none() {
        validate_lexlean_declarations(&lex_value, &lex_snapshot, &corpus)?;
    }
    let lex_manifest = std::fs::read(build_root.join("lexlean/build/manifest.json"))
        .map_err(|error| PrismError::new("PP4002", format!("LexLean manifest: {error}")))?;
    let attested_manifest = lex_value
        .get("build_manifest")
        .and_then(|value| value.get("sha256"))
        .and_then(Value::as_str)
        .ok_or_else(|| PrismError::new("PP4004", "LexLean manifest hash is absent"))?;
    if format!("{:x}", Sha256::digest(&lex_manifest)) != attested_manifest {
        return Err(PrismError::new(
            "PP4001",
            "LexLean build manifest is not attested",
        ));
    }
    let lex_manifest_value: Value = serde_json::from_slice(&lex_manifest)
        .map_err(|error| PrismError::new("PP4004", format!("LexLean manifest: {error}")))?;
    let output_rows = lex_manifest_value
        .get("outputs")
        .and_then(Value::as_array)
        .ok_or_else(|| PrismError::new("PP4004", "LexLean manifest outputs are absent"))?;
    let mut attested_lean = BTreeMap::new();
    for row in output_rows {
        if row.get("kind").and_then(Value::as_str) != Some("lean") {
            continue;
        }
        let path = row
            .get("path")
            .and_then(Value::as_str)
            .ok_or_else(|| PrismError::new("PP4004", "attested Lean path is absent"))?;
        let relative = Path::new(path);
        if relative.is_absolute()
            || relative
                .components()
                .any(|component| !matches!(component, std::path::Component::Normal(_)))
            || !path.starts_with("modules/")
            || !path.ends_with(".lean")
        {
            return Err(PrismError::new(
                "PP4004",
                format!("invalid attested Lean path {path}"),
            ));
        }
        let byte_length = row
            .get("byte_length")
            .and_then(Value::as_u64)
            .ok_or_else(|| PrismError::new("PP4004", "attested Lean size is absent"))?;
        let sha256 = row
            .get("sha256")
            .and_then(Value::as_str)
            .ok_or_else(|| PrismError::new("PP4004", "attested Lean hash is absent"))?;
        if sha256.len() != 64 || !sha256.bytes().all(|byte| byte.is_ascii_hexdigit()) {
            return Err(PrismError::new(
                "PP4004",
                format!("invalid attested Lean hash for {path}"),
            ));
        }
        if attested_lean
            .insert(path.to_owned(), (byte_length, sha256.to_owned()))
            .is_some()
        {
            return Err(PrismError::new(
                "PP4004",
                format!("duplicate attested Lean path {path}"),
            ));
        }
    }
    if attested_lean.is_empty() {
        return Err(PrismError::new(
            "PP4004",
            "LexLean manifest attests no generated Lean modules",
        ));
    }
    if model.application.is_some() {
        return run_application(
            controller,
            &config,
            build,
            model,
            model_bytes,
            build_manifest,
            &build_root,
            lex_attestation,
            lex_attestation_id,
            toolchain.records,
        );
    }

    let staging_parent = output_root.join(".verify-work");
    std::fs::create_dir_all(&staging_parent)
        .map_err(|error| PrismError::new("PP4002", format!("verification work: {error}")))?;
    let work = tempfile::Builder::new()
        .prefix("chain-")
        .tempdir_in(&staging_parent)
        .map_err(|error| PrismError::new("PP4002", format!("verification work: {error}")))?;
    let workspace = work.path();
    let lean_archive = controller.root.join("vendor/lean4-prod/lean.tar");
    if !lean_archive.is_file() {
        return Err(PrismError::new(
            "PP5008",
            "pinned lean4-prod package archive is missing",
        ));
    }
    let lean_package = workspace.join("lean4-prod");
    std::fs::create_dir(&lean_package)
        .map_err(|error| PrismError::new("PP4002", format!("Lean package staging: {error}")))?;
    let archive_file = File::open(&lean_archive)
        .map_err(|error| PrismError::new("PP4002", format!("Lean package archive: {error}")))?;
    tar::Archive::new(archive_file)
        .unpack(&lean_package)
        .map_err(|error| PrismError::new("PP4002", format!("Lean package extraction: {error}")))?;
    if !lean_package.join("Prod/Export.lean").is_file() {
        return Err(PrismError::new(
            "PP5008",
            "pinned lean4-prod package is missing",
        ));
    }
    let replacements = [
        (workspace, "$STAGING"),
        (controller.root.as_path(), "$PROJECT"),
        (lean_package.as_path(), "$LEAN4_PROD"),
    ];
    let mut modules = Vec::new();
    for (path, (expected_size, expected_hash)) in &attested_lean {
        let source = build_root.join("lexlean/build").join(path);
        let metadata = std::fs::symlink_metadata(&source)
            .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", source.display())))?;
        if !metadata.file_type().is_file() || metadata.len() != *expected_size {
            return Err(PrismError::new(
                "PP4001",
                format!("attested generated Lean file {path} has the wrong type or size"),
            ));
        }
        let bytes = std::fs::read(&source)
            .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", source.display())))?;
        if format!("{:x}", Sha256::digest(&bytes)) != *expected_hash {
            return Err(PrismError::new(
                "PP4001",
                format!("attested generated Lean file {path} has changed"),
            ));
        }
        let relative = Path::new(path)
            .strip_prefix("modules")
            .map_err(|_| PrismError::new("PP9001", "generated module path escaped"))?;
        write(&workspace.join(relative), &bytes)?;
        modules.push(
            relative
                .with_extension("")
                .to_string_lossy()
                .replace(['/', '\\'], "."),
        );
    }
    modules.sort();
    if modules.is_empty() {
        return Err(PrismError::new(
            "PP4002",
            "no generated Lean modules were staged",
        ));
    }
    let roots_toml = modules
        .iter()
        .map(|module| serde_json::to_string(module).expect("module name serializes"))
        .collect::<Vec<_>>()
        .join(", ");
    let lakefile = format!(
        "name = \"prismpm_verify\"\nversion = \"0.1.0\"\n\n[[lean_lib]]\nname = \"PrismGenerated\"\nroots = [{}]\n",
        roots_toml,
    );
    write(&workspace.join("lakefile.toml"), lakefile.as_bytes())?;
    write(
        &workspace.join("lean-toolchain"),
        b"leanprover/lean4:v4.32.1\n",
    )?;

    let lake = toolchain.lake;
    let rustfmt = toolchain.rustfmt;
    let rustc = toolchain.rustc;
    let no_env = BTreeMap::new();
    let mut processes = toolchain.records;
    processes.push(run_process(
        "lake-build-generated",
        &lake,
        &["build".to_owned(), "PrismGenerated".to_owned()],
        workspace,
        &no_env,
        &replacements,
        "PP5001",
    )?);
    for module in &modules {
        processes.push(run_process(
            "leanchecker",
            &lake,
            &["env".to_owned(), "leanchecker".to_owned(), module.clone()],
            workspace,
            &no_env,
            &replacements,
            "PP5002",
        )?);
    }
    processes.push(run_process(
        "lean4-prod-build",
        &lake,
        &["build".to_owned(), "prod-export".to_owned()],
        &lean_package,
        &no_env,
        &replacements,
        "PP5004",
    )?);
    let lean_path = workspace.join(".lake/build/lib/lean");
    let mut export_env = BTreeMap::new();
    export_env.insert(
        "LEAN_PATH".to_owned(),
        lean_path.to_string_lossy().into_owned(),
    );
    let export_once =
        |name: &str, processes: &mut Vec<ProcessRecord>| -> Result<PathBuf, PrismError> {
            let out = workspace.join(name);
            let mut args = vec![
                "exe".to_owned(),
                "prod-export".to_owned(),
                "--module".to_owned(),
                roots.lean_module.clone(),
            ];
            for root in &roots.roots {
                args.push("--root".to_owned());
                args.push(root.clone());
            }
            args.extend([
                "--ir-module".to_owned(),
                roots.ir_module.clone(),
                "--out".to_owned(),
                out.to_string_lossy().into_owned(),
            ]);
            processes.push(run_process(
                "prod-export",
                &lake,
                &args,
                &lean_package,
                &export_env,
                &replacements,
                "PP5004",
            )?);
            Ok(out)
        };
    let export_a = export_once("export-a", &mut processes)?;
    let export_b = export_once("export-b", &mut processes)?;
    for name in ["kernel.ir", "roots.json", "coverage.json"] {
        let left = std::fs::read(export_a.join(name))
            .map_err(|error| PrismError::new("PP5004", format!("{name}: {error}")))?;
        let right = std::fs::read(export_b.join(name))
            .map_err(|error| PrismError::new("PP5004", format!("{name}: {error}")))?;
        if left != right {
            return Err(PrismError::new(
                "PP5004",
                format!("{name} is not deterministic"),
            ));
        }
    }
    let coverage: Value = serde_json::from_slice(
        &std::fs::read(export_a.join("coverage.json"))
            .map_err(|error| PrismError::new("PP5004", format!("coverage: {error}")))?,
    )
    .map_err(|error| PrismError::new("PP5004", format!("coverage: {error}")))?;
    validate_coverage(&coverage, &roots.roots)?;
    let kernel = std::fs::read_to_string(export_a.join("kernel.ir"))
        .map_err(|error| PrismError::new("PP5004", format!("kernel.ir: {error}")))?;
    let module = parse_kernel(&kernel)?;
    let generated_a = prod_codegen::generate_module(&module)
        .map_err(|error| PrismError::new("PP5005", error.to_string()))?;
    let generated_b = prod_codegen::generate_module(&module)
        .map_err(|error| PrismError::new("PP5005", error.to_string()))?;
    if generated_a != generated_b {
        return Err(PrismError::new(
            "PP5005",
            "Rust generation is not deterministic",
        ));
    }
    let generated_path = workspace.join("generated.rs");
    let harness_path = workspace.join("harness.rs");
    write(&generated_path, generated_a.as_bytes())?;
    write(
        &harness_path,
        harness(&model, &corpus, &corpus_sha256).as_bytes(),
    )?;
    processes.push(run_process(
        "rustfmt",
        &rustfmt,
        &[
            "--edition".to_owned(),
            "2021".to_owned(),
            generated_path.to_string_lossy().into_owned(),
            harness_path.to_string_lossy().into_owned(),
        ],
        workspace,
        &no_env,
        &replacements,
        "PP5005",
    )?);
    let executable_path = workspace.join("validator");
    let allocator_rlib = workspace.join("libprod_alloc_counter.rlib");
    let allocator_source = workspace.join("prod_alloc_counter.rs");
    write(&allocator_source, ALLOCATION_COUNTER_SOURCE.as_bytes())?;
    processes.push(run_process(
        "rustc-allocation-counter",
        &rustc,
        &[
            "--edition".to_owned(),
            "2021".to_owned(),
            "--crate-name".to_owned(),
            "prod_alloc_counter".to_owned(),
            "--crate-type".to_owned(),
            "lib".to_owned(),
            "-C".to_owned(),
            "codegen-units=1".to_owned(),
            "-C".to_owned(),
            "debuginfo=0".to_owned(),
            format!(
                "--remap-path-prefix={}=$STAGING",
                workspace.to_string_lossy()
            ),
            allocator_source.to_string_lossy().into_owned(),
            "-o".to_owned(),
            allocator_rlib.to_string_lossy().into_owned(),
        ],
        workspace,
        &no_env,
        &replacements,
        "PP5005",
    )?);
    processes.push(run_process(
        "rustc",
        &rustc,
        &[
            "--edition".to_owned(),
            "2021".to_owned(),
            "-C".to_owned(),
            "opt-level=3".to_owned(),
            "-C".to_owned(),
            "debug-assertions=yes".to_owned(),
            "-C".to_owned(),
            "codegen-units=1".to_owned(),
            "-C".to_owned(),
            "debuginfo=0".to_owned(),
            "-C".to_owned(),
            "strip=symbols".to_owned(),
            "-C".to_owned(),
            "link-arg=-Wl,--build-id=none".to_owned(),
            format!(
                "--remap-path-prefix={}=$STAGING",
                workspace.to_string_lossy()
            ),
            "--extern".to_owned(),
            format!("prod_alloc_counter={}", allocator_rlib.to_string_lossy()),
            harness_path.to_string_lossy().into_owned(),
            "-o".to_owned(),
            executable_path.to_string_lossy().into_owned(),
        ],
        workspace,
        &no_env,
        &replacements,
        "PP5005",
    )?);
    let first = run_process(
        "generated-validator",
        &executable_path,
        &[],
        workspace,
        &no_env,
        &replacements,
        "PP5006",
    )?;
    let second = run_process(
        "generated-validator",
        &executable_path,
        &[],
        workspace,
        &no_env,
        &replacements,
        "PP5006",
    )?;
    if first.stdout != second.stdout || first.stderr != second.stderr {
        return Err(PrismError::new(
            "PP5006",
            "execution evidence is not deterministic",
        ));
    }
    let execution: Value = serde_json::from_str(first.stdout.trim())
        .map_err(|error| PrismError::new("PP5006", format!("execution output: {error}")))?;
    validate_execution(&execution, &corpus, &corpus_sha256)?;
    let execution_bytes = encode_value(&execution)?;
    processes.push(first);
    processes.push(second);

    let artifact = |path: &Path| -> Result<Value, PrismError> {
        Ok(json!({
            "byte_length": std::fs::metadata(path).map_err(|error| PrismError::new("PP4002", error.to_string()))?.len(),
            "sha256": hash_file(path)?
        }))
    };
    let process_value = serde_json::to_value(&processes)
        .map_err(|error| PrismError::new("PP9001", error.to_string()))?;
    let manifest = json!({
        "artifacts": {
            "coverage": artifact(&export_a.join("coverage.json"))?,
            "executable": artifact(&executable_path)?,
            "execution_corpus": {"byte_length": EXECUTION_CORPUS_SOURCE.len(), "sha256": corpus_sha256},
            "execution_evidence": {"byte_length": execution_bytes.len(), "sha256": format!("{:x}", Sha256::digest(&execution_bytes))},
            "generated_rust": artifact(&generated_path)?,
            "model": {"byte_length": model_bytes.len(), "sha256": content_id(&model_bytes)},
            "kernel_ir": artifact(&export_a.join("kernel.ir"))?,
            "lexlean_attestation": {"byte_length": lex_attestation.len(), "sha256": format!("{:x}", Sha256::digest(&lex_attestation))},
            "roots": artifact(&export_a.join("roots.json"))?
        },
        "build_id": build.build_id,
        "execution": execution,
        "lexlean_attestation_id": lex_verified.attestation_id.to_string(),
        "processes": process_value,
        "runtime_roots": roots.roots,
        "schema": "prismpm/verification-manifest/1"
    });
    let manifest_bytes = encode_value(&manifest)?;
    let attestation_id = content_id(&manifest_bytes);
    let files = vec![
        (
            "coverage.json".to_owned(),
            std::fs::read(export_a.join("coverage.json"))
                .map_err(|error| PrismError::new("PP4002", error.to_string()))?,
        ),
        (
            "execution-corpus.toml".to_owned(),
            EXECUTION_CORPUS_SOURCE.as_bytes().to_vec(),
        ),
        ("execution.json".to_owned(), execution_bytes),
        (
            "generated.rs".to_owned(),
            std::fs::read(&generated_path)
                .map_err(|error| PrismError::new("PP4002", error.to_string()))?,
        ),
        (
            "kernel.ir".to_owned(),
            std::fs::read(export_a.join("kernel.ir"))
                .map_err(|error| PrismError::new("PP4002", error.to_string()))?,
        ),
        ("lexlean-attestation.json".to_owned(), lex_attestation),
        ("manifest.json".to_owned(), manifest_bytes),
        (
            "roots.json".to_owned(),
            std::fs::read(export_a.join("roots.json"))
                .map_err(|error| PrismError::new("PP4002", error.to_string()))?,
        ),
    ];
    publish(&output_root, &attestation_id, &files)?;
    Ok(VerifyResult {
        schema: "prismpm/verify-result/1".to_owned(),
        attestation_id: attestation_id.clone(),
        build_id: build.build_id,
        verified_root: format!("{}/verified/{attestation_id}", config.build_root),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn corpus() -> (RuntimeRoots, ExecutionCorpus, String) {
        let roots: RuntimeRoots = toml::from_str(ROOTS_SOURCE).expect("runtime roots");
        let (corpus, sha256) = execution_corpus(&roots).expect("execution corpus");
        (roots, corpus, sha256)
    }

    fn limited_with_code(
        program: &str,
        args: &[&str],
        timeout: &str,
        output: usize,
        code: &'static str,
    ) -> PrismError {
        let program = executable(program).expect("test utility is installed");
        run_process_limited(
            "test-child",
            &program,
            &args
                .iter()
                .map(|value| (*value).to_owned())
                .collect::<Vec<_>>(),
            Path::new("/tmp"),
            &BTreeMap::new(),
            &[],
            code,
            timeout,
            output,
        )
        .expect_err("child must fail")
    }

    fn limited(program: &str, args: &[&str], timeout: &str, output: usize) -> PrismError {
        limited_with_code(program, args, timeout, output, "PP5001")
    }

    #[test]
    fn child_output_overflow_is_a_registered_failure() {
        let error = limited("head", &["-c", "64", "/dev/zero"], "5", 16);
        assert_eq!(error.code, "PP5007");
        assert_eq!(error.message, "test-child output limit exceeded");
    }

    #[test]
    fn lake_success_output_discards_parallel_job_numbers() {
        let left = "Build completed successfully (2 jobs).\n✔ [1/2] Built B (1.2s)\n✔ [2/2] Built A (500ms)\n";
        let right = "✔ [1/2] Built A (800ms)\nBuild completed successfully (2 jobs).\n✔ [2/2] Built B (900ms)\n";
        assert_eq!(
            stable_success_output("lake-build-generated", left.to_owned()),
            stable_success_output("lake-build-generated", right.to_owned())
        );
    }

    #[test]
    fn cargo_success_output_discards_elapsed_time_only() {
        let left = "    Finished `test` profile in 0.22s\nsubstantive output\n";
        let right = "    Finished `test` profile in 19.75s\nsubstantive output\n";
        assert_eq!(
            stable_success_output("application-package-test", left.to_owned()),
            stable_success_output("application-package-test", right.to_owned())
        );
        assert!(
            stable_success_output("application-package-test", left.to_owned())
                .contains("substantive output")
        );
    }

    #[test]
    fn child_timeout_terminates_the_process_tree() {
        let error = limited("sleep", &["2"], "0.05", 16);
        assert_eq!(error.code, "PP5007");
        assert_eq!(error.message, "test-child timed out");
    }

    #[test]
    fn child_nonzero_exit_uses_the_stage_diagnostic() {
        let error = limited("false", &[], "5", 16);
        assert_eq!(error.code, "PP5001");
        assert!(error.message.contains("exited 1"));
    }

    #[test]
    fn every_external_verification_stage_preserves_its_registered_code() {
        for code in ["PP5001", "PP5002", "PP5004", "PP5005", "PP5006"] {
            let error = limited_with_code("false", &[], "5", 16, code);
            assert_eq!(error.code, code);
            assert!(error.message.contains("exited 1"));
        }
    }

    #[test]
    fn verification_toolchain_preflight_matches_pinned_bytes_and_versions() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
        let tools = preflight_toolchain(&root, &[]).expect("pinned devcontainer");
        assert_eq!(tools.records.len(), 5);
        assert_eq!(
            tools
                .records
                .iter()
                .map(|record| record.tool.as_str())
                .collect::<Vec<_>>(),
            [
                "lean-version",
                "lake-version",
                "rustfmt-version",
                "rustc-version",
                "timeout-version",
            ]
        );
    }

    #[test]
    fn semantic_axiom_mismatch_is_rejected_exactly() {
        let (_, corpus, _) = corpus();
        let snapshot = json!({
            "modules": [{
                "declarations": [{
                    "axiom_policy": {"axioms": [], "kind": "none"},
                    "kind": "theorem",
                    "lean_name": "canonicalIndexAssignmentUnique"
                }],
                "lean_module": "PrismPM.Foundation.Holo"
            }]
        });
        let error = validate_lexlean_declarations(
            &json!({
                "declarations": [{
                    "name": "PrismPM.Foundation.Holo.canonicalIndexAssignmentUnique",
                    "observed": ["propext"],
                    "policy": {"axioms": [], "kind": "none"},
                    "result": "ok"
                }]
            }),
            &snapshot,
            &corpus,
        )
        .unwrap_err();
        assert_eq!(error.code, "PP5003");
        assert!(error.message.contains("nonempty axiom audit"));

        let error = validate_lexlean_declarations(&json!({"declarations": []}), &snapshot, &corpus)
            .unwrap_err();
        assert_eq!(error.code, "PP5003");
        assert_eq!(
            error.message,
            "Prism declaration PrismPM.Foundation.Holo.canonicalIndexAssignmentUnique has no axiom audit"
        );
    }

    #[test]
    fn semantic_definition_may_use_its_exact_registered_axioms() {
        let (_, mut corpus, _) = corpus();
        corpus.oracle.clear();
        let snapshot = json!({
            "modules": [{
                "declarations": [{
                    "axiom_policy": {"axioms": ["propext"], "kind": "exact"},
                    "kind": "definition",
                    "lean_name": "compareBytes"
                }],
                "lean_module": "PrismPM.Foundation.Bytes"
            }]
        });
        validate_lexlean_declarations(
            &json!({
                "declarations": [{
                    "name": "PrismPM.Foundation.Bytes.compareBytes",
                    "observed": ["propext"],
                    "policy": {"axioms": ["propext"], "kind": "exact"},
                    "result": "ok"
                }]
            }),
            &snapshot,
            &corpus,
        )
        .expect("an exact, snapshot-bound definition policy is accepted");
    }

    #[test]
    fn named_export_coverage_rejects_each_gap_class() {
        let roots = vec!["PrismPM.Foundation.Holo.validateComponentIndexes".to_owned()];
        let valid = || {
            json!({
                "erased_proof_dependencies": [],
                "external_calls": [],
                "included_definitions": roots,
                "opaque_nodes": [],
                "requested_roots": roots,
                "unsupported_types": []
            })
        };
        validate_coverage(&valid(), &roots).expect("closed coverage");
        for field in [
            "erased_proof_dependencies",
            "external_calls",
            "opaque_nodes",
            "unsupported_types",
        ] {
            let mut value = valid();
            value[field] = json!(["planted-gap"]);
            let error = validate_coverage(&value, &roots).unwrap_err();
            assert_eq!(error.code, "PP5004");
            assert_eq!(error.message, "named export coverage is unacceptable");
        }
        let mut value = valid();
        value["requested_roots"] = json!([]);
        assert_eq!(
            validate_coverage(&value, &roots).unwrap_err().code,
            "PP5004"
        );
    }

    #[test]
    fn malformed_or_trailing_lcnf_is_rejected() {
        assert_eq!(parse_kernel("not lcnf").unwrap_err().code, "PP5004");
        let valid = "(module Test)";
        parse_kernel(valid).expect("minimal valid LCNF module");
        let error = parse_kernel(&format!("{valid}\ntrailing")).unwrap_err();
        assert_eq!(error.code, "PP5004");
        assert_eq!(error.message, "kernel.ir has trailing syntax");
    }

    #[test]
    fn malformed_execution_output_is_rejected() {
        let (_, corpus, sha256) = corpus();
        let error = validate_execution(&json!({"status": "passed"}), &corpus, &sha256).unwrap_err();
        assert_eq!(error.code, "PP5006");
    }

    #[test]
    fn execution_corpus_is_typed_counted_and_root_complete() {
        let (roots, corpus, sha256) = corpus();
        assert_eq!(corpus.case_count, 597);
        assert_eq!(corpus.exhaustive.case_count, 85);
        assert_eq!(corpus.property.case_count, 512);
        assert_eq!(sha256.len(), 64);
        assert_eq!(
            corpus.oracle.iter().filter(|row| row.runtime_root).count(),
            roots.roots.len()
        );
    }

    #[test]
    fn failed_verification_publication_leaves_no_attestation_directory() {
        let temp = tempfile::tempdir().unwrap();
        let files = vec![
            ("conflict".to_owned(), b"file".to_vec()),
            ("conflict/child".to_owned(), b"child".to_vec()),
        ];
        let error = publish(temp.path(), "planted-partial-publication", &files).unwrap_err();
        assert_eq!(error.code, "PP4002");
        assert!(!temp
            .path()
            .join("verified/planted-partial-publication")
            .exists());
    }

    #[test]
    fn verification_reuse_rejects_an_unmanifested_directory() {
        let temp = tempfile::tempdir().unwrap();
        let files = vec![("manifest.json".to_owned(), b"manifest".to_vec())];
        publish(temp.path(), "existing", &files).expect("first publication");
        std::fs::create_dir(temp.path().join("verified/existing/extra")).unwrap();
        let error = publish(temp.path(), "existing", &files).unwrap_err();
        assert_eq!(error.code, "PP4001");
        assert_eq!(
            error.message,
            "verified artifact set differs from its manifest"
        );
    }
}
