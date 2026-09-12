//! Strict Prism project configuration and confined path resolution.

use crate::error::PrismError;
use serde::{Deserialize, Serialize};
use std::path::{Component, Path, PathBuf};

/// Positive resource limits for projection and diagnostics.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ProjectLimits {
    /// Maximum canonical Holo byte length.
    pub max_holo_bytes: u64,
    /// Maximum total Holo entities and catalog rows.
    pub max_entities: u64,
    /// Maximum returned diagnostics.
    pub max_diagnostics: u64,
}

/// Closed prismpm/project/1 configuration.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ProjectConfig {
    /// Schema discriminator.
    pub spec: String,
    /// Human-facing project name.
    pub project: String,
    /// Confined path to the LexLean project file.
    pub lexlean_project: String,
    /// Confined relative output root.
    pub build_root: String,
    /// Positive resource limits.
    pub limits: ProjectLimits,
}

fn relative(path: &str, field: &str) -> Result<PathBuf, PrismError> {
    let value = Path::new(path);
    let valid_component = |component: &str| {
        let body = component.strip_prefix('.').unwrap_or(component);
        !body.is_empty()
            && body
                .bytes()
                .next()
                .is_some_and(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'_' | b'-'))
            && body
                .bytes()
                .all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'.' | b'_' | b'-'))
    };
    if value.as_os_str().is_empty()
        || path.contains('\\')
        || path.split('/').any(str::is_empty)
        || !path.split('/').all(valid_component)
        || value.components().any(|component| {
            matches!(
                component,
                Component::CurDir
                    | Component::ParentDir
                    | Component::RootDir
                    | Component::Prefix(_)
            )
        })
    {
        return Err(PrismError::new(
            "PP8001",
            format!("{field} is not a confined relative path"),
        ));
    }
    Ok(value.to_path_buf())
}

fn existing_file(root: &Path, relative: &Path) -> Result<PathBuf, PrismError> {
    let joined = root.join(relative);
    let canonical = joined
        .canonicalize()
        .map_err(|error| PrismError::new("PP1002", format!("{}: {error}", joined.display())))?;
    if !canonical.starts_with(root) || !canonical.is_file() {
        return Err(PrismError::new(
            "PP8001",
            "configured file escapes the project",
        ));
    }
    let mut cursor = root.to_path_buf();
    for component in relative.components() {
        cursor.push(component.as_os_str());
        if std::fs::symlink_metadata(&cursor)
            .map(|metadata| metadata.file_type().is_symlink())
            .unwrap_or(false)
        {
            return Err(PrismError::new(
                "PP8001",
                "configured path contains a symlink",
            ));
        }
    }
    Ok(canonical)
}

impl ProjectConfig {
    pub(crate) fn load(
        root: &Path,
        selected: Option<&Path>,
    ) -> Result<(Self, PathBuf), PrismError> {
        let selected = selected.unwrap_or_else(|| Path::new("prismpm.toml"));
        let relative = relative(
            selected
                .to_str()
                .ok_or_else(|| PrismError::new("PP1001", "configuration path is not UTF-8"))?,
            "configuration path",
        )?;
        let path = existing_file(root, &relative)?;
        let bytes = std::fs::read(&path)
            .map_err(|error| PrismError::new("PP1002", format!("{}: {error}", path.display())))?;
        let text = std::str::from_utf8(&bytes)
            .map_err(|_| PrismError::new("PP1001", "configuration is not UTF-8"))?;
        let config: Self = toml::from_str(text)
            .map_err(|error| PrismError::new("PP1001", format!("configuration: {error}")))?;
        config.validate()?;
        Ok((config, path))
    }

    fn validate(&self) -> Result<(), PrismError> {
        if self.spec != "prismpm/project/1" || self.project.is_empty() {
            return Err(PrismError::new(
                "PP1002",
                "project schema or name is invalid",
            ));
        }
        let _ = relative(&self.lexlean_project, "lexlean_project")?;
        let build_root = relative(&self.build_root, "build_root")?;
        if build_root.components().count() != 1 {
            return Err(PrismError::new(
                "PP8001",
                "build_root must be one project-root directory name",
            ));
        }
        if self.limits.max_holo_bytes == 0
            || self.limits.max_entities == 0
            || self.limits.max_diagnostics == 0
            || self.limits.max_holo_bytes > 1_073_741_824
            || self.limits.max_entities > 10_000_000
            || self.limits.max_diagnostics > 10_000
        {
            return Err(PrismError::new(
                "PP1003",
                "project limits are outside fixed bounds",
            ));
        }
        Ok(())
    }

    pub(crate) fn lexlean_path(&self, root: &Path) -> Result<PathBuf, PrismError> {
        existing_file(root, &relative(&self.lexlean_project, "lexlean_project")?)
    }

    pub(crate) fn output_root(&self, root: &Path) -> Result<PathBuf, PrismError> {
        let relative = relative(&self.build_root, "build_root")?;
        let mut cursor = root.to_path_buf();
        for component in relative.components() {
            cursor.push(component.as_os_str());
            match std::fs::symlink_metadata(&cursor) {
                Ok(metadata) if metadata.file_type().is_symlink() => {
                    return Err(PrismError::new(
                        "PP8001",
                        "configured output path contains a symlink",
                    ));
                }
                Ok(metadata) if !metadata.is_dir() => {
                    return Err(PrismError::new(
                        "PP8001",
                        "configured output path contains a non-directory",
                    ));
                }
                Ok(_) => {}
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => break,
                Err(error) => {
                    return Err(PrismError::new(
                        "PP8001",
                        format!("inspect configured output path: {error}"),
                    ));
                }
            }
        }
        Ok(root.join(relative))
    }
}
