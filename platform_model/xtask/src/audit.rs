//! Repository audits for PrismPM.

use crate::Fail;
use repo_model::Model;
use sha2::Digest;
use std::collections::BTreeSet;
use std::path::Path;

/// Audit that no handwritten .lean or lakefile.lean exists in source paths.
pub fn audit_no_handwritten_lean(root: &Path) -> Result<(), Fail> {
    let golden_root = root.join("tests/golden/stdlib");
    let mut allowed = std::collections::BTreeSet::new();
    let golden_manifest = golden_root.join("golden-manifest.json");
    if golden_manifest.is_file() {
        let value: serde_json::Value = serde_json::from_slice(&std::fs::read(&golden_manifest)?)?;
        let compiler = value
            .get("compiler_semantics_id")
            .and_then(serde_json::Value::as_str)
            .ok_or("golden manifest lacks compiler_semantics_id")?;
        if compiler.len() != 64 || !compiler.bytes().all(|byte| byte.is_ascii_hexdigit()) {
            return Err("golden manifest has an invalid compiler_semantics_id".into());
        }
        let generated = value
            .get("generated_lean")
            .and_then(serde_json::Value::as_array)
            .ok_or("golden manifest lacks generated_lean")?;
        if generated.is_empty() {
            return Err("golden manifest attests no generated Lean".into());
        }
        for row in generated {
            let relative = row
                .get("path")
                .and_then(serde_json::Value::as_str)
                .ok_or("golden Lean row lacks path")?;
            let source_relative = row
                .get("source_path")
                .and_then(serde_json::Value::as_str)
                .ok_or("golden Lean row lacks source_path")?;
            let expected = row
                .get("sha256")
                .and_then(serde_json::Value::as_str)
                .ok_or("golden Lean row lacks sha256")?;
            let source_expected = row
                .get("source_sha256")
                .and_then(serde_json::Value::as_str)
                .ok_or("golden Lean row lacks source_sha256")?;
            if !relative.starts_with("build/lexlean/build/modules/")
                || !relative.ends_with(".lean")
                || !source_relative.starts_with("source/")
                || !source_relative.ends_with(".lex.tex")
            {
                return Err(format!("invalid generated Lean golden mapping {relative}").into());
            }
            let path = golden_root.join(relative);
            let source = golden_root.join(source_relative);
            let actual = format!("{:x}", sha2::Sha256::digest(std::fs::read(&path)?));
            let source_actual = format!("{:x}", sha2::Sha256::digest(std::fs::read(&source)?));
            if actual != expected || source_actual != source_expected {
                return Err(
                    format!("generated Lean golden mapping is stale for {relative}").into(),
                );
            }
            if !allowed.insert(path) {
                return Err(format!("duplicate generated Lean golden path {relative}").into());
            }
        }
    }
    for entry in walkdir::WalkDir::new(root).into_iter().flatten() {
        if !entry.file_type().is_file() {
            continue;
        }
        let path = entry.path();
        let rel = path.strip_prefix(root).unwrap_or(path).to_string_lossy();
        if Path::new(rel.as_ref()).components().any(|component| {
            matches!(
                component.as_os_str().to_str(),
                Some(".prism" | ".lexlean" | ".git" | "target" | "node_modules")
            )
        }) {
            continue;
        }
        if rel.ends_with(".lean") && !allowed.contains(path) {
            return Err(
                format!("no-handwritten-lean audit failed: found {}", path.display()).into(),
            );
        }
        if rel.ends_with("lakefile.lean") {
            return Err(
                format!("no-handwritten-lean audit failed: found {}", path.display()).into(),
            );
        }
        if rel.ends_with(".ir") {
            let vendor_root = root.join("vendor/lean4-prod/rust");
            if let Ok(vendor_relative) = path.strip_prefix(&vendor_root) {
                let digest = format!("{:x}", sha2::Sha256::digest(std::fs::read(path)?));
                let manifest = std::fs::read_to_string(vendor_root.join("MANIFEST.sha256"))?;
                let row = format!(
                    "{digest}  {}",
                    vendor_relative.to_string_lossy().replace('\\', "/")
                );
                if manifest.lines().any(|line| line == row) {
                    continue;
                }
                return Err(
                    format!(
                        "generated-output audit failed: vendored generated fixture {rel} is not hash-pinned"
                    )
                    .into(),
                );
            }
            return Err(format!(
                "generated-output audit failed: source tree contains {rel}; retain its normalized hash record instead"
            )
            .into());
        }
        if rel.ends_with("/generated.rs") {
            return Err(format!(
                "generated-output audit failed: source tree contains {rel}; retain its normalized hash record instead"
            )
            .into());
        }
    }
    Ok(())
}

/// Audit the generated-Lean-only formal contract at its LexLean source.
///
/// This is deliberately structural: LexLean and Lean establish typing and
/// proofs, while this gate prevents the registered validator theorems from
/// drifting into vacuous statements or undeclared axiom policies.
pub fn audit_formal_contract(root: &Path) -> Result<(), Fail> {
    if std::fs::read(root.join("crates/prismpm/src/prod_alloc_counter.rs.inc"))?
        != std::fs::read(root.join("vendor/lean4-prod/rust/prod-alloc-counter/src/lib.rs"))?
    {
        return Err("embedded allocation counter differs from the pinned upstream source".into());
    }
    let path = root.join("stdlib/src/Foundation/Holo.lex.tex");
    let source = std::fs::read_to_string(&path)?;
    let payload = source
        .lines()
        .find_map(|line| {
            line.strip_prefix("\\semanticdata{")
                .and_then(|value| value.strip_suffix('}'))
        })
        .ok_or("Foundation.Holo has no semantic module payload")?;
    let value: serde_json::Value = serde_json::from_str(payload)?;
    let declarations = value
        .get("declarations")
        .and_then(serde_json::Value::as_array)
        .ok_or("Foundation.Holo has no semantic declarations")?;
    let by_name = declarations
        .iter()
        .filter_map(|row| Some((row.get("name")?.as_str()?, row)))
        .collect::<std::collections::BTreeMap<_, _>>();

    for theorem in declarations
        .iter()
        .filter(|row| row.get("kind").and_then(serde_json::Value::as_str) == Some("theorem"))
    {
        if theorem
            .get("axioms")
            .and_then(serde_json::Value::as_array)
            .is_some_and(|axioms| !axioms.is_empty())
        {
            return Err(format!(
                "Prism theorem {} declares a nonempty axiom policy",
                theorem
                    .get("name")
                    .and_then(serde_json::Value::as_str)
                    .unwrap_or("<unnamed>")
            )
            .into());
        }
    }

    let pairs = [
        ("componentIndexes_sound_complete", "componentIndexesValid"),
        ("edgeEndpoints_sound_complete", "edgeEndpointsValid"),
        ("riskLinks_sound_complete", "riskLinksValid"),
        ("controlLinks_sound_complete", "controlLinksValid"),
        ("viewpointLinks_sound_complete", "viewpointLinksValid"),
        ("qualityLinks_sound_complete", "qualityLinksValid"),
        ("flattenedBounds_sound_complete", "flattenedBoundsValid"),
        ("standardsProfile_sound_complete", "standardsProfileValid"),
    ];
    for (theorem_name, proposition_name) in pairs {
        let theorem = by_name
            .get(theorem_name)
            .ok_or_else(|| format!("missing formal theorem {theorem_name}"))?;
        let statement = theorem
            .get("statement")
            .ok_or_else(|| format!("{theorem_name} has no statement"))?;
        let right_function = statement
            .get("right")
            .and_then(|right| right.get("function"))
            .and_then(|function| function.get("name"))
            .and_then(serde_json::Value::as_str);
        if statement.get("kind").and_then(serde_json::Value::as_str) != Some("iff")
            || right_function != Some(proposition_name)
        {
            return Err(format!("{theorem_name} is not an iff with {proposition_name}").into());
        }
    }

    let assignment = by_name
        .get("canonicalIndexAssignment")
        .ok_or("missing canonical index-assignment proposition")?;
    let assignment_body = assignment
        .get("body")
        .ok_or("canonical index-assignment proposition has no body")?;
    if assignment
        .get("result")
        .and_then(|result| result.get("kind"))
        != Some(&serde_json::Value::String("prop".to_owned()))
        || assignment_body
            .get("kind")
            .and_then(serde_json::Value::as_str)
            != Some("eq")
        || assignment_body
            .get("right")
            .and_then(|right| right.get("function"))
            .and_then(|function| function.get("name"))
            .and_then(serde_json::Value::as_str)
            != Some("canonicalIndexes")
    {
        return Err("canonical index assignment is not equality to canonicalIndexes".into());
    }
    let uniqueness = by_name
        .get("canonicalIndexAssignmentUnique")
        .ok_or("missing canonical index uniqueness theorem")?;
    let statement = uniqueness
        .get("statement")
        .ok_or("canonical index uniqueness theorem has no statement")?;
    if statement.get("kind").and_then(serde_json::Value::as_str) != Some("iff")
        || statement
            .get("left")
            .and_then(|left| left.get("function"))
            .and_then(|function| function.get("name"))
            .and_then(serde_json::Value::as_str)
            != Some("canonicalIndexAssignment")
        || statement
            .get("right")
            .and_then(|right| right.get("right"))
            .and_then(|right| right.get("function"))
            .and_then(|function| function.get("name"))
            .and_then(serde_json::Value::as_str)
            != Some("canonicalIndexes")
    {
        return Err("canonical index uniqueness theorem is not the exact characterization".into());
    }

    let corpus_source =
        std::fs::read_to_string(root.join("stdlib/src/Production/SystemValidationCorpus.lex.tex"))?;
    let corpus_payload = corpus_source
        .lines()
        .find_map(|line| {
            line.strip_prefix("\\semanticdata{")
                .and_then(|value| value.strip_suffix('}'))
        })
        .ok_or("Production.SystemValidationCorpus has no semantic module payload")?;
    let corpus: serde_json::Value = serde_json::from_str(corpus_payload)?;
    let corpus_declarations = corpus["declarations"]
        .as_array()
        .ok_or("Production.SystemValidationCorpus has no semantic declarations")?;
    let corpus_by_name = corpus_declarations
        .iter()
        .filter_map(|row| Some((row.get("name")?.as_str()?, row)))
        .collect::<std::collections::BTreeMap<_, _>>();
    for family in [
        "CapabilitySatisfaction",
        "Closure",
        "Compatibility",
        "DeploymentOrder",
        "EvidenceClosure",
        "LicenseClosure",
        "MigrationOrder",
        "ReferentialIntegrity",
        "ReleaseCompleteness",
        "RollbackSafety",
        "SecretFlow",
        "Uniqueness",
    ] {
        for (suffix, model, expected) in [
            ("Sound", "corpusValidModel".to_owned(), true),
            (
                "RejectsMutation",
                format!("corpusInvalid{family}Model"),
                false,
            ),
        ] {
            let theorem_name = format!("corpus{family}{suffix}");
            let theorem = corpus_by_name
                .get(theorem_name.as_str())
                .ok_or_else(|| format!("missing direct model theorem {theorem_name}"))?;
            let statement = &theorem["statement"];
            if theorem["kind"] != "theorem"
                || theorem["axioms"]
                    .as_array()
                    .is_none_or(|rows| !rows.is_empty())
                || statement["kind"] != "eq"
                || statement["left"]["function"]["module"] != "Production.SystemValidation"
                || statement["left"]["function"]["name"] != format!("validateModel{family}")
                || statement["left"]["arguments"][0]["function"]["name"] != model
                || statement["left"]["arguments"][1]["function"]["name"] != "corpusManifest"
                || statement["right"]["value"] != expected
            {
                return Err(format!(
                    "{theorem_name} does not prove its exact typed model predicate"
                )
                .into());
            }
        }
    }
    let aggregate = corpus_by_name
        .get("corpusManifestSound")
        .ok_or("missing aggregate typed model theorem")?;
    if aggregate["kind"] != "theorem"
        || aggregate["axioms"]
            .as_array()
            .is_none_or(|rows| !rows.is_empty())
        || aggregate["statement"]["left"]["function"]["module"] != "Production.SystemValidation"
        || aggregate["statement"]["left"]["function"]["name"] != "validateManifest"
        || aggregate["statement"]["left"]["arguments"][0]["function"]["name"] != "corpusValidModel"
        || aggregate["statement"]["left"]["arguments"][1]["function"]["name"] != "corpusManifest"
        || aggregate["statement"]["right"]["value"] != true
    {
        return Err("aggregate typed model theorem is not the exact direct predicate".into());
    }
    Ok(())
}

/// Audit that unsafe code is forbidden across workspace Rust crates.
pub fn audit_no_unsafe(root: &Path) -> Result<(), Fail> {
    for entry in walkdir::WalkDir::new(root.join("crates"))
        .into_iter()
        .flatten()
    {
        if !entry.file_type().is_file() {
            continue;
        }
        let path = entry.path();
        if path.extension().is_some_and(|ext| ext == "rs") {
            let text = std::fs::read_to_string(path)?;
            if text.contains("unsafe ") && !path.to_string_lossy().contains("tests") {
                return Err(
                    format!("unsafe audit failed: found unsafe in {}", path.display()).into(),
                );
            }
        }
    }
    Ok(())
}

/// Audit that only crates/prismpm is publishable and repo crates are private.
pub fn audit_shipped(root: &Path) -> Result<(), Fail> {
    let internal_crates = ["crates/model", "crates/conformance", "xtask"];
    for cr in internal_crates {
        let manifest_path = root.join(cr).join("Cargo.toml");
        let content = std::fs::read_to_string(&manifest_path)?;
        if !content.contains("publish = false") {
            return Err(format!(
                "{}: internal crate must have publish = false",
                manifest_path.display()
            )
            .into());
        }
    }
    let workspace = std::fs::read_to_string(root.join("Cargo.toml"))?;
    for forbidden in ["../LexLean", "../lean4-prod"] {
        if workspace.contains(forbidden) {
            return Err(format!("workspace contains adjacent dependency path {forbidden}").into());
        }
    }
    let container = std::fs::read_to_string(root.join(".devcontainer/devcontainer.json"))?;
    if container.contains("../LexLean") || container.contains("../lean4-prod") {
        return Err("devcontainer depends on a host-specific adjacent mount".into());
    }
    let value: serde_json::Value = serde_json::from_str(&container)?;
    if value
        .get("mounts")
        .and_then(serde_json::Value::as_array)
        .is_some_and(|mounts| {
            mounts.iter().any(|mount| {
                mount.as_str()
                    != Some("source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind")
            })
        })
    {
        return Err("devcontainer contains a host-specific non-Docker mount".into());
    }
    Ok(())
}

fn hash_file(path: &Path) -> Result<String, Fail> {
    Ok(format!("{:x}", sha2::Sha256::digest(std::fs::read(path)?)))
}

fn audit_tree_manifest(root: &Path, manifest: &Path, tree_root: &Path) -> Result<(), Fail> {
    let source = std::fs::read_to_string(root.join(manifest))?;
    if !source.ends_with('\n') || source.contains('\r') {
        return Err(format!("{} is not canonical text", manifest.display()).into());
    }
    let mut declared = std::collections::BTreeMap::new();
    for line in source.lines() {
        let (sha256, relative) = line
            .split_once("  ")
            .ok_or_else(|| format!("malformed tree-manifest row in {}", manifest.display()))?;
        if sha256.len() != 64 || !sha256.bytes().all(|byte| byte.is_ascii_hexdigit()) {
            return Err(format!("invalid tree-manifest checksum for {relative}").into());
        }
        let relative_path = Path::new(relative);
        if relative_path.is_absolute()
            || relative
                .split('/')
                .any(|component| component.is_empty() || matches!(component, "." | ".."))
            || declared
                .insert(relative.to_owned(), sha256.to_owned())
                .is_some()
        {
            return Err(format!("invalid tree-manifest path {relative}").into());
        }
    }
    let tree = root.join(tree_root);
    let metadata = std::fs::symlink_metadata(&tree)?;
    if !metadata.file_type().is_dir() || metadata.file_type().is_symlink() {
        return Err(format!(
            "vendored dependency root is not a directory: {}",
            tree.display()
        )
        .into());
    }
    let mut observed = std::collections::BTreeMap::new();
    for entry in walkdir::WalkDir::new(&tree)
        .min_depth(1)
        .into_iter()
        .filter_entry(|entry| !(entry.file_type().is_dir() && entry.file_name() == "target"))
    {
        let entry = entry?;
        if entry.file_type().is_symlink() {
            return Err(format!(
                "vendored dependency tree has symlink {}",
                entry.path().display()
            )
            .into());
        }
        if !entry.file_type().is_file() || entry.path() == root.join(manifest) {
            continue;
        }
        let relative = entry
            .path()
            .strip_prefix(&tree)?
            .to_string_lossy()
            .replace('\\', "/");
        observed.insert(relative, hash_file(entry.path())?);
    }
    if declared != observed {
        return Err(format!(
            "vendored dependency tree {} differs from {}",
            tree_root.display(),
            manifest.display()
        )
        .into());
    }
    Ok(())
}

/// Audit immutable dependency revisions, source modes, and vendored checksums.
pub fn audit_dependencies(root: &Path) -> Result<(), Fail> {
    let path = root.join("model/dependencies.toml");
    let source = std::fs::read_to_string(&path)?;
    for forbidden in ["pending", "placeholder", "branch", "../"] {
        if source.to_ascii_lowercase().contains(forbidden) {
            return Err(format!("dependency register contains forbidden token {forbidden}").into());
        }
    }
    let value: toml::Value = toml::from_str(&source)?;
    if value.get("spec").and_then(toml::Value::as_str) != Some("prismpm/dependencies/1") {
        return Err("dependency register has the wrong schema".into());
    }
    let rows = value
        .get("dependency")
        .and_then(toml::Value::as_array)
        .ok_or("dependency register has no rows")?;
    let ids = rows
        .iter()
        .filter_map(|row| row.get("id").and_then(toml::Value::as_str))
        .collect::<Vec<_>>();
    if ids != ["lean4-prod", "lexlean", "hologram-live", "uor-hologram"] {
        return Err("dependency rows are not the exact canonical set/order".into());
    }
    for row in rows {
        let id = row
            .get("id")
            .and_then(toml::Value::as_str)
            .ok_or("dependency row lacks id")?;
        let revision = row
            .get("revision")
            .and_then(toml::Value::as_str)
            .ok_or("dependency row lacks revision")?;
        if revision.len() != 40 || !revision.bytes().all(|byte| byte.is_ascii_hexdigit()) {
            return Err(format!("{id} revision is not a full commit").into());
        }
        let expected_source = if id == "uor-hologram" {
            "git"
        } else {
            "vendored"
        };
        if row.get("source").and_then(toml::Value::as_str) != Some(expected_source) {
            return Err(format!("{id} does not use canonical source {expected_source}").into());
        }
        let artifacts = row.get("artifact").and_then(toml::Value::as_array);
        if expected_source == "git" {
            if artifacts.is_some_and(|values| !values.is_empty()) {
                return Err(format!("Git-only dependency {id} declares local artifacts").into());
            }
            continue;
        }
        let artifacts = artifacts.ok_or_else(|| format!("{id} has no artifact checksums"))?;
        if artifacts.is_empty() {
            return Err(format!("{id} has no artifact checksums").into());
        }
        for artifact in artifacts {
            let kind = artifact
                .get("kind")
                .and_then(toml::Value::as_str)
                .ok_or("dependency artifact lacks kind")?;
            let relative = artifact
                .get("path")
                .and_then(toml::Value::as_str)
                .ok_or("dependency artifact lacks path")?;
            let expected = artifact
                .get("sha256")
                .and_then(toml::Value::as_str)
                .ok_or("dependency artifact lacks sha256")?;
            if Path::new(relative).is_absolute()
                || relative
                    .split('/')
                    .any(|component| component.is_empty() || component == ".." || component == ".")
                || !relative.starts_with("vendor/")
            {
                return Err(format!("invalid vendored artifact path {relative}").into());
            }
            if expected.len() != 64 || !expected.bytes().all(|byte| byte.is_ascii_hexdigit()) {
                return Err(format!("invalid checksum for {relative}").into());
            }
            let actual = hash_file(&root.join(relative))?;
            if actual != expected {
                return Err(format!("vendored artifact checksum drifted for {relative}").into());
            }
            match kind {
                "file" => {
                    if artifact.get("tree_root").is_some() {
                        return Err(format!("file artifact {relative} declares tree_root").into());
                    }
                }
                "tree-manifest" => {
                    let tree_root = artifact
                        .get("tree_root")
                        .and_then(toml::Value::as_str)
                        .ok_or("tree-manifest artifact lacks tree_root")?;
                    if Path::new(tree_root).is_absolute()
                        || !tree_root.starts_with("vendor/")
                        || tree_root.split('/').any(|component| {
                            component.is_empty() || matches!(component, "." | "..")
                        })
                    {
                        return Err(format!("invalid vendored tree root {tree_root}").into());
                    }
                    audit_tree_manifest(root, Path::new(relative), Path::new(tree_root))?;
                }
                _ => return Err(format!("unknown dependency artifact kind {kind}").into()),
            }
        }
    }
    Ok(())
}

/// Audit pinned tool installers and full-SHA CI actions.
pub fn audit_tools_ci(root: &Path) -> Result<(), Fail> {
    let tools = std::fs::read_to_string(root.join("tools.lock"))?;
    let lock: toml::Value = toml::from_str(&tools)?;
    let dockerfile = std::fs::read_to_string(root.join(".devcontainer/Dockerfile"))?;
    let hosts = lock
        .get("support")
        .and_then(|value| value.get("hosts"))
        .and_then(toml::Value::as_array)
        .ok_or("tools.lock has no supported-host array")?;
    let claimed_hosts = hosts
        .iter()
        .map(|host| host.as_str().ok_or("supported host is not a string"))
        .collect::<Result<Vec<_>, _>>()?;
    if claimed_hosts != repo_model::release::HOST_TARGETS
        || claimed_hosts != ["aarch64-unknown-linux-gnu", "x86_64-unknown-linux-gnu"]
    {
        return Err("supported host claims differ between tools.lock and release policy".into());
    }
    let sdk_dockerfile = std::fs::read_to_string(root.join("sdk/Dockerfile"))?;
    for (name, value) in lock
        .get("sdk-bases")
        .and_then(toml::Value::as_table)
        .ok_or("tools.lock has no sdk-bases table")?
    {
        let value = value
            .as_str()
            .ok_or_else(|| format!("sdk-bases.{name} is not a string"))?;
        let (source, source_name) = if name == "devcontainer" {
            (&dockerfile, ".devcontainer/Dockerfile")
        } else {
            (&sdk_dockerfile, "sdk/Dockerfile")
        };
        if !source.contains(value) {
            return Err(format!("sdk-bases.{name} is not bound by {source_name}").into());
        }
    }
    let adapters = lock
        .get("target-adapters")
        .and_then(toml::Value::as_table)
        .ok_or("tools.lock has no target-adapters table")?;
    for (name, relative) in [
        ("compose", "adapters/compose.json"),
        ("github_pages", "adapters/github-pages.json"),
        ("kubernetes", "adapters/kubernetes.json"),
        (
            "ingress_nginx_kind_manifest",
            "adapters/ingress-nginx-kind-v1.15.1.yaml",
        ),
    ] {
        let expected = adapters
            .get(name)
            .and_then(toml::Value::as_str)
            .ok_or_else(|| format!("target-adapters.{name} is absent"))?;
        let actual = format!(
            "sha256:{:x}",
            sha2::Sha256::digest(std::fs::read(root.join(relative))?)
        );
        if expected != actual {
            return Err(format!("target-adapters.{name} digest is stale").into());
        }
    }
    let kubernetes_adapter = std::fs::read_to_string(root.join("adapters/kubernetes.json"))?;
    for name in ["ingress_nginx_controller", "ingress_nginx_admission"] {
        let value = adapters
            .get(name)
            .and_then(toml::Value::as_str)
            .ok_or_else(|| format!("target-adapters.{name} is absent"))?;
        if !kubernetes_adapter.contains(value) {
            return Err(format!("target-adapters.{name} is not bound by kubernetes.json").into());
        }
    }
    for architecture in ["amd64", "arm64"] {
        let downloads = lock
            .get("sdk-downloads")
            .and_then(|value| value.get(architecture))
            .and_then(toml::Value::as_table)
            .ok_or_else(|| format!("tools.lock has no sdk-downloads.{architecture} table"))?;
        for (name, digest) in downloads {
            let digest = digest
                .as_str()
                .ok_or_else(|| format!("sdk-downloads.{architecture}.{name} is not a string"))?;
            if digest.len() != 64
                || !digest.bytes().all(|byte| byte.is_ascii_hexdigit())
                || !sdk_dockerfile.contains(digest)
            {
                return Err(format!(
                    "sdk-downloads.{architecture}.{name} is not checksum-bound by sdk/Dockerfile"
                )
                .into());
            }
        }
    }
    let sdk_sources = format!(
        "{}{}{}{}{}",
        sdk_dockerfile,
        std::fs::read_to_string(root.join("sdk/generate-inventory.mjs"))?,
        std::fs::read_to_string(root.join("sdk/devcontainer-cli/package-lock.json"))?,
        std::fs::read_to_string(root.join("sdk/oracles/package-lock.json"))?,
        std::fs::read_to_string(root.join("sdk/runtime/package-lock.json"))?
    );
    for table in ["sdk-tools", "runtime-libraries"] {
        for (name, version) in lock
            .get(table)
            .and_then(toml::Value::as_table)
            .ok_or_else(|| format!("tools.lock has no {table} table"))?
        {
            let version = version
                .as_str()
                .ok_or_else(|| format!("{table}.{name} is not a string"))?;
            if !sdk_sources.contains(version) {
                return Err(
                    format!("{table}.{name} is not version-bound by the SDK inputs").into(),
                );
            }
        }
    }
    for value in [
        "1.97.1",
        "leanprover/lean4:v4.32.1",
        "4.2.3",
        "1.57.0",
        "0.20.2",
    ] {
        if !tools.contains(value) || !dockerfile.contains(value) {
            return Err(
                format!("tool pin {value} is not shared by tools.lock and Dockerfile").into(),
            );
        }
    }
    for name in ["rustup", "elan", "just", "cargo-deny"] {
        let row = lock
            .get(name)
            .and_then(toml::Value::as_table)
            .ok_or_else(|| format!("tools.lock has no {name} installer row"))?;
        let platform = row
            .get("platform")
            .and_then(toml::Value::as_str)
            .ok_or_else(|| format!("{name} installer platform is absent"))?;
        let url = row
            .get("url")
            .and_then(toml::Value::as_str)
            .ok_or_else(|| format!("{name} installer URL is absent"))?;
        let sha256 = row
            .get("sha256")
            .and_then(toml::Value::as_str)
            .ok_or_else(|| format!("{name} installer checksum is absent"))?;
        if !platform.starts_with("x86_64-unknown-linux-")
            || !url.starts_with("https://")
            || sha256.len() != 64
            || !sha256.bytes().all(|byte| byte.is_ascii_hexdigit())
            || !dockerfile.contains(url)
            || !dockerfile.contains(sha256)
        {
            return Err(format!("{name} installer is not source/checksum pinned").into());
        }
    }
    let verification = lock
        .get("verification-executables")
        .and_then(toml::Value::as_table)
        .ok_or("tools.lock has no verification-executables row")?;
    let verification_source =
        std::fs::read_to_string(root.join("crates/prismpm/src/verification.rs"))?;
    for name in ["elan_proxy_sha256", "rustup_proxy_sha256", "timeout_sha256"] {
        let digest = verification
            .get(name)
            .and_then(toml::Value::as_str)
            .ok_or_else(|| format!("verification executable {name} has no checksum"))?;
        if digest.len() != 64
            || !digest.bytes().all(|byte| byte.is_ascii_hexdigit())
            || !verification_source.contains(digest)
        {
            return Err(format!("verification executable {name} is not preflight-pinned").into());
        }
    }
    if verification
        .get("timeout_package")
        .and_then(toml::Value::as_str)
        != Some("coreutils=9.1-1")
        || !dockerfile.contains("coreutils=9.1-1")
    {
        return Err("the timeout provider package is not version-pinned".into());
    }
    if !dockerfile.contains("FROM docker.io/library/debian:bookworm-slim@sha256:") {
        return Err("devcontainer base image is not digest-pinned".into());
    }
    for workflow in [
        ".github/workflows/honesty.yml",
        ".github/workflows/reproducibility.yml",
        ".github/workflows/vv.yml",
    ] {
        let source = std::fs::read_to_string(root.join(workflow))?;
        for line in source.lines().map(str::trim) {
            let Some(value) = line
                .strip_prefix("- uses: ")
                .or_else(|| line.strip_prefix("uses: "))
            else {
                continue;
            };
            let reference = value
                .split('#')
                .next()
                .and_then(|value| value.trim().rsplit_once('@').map(|pair| pair.1))
                .ok_or_else(|| format!("{workflow} has malformed action reference"))?;
            if reference.len() != 40 || !reference.bytes().all(|byte| byte.is_ascii_hexdigit()) {
                return Err(format!("{workflow} action is not pinned to a full commit").into());
            }
        }
    }
    Ok(())
}

/// Audit that every diagnostic code used in crates/ is registered in model/errors.toml.
pub fn audit_errors(root: &Path, model: &Model) -> Result<(), Fail> {
    let registered: BTreeSet<&str> = model.errors.error.iter().map(|e| e.code.as_str()).collect();
    for entry in walkdir::WalkDir::new(root.join("crates"))
        .into_iter()
        .flatten()
    {
        if !entry.file_type().is_file() {
            continue;
        }
        let path = entry.path();
        if path.extension().is_some_and(|ext| ext == "rs") {
            let text = std::fs::read_to_string(path)?;
            for word in text.split(|c: char| !c.is_alphanumeric()) {
                if word.starts_with("PP")
                    && word.len() == 6
                    && word.chars().skip(2).all(|c| c.is_ascii_digit())
                    && !registered.contains(word)
                {
                    return Err(format!(
                        "{}: references unregistered error code `{word}`",
                        path.display()
                    )
                    .into());
                }
            }
        }
    }
    Ok(())
}

/// Audit the exact Holo emitter input closure and its stored semantics digest.
pub fn audit_emitter_inputs(root: &Path, model: &Model) -> Result<(), Fail> {
    const EXPECTED: [&str; 8] = [
        "crates/prismpm/src/holo/canonical.rs",
        "crates/prismpm/src/holo/model_document.rs",
        "crates/prismpm/src/holo/mod.rs",
        "crates/prismpm/src/holo/projector.rs",
        "crates/prismpm/src/holo/validate.rs",
        "model/projection.toml",
        "model/standards.toml",
        "schemas/model-document.schema.json",
    ];
    if model.emitter_inputs.spec != "prismpm/emitter-inputs/1"
        || model.emitter_inputs.inputs != EXPECTED
    {
        return Err("emitter input list is not the exact canonical closure".into());
    }
    for relative in &model.emitter_inputs.inputs {
        let path = root.join(relative);
        if !path.is_file()
            || relative.starts_with(".prism")
            || relative.starts_with(".lexlean")
            || relative.contains("generated")
        {
            return Err(format!("invalid emitter input {relative}").into());
        }
    }
    let actual = prismpm::holo::projector::compute_emitter_semantics_id();
    if model.emitter_inputs.digest != actual {
        return Err(format!(
            "emitter digest is stale: registered {}, actual {actual}",
            model.emitter_inputs.digest
        )
        .into());
    }
    Ok(())
}

/// Audit that release-scope standards and facet entries form an exact map.
pub fn audit_standards_map(root: &Path, model: &Model) -> Result<(), Fail> {
    let mut mapped = BTreeSet::new();
    for row in &model.standards.standard {
        if row.release_scope
            && (row.coverage_state != "implemented" || row.facet_entries.is_empty())
        {
            return Err(format!("{} is not implemented by a facet entry", row.id).into());
        }
        for entry in &row.facet_entries {
            if !mapped.insert(entry.clone()) {
                return Err(format!("facet entry {entry} maps to multiple standards").into());
            }
            let path = root
                .join("language")
                .join(&row.facet_package)
                .join("entries")
                .join(format!("{entry}.toml"));
            if !path.is_file() {
                return Err(format!("{} references missing facet entry {entry}", row.id).into());
            }
            let source = std::fs::read_to_string(&path)?;
            if !source.contains(&format!("id = \"{entry}\"")) {
                return Err(format!("{} does not declare ID {entry}", path.display()).into());
            }
        }
    }
    for package in ["prism.arch", "prism.qual", "prism.sec"] {
        for entry in walkdir::WalkDir::new(root.join("language").join(package).join("entries"))
            .min_depth(1)
            .max_depth(1)
            .into_iter()
            .flatten()
            .filter(|entry| entry.file_type().is_file())
        {
            let source = std::fs::read_to_string(entry.path())?;
            let id = source
                .lines()
                .find_map(|line| {
                    line.strip_prefix("id = \"")
                        .and_then(|v| v.strip_suffix('"'))
                })
                .ok_or_else(|| format!("{} lacks an entry ID", entry.path().display()))?;
            if !mapped.contains(id) {
                return Err(format!("facet entry {id} has no standards row").into());
            }
        }
    }
    Ok(())
}
