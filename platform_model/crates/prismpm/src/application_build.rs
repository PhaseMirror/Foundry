//! Generic production pipeline for a closed Prism application value.

use crate::error::PrismError;
use crate::holo::archive::{compose_application, ApplicationArchiveInput, ArchiveProvenance};
use crate::holo::canonical::{content_id, encode_value};
use crate::holo::model_document::{ApplicationModel, ModelDocument};
use crate::verification::{executable, run_process};
use prod_codegen::{
    generate_cargo_package, generate_core_wasm_package, generate_view_v1, BrowserAdapterBinding,
    CargoDependency, CargoPackageSpec, CoreWasmSpec, EvaluatedViewV1, GeneratedPackage,
    ViewOperation,
};
use serde::Deserialize;
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use std::collections::{BTreeMap, BTreeSet};
use std::io::Cursor;
use std::path::{Component, Path, PathBuf};

const HOLOGRAM_LIVE_COMMIT: &str = "d8208266d8abdc2445b7bbc0cef412a566adfaf1";
const UOR_HOLOGRAM_COMMIT: &str = "2bda6a9a9476872dade705bd61ece4209607f6da";
const LEAN4_PROD_ARCHIVE: &[u8] = include_bytes!("../vendor/lean4-prod/lean.tar");
const DEPENDENCY_REGISTER: &str = include_str!("../model/dependencies.toml");
const STDLIB_RELEASE_SOURCE: &str = include_str!("../stdlib/release.json");
const STDLIB_CRATE: &[u8] = include_bytes!("../stdlib/generated/prism-stdlib-0.1.0.crate");
const REGISTRY_ARCHIVE: &[u8] = include_bytes!("../vendor/registry.tar");
const LICENSE_MIT: &str = include_str!("../LICENSE-MIT");
const LICENSE_APACHE: &str = include_str!("../LICENSE-APACHE");

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct StdlibRelease {
    schema: String,
    semantic_id: String,
    crate_path: String,
    crate_sha256: String,
}

#[derive(Debug, Deserialize)]
struct DependencyRegister {
    dependency: Vec<Dependency>,
}

#[derive(Debug, Deserialize)]
struct Dependency {
    id: String,
    revision: String,
    #[serde(default)]
    artifact: Vec<DependencyArtifact>,
}

#[derive(Debug, Deserialize)]
struct DependencyArtifact {
    path: String,
    sha256: String,
}

/// One application artifact prepared in memory before atomic publication.
pub(crate) type ApplicationArtifact = (String, Vec<u8>);

fn sha256(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}

fn canonical_relative(value: &str) -> Result<&str, PrismError> {
    if value.is_empty()
        || value.contains('\\')
        || Path::new(value)
            .components()
            .any(|component| !matches!(component, Component::Normal(_)))
    {
        return Err(PrismError::new(
            "PP4002",
            format!("generated artifact path is not canonical: {value}"),
        ));
    }
    Ok(value)
}

fn write(path: &Path, bytes: &[u8]) -> Result<(), PrismError> {
    let parent = path
        .parent()
        .ok_or_else(|| PrismError::new("PP4002", "generated artifact has no parent"))?;
    std::fs::create_dir_all(parent)
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", parent.display())))?;
    std::fs::write(path, bytes)
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", path.display())))
}

fn publish_package(root: &Path, package: &GeneratedPackage) -> Result<(), PrismError> {
    std::fs::create_dir(root)
        .map_err(|error| PrismError::new("PP4002", format!("{}: {error}", root.display())))?;
    for file in &package.files {
        canonical_relative(&file.path)?;
        write(&root.join(&file.path), &file.bytes)?;
    }
    Ok(())
}

fn dependency<'a>(
    register: &'a DependencyRegister,
    id: &str,
) -> Result<&'a Dependency, PrismError> {
    register
        .dependency
        .iter()
        .find(|dependency| dependency.id == id)
        .ok_or_else(|| PrismError::new("PP9001", format!("dependency {id} is not registered")))
}

fn artifact_sha(dependency: &Dependency, suffix: &str) -> Result<String, PrismError> {
    dependency
        .artifact
        .iter()
        .find(|artifact| artifact.path.ends_with(suffix))
        .map(|artifact| artifact.sha256.clone())
        .ok_or_else(|| {
            PrismError::new(
                "PP9001",
                format!("registered dependency artifact {suffix} is absent"),
            )
        })
}

fn parse_kernel(path: &Path) -> Result<prod_ir::Module, PrismError> {
    let text = std::fs::read_to_string(path)
        .map_err(|error| PrismError::new("PP5004", format!("{}: {error}", path.display())))?;
    let (remaining, module) = prod_ir::parser::parse_module(&text)
        .map_err(|error| PrismError::new("PP5004", format!("LCNF parse: {error:?}")))?;
    if !remaining.trim().is_empty() {
        return Err(PrismError::new("PP5004", "LCNF has trailing input"));
    }
    Ok(module)
}

fn view_value(
    model: &ModelDocument,
    application: &ApplicationModel,
    core_sha: &str,
) -> EvaluatedViewV1 {
    let view_json = serde_json::to_value(&application.view).expect("owned View serializes");
    let view_id = content_id(&encode_value(&view_json).expect("owned View canonicalizes"));
    EvaluatedViewV1 {
        title: application.view.title.clone(),
        heading: application.view.heading.clone(),
        left_label: application.view.left_label.clone(),
        right_label: application.view.right_label.clone(),
        operation_label: application.view.operation_label.clone(),
        submit_label: application.view.submit_label.clone(),
        input_error: application.view.input_error.clone(),
        division_by_zero_error: application.view.division_error.clone(),
        overflow_error: application.view.overflow_error.clone(),
        operations: application
            .view
            .operations
            .iter()
            .map(|operation| ViewOperation {
                label: operation.label.clone(),
                request_name: operation.request_name.clone(),
                rust_variant: operation.rust_variant.clone(),
                discriminant: operation.discriminant,
            })
            .collect(),
        initial_operation: application.view.initial_operation,
        model_id: content_id(
            &encode_value(&serde_json::to_value(model).expect("model serializes"))
                .expect("model canonicalizes"),
        ),
        view_model_id: view_id,
        generated_core_sha256: core_sha.to_owned(),
    }
}

fn source_manifest(
    model: &ModelDocument,
    lex_manifest: &[u8],
    kernel: &[u8],
    coverage: &[u8],
) -> Result<Vec<u8>, PrismError> {
    encode_value(&json!({
        "files": [
            {"kind":"lexlean-build-manifest","sha256":sha256(lex_manifest)},
            {"kind":"lean4-prod-coverage","sha256":sha256(coverage)},
            {"kind":"lean4-prod-kernel-ir","sha256":sha256(kernel)},
            {"kind":"model-document","sha256":content_id(&encode_value(&serde_json::to_value(model).map_err(|error| PrismError::new("PP9001", error.to_string()))?)?)}
        ],
        "semantic_id": model.provenance.semantic_id,
        "source_id": model.provenance.source_id,
        "version": 4
    }))
}

fn package_readme(application: &ApplicationModel) -> String {
    let entry = application
        .entry_root
        .rsplit('.')
        .next()
        .expect("validated application entry root");
    let example = application
        .acceptance_vectors
        .first()
        .map(|vector| {
            format!(
                "use {}::{};\n\nassert_eq!({}(vec!{:?}), vec!{:?});",
                application.cargo_name.replace('-', "_"),
                entry,
                entry,
                vector.request,
                vector.response
            )
        })
        .unwrap_or_else(|| {
            format!(
                "use {}::{};",
                application.cargo_name.replace('-', "_"),
                entry
            )
        });
    format!(
        "# {}\n\n{}\n\nThis package is generated from the authoritative Prism application model. Do not edit generated Rust.\n\n```rust\n{}\n```\n",
        application.name,
        application.cargo_description,
        example
    )
}

fn cargo_home(workspace: &Path, registry: &Path) -> Result<PathBuf, PrismError> {
    let home = workspace.join("cargo-home");
    std::fs::create_dir(&home)
        .map_err(|error| PrismError::new("PP4002", format!("Cargo home: {error}")))?;
    let config = format!(
        "[net]\noffline = true\n\n[source.crates-io]\nreplace-with = \"prismpm-local\"\n\n[source.prismpm-local]\nlocal-registry = {:?}\n",
        registry.to_string_lossy()
    );
    write(&home.join("config.toml"), config.as_bytes())?;
    Ok(home)
}

fn stdlib_registry(workspace: &Path, stdlib: &StdlibRelease) -> Result<PathBuf, PrismError> {
    let registry = workspace.join("registry");
    std::fs::create_dir(&registry)
        .map_err(|error| PrismError::new("PP4101", format!("local registry: {error}")))?;
    tar::Archive::new(Cursor::new(REGISTRY_ARCHIVE))
        .unpack(&registry)
        .map_err(|error| PrismError::new("PP4101", format!("local registry: {error}")))?;
    let index = registry.join("index/pr/is");
    std::fs::create_dir_all(&index)
        .map_err(|error| PrismError::new("PP4101", format!("local registry: {error}")))?;
    write(&registry.join("prism-stdlib-0.1.0.crate"), STDLIB_CRATE)?;
    let row = format!(
        "{{\"name\":\"prism-stdlib\",\"vers\":\"0.1.0\",\"deps\":[],\"cksum\":\"{}\",\"features\":{{\"default\":[\"std\"],\"std\":[]}},\"yanked\":false}}\n",
        stdlib.crate_sha256
    );
    write(&index.join("prism-stdlib"), row.as_bytes())?;
    Ok(registry)
}

fn add_application_to_registry(
    registry: &Path,
    application: &ApplicationModel,
    crate_bytes: &[u8],
    stdlib_sha256: &str,
) -> Result<(), PrismError> {
    write(
        &registry.join(format!(
            "{}-{}.crate",
            application.cargo_name, application.cargo_version
        )),
        crate_bytes,
    )?;
    let name = &application.cargo_name;
    let index_path = if name.len() == 1 {
        registry.join("index/1").join(name)
    } else if name.len() == 2 {
        registry.join("index/2").join(name)
    } else if name.len() == 3 {
        registry.join("index/3").join(&name[0..1]).join(name)
    } else {
        registry
            .join("index")
            .join(&name[0..2])
            .join(&name[2..4])
            .join(name)
    };
    let row = json!({
        "cksum": sha256(crate_bytes),
        "deps": [{
            "default_features": false,
            "features": [],
            "kind": "normal",
            "name": "prism-stdlib",
            "optional": false,
            "registry": Value::Null,
            "req": "=0.1.0",
            "target": Value::Null
        }],
        "features": {"default":["std"],"std":["prism-stdlib/std"]},
        "name": name,
        "vers": application.cargo_version,
        "yanked": false
    });
    let mut row =
        serde_json::to_vec(&row).map_err(|error| PrismError::new("PP9001", error.to_string()))?;
    row.push(b'\n');
    write(&index_path, &row)?;
    if stdlib_sha256.len() != 64 {
        return Err(PrismError::new(
            "PP4101",
            "stdlib registry checksum is invalid",
        ));
    }
    Ok(())
}

/// Materialize the embedded, checksum-pinned local registry plus one generated
/// application candidate and return an isolated offline Cargo home.
pub(crate) fn application_cargo_home(
    workspace: &Path,
    application: &ApplicationModel,
    crate_bytes: &[u8],
) -> Result<PathBuf, PrismError> {
    let stdlib: StdlibRelease = serde_json::from_str(STDLIB_RELEASE_SOURCE)
        .map_err(|error| PrismError::new("PP4101", format!("stdlib release: {error}")))?;
    if sha256(STDLIB_CRATE) != stdlib.crate_sha256 {
        return Err(PrismError::new(
            "PP4101",
            "embedded stdlib crate checksum disagrees with its release metadata",
        ));
    }
    let registry = stdlib_registry(workspace, &stdlib)?;
    add_application_to_registry(&registry, application, crate_bytes, &stdlib.crate_sha256)?;
    cargo_home(workspace, &registry)
}

fn run(
    name: &str,
    program: &Path,
    args: &[&str],
    cwd: &Path,
    env: &BTreeMap<String, String>,
    replacements: &[(&Path, &str)],
    failure: &'static str,
) -> Result<(), PrismError> {
    let args = args
        .iter()
        .map(|argument| (*argument).to_owned())
        .collect::<Vec<_>>();
    run_process(name, program, &args, cwd, env, replacements, failure).map(|_| ())
}

/// Produce every platform-independent target declared by an evaluated
/// application. The returned bytes are not visible until the controller's
/// normal atomic publication step succeeds.
pub(crate) fn generate(
    repository_root: &Path,
    model: &ModelDocument,
    model_bytes: &[u8],
    lex_root: &Path,
    lex_manifest_bytes: &[u8],
) -> Result<Vec<ApplicationArtifact>, PrismError> {
    let application = model.application.as_ref().ok_or_else(|| {
        PrismError::new(
            "PP9001",
            "application generation was requested for a non-application",
        )
    })?;
    let stdlib: StdlibRelease = serde_json::from_str(STDLIB_RELEASE_SOURCE)
        .map_err(|error| PrismError::new("PP4101", format!("stdlib release: {error}")))?;
    if stdlib.schema != "prismpm/stdlib-release/1"
        || stdlib.semantic_id.len() != 64
        || stdlib.crate_sha256.len() != 64
    {
        return Err(PrismError::new(
            "PP4101",
            "stdlib release metadata is invalid",
        ));
    }
    if stdlib.crate_path != "stdlib/generated/prism-stdlib-0.1.0.crate"
        || sha256(STDLIB_CRATE) != stdlib.crate_sha256
    {
        return Err(PrismError::new(
            "PP4101",
            "stdlib crate checksum disagrees with its release metadata",
        ));
    }

    let dependency_register: DependencyRegister = toml::from_str(DEPENDENCY_REGISTER)
        .map_err(|error| PrismError::new("PP9001", format!("dependencies: {error}")))?;
    let lexlean = dependency(&dependency_register, "lexlean")?;
    let lean4_prod = dependency(&dependency_register, "lean4-prod")?;

    let work = tempfile::Builder::new()
        .prefix("prismpm-application-")
        .tempdir()
        .map_err(|error| PrismError::new("PP4002", format!("application work: {error}")))?;
    let workspace = work.path();
    let lean_package = workspace.join("lean4-prod");
    std::fs::create_dir(&lean_package)
        .map_err(|error| PrismError::new("PP4002", format!("Lean package: {error}")))?;
    tar::Archive::new(Cursor::new(LEAN4_PROD_ARCHIVE))
        .unpack(&lean_package)
        .map_err(|error| PrismError::new("PP5008", format!("vendored lean4-prod: {error}")))?;

    let lex_manifest: Value = serde_json::from_slice(lex_manifest_bytes)
        .map_err(|error| PrismError::new("PP4004", format!("LexLean manifest: {error}")))?;
    let outputs = lex_manifest
        .get("outputs")
        .and_then(Value::as_array)
        .ok_or_else(|| PrismError::new("PP4004", "LexLean output list is absent"))?;
    let mut modules = BTreeSet::new();
    for row in outputs {
        if row.get("kind").and_then(Value::as_str) != Some("lean") {
            continue;
        }
        let path = row
            .get("path")
            .and_then(Value::as_str)
            .ok_or_else(|| PrismError::new("PP4004", "LexLean Lean path is absent"))?;
        canonical_relative(path)?;
        let relative = Path::new(path)
            .strip_prefix("modules")
            .map_err(|_| PrismError::new("PP4004", "LexLean Lean path is outside modules"))?;
        let bytes = std::fs::read(lex_root.join(path))
            .map_err(|error| PrismError::new("PP4002", format!("{path}: {error}")))?;
        if row.get("sha256").and_then(Value::as_str) != Some(sha256(&bytes).as_str()) {
            return Err(PrismError::new(
                "PP4001",
                format!("generated Lean changed: {path}"),
            ));
        }
        write(&workspace.join(relative), &bytes)?;
        modules.insert(
            relative
                .with_extension("")
                .to_string_lossy()
                .replace(['/', '\\'], "."),
        );
    }
    if modules.is_empty() {
        return Err(PrismError::new(
            "PP4004",
            "application has no generated Lean module",
        ));
    }
    let lakefile = format!(
        "name = \"prismpm_application\"\nversion = \"0.1.0\"\n\n[[lean_lib]]\nname = \"PrismGenerated\"\nroots = [{}]\n",
        modules
            .iter()
            .map(|module| serde_json::to_string(module).expect("module serializes"))
            .collect::<Vec<_>>()
            .join(", ")
    );
    write(&workspace.join("lakefile.toml"), lakefile.as_bytes())?;
    write(
        &workspace.join("lean-toolchain"),
        b"leanprover/lean4:v4.32.1\n",
    )?;

    let lake = executable("lake")?;
    let cargo = executable("cargo")?;
    let replacements = [
        (workspace, "$APPLICATION_WORK"),
        (repository_root, "$PROJECT"),
        (lean_package.as_path(), "$LEAN4_PROD"),
    ];
    let no_env = BTreeMap::new();
    run(
        "application-lean",
        &lake,
        &["build", "PrismGenerated"],
        workspace,
        &no_env,
        &replacements,
        "PP5001",
    )?;
    run(
        "application-exporter",
        &lake,
        &["build", "prod-export"],
        &lean_package,
        &no_env,
        &replacements,
        "PP5004",
    )?;
    let export = workspace.join("export");
    let mut export_args = vec![
        "exe".to_owned(),
        "prod-export".to_owned(),
        "--module".to_owned(),
        modules.iter().next().expect("one module").clone(),
    ];
    for root in &application.library_roots {
        export_args.push("--root".to_owned());
        export_args.push(root.clone());
    }
    export_args.extend([
        "--ir-module".to_owned(),
        application.name.clone(),
        "--out".to_owned(),
        export.to_string_lossy().into_owned(),
    ]);
    let mut export_env = BTreeMap::new();
    export_env.insert(
        "LEAN_PATH".to_owned(),
        workspace
            .join(".lake/build/lib/lean")
            .to_string_lossy()
            .into_owned(),
    );
    run_process(
        "application-export",
        &lake,
        &export_args,
        &lean_package,
        &export_env,
        &replacements,
        "PP5004",
    )?;
    let kernel_bytes = std::fs::read(export.join("kernel.ir"))
        .map_err(|error| PrismError::new("PP5004", format!("kernel.ir: {error}")))?;
    let roots_bytes = std::fs::read(export.join("roots.json"))
        .map_err(|error| PrismError::new("PP5004", format!("roots.json: {error}")))?;
    let coverage_bytes = std::fs::read(export.join("coverage.json"))
        .map_err(|error| PrismError::new("PP5004", format!("coverage.json: {error}")))?;
    let module = parse_kernel(&export.join("kernel.ir"))?;

    let package = generate_cargo_package(
        &module,
        &CargoPackageSpec {
            name: application.cargo_name.clone(),
            version: application.cargo_version.clone(),
            description: application.cargo_description.clone(),
            repository: application.cargo_repository.clone(),
            homepage: application.cargo_homepage.clone(),
            readme: package_readme(application),
            license_mit: LICENSE_MIT.to_owned(),
            license_apache: LICENSE_APACHE.to_owned(),
            input_sha256: sha256(&kernel_bytes),
            dependencies: vec![CargoDependency {
                name: "prism-stdlib".to_owned(),
                version: "0.1.0".to_owned(),
                checksum: stdlib.crate_sha256.clone(),
                default_features: false,
                features: Vec::new(),
            }],
        },
    )
    .map_err(|error| PrismError::new("PP4102", error.to_string()))?;
    let package_root = workspace.join("cargo-package");
    publish_package(&package_root, &package)?;
    let registry = stdlib_registry(workspace, &stdlib)?;
    let cargo_home = cargo_home(workspace, &registry)?;
    let mut cargo_env = BTreeMap::new();
    cargo_env.insert(
        "CARGO_HOME".to_owned(),
        cargo_home.to_string_lossy().into_owned(),
    );
    cargo_env.insert("CARGO_NET_OFFLINE".to_owned(), "true".to_owned());
    cargo_env.insert(
        "RUSTFLAGS".to_owned(),
        format!(
            "--remap-path-prefix={}=$APPLICATION_WORK",
            workspace.to_string_lossy()
        ),
    );
    run(
        "application-cargo-check",
        &cargo,
        &["check", "--locked", "--offline"],
        &package_root,
        &cargo_env,
        &replacements,
        "PP4102",
    )?;
    run(
        "application-cargo-check-no-std",
        &cargo,
        &["check", "--locked", "--offline", "--no-default-features"],
        &package_root,
        &cargo_env,
        &replacements,
        "PP4102",
    )?;
    run(
        "application-cargo-package",
        &cargo,
        &["package", "--locked", "--offline", "--allow-dirty"],
        &package_root,
        &cargo_env,
        &replacements,
        "PP4102",
    )?;
    let crate_file = package_root.join("target/package").join(format!(
        "{}-{}.crate",
        application.cargo_name, application.cargo_version
    ));
    let crate_bytes = std::fs::read(&crate_file)
        .map_err(|error| PrismError::new("PP4102", format!("generated crate: {error}")))?;

    let registry_source_root = cargo_home.join("registry/src");
    let mut registry_sources = std::fs::read_dir(&registry_source_root)
        .map_err(|error| PrismError::new("PP4101", format!("Cargo registry source: {error}")))?
        .map(|entry| {
            entry
                .map_err(|error| PrismError::new("PP4101", error.to_string()))
                .and_then(|entry| {
                    if entry
                        .file_type()
                        .map_err(|error| PrismError::new("PP4101", error.to_string()))?
                        .is_dir()
                    {
                        Ok(entry.path())
                    } else {
                        Err(PrismError::new(
                            "PP4101",
                            "Cargo registry source contains a non-directory",
                        ))
                    }
                })
        })
        .collect::<Result<Vec<_>, _>>()?;
    registry_sources.sort();
    if registry_sources.len() != 1 {
        return Err(PrismError::new(
            "PP4101",
            "Cargo registry source closure is not exact",
        ));
    }
    cargo_env.insert(
        "RUSTFLAGS".to_owned(),
        format!(
            "--remap-path-prefix={}=$APPLICATION_WORK --remap-path-prefix={}=$CARGO_REGISTRY_SRC",
            workspace.to_string_lossy(),
            registry_sources[0].to_string_lossy()
        ),
    );

    let entry = application
        .entry_root
        .rsplit('.')
        .next()
        .ok_or_else(|| PrismError::new("PP2001", "application entry root is malformed"))?;
    let core_package = generate_core_wasm_package(
        &module,
        &CoreWasmSpec {
            crate_name: format!("{}-core-wasm", application.cargo_name),
            entry: entry.to_owned(),
            export_name: "holo_run".to_owned(),
            input_allocation_cap: application.guest_allocation_maximum,
            output_allocation_cap: application.response_maximum,
            maximum_pages: 32,
            input_ir_sha256: sha256(&kernel_bytes),
        },
    )
    .map_err(|error| PrismError::new("PP5101", error.to_string()))?;
    let core_root = workspace.join("core-wasm");
    publish_package(&core_root, &core_package)?;
    run(
        "application-core-wasm",
        &cargo,
        &["build", "--locked", "--offline", "--release"],
        &core_root,
        &cargo_env,
        &replacements,
        "PP5101",
    )?;
    let wasm_stem = format!("{}_core_wasm", application.cargo_name.replace('-', "_"));
    let wasm_path = core_root
        .join("target/wasm32-unknown-unknown/release")
        .join(format!("{wasm_stem}.wasm"));
    let wasm = std::fs::read(&wasm_path)
        .map_err(|error| PrismError::new("PP5101", format!("Core-Wasm output: {error}")))?;

    let generated_core_sha = sha256(
        package
            .files
            .iter()
            .find(|file| file.path == "generation-manifest.json")
            .ok_or_else(|| PrismError::new("PP4102", "generated core manifest is absent"))?
            .bytes
            .as_slice(),
    );
    let evaluated_view = view_value(model, application, &generated_core_sha);
    let generated_view = generate_view_v1(
        &evaluated_view,
        &BrowserAdapterBinding {
            package_name: format!("{}-browser", application.cargo_name),
            package_version: application.cargo_version.clone(),
            core_crate_name: application.cargo_name.clone(),
            core_crate_version: application.cargo_version.clone(),
            core_operation_type: application.operation_type.clone(),
            core_error_type: application.error_type.clone(),
            core_function: application.function_name.clone(),
        },
    )
    .map_err(|error| PrismError::new("PP5203", error.to_string()))?;
    add_application_to_registry(&registry, application, &crate_bytes, &stdlib.crate_sha256)?;
    let browser_root = workspace.join("browser-adapter");
    publish_package(&browser_root, &generated_view.browser_adapter)?;
    run(
        "browser-adapter-lock",
        &cargo,
        &["generate-lockfile", "--offline"],
        &browser_root,
        &cargo_env,
        &replacements,
        "PP5203",
    )?;
    run(
        "browser-adapter-wasm",
        &cargo,
        &[
            "build",
            "--locked",
            "--offline",
            "--release",
            "--target",
            "wasm32-unknown-unknown",
        ],
        &browser_root,
        &cargo_env,
        &replacements,
        "PP5203",
    )?;
    let wasm_bindgen = executable("wasm-bindgen")?;
    let browser_stem = application.cargo_name.replace('-', "_");
    let adapter_wasm = browser_root
        .join("target/wasm32-unknown-unknown/release")
        .join(format!("{browser_stem}_browser.wasm"));
    let browser_binding = workspace.join("browser-binding");
    std::fs::create_dir(&browser_binding)
        .map_err(|error| PrismError::new("PP5203", format!("browser binding: {error}")))?;
    let adapter_wasm_argument = adapter_wasm.to_string_lossy().into_owned();
    let browser_binding_argument = browser_binding.to_string_lossy().into_owned();
    run(
        "browser-wasm-bindgen",
        &wasm_bindgen,
        &[
            "--target",
            "web",
            "--no-typescript",
            "--out-name",
            &browser_stem,
            "--out-dir",
            &browser_binding_argument,
            &adapter_wasm_argument,
        ],
        &browser_root,
        &no_env,
        &replacements,
        "PP5203",
    )?;
    let browser_js_name = format!("{browser_stem}.js");
    let browser_wasm_name = format!("{browser_stem}_bg.wasm");
    let browser_js = std::fs::read(browser_binding.join(&browser_js_name))
        .map_err(|error| PrismError::new("PP5203", format!("browser JavaScript: {error}")))?;
    let browser_wasm = std::fs::read(browser_binding.join(&browser_wasm_name))
        .map_err(|error| PrismError::new("PP5203", format!("browser Wasm: {error}")))?;
    let browser_lock = std::fs::read(browser_root.join("Cargo.lock"))
        .map_err(|error| PrismError::new("PP5203", format!("browser lock: {error}")))?;
    let browser_provenance = encode_value(&json!({
        "adapter_lock_sha256": sha256(&browser_lock),
        "adapter_wasm_sha256": sha256(&browser_wasm),
        "binding_javascript_sha256": sha256(&browser_js),
        "generated_core_sha256": generated_core_sha,
        "model_id": evaluated_view.model_id,
        "schema": "prismpm/browser-provenance/1",
        "view_manifest_sha256": sha256(&generated_view.view_manifest.bytes),
        "view_model_id": evaluated_view.view_model_id
    }))?;
    let browser_projection_sha = sha256(&browser_provenance);
    let view_model_id = evaluated_view.view_model_id.clone();
    let source_manifest =
        source_manifest(model, lex_manifest_bytes, &kernel_bytes, &coverage_bytes)?;
    let target_profile = encode_value(&json!({
        "contract": application.core_contract,
        "export": "holo_run",
        "input_allocation_cap": application.guest_allocation_maximum,
        "maximum_pages": 32,
        "response_maximum": application.response_maximum,
        "schema": "lean4-prod/core-wasm-target/1"
    }))?;
    let lcnf_manifest = encode_value(&json!({
        "coverage_sha256": sha256(&coverage_bytes),
        "kernel_ir_sha256": sha256(&kernel_bytes),
        "roots_sha256": sha256(&roots_bytes),
        "schema": "prismpm/lcnf-manifest/1"
    }))?;
    let holo = compose_application(&ApplicationArchiveInput {
        application_name: application.name.clone(),
        guest_wasm: wasm.clone(),
        view_bundle: generated_view.hologram_bundle.bytes.clone(),
        model_document: model_bytes.to_vec(),
        source_manifest: source_manifest.clone(),
        provenance: ArchiveProvenance {
            source_id: model.provenance.source_id.clone(),
            semantic_id: model.provenance.semantic_id.clone(),
            compiler_semantics_id: model.provenance.compiler_semantics_id.clone(),
            snapshot_id: model.provenance.snapshot_id.clone(),
            stdlib_semantics_id: stdlib.semantic_id,
            prism_stdlib_crate_sha256: stdlib.crate_sha256,
            lexlean_commit: lexlean.revision.clone(),
            lexlean_package_sha256: artifact_sha(lexlean, ".crate")?,
            lean4_prod_commit: lean4_prod.revision.clone(),
            hologram_live_commit: HOLOGRAM_LIVE_COMMIT.to_owned(),
            uor_hologram_commit: UOR_HOLOGRAM_COMMIT.to_owned(),
            target_profile_id: sha256(&target_profile),
            lean_manifest_sha256: sha256(lex_manifest_bytes),
            lcnf_manifest_sha256: sha256(&lcnf_manifest),
            generated_core_sha256: generated_core_sha,
            cargo_name: application.cargo_name.clone(),
            cargo_version: application.cargo_version.clone(),
            cargo_crate_sha256: sha256(&crate_bytes),
            view_model_id,
            browser_projection_sha256: browser_projection_sha,
        },
    })?;

    let mut artifacts = vec![
        (format!("{}.holo", application.name), holo.bytes),
        (
            "application/application-manifest.bin".to_owned(),
            holo.application_manifest,
        ),
        (
            "application/capability-request.bin".to_owned(),
            holo.capability_request,
        ),
        ("application/directory.json".to_owned(), holo.directory),
        (
            "application/holo-identities.json".to_owned(),
            encode_value(
                &serde_json::to_value(holo.identities)
                    .map_err(|error| PrismError::new("PP9001", error.to_string()))?,
            )?,
        ),
        ("application/lcnf-manifest.json".to_owned(), lcnf_manifest),
        (
            "application/model-provenance.json".to_owned(),
            holo.prism_extension,
        ),
        (
            "application/source-manifest.json".to_owned(),
            source_manifest,
        ),
        ("application/target-profile.json".to_owned(), target_profile),
        ("cargo/kernel.ir".to_owned(), kernel_bytes),
        ("cargo/roots.json".to_owned(), roots_bytes),
        ("cargo/coverage.json".to_owned(), coverage_bytes),
        (
            format!(
                "cargo/{}-{}.crate",
                application.cargo_name, application.cargo_version
            ),
            crate_bytes,
        ),
        (format!("core-wasm/{wasm_stem}.wasm"), wasm),
    ];
    artifacts.extend(
        package
            .files
            .into_iter()
            .map(|file| (format!("cargo/package/{}", file.path), file.bytes)),
    );
    artifacts.push(("view/browser-adapter/Cargo.lock".to_owned(), browser_lock));
    artifacts.push((format!("view/browser/{browser_js_name}"), browser_js));
    artifacts.push((format!("view/browser/{browser_wasm_name}"), browser_wasm));
    artifacts.push((
        "view/browser/provenance.json".to_owned(),
        browser_provenance,
    ));
    artifacts.extend(
        core_package
            .files
            .into_iter()
            .map(|file| (format!("core-wasm/package/{}", file.path), file.bytes)),
    );
    artifacts.extend(
        generated_view
            .hologram_assets
            .into_iter()
            .map(|file| (format!("view/hologram/{}", file.path), file.bytes)),
    );
    artifacts.push((
        "view/hologram/view.holoview".to_owned(),
        generated_view.hologram_bundle.bytes,
    ));
    artifacts.extend(
        generated_view
            .browser_assets
            .into_iter()
            .map(|file| (format!("view/browser/{}", file.path), file.bytes)),
    );
    artifacts.extend(
        generated_view
            .browser_adapter
            .files
            .into_iter()
            .map(|file| (format!("view/browser-adapter/{}", file.path), file.bytes)),
    );
    artifacts.push((
        "view/view-manifest.json".to_owned(),
        generated_view.view_manifest.bytes,
    ));
    artifacts.sort_by(|left, right| left.0.as_bytes().cmp(right.0.as_bytes()));
    if artifacts.windows(2).any(|pair| pair[0].0 == pair[1].0) {
        return Err(PrismError::new(
            "PP9001",
            "application generator produced duplicate paths",
        ));
    }
    Ok(artifacts)
}
