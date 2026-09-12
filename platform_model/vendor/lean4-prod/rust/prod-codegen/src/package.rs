//! Deterministic Cargo-library package projection for one exported IR module.

use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;
use sha2::{Digest, Sha256};

use prod_ir::Module;

use crate::{generate_module, Error};

/// One exact crates.io dependency selected by the authoritative model.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CargoDependency {
    pub name: String,
    pub version: String,
    /// SHA-256 checksum of the exact registry `.crate` archive.
    pub checksum: String,
    pub default_features: bool,
    pub features: Vec<String>,
}

/// Metadata and license inputs owned by the calling application model.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CargoPackageSpec {
    pub name: String,
    pub version: String,
    pub description: String,
    pub repository: String,
    pub homepage: String,
    pub readme: String,
    pub license_mit: String,
    pub license_apache: String,
    /// SHA-256 of the exact exported LCNF IR bytes.
    pub input_sha256: String,
    /// Exact registry dependencies in bytewise package-name order.
    pub dependencies: Vec<CargoDependency>,
}

/// One package-relative regular file. Paths are bytewise sorted.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PackageFile {
    pub path: String,
    pub bytes: Vec<u8>,
}

/// Complete deterministic package tree.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GeneratedPackage {
    pub files: Vec<PackageFile>,
}

fn sha256(bytes: &[u8]) -> String {
    let digest = Sha256::digest(bytes);
    let mut out = String::with_capacity(64);
    for byte in digest {
        out.push_str(&format!("{byte:02x}"));
    }
    out
}

fn json_string(value: &str) -> String {
    let mut out = String::from("\"");
    for character in value.chars() {
        match character {
            '\"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if c < ' ' => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('\"');
    out
}

fn valid_package_name(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= 64
        && value.bytes().all(|byte| {
            byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'-' || byte == b'_'
        })
        && value.as_bytes()[0].is_ascii_lowercase()
}

fn valid_version(value: &str) -> bool {
    let parts: Vec<&str> = value.split('.').collect();
    parts.len() == 3
        && parts.iter().all(|part| {
            !part.is_empty()
                && part.bytes().all(|byte| byte.is_ascii_digit())
                && (part == &"0" || !part.starts_with('0'))
        })
}

fn validate(spec: &CargoPackageSpec) -> Result<(), Error> {
    if !valid_package_name(&spec.name) {
        return Err(Error::OpaqueType(
            "invalid generated Cargo package name".to_string(),
        ));
    }
    if !valid_version(&spec.version) {
        return Err(Error::OpaqueType(
            "invalid generated Cargo package version".to_string(),
        ));
    }
    if !spec.repository.starts_with("https://") || !spec.homepage.starts_with("https://") {
        return Err(Error::OpaqueType(
            "generated package URLs must use https".to_string(),
        ));
    }
    if spec.input_sha256.len() != 64
        || !spec
            .input_sha256
            .bytes()
            .all(|byte| byte.is_ascii_hexdigit() && !byte.is_ascii_uppercase())
    {
        return Err(Error::OpaqueType(
            "invalid lowercase input SHA-256".to_string(),
        ));
    }
    let mut previous: Option<&str> = None;
    for dependency in &spec.dependencies {
        if !valid_package_name(&dependency.name)
            || !valid_version(&dependency.version)
            || dependency.checksum.len() != 64
            || !dependency
                .checksum
                .bytes()
                .all(|byte| byte.is_ascii_hexdigit() && !byte.is_ascii_uppercase())
            || previous.is_some_and(|name| name >= dependency.name.as_str())
            || dependency
                .features
                .windows(2)
                .any(|pair| pair[0] >= pair[1])
            || dependency
                .features
                .iter()
                .any(|feature| !valid_package_name(feature))
        {
            return Err(Error::OpaqueType(
                "invalid or noncanonical generated Cargo dependency".to_string(),
            ));
        }
        previous = Some(&dependency.name);
    }
    Ok(())
}

fn file(path: &str, text: String) -> PackageFile {
    PackageFile {
        path: path.to_string(),
        bytes: text.into_bytes(),
    }
}

/// Generate a complete Cargo package without consulting the filesystem,
/// clock, environment, or network.
pub fn generate_cargo_package(
    module: &Module,
    spec: &CargoPackageSpec,
) -> Result<GeneratedPackage, Error> {
    validate(spec)?;
    let generated = generate_module(module)?;
    let forwarded_std = spec
        .dependencies
        .iter()
        .map(|dependency| format!("\"{}/std\"", dependency.name))
        .collect::<Vec<_>>()
        .join(", ");
    let mut dependencies = String::new();
    for dependency in &spec.dependencies {
        let features = dependency
            .features
            .iter()
            .map(|feature| json_string(feature))
            .collect::<Vec<_>>()
            .join(", ");
        dependencies.push_str(&format!(
            "{} = {{ version = \"={}\", default-features = {}, features = [{}] }}\n",
            dependency.name, dependency.version, dependency.default_features, features
        ));
    }
    let manifest = format!(
        "[package]\nname = {}\nversion = {}\nedition = \"2021\"\nrust-version = \"1.85\"\ndescription = {}\nlicense = \"MIT OR Apache-2.0\"\nrepository = {}\nhomepage = {}\nreadme = \"README.md\"\ninclude = [\"src/**\", \"Cargo.toml\", \"Cargo.lock\", \"README.md\", \"LICENSE-MIT\", \"LICENSE-APACHE\", \"generation-manifest.json\"]\n\n[features]\ndefault = [\"std\"]\nstd = [{}]\n\n[dependencies]\n{}\n[lib]\npath = \"src/lib.rs\"\n",
        json_string(&spec.name),
        json_string(&spec.version),
        json_string(&spec.description),
        json_string(&spec.repository),
        json_string(&spec.homepage),
        forwarded_std,
        dependencies,
    );
    let dependency_names = spec
        .dependencies
        .iter()
        .map(|dependency| format!(" \"{}\",\n", dependency.name))
        .collect::<String>();
    let root_dependencies = if dependency_names.is_empty() {
        String::new()
    } else {
        format!("dependencies = [\n{dependency_names}]\n")
    };
    let dependency_packages = spec
        .dependencies
        .iter()
        .map(|dependency| {
            format!(
                "\n[[package]]\nname = {}\nversion = {}\nsource = \"registry+https://github.com/rust-lang/crates.io-index\"\nchecksum = {}\n",
                json_string(&dependency.name),
                json_string(&dependency.version),
                json_string(&dependency.checksum),
            )
        })
        .collect::<String>();
    let lock = format!(
        "# This file is automatically @generated by Cargo.\n# It is not intended for manual editing.\nversion = 4\n\n[[package]]\nname = {}\nversion = {}\n{}{}",
        json_string(&spec.name),
        json_string(&spec.version),
        root_dependencies,
        dependency_packages,
    );
    let source = format!(
        "#![cfg_attr(not(feature = \"std\"), no_std)]\n#![allow(dead_code, non_snake_case, unused_parens, unused_variables)]\nextern crate alloc;\n\n#[derive(Debug, Clone, Copy, PartialEq, Eq)]\npub enum ComputeError {{\n    AddOverflow,\n    MulOverflow,\n    ShiftExponentTooLarge,\n    ShiftOverflow,\n    PowExponentTooLarge,\n    PowOverflow,\n    OutputTooSmall,\n}}\n\n{generated}"
    );

    let mut files = vec![
        file("Cargo.lock", lock),
        file("Cargo.toml", manifest),
        file("LICENSE-APACHE", spec.license_apache.clone()),
        file("LICENSE-MIT", spec.license_mit.clone()),
        file("README.md", spec.readme.clone()),
        file("src/lib.rs", source),
    ];
    files.sort_by(|left, right| left.path.as_bytes().cmp(right.path.as_bytes()));

    let mut records = String::new();
    for item in &files {
        records.push_str(&format!(
            "{{\"path\":{},\"sha256\":{}}},",
            json_string(&item.path),
            json_string(&sha256(&item.bytes))
        ));
    }
    records.pop();
    let dependency_records = spec
        .dependencies
        .iter()
        .map(|dependency| {
            let features = dependency
                .features
                .iter()
                .map(|feature| json_string(feature))
                .collect::<Vec<_>>()
                .join(",");
            format!(
                "{{\"checksum\":{},\"default_features\":{},\"features\":[{}],\"name\":{},\"version\":{}}}",
                json_string(&dependency.checksum),
                dependency.default_features,
                features,
                json_string(&dependency.name),
                json_string(&dependency.version),
            )
        })
        .collect::<Vec<_>>()
        .join(",");
    let generation = format!(
        "{{\"dependencies\":[{dependency_records}],\"files\":[{records}],\"input_ir_sha256\":{},\"module\":{},\"schema\":\"lean4-prod/cargo-package-manifest/1\"}}\n",
        json_string(&spec.input_sha256),
        json_string(&module.name),
    );
    files.push(file("generation-manifest.json", generation));
    files.sort_by(|left, right| left.path.as_bytes().cmp(right.path.as_bytes()));
    Ok(GeneratedPackage { files })
}
