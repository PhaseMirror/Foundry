//! Conformance test cases verifying every registered capability.

use repo_model::repo_root;
use serde_json::Value;
use sha2::{Digest, Sha256};
use std::collections::BTreeSet;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::OnceLock;

static CHECK: OnceLock<Result<prismpm::controller::CheckResult, String>> = OnceLock::new();
static BUILD: OnceLock<Result<prismpm::controller::BuildResult, String>> = OnceLock::new();
static VERIFY: OnceLock<Result<prismpm::controller::VerifyResult, String>> = OnceLock::new();

fn checked(root: &Path) -> &'static prismpm::controller::CheckResult {
    CHECK
        .get_or_init(|| {
            prismpm::Controller::load(root)
                .and_then(|controller| {
                    controller.check(prismpm::controller::CheckRequest { config_path: None })
                })
                .map_err(|error| error.to_string())
        })
        .as_ref()
        .unwrap_or_else(|error| panic!("shared Prism check failed: {error}"))
}

fn built(root: &Path) -> &'static prismpm::controller::BuildResult {
    BUILD
        .get_or_init(|| {
            prismpm::Controller::load(root)
                .and_then(|controller| {
                    controller.build(prismpm::controller::BuildRequest { config_path: None })
                })
                .map_err(|error| error.to_string())
        })
        .as_ref()
        .unwrap_or_else(|error| panic!("shared Prism build failed: {error}"))
}

fn verified(root: &Path) -> &'static prismpm::controller::VerifyResult {
    VERIFY
        .get_or_init(|| {
            prismpm::Controller::load(root)
                .and_then(|controller| {
                    controller.verify(prismpm::controller::VerifyRequest { config_path: None })
                })
                .map_err(|error| error.to_string())
        })
        .as_ref()
        .unwrap_or_else(|error| panic!("shared Prism verification failed: {error}"))
}

fn build_root(root: &Path) -> PathBuf {
    root.join(".prism/build").join(&built(root).build_id)
}

fn verified_root(root: &Path) -> PathBuf {
    root.join(&verified(root).verified_root)
}

fn json(path: &Path) -> Value {
    serde_json::from_slice(
        &std::fs::read(path).unwrap_or_else(|error| panic!("{}: {error}", path.display())),
    )
    .unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn build_manifest(root: &Path) -> Value {
    json(&build_root(root).join("manifest.json"))
}

fn verification_manifest(root: &Path) -> Value {
    json(&verified_root(root).join("manifest.json"))
}

fn model_bytes(root: &Path) -> Vec<u8> {
    std::fs::read(build_root(root).join("model.prism.json")).expect("published model.prism.json")
}

fn model(root: &Path) -> Value {
    serde_json::from_slice(&model_bytes(root)).expect("canonical model-document JSON")
}

fn sample_application_holo(root: &Path) -> prismpm::holo::archive::GeneratedHolo {
    let model_document = model_bytes(root);
    let digest = "0".repeat(64);
    let commit = "0".repeat(40);
    prismpm::holo::archive::compose_application(&prismpm::holo::archive::ApplicationArchiveInput {
        application_name: "Conformance".to_owned(),
        guest_wasm: b"\0asm\x01\0\0\0".to_vec(),
        view_bundle: b"HOLOVIEW\0\x01".to_vec(),
        model_document,
        source_manifest: br#"{"version":4}"#.to_vec(),
        provenance: prismpm::holo::archive::ArchiveProvenance {
            source_id: digest.clone(),
            semantic_id: digest.clone(),
            compiler_semantics_id: digest.clone(),
            snapshot_id: digest.clone(),
            stdlib_semantics_id: digest.clone(),
            prism_stdlib_crate_sha256: digest.clone(),
            lexlean_commit: commit.clone(),
            lexlean_package_sha256: digest.clone(),
            lean4_prod_commit: commit.clone(),
            hologram_live_commit: commit.clone(),
            uor_hologram_commit: commit,
            target_profile_id: digest.clone(),
            lean_manifest_sha256: digest.clone(),
            lcnf_manifest_sha256: digest.clone(),
            generated_core_sha256: digest.clone(),
            cargo_name: "conformance".to_owned(),
            cargo_version: "0.1.0".to_owned(),
            cargo_crate_sha256: digest.clone(),
            view_model_id: digest.clone(),
            browser_projection_sha256: digest,
        },
    })
    .expect("sample Holo/1 application composes")
}

fn snapshot(root: &Path) -> Value {
    json(&build_root(root).join("lexlean/snapshot.json"))
}

fn assert_prism_theorems_axiom_free(root: &Path) {
    let snapshot = snapshot(root);
    let theorem_names = snapshot["modules"]
        .as_array()
        .expect("snapshot modules")
        .iter()
        .flat_map(|module| {
            let lean_module = module["lean_module"]
                .as_str()
                .expect("snapshot Lean module");
            module["declarations"]
                .as_array()
                .expect("snapshot declarations")
                .iter()
                .filter(|declaration| declaration["kind"].as_str() == Some("theorem"))
                .map(move |declaration| {
                    format!(
                        "{lean_module}.{}",
                        declaration["lean_name"]
                            .as_str()
                            .expect("snapshot theorem name")
                    )
                })
        })
        .collect::<BTreeSet<_>>();
    assert!(
        !theorem_names.is_empty(),
        "snapshot contains no Prism theorems"
    );

    let attestation = json(&verified_root(root).join("lexlean-attestation.json"));
    let audits = attestation["declarations"]
        .as_array()
        .expect("attested declarations");
    for theorem in theorem_names {
        let audit = audits
            .iter()
            .find(|row| row["name"].as_str() == Some(theorem.as_str()))
            .unwrap_or_else(|| panic!("missing theorem audit for {theorem}"));
        assert_eq!(audit["result"], "ok", "failed theorem audit for {theorem}");
        assert_eq!(
            audit["policy"]["kind"], "none",
            "nonempty theorem policy for {theorem}"
        );
        assert!(
            audit["observed"].as_array().is_some_and(Vec::is_empty),
            "nonempty observed theorem axioms for {theorem}"
        );
    }
}

fn semantic_names(root: &Path, module: &str) -> BTreeSet<String> {
    snapshot(root)["modules"]
        .as_array()
        .expect("snapshot modules")
        .iter()
        .find(|row| row["name"].as_str() == Some(module))
        .unwrap_or_else(|| panic!("snapshot module {module}"))["semantic"]["declarations"]
        .as_array()
        .expect("semantic declarations")
        .iter()
        .map(|row| row["name"].as_str().expect("declaration name").to_owned())
        .collect()
}

fn assert_declarations(root: &Path, module: &str, expected: &[&str]) {
    let names = semantic_names(root, module);
    for name in expected {
        assert!(names.contains(*name), "{module} is missing {name}");
    }
}

fn sha256(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}

fn assert_hex_digest(value: &str) {
    assert_eq!(value.len(), 64, "digest length: {value}");
    assert!(
        value.bytes().all(|byte| byte.is_ascii_hexdigit()),
        "digest spelling: {value}"
    );
}

fn read(root: &Path, relative: &str) -> String {
    std::fs::read_to_string(root.join(relative))
        .unwrap_or_else(|error| panic!("{relative}: {error}"))
}

fn assert_contains(root: &Path, relative: &str, needles: &[&str]) {
    let source = read(root, relative);
    for needle in needles {
        assert!(source.contains(needle), "{relative} is missing {needle}");
    }
}

fn assert_indexed(array: &Value) {
    let rows = array.as_array().expect("model-document collection");
    let ids: Vec<_> = rows
        .iter()
        .map(|row| row["id"].as_str().expect("qualified entity ID"))
        .collect();
    assert!(
        ids.windows(2).all(|pair| pair[0] < pair[1]),
        "IDs are not strictly sorted"
    );
    for (expected, row) in rows.iter().enumerate() {
        assert_eq!(row["index"].as_u64(), Some(expected as u64));
        assert!(row["id"].as_str().unwrap().contains("::"));
    }
}

fn artifact<'a>(manifest: &'a Value, name: &str) -> &'a Value {
    manifest["artifacts"]
        .get(name)
        .unwrap_or_else(|| panic!("verification manifest is missing {name}"))
}

fn assert_artifact(root: &Path, name: &str, filename: &str) {
    let manifest = verification_manifest(root);
    let bytes = std::fs::read(verified_root(root).join(filename)).expect("published artifact");
    let row = artifact(&manifest, name);
    assert_eq!(row["byte_length"].as_u64(), Some(bytes.len() as u64));
    assert_eq!(row["sha256"].as_str(), Some(sha256(&bytes).as_str()));
}

fn process_tools(root: &Path) -> BTreeSet<String> {
    verification_manifest(root)["processes"]
        .as_array()
        .expect("process records")
        .iter()
        .map(|row| row["tool"].as_str().expect("process tool").to_owned())
        .collect()
}

fn copy_project(root: &Path, destination: &Path) {
    for relative in ["language", "stdlib"] {
        for entry in walkdir::WalkDir::new(root.join(relative)) {
            let entry = entry.unwrap();
            let suffix = entry.path().strip_prefix(root).unwrap();
            let target = destination.join(suffix);
            if entry.file_type().is_dir() {
                std::fs::create_dir_all(target).unwrap();
            } else if entry.file_type().is_file() {
                std::fs::copy(entry.path(), target).unwrap();
            }
        }
    }
    for relative in [
        "lake-manifest.json",
        "lakefile.toml",
        "lean-toolchain",
        "lexlean.lock",
        "lexlean.toml",
        "prismpm.toml",
    ] {
        std::fs::copy(root.join(relative), destination.join(relative)).unwrap();
    }
}

fn tree(root: &Path) -> Vec<(String, Vec<u8>)> {
    let mut files = walkdir::WalkDir::new(root)
        .into_iter()
        .map(Result::unwrap)
        .filter(|entry| entry.file_type().is_file())
        .map(|entry| {
            (
                entry
                    .path()
                    .strip_prefix(root)
                    .unwrap()
                    .to_string_lossy()
                    .replace('\\', "/"),
                std::fs::read(entry.path()).unwrap(),
            )
        })
        .collect::<Vec<_>>();
    files.sort_by(|left, right| left.0.as_bytes().cmp(right.0.as_bytes()));
    files
}

/// Execute a conformance case by ID.
pub fn run(id: &str) {
    let root = repo_root();
    let model = repo_model::Model::load_from_repo_root().expect("model loads");
    let row = model
        .ids
        .get(id)
        .unwrap_or_else(|| panic!("ID {id} must exist in model/ids.toml"));
    assert_eq!(
        row.level,
        repo_model::Level::Build,
        "{id} must be level build"
    );

    match id {
        "RP-01" => verify_rp_01(&root),
        "RP-02" => verify_rp_02(&root),
        "RP-03" => verify_rp_03(&root),
        "RP-04" => verify_rp_04(&root),
        "RP-05" => verify_rp_05(&root),
        "RP-06" => verify_rp_06(&root),
        "RP-07" => verify_rp_07(&root),
        "RP-08" => verify_rp_08(&root),
        "RP-09" => verify_rp_09(&root),
        "RP-10" => verify_rp_10(&root),
        "RP-11" => verify_rp_11(&root),
        "RP-12" => verify_rp_12(&root),

        "FT-01" | "FT-02" | "FT-03" | "FT-04" | "FT-05" | "FT-06" | "FT-07" | "FT-08" | "FT-09"
        | "FT-10" => {
            verify_facets(&root, id);
        }

        "HO-01" | "HO-02" | "HO-03" | "HO-04" | "HO-05" | "HO-06" | "HO-07" | "HO-08" | "HO-09"
        | "HO-10" => {
            verify_holo(&root, id);
        }

        "CT-01" | "CT-02" | "CT-03" | "CT-04" | "CT-05" | "CT-06" | "CT-07" | "CT-08" | "CT-09"
        | "CT-10" | "CT-11" => {
            verify_controller(&root, id);
        }

        "ST-01" | "ST-02" | "ST-03" | "ST-04" | "ST-05" | "ST-06" | "ST-07" | "ST-08" | "ST-09"
        | "ST-10" => {
            verify_stdlib(&root, id);
        }

        "AR-01" | "AR-02" | "AR-03" | "AR-04" | "AR-05" | "AR-06" | "AR-07" | "AR-08" | "AR-09"
        | "AR-10" => {
            verify_artifacts(&root, id);
        }

        "EX-01" | "EX-02" | "EX-03" | "EX-04" | "EX-05" | "EX-06" | "EX-07" | "EX-08" | "EX-09"
        | "EX-10" => {
            verify_execution(&root, id);
        }

        "VR-01" | "VR-02" | "VR-03" | "VR-04" | "VR-05" | "VR-06" | "VR-07" | "VR-08" | "VR-09"
        | "VR-10" | "VR-11" | "VR-12" => {
            verify_verification(&root, id);
        }

        "SE-01" | "SE-02" | "SE-03" | "SE-04" | "SE-05" | "SE-06" | "SE-07" | "SE-08" => {
            verify_security(&root, id);
        }

        _ => panic!("unhandled conformance id: {id}"),
    }
}

fn verify_rp_01(root: &Path) {
    assert!(root.join("Cargo.toml").exists());
    assert!(root.join("crates/prismpm").exists());
    assert!(root.join("crates/model").exists());
    assert!(root.join("crates/conformance").exists());
    assert!(root.join("xtask").exists());
    assert!(!root.join("src").exists());
    assert_contains(
        root,
        "Cargo.toml",
        &["[workspace]", "members = [\"crates/*\", \"xtask\"]"],
    );
}

fn verify_rp_02(root: &Path) {
    let rust_toolchain = std::fs::read_to_string(root.join("rust-toolchain.toml")).unwrap();
    assert!(rust_toolchain.contains("1.97.1"));
    let lean_toolchain = std::fs::read_to_string(root.join("lean-toolchain")).unwrap();
    assert!(lean_toolchain.contains("leanprover/lean4:v4.32.1"));
    assert_contains(
        root,
        "tools.lock",
        &["1.97.1", "v4.32.1", "4.2.3", "1.57.0", "0.20.2"],
    );
}

fn verify_rp_03(root: &Path) {
    let model = repo_model::Model::load(&root.join("model")).unwrap();
    model.check().unwrap();
}

fn verify_rp_04(root: &Path) {
    assert_contains(
        root,
        ".devcontainer/Dockerfile",
        &["rustup-init", "sha256sum -c", "leanprover/lean4:v4.32.1"],
    );
    let workflow = read(root, ".github/workflows/vv.yml");
    assert!(workflow.contains("actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683"));
    assert!(workflow.contains("runCmd: |"));
    assert_eq!(
        workflow.matches("just vv").count(),
        2,
        "the CI workflow must exercise repeatable verification"
    );
}

fn verify_rp_05(root: &Path) {
    let cargo_toml = std::fs::read_to_string(root.join("Cargo.toml")).unwrap();
    assert!(cargo_toml.contains("missing_docs = \"deny\""));
}

fn verify_rp_06(root: &Path) {
    let justfile = std::fs::read_to_string(root.join("Justfile")).unwrap();
    assert!(justfile.contains("vv:"));
}

fn verify_rp_07(root: &Path) {
    let spec = std::fs::read_to_string(root.join("SPEC.md")).unwrap();
    assert!(spec.contains("## Appendix A. Conformance ID Registry"));
}

fn verify_rp_08(root: &Path) {
    let report = crate::runner::scenarios_in(&root.join("features/suites")).unwrap();
    assert!(
        report.violations.is_empty(),
        "violations: {:?}",
        report.violations
    );
}

fn verify_rp_09(root: &Path) {
    let left = tempfile::tempdir().unwrap();
    let right = tempfile::tempdir().unwrap();
    copy_project(root, left.path());
    copy_project(root, right.path());
    let first = prismpm::Controller::load(left.path())
        .unwrap()
        .build(prismpm::controller::BuildRequest { config_path: None })
        .unwrap();
    let second = prismpm::Controller::load(right.path())
        .unwrap()
        .build(prismpm::controller::BuildRequest { config_path: None })
        .unwrap();
    assert_eq!(first.build_id, second.build_id);
    assert_eq!(
        tree(&left.path().join(".prism/build").join(&first.build_id)),
        tree(&right.path().join(".prism/build").join(&second.build_id))
    );
}

fn verify_rp_10(root: &Path) {
    let model = repo_model::Model::load_from_repo_root().unwrap();
    let conformance = read(root, "CONFORMANCE.md");
    let errors = read(root, "ERRORS.md");
    assert!(model.ids.id.iter().all(|row| conformance.contains(&row.id)));
    assert!(model
        .errors
        .error
        .iter()
        .all(|row| errors.contains(&row.code)));
}

fn verify_rp_11(root: &Path) {
    assert_contains(
        root,
        "LICENSE-MIT",
        &["MIT License", "Permission is hereby granted"],
    );
    assert_contains(root, "LICENSE-APACHE", &["Apache License", "Version 2.0"]);
    assert_contains(root, "Cargo.toml", &["license = \"MIT OR Apache-2.0\""]);
}

fn verify_rp_12(root: &Path) {
    let source = std::fs::read_to_string(root.join("crates/model/src/release.rs")).unwrap();
    for criterion in [
        "vv-evidence.json",
        "release source tree is not clean",
        "coverage_state",
        "CHANGELOG.md",
    ] {
        assert!(
            source.contains(criterion),
            "missing release criterion {criterion}"
        );
    }
    let fixture = tempfile::tempdir().unwrap();
    for entry in walkdir::WalkDir::new(root.join("model")) {
        let entry = entry.unwrap();
        let suffix = entry.path().strip_prefix(root).unwrap();
        let target = fixture.path().join(suffix);
        if entry.file_type().is_dir() {
            std::fs::create_dir_all(target).unwrap();
        } else if entry.file_type().is_file() {
            std::fs::copy(entry.path(), target).unwrap();
        }
    }
    for relative in ["Cargo.toml", "CHANGELOG.md"] {
        std::fs::copy(root.join(relative), fixture.path().join(relative)).unwrap();
    }
    for args in [
        &["init", "--quiet"][..],
        &["config", "user.name", "PrismPM conformance"][..],
        &["config", "user.email", "conformance@example.invalid"][..],
        &["add", "."][..],
        &["commit", "--quiet", "-m", "release fixture"][..],
    ] {
        let status = Command::new("git")
            .args(args)
            .current_dir(fixture.path())
            .status()
            .unwrap();
        assert!(status.success(), "git {} failed", args.join(" "));
    }
    std::fs::write(fixture.path().join("dirty.fixture"), b"dirty\n").unwrap();

    let issues = repo_model::release::check(fixture.path(), &[])
        .expect_err("the local untagged, dirty, missing-evidence fixture must be refused");
    assert!(issues.iter().any(|issue| issue.contains("not clean")));
    assert!(issues.iter().any(|issue| issue.contains("not tagged")));
    assert!(issues.iter().any(|issue| issue.contains("evidence")));
}

fn verify_facets(root: &Path, id: &str) {
    match id {
        "FT-01" => assert_declarations(
            root,
            "Foundation.Arch",
            &[
                "Component",
                "Edge",
                "Stakeholder",
                "Concern",
                "Viewpoint",
                "View",
            ],
        ),
        "FT-02" => assert_declarations(root, "Foundation.Sec", &["Asset", "SecurityActivity"]),
        "FT-03" => assert_declarations(
            root,
            "Foundation.Sec",
            &["ApplicationSecurityControl", "VerificationMeasurement"],
        ),
        "FT-04" => assert_declarations(
            root,
            "Foundation.Sec",
            &["Threat", "Risk", "Likelihood", "Impact"],
        ),
        "FT-05" => assert_declarations(
            root,
            "Foundation.Qual",
            &[
                "ProductQualityCharacteristic",
                "QualitySubcharacteristic",
                "QualityRequirement",
                "QualityMeasure",
            ],
        ),
        "FT-06" => {
            for package in ["prism.arch", "prism.sec", "prism.qual"] {
                assert_contains(
                    root,
                    &format!("language/{package}/lexicon.toml"),
                    &["spec = \"lexlean/lexicon/1\"", "language = \"1.1\""],
                );
                for entry in
                    walkdir::WalkDir::new(root.join("language").join(package).join("entries"))
                {
                    let entry = entry.unwrap();
                    if entry.path().extension().and_then(|value| value.to_str()) == Some("toml") {
                        let source = std::fs::read_to_string(entry.path()).unwrap();
                        for field in ["[denotation]", "[[form]]", "canonical_source = true"] {
                            assert!(
                                source.contains(field),
                                "{} lacks {field}",
                                entry.path().display()
                            );
                        }
                    }
                }
            }
        }
        "FT-07" => {
            assert_contains(
                root,
                "language/prism.sec/lexicon.toml",
                &["prism.arch@1.0.0"],
            );
            assert_contains(
                root,
                "language/prism.qual/lexicon.toml",
                &["prism.arch@1.0.0"],
            );
            assert!(!read(root, "language/prism.arch/lexicon.toml").contains("prism.sec"));
        }
        "FT-08" => {
            let standards = read(root, "model/standards.toml");
            for entry in walkdir::WalkDir::new(root.join("language")) {
                let entry = entry.unwrap();
                if entry.path().extension().and_then(|value| value.to_str()) == Some("toml")
                    && entry
                        .path()
                        .components()
                        .any(|part| part.as_os_str() == "entries")
                {
                    let value: toml::Value =
                        toml::from_str(&std::fs::read_to_string(entry.path()).unwrap()).unwrap();
                    let entry_id = value["id"].as_str().unwrap();
                    assert!(
                        standards.contains(&format!("\"{entry_id}\"")),
                        "unmapped entry {entry_id}"
                    );
                }
            }
        }
        "FT-09" => {
            let manifest = build_manifest(root);
            let outputs = manifest["files"]
                .as_array()
                .or_else(|| manifest["outputs"].as_array())
                .expect("build outputs");
            assert!(outputs
                .iter()
                .any(|row| row["kind"].as_str() == Some("lean")));
            assert!(outputs
                .iter()
                .any(|row| matches!(row["kind"].as_str(), Some("latex" | "tex"))));
        }
        "FT-10" => {
            assert_contains(
                root,
                "lexlean.lock",
                &[
                    "language = \"1.1\"",
                    "prism.arch",
                    "prism.sec",
                    "prism.qual",
                ],
            );
            assert_contains(root, "Justfile", &["repro"]);
        }
        _ => unreachable!(),
    }
}

fn verify_holo(root: &Path, id: &str) {
    let document = model(root);
    let bytes = model_bytes(root);
    match id {
        "HO-01" => {
            let holo = sample_application_holo(root);
            assert_eq!(&holo.bytes[..6], b"HOLO\x04\0");
            prismpm::holo::archive::validate_application(&holo.bytes).unwrap();
        }
        "HO-02" => {
            assert_eq!(document["schema"], "prismpm/model-document/1");
            let _: prismpm::holo::model_document::ModelDocument =
                serde_json::from_slice(&bytes).unwrap();
            let schema = json(&root.join("schemas/model-document.schema.json"));
            assert_eq!(schema["$id"], "prismpm/model-document/1");
        }
        "HO-03" => {
            assert!(!bytes.ends_with(b"\n"));
            assert_eq!(
                prismpm::holo::canonical::encode_value(&document).unwrap(),
                bytes
            );
            assert_eq!(checked(root).model_id, sha256(&bytes));
        }
        "HO-04" => {
            assert_eq!(
                document["provenance"]["snapshot_id"].as_str().unwrap(),
                sha256(&std::fs::read(build_root(root).join("lexlean/snapshot.json")).unwrap())
            );
            assert_eq!(
                document["provenance"]["semantic_id"],
                snapshot(root)["semantic_id"]
            );
        }
        "HO-05" => {
            for section in ["architecture", "security", "quality"] {
                for rows in document[section].as_object().unwrap().values() {
                    assert_indexed(rows);
                }
            }
        }
        "HO-06" => {
            let text = std::str::from_utf8(&bytes).unwrap();
            for forbidden in [
                root.to_string_lossy().as_ref(),
                "/workspaces/",
                "timestamp",
                "hostname",
            ] {
                assert!(
                    !text.contains(forbidden),
                    "model document contains unstable value {forbidden}"
                );
            }
        }
        "HO-07" => {
            assert!(prismpm::holo::archive::validate_application(&bytes).is_err());
            let mut wrong_version = sample_application_holo(root).bytes;
            wrong_version[4] = 5;
            assert!(prismpm::holo::archive::validate_application(&wrong_version).is_err());
        }
        "HO-08" => {
            let emitter = document["provenance"]["emitter_semantics_id"]
                .as_str()
                .unwrap();
            assert_hex_digest(emitter);
            assert_contains(root, "model/emitter-inputs.toml", &[emitter]);
        }
        "HO-09" => {
            assert!(root
                .join("tests/golden/stdlib/build/model.prism.json")
                .exists());
            assert!(root
                .join("tests/golden/stdlib/golden-manifest.json")
                .exists());
        }
        "HO-10" => {
            let holo = sample_application_holo(root);
            prismpm::holo::archive::validate_application(&holo.bytes).unwrap();
            let mut mutation = holo.bytes;
            let middle = mutation.len() / 2;
            mutation[middle] ^= 1;
            assert!(prismpm::holo::archive::validate_application(&mutation).is_err());
        }
        _ => unreachable!(),
    }
}

fn verify_controller(root: &Path, id: &str) {
    if id == "CT-11" {
        let project = tempfile::tempdir().unwrap();
        std::fs::copy(
            root.join("prismpm.toml"),
            project.path().join("prismpm.toml"),
        )
        .unwrap();
        std::fs::copy(
            root.join("lexlean.toml"),
            project.path().join("lexlean.toml"),
        )
        .unwrap();
        let output = project.path().join(".prism");
        std::fs::create_dir(&output).unwrap();
        std::fs::write(output.join("owned"), b"owned").unwrap();
        let controller = prismpm::Controller::load(project.path()).unwrap();
        let result = controller
            .clean(prismpm::controller::CleanRequest { config_path: None })
            .unwrap();
        assert_eq!(result.schema, "prismpm/clean-result/1");
        assert_eq!(result.removed, ".prism");
        assert!(!output.exists());

        let outside = tempfile::tempdir().unwrap();
        std::fs::write(outside.path().join("preserved"), b"outside").unwrap();
        #[cfg(unix)]
        std::os::unix::fs::symlink(outside.path(), &output).unwrap();
        #[cfg(not(unix))]
        panic!("CT-11 is normative on the supported Unix host");
        let error = controller
            .clean(prismpm::controller::CleanRequest { config_path: None })
            .unwrap_err();
        assert_eq!(error.code, "PP8001");
        assert!(outside.path().join("preserved").exists());
        return;
    }
    match id {
        "CT-01" => {
            let _: prismpm::controller::CheckRequest =
                prismpm::controller::CheckRequest { config_path: None };
            let _: prismpm::controller::BuildRequest =
                prismpm::controller::BuildRequest { config_path: None };
            assert_eq!(checked(root).schema, "prismpm/check-result/1");
            assert_eq!(built(root).schema, "prismpm/build-result/1");
        }
        "CT-02" => assert_contains(
            root,
            "crates/prismpm/src/controller/mod.rs",
            &["Engine", ".snapshot(", ".build("],
        ),
        "CT-03" => {
            let result = checked(root);
            assert_hex_digest(&result.snapshot_id);
            assert_hex_digest(&result.model_id);
        }
        "CT-04" => {
            let result = built(root);
            assert_eq!(
                build_root(root),
                root.join(&result.manifest_path).parent().unwrap()
            );
            assert!(build_root(root).join("manifest.json").exists());
        }
        "CT-05" => assert_contains(
            root,
            "crates/prismpm/src/cli.rs",
            &[
                "encode_value",
                "Commands::Check",
                "Commands::Build",
                "Commands::Verify",
            ],
        ),
        "CT-06" => assert_contains(
            root,
            "prismpm.toml",
            &["max_holo_bytes", "max_entities", "max_diagnostics"],
        ),
        "CT-07" => {
            let errors = read(root, "model/errors.toml");
            for code in [
                "PP1001", "PP2001", "PP3001", "PP4001", "PP5001", "PP8001", "PP9001",
            ] {
                assert!(errors.contains(code), "missing diagnostic range {code}");
            }
        }
        "CT-08" => assert!(!read(root, "crates/prismpm/src/controller/mod.rs").contains("reqwest")),
        "CT-09" => {
            let config: toml::Value = toml::from_str(&read(root, "prismpm.toml")).unwrap();
            assert_eq!(config["spec"].as_str(), Some("prismpm/project/1"));
            assert!(root.join("schemas/project.schema.json").exists());
        }
        "CT-10" => assert_contains(root, "crates/prismpm/src/error.rs", &["causes", "LexLean"]),
        _ => unreachable!(),
    }
}

fn verify_stdlib(root: &Path, id: &str) {
    match id {
        "ST-01" => assert_declarations(
            root,
            "Foundation.Arch",
            &[
                "StandardReference",
                "Component",
                "Edge",
                "ViewpointClass",
                "ViewClass",
            ],
        ),
        "ST-02" => assert_declarations(
            root,
            "Foundation.Sec",
            &[
                "Asset",
                "ApplicationSecurityControl",
                "SecurityActivity",
                "VerificationMeasurement",
            ],
        ),
        "ST-03" => assert_declarations(
            root,
            "Foundation.Sec",
            &["Threat", "Risk", "Likelihood", "Impact"],
        ),
        "ST-04" => assert_declarations(
            root,
            "Foundation.Qual",
            &[
                "ProductQualityCharacteristic",
                "QualitySubcharacteristic",
                "QualityRequirement",
                "QualityMeasure",
            ],
        ),
        "ST-05" => {
            for entry in walkdir::WalkDir::new(root.join("stdlib")) {
                let entry = entry.unwrap();
                assert_ne!(
                    entry.path().extension().and_then(|value| value.to_str()),
                    Some("lean"),
                    "handwritten Lean: {}",
                    entry.path().display()
                );
                assert_ne!(entry.file_name().to_str(), Some("lakefile.lean"));
            }
        }
        "ST-06" => {
            assert_declarations(root, "Foundation.Arch", &["edgeIngress", "edgeReturnCycle"]);
            assert!(root.join("tests/negative/dangling-edge/case.toml").exists());
        }
        "ST-07" => {
            assert_prism_theorems_axiom_free(root);
        }
        "ST-08" => {
            let roots = json(&verified_root(root).join("roots.json"));
            assert_eq!(
                roots["requested_roots"],
                verification_manifest(root)["runtime_roots"]
            );
        }
        "ST-09" => {
            let golden = root.join("tests/golden/stdlib");
            for path in [
                "build/model.prism.json",
                "build/manifest.json",
                "build/lexlean/snapshot.json",
                "golden-manifest.json",
            ] {
                assert!(golden.join(path).exists(), "missing golden {path}");
            }
        }
        "ST-10" => {
            assert_eq!(verified(root).schema, "prismpm/verify-result/1");
            assert_eq!(model(root)["schema"], "prismpm/model-document/1");
        }
        _ => unreachable!(),
    }
}

fn verify_artifacts(root: &Path, id: &str) {
    let manifest = build_manifest(root);
    let bytes = std::fs::read(build_root(root).join("manifest.json")).unwrap();
    let outputs = manifest["files"]
        .as_array()
        .or_else(|| manifest["outputs"].as_array())
        .expect("build files");
    match id {
        "AR-01" => assert_eq!(
            build_root(root).file_name().unwrap().to_str(),
            Some(built(root).build_id.as_str())
        ),
        "AR-02" => {
            for row in outputs {
                assert!(row["path"].is_string() && row["kind"].is_string());
                assert!(row["byte_length"].is_u64());
                assert_hex_digest(row["sha256"].as_str().unwrap());
            }
        }
        "AR-03" => {
            assert_hex_digest(&built(root).build_id);
            for row in outputs {
                assert_hex_digest(row["sha256"].as_str().unwrap());
            }
        }
        "AR-04" => {
            let text = std::str::from_utf8(&bytes).unwrap();
            assert!(!text.contains(root.to_string_lossy().as_ref()));
            assert!(!text.contains("timestamp"));
        }
        "AR-05" => assert_contains(
            root,
            "crates/prismpm/src/controller/mod.rs",
            &["rename", "staging"],
        ),
        "AR-06" => assert_contains(
            root,
            "crates/prismpm/src/controller/mod.rs",
            &["verify_existing"],
        ),
        "AR-07" => assert!(root.join("tests/negative/artifact").exists()),
        "AR-08" => {
            assert!(outputs
                .iter()
                .any(|row| row["kind"].as_str() == Some("lean")));
            assert!(outputs
                .iter()
                .any(|row| matches!(row["kind"].as_str(), Some("latex" | "tex"))));
        }
        "AR-09" => assert!(
            outputs
                .iter()
                .filter(|row| row["kind"].as_str() == Some("source-map"))
                .count()
                >= 5
        ),
        "AR-10" => assert!(
            outputs
                .iter()
                .filter(|row| row["kind"].as_str() == Some("coverage"))
                .count()
                >= 5
        ),
        _ => unreachable!(),
    }
}

fn verify_execution(root: &Path, id: &str) {
    let manifest = verification_manifest(root);
    let evidence = json(&verified_root(root).join("execution.json"));
    let coverage = json(&verified_root(root).join("coverage.json"));
    let roots = json(&verified_root(root).join("roots.json"));
    match id {
        "EX-01" => {
            assert_artifact(root, "kernel_ir", "kernel.ir");
            assert!(process_tools(root).contains("prod-export"));
        }
        "EX-02" => {
            for field in ["opaque_nodes", "unsupported_types", "external_calls"] {
                assert!(
                    coverage[field].as_array().is_some_and(Vec::is_empty),
                    "nonempty coverage {field}"
                );
            }
            assert_eq!(coverage["requested_roots"], roots["requested_roots"]);
        }
        "EX-03" => {
            assert_eq!(evidence["no_allocation"], true);
            assert_contains(
                root,
                "crates/prismpm/src/verification.rs",
                &["prod_alloc_counter", "allocation"],
            );
        }
        "EX-04" => {
            assert_eq!(model(root)["schema"], "prismpm/model-document/1");
            assert_contains(
                root,
                "crates/prismpm/src/verification.rs",
                &["decode_canonical", "normalize"],
            );
        }
        "EX-05" => {
            assert_eq!(evidence["status"], "passed");
            assert_eq!(manifest["execution"], evidence);
        }
        "EX-06" => {
            assert_eq!(evidence["case_count"], 597);
            assert_eq!(evidence["strategy"], "exhaustive-v1+lcg-v1");
            assert!(evidence["corpus_sha256"].is_string());
        }
        "EX-07" => {
            assert_eq!(evidence["seed"], "5eedcafef00dbeef");
            assert_eq!(evidence["bounds"]["max_length"], 16);
            assert_artifact(root, "execution_corpus", "execution-corpus.toml");
        }
        "EX-08" => assert_eq!(evidence["no_panic"], true),
        "EX-09" => assert!(roots["erased_proof_dependencies"].as_array().is_some()),
        "EX-10" => {
            assert_eq!(evidence["bounds"]["value_domain"], "u64");
            let corpus: toml::Value =
                toml::from_str(&read(root, "model/execution-corpus.toml")).unwrap();
            assert_eq!(
                corpus["property"]["generated_value_modulus"].as_integer(),
                Some(20)
            );
            assert_eq!(corpus["property"]["max_length"].as_integer(), Some(16));
        }
        _ => unreachable!(),
    }
}

fn verify_verification(root: &Path, id: &str) {
    let manifest = verification_manifest(root);
    let tools = process_tools(root);
    match id {
        "VR-01" => {
            assert!(tools.contains("lake-build-generated"));
            assert_contains(root, "lean-toolchain", &["leanprover/lean4:v4.32.1"]);
        }
        "VR-02" => {
            for row in manifest["processes"].as_array().unwrap() {
                assert!(row["argv"].is_array());
                assert_hex_digest(row["executable_sha256"].as_str().unwrap());
                assert_eq!(row["exit_code"], 0);
            }
        }
        "VR-03" => assert_contains(
            root,
            "crates/prismpm/src/verification.rs",
            &["tempdir", "lakefile.toml"],
        ),
        "VR-04" => assert!(tools.contains("leanchecker")),
        "VR-05" => assert_prism_theorems_axiom_free(root),
        "VR-06" => {
            assert_eq!(verified(root).schema, "prismpm/verify-result/1");
            assert_eq!(
                verified_root(root).file_name().unwrap().to_str(),
                Some(verified(root).attestation_id.as_str())
            );
        }
        "VR-07" => {
            let model_bytes = std::fs::read(build_root(root).join("model.prism.json")).unwrap();
            let holo_row = artifact(&manifest, "model");
            assert_eq!(holo_row["byte_length"], model_bytes.len() as u64);
            assert_eq!(holo_row["sha256"], sha256(&model_bytes));
            for (name, filename) in [
                ("execution_evidence", "execution.json"),
                ("kernel_ir", "kernel.ir"),
                ("generated_rust", "generated.rs"),
                ("lexlean_attestation", "lexlean-attestation.json"),
            ] {
                assert_artifact(root, name, filename);
            }
        }
        "VR-08" => assert_contains(
            root,
            "crates/prismpm/src/verification.rs",
            &["PP5002", "PP5003", "PP5004"],
        ),
        "VR-09" => assert!(!read(root, "crates/prismpm/src/verification.rs").contains("http")),
        "VR-10" => assert_contains(
            root,
            "crates/prismpm/src/verification.rs",
            &["timeout", "CHILD_OUTPUT_LIMIT"],
        ),
        "VR-11" => assert_contains(root, "VERIFICATION.md", &["Planted", "restoring commit"]),
        "VR-12" => {
            assert_hex_digest(&verified(root).attestation_id);
            assert_eq!(
                sha256(&std::fs::read(verified_root(root).join("manifest.json")).unwrap()),
                verified(root).attestation_id
            );
        }
        _ => unreachable!(),
    }
}

fn verify_security(root: &Path, id: &str) {
    match id {
        "SE-01" => assert_contains(
            root,
            "crates/prismpm/src/controller/mod.rs",
            &["confined", "output_root"],
        ),
        "SE-02" => {
            assert!(root.join("tests/negative/path").exists());
            assert_contains(root, "crates/prismpm/src/controller/mod.rs", &["symlink"]);
            assert_contains(root, "crates/prismpm/src/config.rs", &["ParentDir"]);
        }
        "SE-03" => {
            let source = read(root, "crates/prismpm/src/verification.rs");
            assert!(source.contains("Command::new"));
            assert!(!source.contains("sh -c"));
        }
        "SE-04" => assert_contains(
            root,
            "crates/prismpm/src/verification.rs",
            &["env_clear", "LC_ALL", "LANG"],
        ),
        "SE-05" => assert_contains(
            root,
            "crates/prismpm/src/controller/mod.rs",
            &["rename", "sync_all"],
        ),
        "SE-06" => {
            for relative in [
                "crates/prismpm/src/lib.rs",
                "crates/model/src/lib.rs",
                "crates/conformance/src/lib.rs",
            ] {
                assert_contains(root, relative, &["forbid(unsafe_code)"]);
            }
        }
        "SE-07" => {
            assert!(checked(root).entity_count > 0);
            assert_contains(
                root,
                "crates/prismpm/src/config.rs",
                &["max_holo_bytes", "max_entities", "max_diagnostics"],
            );
        }
        "SE-08" => {
            assert!(root.join("deny.toml").exists());
            assert_contains(root, "xtask/src/main.rs", &["deny", "--all-features"]);
        }
        _ => unreachable!(),
    }
}
