//! Production contract tests over the committed Prism-stdlib project.

use lexlean::{CheckRequest as LexCheckRequest, Engine, Selection};
use prismpm::controller::{BuildRequest, CheckRequest, Controller};
use prismpm::holo::canonical::{content_id, decode_canonical, encode_canonical};
use prismpm::holo::projector::project_snapshot;
use proptest::prelude::*;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::OnceLock;

fn root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .expect("crate is below repository root")
        .to_path_buf()
}

fn document() -> prismpm::holo::ModelDocument {
    let project = camino::Utf8PathBuf::from_path_buf(root().join("lexlean.toml")).expect("UTF-8");
    let snapshot = Engine::load(&project)
        .expect("LexLean project")
        .snapshot(LexCheckRequest {
            selection: Selection::Entrypoints,
        })
        .expect("snapshot");
    project_snapshot(&snapshot).expect("model-document projection")
}

fn canonical_bytes() -> &'static [u8] {
    static BYTES: OnceLock<Vec<u8>> = OnceLock::new();
    BYTES
        .get_or_init(|| encode_canonical(&document()).expect("canonical model document"))
        .as_slice()
}

fn copy_tree(from: &Path, to: &Path) {
    for relative in ["language", "stdlib"] {
        for entry in walkdir::WalkDir::new(from.join(relative)) {
            let entry = entry.expect("tree entry");
            let suffix = entry.path().strip_prefix(from).expect("relative");
            let destination = to.join(suffix);
            if entry.file_type().is_dir() {
                std::fs::create_dir_all(&destination).expect("create directory");
            } else if entry.file_type().is_file() {
                std::fs::copy(entry.path(), destination).expect("copy file");
            }
        }
    }
    for relative in [
        "lean-toolchain",
        "lakefile.toml",
        "lake-manifest.json",
        "lexlean.lock",
        "lexlean.toml",
        "prismpm.toml",
    ] {
        std::fs::copy(from.join(relative), to.join(relative)).expect("copy project file");
    }
}

#[test]
fn holo_roundtrip_schema_and_cycles_are_valid() {
    let doc = document();
    let bytes = encode_canonical(&doc).expect("canonical model document");
    assert_eq!(decode_canonical(&bytes).expect("decode"), doc);
    assert_eq!(encode_canonical(&doc).expect("repeat"), bytes);
    assert_eq!(content_id(&bytes).len(), 64);
    assert!(doc.architecture.edges.iter().any(|left| doc
        .architecture
        .edges
        .iter()
        .any(|right| { left.from_index == right.to_index && left.to_index == right.from_index })));

    let schema: serde_json::Value =
        serde_json::from_slice(include_bytes!("../schemas/model-document.schema.json"))
            .expect("schema JSON");
    let validator = jsonschema::validator_for(&schema).expect("valid JSON Schema");
    let value: serde_json::Value = serde_json::from_slice(&bytes).expect("model-document JSON");
    assert!(validator.is_valid(&value));
}

#[test]
fn strict_holo_decode_rejects_each_malformed_class() {
    let bytes = encode_canonical(&document()).expect("canonical model document");
    let text = String::from_utf8(bytes.clone()).expect("UTF-8");
    let cases = [
        format!("{}\n", text),
        text.replacen('{', "{ ", 1),
        text.replacen("\"index\":0", "\"index\":0.0", 1),
        text.replacen("\"index\":0", "\"index\":00", 1),
        text.replacen(
            "\"schema\":\"prismpm/model-document/1\"",
            "\"schema\":\"prismpm/model-document/1\",\"schema\":\"prismpm/model-document/1\"",
            1,
        ),
        text.replacen(
            "\"schema\":\"prismpm/model-document/1\"",
            "\"schema\":\"prismpm/model-document/1\",\"unknown\":true",
            1,
        ),
    ];
    for malformed in cases {
        assert!(
            decode_canonical(malformed.as_bytes()).is_err(),
            "accepted {malformed}"
        );
    }
    let mut invalid_utf8 = bytes;
    invalid_utf8.insert(1, 0xff);
    assert!(decode_canonical(&invalid_utf8).is_err());
}

#[test]
fn cross_references_and_order_are_enforced() {
    let mut doc = document();
    doc.architecture.edges[0].from_index = u64::MAX;
    assert_eq!(
        encode_canonical(&doc).expect_err("dangling edge").code,
        "PP2004"
    );

    let mut doc = document();
    doc.architecture.components.swap(0, 1);
    for (index, component) in doc.architecture.components.iter_mut().enumerate() {
        component.index = index as u64;
    }
    let error = encode_canonical(&doc).expect_err("noncanonical order");
    assert_eq!(error.code, "PP4004");
    assert_eq!(
        error.message,
        "component IDs are not in canonical ASCII order"
    );
}

#[test]
fn check_is_no_write_and_build_detects_tampering() {
    let temp = tempfile::tempdir().expect("tempdir");
    copy_tree(&root(), temp.path());
    let controller = Controller::load(temp.path()).expect("controller");
    let checked = controller
        .check(CheckRequest { config_path: None })
        .expect("check");
    assert_eq!(checked.entity_count, 18);
    assert!(!temp.path().join(".prism").exists());
    assert!(!temp.path().join(".lexlean").exists());

    let built = controller
        .build(BuildRequest { config_path: None })
        .expect("build");
    let published = temp.path().join(".prism/build").join(&built.build_id);
    for required in [
        "lexlean/build/maps/PrismPM/Foundation/Holo.map.json",
        "lexlean/build/coverage/PrismPM/Foundation/Holo.coverage.json",
        "lexlean/build/lexicons/Foundation.Holo.closure.json",
    ] {
        assert!(
            published.join(required).is_file(),
            "complete LexLean artifact set includes {required}"
        );
    }
    let holo = temp
        .path()
        .join(".prism/build")
        .join(&built.build_id)
        .join("model.prism.json");
    let extra = holo.parent().unwrap().join("unmanifested-empty-directory");
    std::fs::create_dir(&extra).expect("plant extra directory");
    assert_eq!(
        controller
            .build(BuildRequest { config_path: None })
            .expect_err("extra directory is rejected")
            .code,
        "PP4001"
    );
    std::fs::remove_dir(&extra).expect("restore exact tree");
    std::fs::write(&holo, b"tampered").expect("plant tamper");
    assert_eq!(
        controller
            .build(BuildRequest { config_path: None })
            .expect_err("tampering is rejected")
            .code,
        "PP4001"
    );
}

#[test]
fn configuration_limits_unknown_fields_and_escapes_fail() {
    let temp = tempfile::tempdir().expect("tempdir");
    copy_tree(&root(), temp.path());
    let controller = Controller::load(temp.path()).expect("controller");

    let config = temp.path().join("prismpm.toml");
    let original = std::fs::read_to_string(&config).expect("config");
    std::fs::write(
        &config,
        original.replace("max_entities = 100000", "max_entities = 1"),
    )
    .expect("limit config");
    assert_eq!(
        controller
            .check(CheckRequest { config_path: None })
            .expect_err("entity limit")
            .code,
        "PP1003"
    );

    std::fs::write(&config, format!("{original}\nunknown = true\n")).expect("unknown config");
    assert_eq!(
        controller
            .check(CheckRequest { config_path: None })
            .expect_err("unknown field")
            .code,
        "PP1001"
    );

    std::fs::write(
        &config,
        original.replace(
            "lexlean_project = \"lexlean.toml\"",
            "lexlean_project = \"../lexlean.toml\"",
        ),
    )
    .expect("escape config");
    assert_eq!(
        controller
            .check(CheckRequest { config_path: None })
            .expect_err("path escape")
            .code,
        "PP8001"
    );
}

#[test]
fn cli_machine_contract_is_one_canonical_line_with_stable_exits() {
    let temp = tempfile::tempdir().expect("tempdir");
    copy_tree(&root(), temp.path());
    let binary = env!("CARGO_BIN_EXE_prismpm");
    let success = Command::new(binary)
        .args([
            "--project",
            temp.path().to_str().expect("UTF-8"),
            "--json",
            "check",
        ])
        .output()
        .expect("run CLI");
    assert!(success.status.success());
    assert!(success.stderr.is_empty());
    assert_eq!(
        success.stdout.iter().filter(|byte| **byte == b'\n').count(),
        1
    );
    assert_eq!(success.stdout.last(), Some(&b'\n'));
    let value: serde_json::Value =
        serde_json::from_slice(&success.stdout).expect("machine result JSON");
    assert_eq!(value["schema"], "prismpm/check-result/1");
    assert!(!String::from_utf8_lossy(&success.stdout).contains(": "));

    std::fs::write(temp.path().join("prismpm.toml"), "spec = \"wrong\"\n").expect("bad config");
    let failure = Command::new(binary)
        .args([
            "--project",
            temp.path().to_str().expect("UTF-8"),
            "--json",
            "check",
        ])
        .output()
        .expect("run failing CLI");
    assert_eq!(failure.status.code(), Some(2));
    assert!(failure.stderr.is_empty());
    let value: serde_json::Value =
        serde_json::from_slice(&failure.stdout).expect("machine diagnostic JSON");
    assert_eq!(value["schema"], "prismpm/error-result/1");
    assert_eq!(value["diagnostic"]["code"], "PP1001");
}

#[test]
fn public_diagnostic_codes_are_closed_under_construction_and_deserialization() {
    let unregistered = concat!("P", "P7777");
    let rejected = prismpm::PrismError::new(unregistered, "unregistered");
    assert_eq!(rejected.code, "PP9001");
    assert!(rejected
        .notes
        .iter()
        .any(|note| note.message.contains("unregistered internal diagnostic")));
    let encoded = format!(
        r#"{{"causes":[],"code":"{unregistered}","help":[],"labels":[],"message":"bad","notes":[],"primary":null}}"#
    );
    assert!(serde_json::from_str::<prismpm::PrismError>(&encoded).is_err());
}

#[test]
fn cleanup_cannot_select_the_project_root_as_output() {
    let temp = tempfile::tempdir().expect("temporary project");
    std::fs::write(
        temp.path().join("prismpm.toml"),
        "spec = \"prismpm/project/1\"\nproject = \"protected\"\nlexlean_project = \"lexlean.toml\"\nbuild_root = \".\"\n\n[limits]\nmax_holo_bytes = 1\nmax_entities = 1\nmax_diagnostics = 1\n",
    )
    .expect("configuration");
    std::fs::write(temp.path().join("lexlean.toml"), "protected\n").expect("sentinel");
    let controller = Controller::load(temp.path()).expect("controller");
    let error = controller
        .clean(prismpm::controller::CleanRequest { config_path: None })
        .expect_err("project-root cleanup must be rejected");
    assert_eq!(error.code, "PP8001");
    assert!(temp.path().join("lexlean.toml").is_file());
}

#[test]
fn strict_holo_decode_distinguishes_floats_and_trailing_bytes() {
    let mut trailing = canonical_bytes().to_vec();
    trailing.push(b' ');
    let trailing_error = decode_canonical(&trailing).unwrap_err();
    assert_eq!(trailing_error.code, "PP4004");
    assert_eq!(
        trailing_error.message,
        "bytes follow the canonical model-document JSON value"
    );

    let text = std::str::from_utf8(canonical_bytes()).expect("canonical UTF-8");
    let floating = text.replacen("\"index\":0", "\"index\":0.5", 1);
    let floating_error = decode_canonical(floating.as_bytes()).unwrap_err();
    assert_eq!(floating_error.code, "PP4004");
    assert!(floating_error
        .message
        .contains("floating-point values are forbidden"));
    assert_ne!(trailing_error.message, floating_error.message);
}

proptest! {
    #[test]
    fn content_ids_are_stable_and_sensitive(suffix in prop::collection::vec(any::<u8>(), 0..128)) {
        let canonical = canonical_bytes();
        prop_assert_eq!(content_id(canonical), content_id(canonical));
        let mut changed = canonical.to_vec();
        changed.extend_from_slice(&suffix);
        if !suffix.is_empty() {
            prop_assert_ne!(content_id(canonical), content_id(&changed));
        }
    }

    #[test]
    fn arbitrary_holo_bytes_are_rejected_or_canonical_without_panicking(bytes in prop::collection::vec(any::<u8>(), 0..4096)) {
        if let Ok(decoded) = decode_canonical(&bytes) {
            prop_assert_eq!(encode_canonical(&decoded).expect("accepted Holo re-encodes"), bytes);
        }
    }

    #[test]
    fn graph_reference_validation_matches_collection_bounds(candidate in any::<u64>()) {
        let mut doc = document();
        let bound = doc.architecture.components.len() as u64;
        doc.architecture.edges[0].from_index = candidate;
        let observed = encode_canonical(&doc).is_ok();
        prop_assert_eq!(observed, candidate < bound);
    }

    #[test]
    fn canonical_indexes_are_exactly_zero_based(candidate in any::<u64>()) {
        let mut doc = document();
        doc.architecture.components[0].index = candidate;
        let expected = candidate == 0;
        prop_assert_eq!(encode_canonical(&doc).is_ok(), expected);
    }

    #[test]
    fn configuration_and_manifest_parsers_are_total(bytes in prop::collection::vec(any::<u8>(), 0..2048)) {
        let text = String::from_utf8_lossy(&bytes);
        let _ = toml::from_str::<prismpm::config::ProjectConfig>(&text);
        let _ = serde_json::from_slice::<serde_json::Value>(&bytes);
    }
}
