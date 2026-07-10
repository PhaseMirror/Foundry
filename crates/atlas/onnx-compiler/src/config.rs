//! Configuration file support for hologram-onnx-compiler
//!
//! Supports loading compiler settings from TOML configuration files.
//!
//! # Config File Locations
//!
//! The compiler searches for config files in the following order:
//! 1. Path specified via `--config` CLI argument
//! 2. `./hologram-onnx-compiler.toml` (current directory)
//! 3. `~/.config/hologram/onnx-compiler.toml` (user config)
//!
//! # Example Config File
//!
//! ```toml
//! # hologram-onnx-compiler.toml
//!
//! # Memory budget in MB (default: 8192)
//! memory_budget = 16384
//!
//! # Accuracy target 0.0-1.0 (default: 0.95)
//! accuracy = 0.99
//!
//! # Enable parallel processing (default: true)
//! parallel = true
//!
//! # Enable verbose output (default: false)
//! verbose = true
//!
//! # Export debug artifacts to this directory
//! debug_export = "/tmp/debug"
//!
//! # Enable checkpointing for resumable compilation
//! checkpoint_dir = "/tmp/checkpoints"
//!
//! # Save checkpoint every N operations (default: 10)
//! checkpoint_interval = 5
//! ```

use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

/// Root configuration that can contain sections for different tools
///
/// Supports two formats:
///
/// 1. **Sectioned format** (recommended for shared config):
/// ```toml
/// [onnx-compiler]
/// memory_budget = 16384
/// accuracy = 0.99
/// parallel = true
/// verbose = true
/// ```
///
/// 2. **Direct format** (backward compatible):
/// ```toml
/// memory_budget = 16384
/// accuracy = 0.99
/// parallel = true
/// verbose = true
/// ```
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct RootConfig {
    /// ONNX compiler settings (under [onnx-compiler] section)
    #[serde(rename = "onnx-compiler", skip_serializing_if = "Option::is_none")]
    pub onnx_compiler: Option<CompilerConfig>,

    /// Direct settings (for backward compatibility, flattened at root level)
    #[serde(flatten, skip_serializing_if = "Option::is_none")]
    pub direct: Option<CompilerConfig>,
}

/// Compiler configuration loaded from TOML file
///
/// All fields are optional. CLI arguments override config file values.
///
/// Supports both sectioned and direct formats (see `RootConfig` for examples).
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct CompilerConfig {
    /// Input ONNX model path
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input: Option<PathBuf>,

    /// Memory budget in MB (default: 8192)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub memory_budget: Option<usize>,

    /// Accuracy target 0.0-1.0 (default: 0.95)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub accuracy: Option<f64>,

    /// Enable parallel processing (default: true)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parallel: Option<bool>,

    /// Enable verbose output (default: false)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub verbose: Option<bool>,

    /// Export debug artifacts to directory
    #[serde(skip_serializing_if = "Option::is_none")]
    pub debug_export: Option<PathBuf>,

    /// Checkpoint directory for resumable compilation
    #[serde(skip_serializing_if = "Option::is_none")]
    pub checkpoint_dir: Option<PathBuf>,

    /// Checkpoint interval (save every N operations)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub checkpoint_interval: Option<usize>,
}

impl CompilerConfig {
    /// Load config from TOML file
    ///
    /// Supports both sectioned and direct formats:
    ///
    /// Sectioned format (recommended):
    /// ```toml
    /// [onnx-compiler]
    /// memory_budget = 16384
    /// ```
    ///
    /// Direct format (backward compatible):
    /// ```toml
    /// memory_budget = 16384
    /// ```
    ///
    /// # Arguments
    ///
    /// * `path` - Path to TOML config file
    ///
    /// # Returns
    ///
    /// Loaded configuration, or error if file cannot be read/parsed
    ///
    /// # Example
    ///
    /// ```no_run
    /// use hologram_onnx_compiler::config::CompilerConfig;
    ///
    /// let config = CompilerConfig::load("hologram-onnx-compiler.toml")?;
    /// # Ok::<(), Box<dyn std::error::Error>>(())
    /// ```
    pub fn load<P: AsRef<Path>>(path: P) -> Result<Self, ConfigError> {
        let contents =
            std::fs::read_to_string(path.as_ref()).map_err(|e| ConfigError::IoError(path.as_ref().to_path_buf(), e))?;

        // Parse as RootConfig to support both formats
        let root: RootConfig =
            toml::from_str(&contents).map_err(|e| ConfigError::ParseError(path.as_ref().to_path_buf(), e))?;

        // Prefer sectioned format, fall back to direct format
        Ok(root.onnx_compiler.or(root.direct).unwrap_or_default())
    }

    /// Find and load config file from standard locations
    ///
    /// Searches in order:
    /// 1. Current directory: `./config.toml` (generic name)
    /// 2. Current directory: `./.hologram-onnx-compiler.toml` (dotfile)
    /// 3. Current directory: `./hologram-onnx-compiler.toml`
    /// 4. User config: `~/.config/hologram/onnx-compiler.toml`
    ///
    /// Returns `None` if no config file found.
    ///
    /// # Example
    ///
    /// ```
    /// use hologram_onnx_compiler::config::CompilerConfig;
    ///
    /// if let Some(config) = CompilerConfig::find_and_load()? {
    ///     println!("Loaded config from standard location");
    /// }
    /// # Ok::<(), Box<dyn std::error::Error>>(())
    /// ```
    pub fn find_and_load() -> Result<Option<Self>, ConfigError> {
        // Try current directory (generic name first - most convenient)
        let generic_config = PathBuf::from("./config.toml");
        if generic_config.exists() {
            return Ok(Some(Self::load(&generic_config)?));
        }

        // Try current directory (dotfile variant)
        let dotfile_config = PathBuf::from("./.hologram-onnx-compiler.toml");
        if dotfile_config.exists() {
            return Ok(Some(Self::load(&dotfile_config)?));
        }

        // Try current directory (tool-specific name)
        let current_dir_config = PathBuf::from("./hologram-onnx-compiler.toml");
        if current_dir_config.exists() {
            return Ok(Some(Self::load(&current_dir_config)?));
        }

        // Try user config directory
        if let Some(home) = dirs::home_dir() {
            let user_config = home.join(".config/hologram/onnx-compiler.toml");
            if user_config.exists() {
                return Ok(Some(Self::load(&user_config)?));
            }
        }

        Ok(None)
    }

    /// Save config to TOML file
    ///
    /// # Arguments
    ///
    /// * `path` - Path to save TOML config file
    ///
    /// # Example
    ///
    /// ```
    /// use hologram_onnx_compiler::config::CompilerConfig;
    ///
    /// let config = CompilerConfig {
    ///     memory_budget: Some(16384),
    ///     accuracy: Some(0.99),
    ///     parallel: Some(true),
    ///     ..Default::default()
    /// };
    ///
    /// config.save("my-config.toml")?;
    /// # Ok::<(), Box<dyn std::error::Error>>(())
    /// ```
    pub fn save<P: AsRef<Path>>(&self, path: P) -> Result<(), ConfigError> {
        let contents = toml::to_string_pretty(self).map_err(ConfigError::SerializeError)?;

        std::fs::write(path.as_ref(), contents).map_err(|e| ConfigError::IoError(path.as_ref().to_path_buf(), e))?;

        Ok(())
    }

    /// Merge with CLI arguments (CLI args take precedence)
    ///
    /// # Arguments
    ///
    /// * `input` - CLI input path (if specified)
    /// * `memory_budget` - CLI memory budget (if specified)
    /// * `accuracy` - CLI accuracy (if specified)
    /// * `parallel` - CLI parallel flag (if specified)
    /// * `verbose` - CLI verbose flag (if specified)
    /// * `debug_export` - CLI debug export path (if specified)
    /// * `checkpoint_dir` - CLI checkpoint directory (if specified)
    /// * `checkpoint_interval` - CLI checkpoint interval (if specified)
    ///
    /// # Returns
    ///
    /// Merged configuration with CLI args overriding config file values
    #[allow(clippy::too_many_arguments)]
    pub fn merge_with_cli(
        &self,
        input: Option<PathBuf>,
        memory_budget: Option<usize>,
        accuracy: Option<f64>,
        parallel: Option<bool>,
        verbose: Option<bool>,
        debug_export: Option<PathBuf>,
        checkpoint_dir: Option<PathBuf>,
        checkpoint_interval: Option<usize>,
    ) -> MergedConfig {
        MergedConfig {
            input: input.or_else(|| self.input.clone()),
            memory_budget: memory_budget.or(self.memory_budget).unwrap_or(8192),
            accuracy: accuracy.or(self.accuracy).unwrap_or(0.95),
            parallel: parallel.or(self.parallel).unwrap_or(false),
            verbose: verbose.or(self.verbose).unwrap_or(false),
            debug_export: debug_export.or_else(|| self.debug_export.clone()),
            checkpoint_dir: checkpoint_dir.or_else(|| self.checkpoint_dir.clone()),
            checkpoint_interval: checkpoint_interval.or(self.checkpoint_interval).unwrap_or(10),
        }
    }
}

/// Merged configuration after combining config file + CLI args
///
/// All fields have concrete values (no Options), except for paths which may be unset.
#[derive(Debug, Clone)]
pub struct MergedConfig {
    /// Input ONNX model path
    pub input: Option<PathBuf>,

    /// Memory budget in MB
    pub memory_budget: usize,

    /// Accuracy target 0.0-1.0
    pub accuracy: f64,

    /// Enable parallel processing
    pub parallel: bool,

    /// Enable verbose output
    pub verbose: bool,

    /// Export debug artifacts to directory
    pub debug_export: Option<PathBuf>,

    /// Checkpoint directory for resumable compilation
    pub checkpoint_dir: Option<PathBuf>,

    /// Checkpoint interval (save every N operations, default: 10)
    pub checkpoint_interval: usize,
}

/// Configuration loading errors
#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    /// Failed to read config file
    #[error("Failed to read config file {0}: {1}")]
    IoError(PathBuf, #[source] std::io::Error),

    /// Failed to parse TOML
    #[error("Failed to parse config file {0}: {1}")]
    ParseError(PathBuf, #[source] toml::de::Error),

    /// Failed to serialize config
    #[error("Failed to serialize config: {0}")]
    SerializeError(#[source] toml::ser::Error),
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use tempfile::NamedTempFile;

    #[test]
    fn test_load_valid_config() {
        let toml_content = r#"
            memory_budget = 16384
            accuracy = 0.99
            parallel = true
            verbose = true
        "#;

        let mut temp_file = NamedTempFile::new().unwrap();
        temp_file.write_all(toml_content.as_bytes()).unwrap();

        let config = CompilerConfig::load(temp_file.path()).unwrap();

        assert_eq!(config.memory_budget, Some(16384));
        assert_eq!(config.accuracy, Some(0.99));
        assert_eq!(config.parallel, Some(true));
        assert_eq!(config.verbose, Some(true));
    }

    #[test]
    fn test_load_partial_config() {
        let toml_content = r#"
            memory_budget = 32768
        "#;

        let mut temp_file = NamedTempFile::new().unwrap();
        temp_file.write_all(toml_content.as_bytes()).unwrap();

        let config = CompilerConfig::load(temp_file.path()).unwrap();

        assert_eq!(config.memory_budget, Some(32768));
        assert_eq!(config.accuracy, None);
        assert_eq!(config.parallel, None);
    }

    #[test]
    fn test_save_and_load_config() {
        let original = CompilerConfig {
            input: Some(PathBuf::from("model.onnx")),
            memory_budget: Some(16384),
            accuracy: Some(0.99),
            parallel: Some(true),
            verbose: Some(false),
            debug_export: Some(PathBuf::from("/tmp/debug")),
            checkpoint_dir: Some(PathBuf::from("/tmp/checkpoints")),
            checkpoint_interval: Some(5),
        };

        let temp_file = NamedTempFile::new().unwrap();
        original.save(temp_file.path()).unwrap();

        let loaded = CompilerConfig::load(temp_file.path()).unwrap();

        assert_eq!(loaded.input, Some(PathBuf::from("model.onnx")));
        assert_eq!(loaded.memory_budget, Some(16384));
        assert_eq!(loaded.accuracy, Some(0.99));
        assert_eq!(loaded.parallel, Some(true));
        assert_eq!(loaded.verbose, Some(false));
        assert_eq!(loaded.debug_export, Some(PathBuf::from("/tmp/debug")));
        assert_eq!(loaded.checkpoint_dir, Some(PathBuf::from("/tmp/checkpoints")));
        assert_eq!(loaded.checkpoint_interval, Some(5));
    }

    #[test]
    fn test_merge_with_cli() {
        let config = CompilerConfig {
            input: Some(PathBuf::from("model.onnx")),
            memory_budget: Some(16384),
            accuracy: Some(0.99),
            parallel: Some(true),
            verbose: Some(false),
            debug_export: None,
            checkpoint_dir: Some(PathBuf::from("/tmp/checkpoints")),
            checkpoint_interval: Some(20),
        };

        // CLI overrides config file
        let merged = config.merge_with_cli(
            None,       // Use config input
            Some(8192), // Override memory_budget
            None,       // Use config accuracy (0.99)
            None,       // Use config parallel (true)
            Some(true), // Override verbose
            Some(PathBuf::from("/tmp/debug")),
            None,    // Use config checkpoint_dir
            Some(5), // Override checkpoint_interval
        );

        assert_eq!(merged.input, Some(PathBuf::from("model.onnx"))); // From config
        assert_eq!(merged.memory_budget, 8192); // CLI override
        assert_eq!(merged.accuracy, 0.99); // From config
        assert!(merged.parallel); // From config
        assert!(merged.verbose); // CLI override
        assert_eq!(merged.debug_export, Some(PathBuf::from("/tmp/debug")));
        assert_eq!(merged.checkpoint_dir, Some(PathBuf::from("/tmp/checkpoints"))); // From config
        assert_eq!(merged.checkpoint_interval, 5); // CLI override
    }

    #[test]
    fn test_merge_with_defaults() {
        let config = CompilerConfig::default();

        let merged = config.merge_with_cli(None, None, None, None, None, None, None, None);

        // All defaults
        assert_eq!(merged.input, None);
        assert_eq!(merged.memory_budget, 8192);
        assert_eq!(merged.accuracy, 0.95);
        assert!(!merged.parallel);
        assert!(!merged.verbose);
        assert_eq!(merged.debug_export, None);
        assert_eq!(merged.checkpoint_dir, None);
        assert_eq!(merged.checkpoint_interval, 10); // Default: 10 operations
    }

    #[test]
    fn test_invalid_toml() {
        // Invalid type in sectioned format
        let toml_content = r#"
            [onnx-compiler]
            memory_budget = "not a number"
        "#;

        let mut temp_file = NamedTempFile::new().unwrap();
        temp_file.write_all(toml_content.as_bytes()).unwrap();

        let result = CompilerConfig::load(temp_file.path());
        assert!(result.is_err());
    }

    #[test]
    fn test_sectioned_format() {
        let toml_content = r#"
            [onnx-compiler]
            memory_budget = 16384
            accuracy = 0.99
            parallel = true
            verbose = true
        "#;

        let mut temp_file = NamedTempFile::new().unwrap();
        temp_file.write_all(toml_content.as_bytes()).unwrap();

        let config = CompilerConfig::load(temp_file.path()).unwrap();

        assert_eq!(config.memory_budget, Some(16384));
        assert_eq!(config.accuracy, Some(0.99));
        assert_eq!(config.parallel, Some(true));
        assert_eq!(config.verbose, Some(true));
    }

    #[test]
    fn test_sectioned_format_with_other_sections() {
        // Config file with multiple sections, only [onnx-compiler] should be read
        let toml_content = r#"
            [other-tool]
            some_setting = "value"

            [onnx-compiler]
            memory_budget = 8192
            accuracy = 0.85

            [another-tool]
            another_setting = 123
        "#;

        let mut temp_file = NamedTempFile::new().unwrap();
        temp_file.write_all(toml_content.as_bytes()).unwrap();

        let config = CompilerConfig::load(temp_file.path()).unwrap();

        assert_eq!(config.memory_budget, Some(8192));
        assert_eq!(config.accuracy, Some(0.85));
        assert_eq!(config.parallel, None);
    }

    #[test]
    fn test_backward_compatible_direct_format() {
        // Old format without sections should still work
        let toml_content = r#"
            memory_budget = 4096
            parallel = true
        "#;

        let mut temp_file = NamedTempFile::new().unwrap();
        temp_file.write_all(toml_content.as_bytes()).unwrap();

        let config = CompilerConfig::load(temp_file.path()).unwrap();

        assert_eq!(config.memory_budget, Some(4096));
        assert_eq!(config.parallel, Some(true));
    }
}
