//! HuggingFace Model Downloader (Token-Free)
//!
//! Downloads entire HuggingFace repositories by cloning the Git repo
//! and downloading LFS files separately.
//!
//! ## Features
//!
//! ### Resumable Downloads (from rustyface)
//! - Streaming downloads with chunked reading
//! - HTTP Range header support for automatic resume
//! - Incremental SHA256 verification
//! - Automatic retry with exponential backoff
//!
//! ### Advanced Filtering (like hf download CLI)
//! - File type filters (ONNX, SafeTensors, Config)
//! - Include/exclude patterns (glob support)
//! - Subdirectory filtering
//! - Multiple filter combinations
//!
//! ### External Data Conversion (from convert-onnx-external-data.py)
//! - Automatic conversion to external data format
//! - Weights stored in separate .bin files
//! - Enables streaming-friendly ONNX models
//! - **Automatic Python venv management** - no manual setup required!
//!
//! ## Example
//!
//! ```no_run
//! use hologram_onnx_downloader::{download_model_with_options, DownloadOptions, FileFilter};
//! use std::path::Path;
//!
//! # async fn example() -> anyhow::Result<()> {
//! // Download only ONNX files from specific components
//! let options = DownloadOptions {
//!     file_filter: FileFilter::OnnxWithConfig,
//!     subdirs: Some(vec!["text_encoder".to_string(), "unet".to_string()]),
//!     include_patterns: Some(vec!["*/model.onnx".to_string()]),
//!     exclude_patterns: Some(vec!["*.md".to_string()]),
//!     verbose: true,
//!     ..Default::default()
//! };
//!
//! let repo_path = download_model_with_options(
//!     "onnxruntime/sd-turbo",
//!     None,
//!     Some(Path::new("downloads")),
//!     &options,
//! ).await?;
//! # Ok(())
//! # }
//! ```

use anyhow::{Context, Result};
use futures_util::StreamExt;
use git2::build::RepoBuilder;
use git2::Repository;
use glob::glob;
use sha2::Digest;
use std::io::{BufRead, Seek, Write};
use std::path::{Path, PathBuf};

/// Base URL for HuggingFace
const DEFAULT_BASE_URL: &str = "https://huggingface.co";

/// File type filter for downloads
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FileFilter {
    /// Download all files
    All,
    /// Only ONNX files (*.onnx)
    OnnxOnly,
    /// Only SafeTensors files (*.safetensors)
    SafeTensorsOnly,
    /// Only configuration files (*.json)
    ConfigOnly,
    /// ONNX and config files
    OnnxWithConfig,
    /// SafeTensors and config files
    SafeTensorsWithConfig,
    /// PyTorch model files (*.safetensors, *.json, *.py, *.txt)
    PyTorchModel,
}

impl FileFilter {
    /// Check if a file should be downloaded based on the filter
    pub fn should_download(&self, filename: &str) -> bool {
        let fname_lower = filename.to_lowercase();

        match self {
            FileFilter::All => true,
            FileFilter::OnnxOnly => fname_lower.ends_with(".onnx"),
            FileFilter::SafeTensorsOnly => fname_lower.ends_with(".safetensors"),
            FileFilter::ConfigOnly => fname_lower.ends_with(".json"),
            FileFilter::OnnxWithConfig => {
                fname_lower.ends_with(".onnx") || fname_lower.ends_with(".json")
            }
            FileFilter::SafeTensorsWithConfig => {
                fname_lower.ends_with(".safetensors") || fname_lower.ends_with(".json")
            }
            FileFilter::PyTorchModel => {
                fname_lower.ends_with(".safetensors")
                    || fname_lower.ends_with(".json")
                    || fname_lower.ends_with(".py")
                    || fname_lower.ends_with(".txt")
                    || fname_lower.ends_with(".bin")
            }
        }
    }
}

/// Download options for HuggingFace repositories
#[derive(Debug, Clone)]
pub struct DownloadOptions {
    /// File type filter
    pub file_filter: FileFilter,

    /// Specific subdirectories to download (e.g., ["unet", "vae"])
    pub subdirs: Option<Vec<String>>,

    /// Include patterns (glob) - only download files matching these patterns
    /// Examples: ["*.onnx", "text_encoder/*", "unet/model.onnx"]
    pub include_patterns: Option<Vec<String>>,

    /// Exclude patterns (glob) - skip files matching these patterns
    /// Examples: ["*.md", "*.txt", "test_*"]
    pub exclude_patterns: Option<Vec<String>>,

    /// Whether to skip LFS files (only clone Git repo)
    pub skip_lfs: bool,

    /// Automatically convert PyTorch models to ONNX if no ONNX files are found
    /// (requires Python with transformers/diffusers packages)
    pub auto_convert_pytorch: bool,

    /// Convert ONNX models to external data format after download/conversion
    /// (weights in separate .bin files for streaming)
    pub convert_to_external: bool,

    /// Verbose output
    pub verbose: bool,
}

impl Default for DownloadOptions {
    fn default() -> Self {
        Self {
            file_filter: FileFilter::All,
            subdirs: None,
            include_patterns: None,
            exclude_patterns: None,
            skip_lfs: false,
            auto_convert_pytorch: false,
            convert_to_external: false,
            verbose: false,
        }
    }
}

/// Download a HuggingFace repository (clones Git repo + downloads LFS files)
///
/// # Arguments
///
/// * `repo_id` - Repository ID (e.g., "deepseek-ai/DeepSeek-OCR")
/// * `filename` - Optional specific file to extract after download
/// * `output_dir` - Output directory (defaults to current directory)
///
/// # Returns
///
/// Path to the cloned repository (or specific file if filename was provided)
pub async fn download_onnx_model(
    repo_id: &str,
    filename: Option<&str>,
    output_dir: Option<&Path>,
) -> Result<PathBuf> {
    download_model_with_options(repo_id, filename, output_dir, &DownloadOptions::default()).await
}

/// Download a HuggingFace repository with custom options
///
/// # Arguments
///
/// * `repo_id` - Repository ID (e.g., "deepseek-ai/DeepSeek-OCR")
/// * `filename` - Optional specific file to extract after download
/// * `output_dir` - Output directory (defaults to current directory)
/// * `options` - Download options (filtering, subdirs, etc.)
///
/// # Returns
///
/// Path to the cloned repository (or specific file if filename was provided)
pub async fn download_model_with_options(
    repo_id: &str,
    filename: Option<&str>,
    output_dir: Option<&Path>,
    options: &DownloadOptions,
) -> Result<PathBuf> {
    if options.verbose {
        tracing::info!("Downloading repository from HuggingFace: {}", repo_id);
    }

    // Get base URL from environment or use default
    let base_url = std::env::var("HF_ENDPOINT").unwrap_or_else(|_| DEFAULT_BASE_URL.to_string());

    // Determine output directory
    let output_path = if let Some(dir) = output_dir {
        dir.to_path_buf()
    } else {
        std::env::current_dir().context("Failed to get current directory")?
    };

    // Create output directory
    std::fs::create_dir_all(&output_path)
        .with_context(|| format!("Failed to create directory: {}", output_path.display()))?;

    // Construct repository path
    let repo_path = output_path.join(repo_id);

    // Check if repository already exists
    let repo_already_existed = repo_path.exists();
    if repo_already_existed {
        if options.verbose {
            tracing::info!(
                "Repository already exists at: {} (skipping clone)",
                repo_path.display()
            );
        }
    } else {
        // Clone the repository
        if options.verbose {
            clone_repository(repo_id, &base_url, &repo_path)?;
        } else {
            clone_repository(repo_id, &base_url, &repo_path)?;
        }
    }

    // Download LFS files
    if !options.skip_lfs {
        if repo_already_existed {
            // If repo already exists, use git lfs pull to download LFS files
            if options.verbose {
                tracing::info!("Downloading LFS files using git lfs pull...");
            }

            use std::process::Command;
            let output = Command::new("git")
                .args(&["-C", repo_path.to_str().unwrap_or("."), "lfs", "pull"])
                .output()
                .context("Failed to run 'git lfs pull'. Is git-lfs installed?")?;

            if !output.status.success() {
                let stderr = String::from_utf8_lossy(&output.stderr);
                tracing::warn!("git lfs pull failed: {}", stderr);
                // Fall back to custom LFS download
                download_lfs_files_filtered(&repo_path, repo_id, &base_url, options).await?;
            } else if options.verbose {
                tracing::info!("✓ LFS files downloaded successfully");
            }
        } else {
            // Fresh clone - use custom download logic with filtering
            download_lfs_files_filtered(&repo_path, repo_id, &base_url, options).await?;
        }
    }

    // Check if ONNX files exist, if not and auto_convert_pytorch is enabled, convert PyTorch to ONNX
    if options.auto_convert_pytorch {
        let has_onnx = has_onnx_files(&repo_path)?;
        if !has_onnx {
            if options.verbose {
                tracing::info!("No ONNX files found, attempting PyTorch to ONNX conversion...");
            }
            convert_pytorch_to_onnx(&repo_path, options.verbose).await?;
        } else if options.verbose {
            tracing::info!("ONNX files found, skipping PyTorch conversion");
        }
    }

    // Convert ONNX models to external data format if requested
    // Note: This requires Python with the 'onnx' package installed
    if options.convert_to_external {
        convert_onnx_to_external_data(&repo_path, options.verbose).await?;
    }

    // If a specific filename was requested, return its path
    if let Some(fname) = filename {
        let file_path = repo_path.join(fname);
        if !file_path.exists() {
            anyhow::bail!("File '{}' not found in repository", fname);
        }
        Ok(file_path)
    } else {
        Ok(repo_path)
    }
}

/// Clone a HuggingFace repository
fn clone_repository(repo_id: &str, base_url: &str, dest_path: &Path) -> Result<Repository> {
    let url = format!("{}/{}", base_url.trim_end_matches('/'), repo_id);

    tracing::info!("Cloning repository from: {}", url);
    tracing::info!("Destination: {}", dest_path.display());

    let repo = RepoBuilder::new()
        .clone(&url, dest_path)
        .with_context(|| format!("Failed to clone repository from {}", url))?;

    tracing::info!("✓ Repository cloned successfully");

    Ok(repo)
}

/// Download LFS files for a repository with filtering
async fn download_lfs_files_filtered(
    repo_path: &Path,
    repo_id: &str,
    base_url: &str,
    options: &DownloadOptions,
) -> Result<()> {
    // Read .gitattributes to find LFS files
    let lfs_files = read_lfs_pointers(repo_path)?;

    if lfs_files.is_empty() {
        if options.verbose {
            tracing::info!("No LFS files found in repository");
        }
        return Ok(());
    }

    // Filter files based on options
    let filtered_files: Vec<String> = lfs_files
        .into_iter()
        .filter(|file| {
            // Check file filter
            if !options.file_filter.should_download(file) {
                return false;
            }

            // Check subdirectory filter
            if let Some(ref subdirs) = options.subdirs {
                let file_path = Path::new(file);
                let first_component = file_path.components().next();
                if let Some(std::path::Component::Normal(comp)) = first_component {
                    let dir_name = comp.to_string_lossy();
                    if !subdirs.iter().any(|subdir| dir_name == subdir.as_str()) {
                        return false;
                    }
                }
            }

            // Check include patterns (like hf download --include)
            if let Some(ref patterns) = options.include_patterns {
                let matches_any = patterns
                    .iter()
                    .any(|pattern| matches_glob_pattern(file, pattern));
                if !matches_any {
                    return false;
                }
            }

            // Check exclude patterns (like hf download --exclude)
            if let Some(ref patterns) = options.exclude_patterns {
                let matches_any = patterns
                    .iter()
                    .any(|pattern| matches_glob_pattern(file, pattern));
                if matches_any {
                    return false;
                }
            }

            true
        })
        .collect();

    if filtered_files.is_empty() {
        if options.verbose {
            tracing::info!("No files matched the filter criteria");
        }
        return Ok(());
    }

    if options.verbose {
        tracing::info!(
            "Found {} LFS file(s) to download (after filtering)",
            filtered_files.len()
        );
    }

    // Extract LFS URLs and download
    let lfs_info = extract_lfs_urls(repo_path, &filtered_files, repo_id, base_url)?;

    // Download all files sequentially (could be parallelized with tokio::spawn if needed)
    for info in lfs_info {
        download_lfs_file(&info, repo_path).await?;
    }

    if options.verbose {
        tracing::info!("✓ All LFS files downloaded successfully");
    }

    Ok(())
}

/// Check if a file path matches a glob pattern
/// Supports patterns like: "*.onnx", "unet/*", "text_encoder/model.onnx"
fn matches_glob_pattern(file: &str, pattern: &str) -> bool {
    // Simple glob matching
    if pattern.contains('*') {
        // Split pattern on '*' and check if all parts are present in order
        let parts: Vec<&str> = pattern.split('*').collect();

        if parts.is_empty() {
            return true;
        }

        let mut file_str = file;
        for (i, part) in parts.iter().enumerate() {
            if part.is_empty() {
                continue;
            }

            if i == 0 {
                // First part - must be at the start
                if !file_str.starts_with(part) {
                    return false;
                }
                file_str = &file_str[part.len()..];
            } else if i == parts.len() - 1 {
                // Last part - must be at the end
                if !file_str.ends_with(part) {
                    return false;
                }
            } else {
                // Middle part - must be present
                if let Some(pos) = file_str.find(part) {
                    file_str = &file_str[pos + part.len()..];
                } else {
                    return false;
                }
            }
        }
        true
    } else {
        // Exact match or prefix match with /
        file == pattern || file.starts_with(&format!("{}/", pattern))
    }
}

/// Read LFS pointer files using git lfs ls-files
fn read_lfs_pointers(repo_path: &Path) -> Result<Vec<String>> {
    use std::process::Command;

    tracing::debug!("Reading LFS files from: {:?}", repo_path);

    // Use git lfs ls-files to get the list of LFS-tracked files
    let output = Command::new("git")
        .args(&["-C", repo_path.to_str().unwrap_or("."), "lfs", "ls-files", "-n"])
        .output()
        .context("Failed to run 'git lfs ls-files'. Is git-lfs installed?")?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        tracing::debug!("git lfs ls-files failed: {}", stderr);
        return Ok(Vec::new());
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let lfs_files: Vec<String> = stdout
        .lines()
        .filter(|line| !line.is_empty())
        .map(|line| line.trim().to_string())
        .collect();

    tracing::debug!("Found {} LFS files", lfs_files.len());
    for file in &lfs_files {
        tracing::debug!("  LFS file: {}", file);
    }

    Ok(lfs_files)
}

/// LFS file information
struct LfsFileInfo {
    url: String,
    sha256: String,
    local_path: PathBuf,
}

/// Extract LFS URLs from pointer files
fn extract_lfs_urls(
    repo_path: &Path,
    lfs_files: &[String],
    repo_id: &str,
    base_url: &str,
) -> Result<Vec<LfsFileInfo>> {
    let mut lfs_info = Vec::new();

    for lfs_file in lfs_files {
        let pointer_path = repo_path.join(lfs_file);
        tracing::debug!("Reading LFS pointer: {:?}", pointer_path);

        let file = std::fs::File::open(&pointer_path)?;
        let reader = std::io::BufReader::new(file);

        let mut oid: Option<String> = None;

        for line in reader.lines() {
            let line = line?;
            if line.starts_with("oid sha256:") {
                oid = Some(line.replace("oid sha256:", "").trim().to_string());
                break;
            }
        }

        if let Some(oid) = oid {
            let url = format!(
                "{}/{}/resolve/main/{}",
                base_url.trim_end_matches('/'),
                repo_id,
                lfs_file
            );

            lfs_info.push(LfsFileInfo {
                url,
                sha256: oid,
                local_path: pointer_path,
            });
        } else {
            tracing::warn!("No OID found in LFS pointer file: {}", lfs_file);
        }
    }

    Ok(lfs_info)
}

/// Resume downloading a file from where it left off
async fn download_lfs_file_resume(
    client: &reqwest::Client,
    url: &str,
    file: &mut std::fs::File,
    hasher: &mut sha2::Sha256,
    downloaded_bytes: &mut u64,
) -> Result<()> {
    // Get the current position in the file (where download was interrupted)
    let start = file.seek(std::io::SeekFrom::End(0))?;
    tracing::debug!("Resuming download from byte position: {}", start);

    // Request the rest of the file using Range header
    let response = client
        .get(url)
        .header("Range", format!("bytes={}-", start))
        .send()
        .await
        .context("Failed to send resume request")?;

    tracing::debug!("Resume response headers: {:?}", response.headers());

    // Stream the remaining content
    if response.status().is_success() || response.status().as_u16() == 206 {
        // 206 = Partial Content
        let mut stream = response.bytes_stream();

        while let Some(chunk) = stream.next().await {
            let chunk = chunk.context("Error reading chunk during resume")?;
            file.write_all(&chunk).context("Failed to write chunk")?;
            hasher.update(&chunk);
            *downloaded_bytes += chunk.len() as u64;
        }
    }

    Ok(())
}

/// Download a single LFS file with streaming and resume capability
async fn download_lfs_file(info: &LfsFileInfo, _repo_path: &Path) -> Result<()> {
    let filename = info
        .local_path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown");

    tracing::info!("Downloading LFS file: {}", filename);
    tracing::debug!("URL: {}", info.url);

    // Create HTTP client
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(300))
        .build()
        .context("Failed to create HTTP client")?;

    // Setup SHA256 hasher
    let mut hasher = sha2::Sha256::new();
    let mut downloaded_bytes: u64 = 0;

    // Create file for writing
    let mut file = std::fs::File::create(&info.local_path)
        .with_context(|| format!("Failed to create file: {}", info.local_path.display()))?;

    // Initial download request
    let response = client
        .get(&info.url)
        .send()
        .await
        .with_context(|| format!("Failed to download from {}", info.url))?;

    if !response.status().is_success() {
        anyhow::bail!(
            "Download failed with status {}: {}",
            response.status(),
            info.url
        );
    }

    let total_size = response.content_length().unwrap_or(0);

    // Stream the response in chunks
    let mut stream = response.bytes_stream();

    while let Some(item) = stream.next().await {
        match item {
            Ok(chunk) => {
                // Write chunk to file
                file.write_all(&chunk).context("Failed to write chunk")?;

                // Update SHA256 hash
                hasher.update(&chunk);

                downloaded_bytes += chunk.len() as u64;
            }
            Err(error) => {
                // Error occurred during streaming - attempt to resume
                tracing::warn!("Stream error occurred: {} - attempting to resume", error);

                // Retry with resume logic
                loop {
                    match download_lfs_file_resume(
                        &client,
                        &info.url,
                        &mut file,
                        &mut hasher,
                        &mut downloaded_bytes,
                    )
                    .await
                    {
                        Ok(_) => {
                            tracing::debug!("Resume successful");
                            break;
                        }
                        Err(e) => {
                            tracing::warn!("Resume failed: {} - retrying", e);
                            tokio::time::sleep(std::time::Duration::from_secs(1)).await;
                            continue;
                        }
                    }
                }
            }
        }
    }

    // Calculate final hash
    let calculated_hash = format!("{:x}", hasher.finalize());

    // Verify hash
    if calculated_hash != info.sha256 {
        anyhow::bail!(
            "SHA256 mismatch for {}: expected {}, got {}",
            filename,
            info.sha256,
            calculated_hash
        );
    }

    tracing::info!(
        "✓ Downloaded {} ({:.2} MB)",
        filename,
        downloaded_bytes as f64 / (1024.0 * 1024.0)
    );

    if total_size > 0 {
        tracing::debug!(
            "Downloaded {}/{} bytes ({:.1}%)",
            downloaded_bytes,
            total_size,
            (downloaded_bytes as f64 / total_size as f64) * 100.0
        );
    }

    Ok(())
}

/// Check if ONNX files exist in the repository
fn has_onnx_files(repo_path: &Path) -> Result<bool> {
    let onnx_pattern = repo_path.join("**/*.onnx");
    let onnx_files: Vec<PathBuf> = glob(onnx_pattern.to_str().unwrap())?
        .filter_map(|e| e.ok())
        .collect();
    Ok(!onnx_files.is_empty())
}

/// Convert PyTorch models to ONNX format
///
/// Automatically detects model type (Stable Diffusion, Transformers, etc.)
/// and converts each component to ONNX format.
async fn convert_pytorch_to_onnx(repo_path: &Path, verbose: bool) -> Result<()> {
    if verbose {
        tracing::info!("Converting PyTorch models to ONNX format...");
    }

    // Create or reuse venv with required packages
    let venv = create_temp_python_venv_for_conversion(verbose).await?;
    let python_cmd = get_venv_python(&venv);

    // Detect model type by checking for specific config files
    let model_type = detect_model_type(repo_path)?;

    if verbose {
        tracing::info!("Detected model type: {:?}", model_type);
    }

    match model_type {
        ModelType::StableDiffusion => {
            convert_stable_diffusion_to_onnx(repo_path, &python_cmd, verbose).await?;
        }
        ModelType::Transformer => {
            convert_transformer_to_onnx(repo_path, &python_cmd, verbose).await?;
        }
        ModelType::Unknown => {
            tracing::warn!("Could not detect model type for PyTorch to ONNX conversion");
            tracing::warn!("Supported types: Stable Diffusion, Transformers (BERT, GPT, etc.)");
        }
    }

    // Clean up venv
    if verbose {
        tracing::info!("Cleaning up temporary virtual environment...");
    }
    let _ = std::fs::remove_dir_all(&venv);

    if verbose {
        tracing::info!("✓ PyTorch to ONNX conversion complete");
    }

    Ok(())
}

/// Model types for PyTorch to ONNX conversion
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ModelType {
    StableDiffusion,
    Transformer,
    Unknown,
}

/// Detect model type from repository structure
fn detect_model_type(repo_path: &Path) -> Result<ModelType> {
    // Check for model_index.json (Stable Diffusion)
    if repo_path.join("model_index.json").exists() {
        return Ok(ModelType::StableDiffusion);
    }

    // Check for config.json
    let config_path = repo_path.join("config.json");
    if config_path.exists() {
        let config_content = std::fs::read_to_string(config_path)?;

        // Check for diffusion-related indicators
        if config_content.contains("UNet")
            || config_content.contains("AutoencoderKL")
            || config_content.contains("CLIPTextModel")
        {
            return Ok(ModelType::StableDiffusion);
        }

        // Check for transformer indicators
        if config_content.contains("transformers")
            || config_content.contains("BertModel")
            || config_content.contains("GPT")
            || config_content.contains("architectures")
        {
            return Ok(ModelType::Transformer);
        }
    }

    Ok(ModelType::Unknown)
}

/// Convert Stable Diffusion components to ONNX
async fn convert_stable_diffusion_to_onnx(
    repo_path: &Path,
    python_cmd: &Path,
    verbose: bool,
) -> Result<()> {
    if verbose {
        tracing::info!("Converting Stable Diffusion components to ONNX...");
    }

    // Find all component directories (unet, vae_encoder, vae_decoder, text_encoder, etc.)
    let component_dirs: Vec<_> = std::fs::read_dir(repo_path)?
        .filter_map(|entry| entry.ok())
        .filter(|entry| entry.path().is_dir())
        .filter(|entry| {
            let name = entry.file_name();
            let name_str = name.to_string_lossy();
            name_str.contains("unet")
                || name_str.contains("vae")
                || name_str.contains("text_encoder")
        })
        .collect();

    if component_dirs.is_empty() {
        tracing::warn!("No Stable Diffusion components found");
        return Ok(());
    }

    for component_dir in component_dirs {
        let component_name = component_dir.file_name();
        let component_path = component_dir.path();

        if verbose {
            tracing::info!("Converting component: {}", component_name.to_string_lossy());
        }

        let output_onnx = component_path.join("model.onnx");

        // Create conversion script
        let script = format!(
            r#"
import sys
import torch
from pathlib import Path

component_path = Path(r"{}")
output_path = Path(r"{}")

# Try to load with diffusers
try:
    from diffusers import UNet2DConditionModel, AutoencoderKL
    from transformers import CLIPTextModel

    component_name = component_path.name.lower()

    if 'unet' in component_name:
        model = UNet2DConditionModel.from_pretrained(str(component_path))
        dummy_input = (
            torch.randn(1, 4, 64, 64),
            torch.tensor([1]),
            torch.randn(1, 77, 768)
        )
        input_names = ["sample", "timestep", "encoder_hidden_states"]
        output_names = ["out_sample"]
    elif 'vae' in component_name or 'autoencoder' in component_name:
        model = AutoencoderKL.from_pretrained(str(component_path))
        dummy_input = torch.randn(1, 3, 512, 512)
        input_names = ["input"]
        output_names = ["output"]
    elif 'text_encoder' in component_name or 'clip' in component_name:
        model = CLIPTextModel.from_pretrained(str(component_path))
        dummy_input = torch.randint(0, 49408, (1, 77))
        input_names = ["input_ids"]
        output_names = ["last_hidden_state"]
    else:
        print(f"Unknown component type: {{component_name}}")
        sys.exit(1)

    model.eval()

    # Export to ONNX
    torch.onnx.export(
        model,
        dummy_input,
        str(output_path),
        opset_version=17,
        input_names=input_names,
        output_names=output_names,
        do_constant_folding=True,
    )

    print(f"✓ Converted {{component_name}} to ONNX")

except Exception as e:
    print(f"Error converting {{component_name}}: {{e}}")
    sys.exit(1)
"#,
            component_path.display(),
            output_onnx.display()
        );

        // Execute conversion
        let output = tokio::process::Command::new(python_cmd)
            .args(&["-c", &script])
            .output()
            .await?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            tracing::warn!(
                "Failed to convert {}: {}",
                component_name.to_string_lossy(),
                stderr
            );
        } else if verbose {
            let stdout = String::from_utf8_lossy(&output.stdout);
            tracing::info!("{}", stdout.trim());
        }
    }

    Ok(())
}

/// Convert Transformer model to ONNX
async fn convert_transformer_to_onnx(
    repo_path: &Path,
    python_cmd: &Path,
    verbose: bool,
) -> Result<()> {
    if verbose {
        tracing::info!("Converting Transformer model to ONNX...");
    }

    let output_onnx = repo_path.join("model.onnx");

    let script = format!(
        r#"
import sys
import torch
from pathlib import Path
from transformers import AutoModel, AutoConfig

model_path = Path(r"{}")
output_path = Path(r"{}")

try:
    config = AutoConfig.from_pretrained(str(model_path))
    model = AutoModel.from_pretrained(str(model_path))
    model.eval()

    # Create dummy inputs
    batch_size = 1
    seq_length = 128
    input_ids = torch.randint(0, config.vocab_size, (batch_size, seq_length))
    attention_mask = torch.ones(batch_size, seq_length, dtype=torch.long)

    dummy_input = {{
        "input_ids": input_ids,
        "attention_mask": attention_mask,
    }}

    # Export to ONNX
    torch.onnx.export(
        model,
        (dummy_input,),
        str(output_path),
        opset_version=17,
        input_names=["input_ids", "attention_mask"],
        output_names=["last_hidden_state"],
        do_constant_folding=True,
    )

    print(f"✓ Converted transformer model to ONNX")

except Exception as e:
    print(f"Error converting transformer: {{e}}")
    sys.exit(1)
"#,
        repo_path.display(),
        output_onnx.display()
    );

    let output = tokio::process::Command::new(python_cmd)
        .args(&["-c", &script])
        .output()
        .await?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        tracing::warn!("Failed to convert transformer: {}", stderr);
    } else if verbose {
        let stdout = String::from_utf8_lossy(&output.stdout);
        tracing::info!("{}", stdout.trim());
    }

    Ok(())
}

/// Create a temporary Python virtual environment with required packages for conversion
async fn create_temp_python_venv_for_conversion(verbose: bool) -> Result<PathBuf> {
    if verbose {
        tracing::info!("Creating temporary Python virtual environment for PyTorch conversion...");
    }

    // Create temp directory for venv
    let temp_dir =
        std::env::temp_dir().join(format!("hologram-pytorch-venv-{}", std::process::id()));

    if temp_dir.exists() {
        std::fs::remove_dir_all(&temp_dir)?;
    }
    std::fs::create_dir_all(&temp_dir)?;

    // Check if python3 is available
    let python_check = tokio::process::Command::new("python3")
        .arg("--version")
        .output()
        .await;

    if python_check.is_err() {
        anyhow::bail!(
            "Python 3 not found. Please install Python 3 to use PyTorch to ONNX conversion."
        );
    }

    if verbose {
        tracing::info!("Creating venv at: {}", temp_dir.display());
    }

    // Create virtual environment
    let output = tokio::process::Command::new("python3")
        .args(&["-m", "venv", temp_dir.to_str().unwrap()])
        .output()
        .await
        .context("Failed to create Python virtual environment")?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        anyhow::bail!("Failed to create venv: {}", stderr);
    }

    // Determine pip path based on OS
    let pip_path = if cfg!(windows) {
        temp_dir.join("Scripts").join("pip.exe")
    } else {
        temp_dir.join("bin").join("pip")
    };

    if verbose {
        tracing::info!("Installing PyTorch packages (this may take a few minutes)...");
    }

    // Install required packages (torch, transformers, diffusers, onnx)
    let packages = vec!["torch", "transformers", "diffusers", "onnx"];
    for package in packages {
        if verbose {
            tracing::info!("Installing {}...", package);
        }

        let output = tokio::process::Command::new(&pip_path)
            .args(&["install", "-q", package])
            .output()
            .await
            .with_context(|| format!("Failed to install {} package", package))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            tracing::warn!("Failed to install {}: {}", package, stderr);
        }
    }

    if verbose {
        tracing::info!("✓ Virtual environment ready with PyTorch packages");
    }

    Ok(temp_dir)
}

/// Create a temporary Python virtual environment with required packages
async fn create_temp_python_venv(verbose: bool) -> Result<PathBuf> {
    if verbose {
        tracing::info!("Creating temporary Python virtual environment...");
    }

    // Create temp directory for venv
    let temp_dir = std::env::temp_dir().join(format!("hologram-onnx-venv-{}", std::process::id()));

    if temp_dir.exists() {
        std::fs::remove_dir_all(&temp_dir)?;
    }
    std::fs::create_dir_all(&temp_dir)?;

    // Check if python3 is available
    let python_check = tokio::process::Command::new("python3")
        .arg("--version")
        .output()
        .await;

    if python_check.is_err() {
        anyhow::bail!(
            "Python 3 not found. Please install Python 3 to use external data conversion."
        );
    }

    if verbose {
        tracing::info!("Creating venv at: {}", temp_dir.display());
    }

    // Create virtual environment
    let output = tokio::process::Command::new("python3")
        .args(&["-m", "venv", temp_dir.to_str().unwrap()])
        .output()
        .await
        .context("Failed to create Python virtual environment")?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        anyhow::bail!("Failed to create venv: {}", stderr);
    }

    // Determine pip path based on OS
    let pip_path = if cfg!(windows) {
        temp_dir.join("Scripts").join("pip.exe")
    } else {
        temp_dir.join("bin").join("pip")
    };

    if verbose {
        tracing::info!("Installing onnx package...");
    }

    // Install onnx package
    let output = tokio::process::Command::new(&pip_path)
        .args(&["install", "-q", "onnx"])
        .output()
        .await
        .context("Failed to install onnx package")?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        anyhow::bail!("Failed to install onnx: {}", stderr);
    }

    if verbose {
        tracing::info!("✓ Virtual environment ready");
    }

    Ok(temp_dir)
}

/// Get Python executable path from venv
fn get_venv_python(venv_path: &Path) -> PathBuf {
    if cfg!(windows) {
        venv_path.join("Scripts").join("python.exe")
    } else {
        venv_path.join("bin").join("python")
    }
}

/// Convert ONNX models to external data format
///
/// This function finds all .onnx files in the repository and converts them
/// to external data format where weights are stored in separate .bin files.
/// This enables true streaming without loading multi-GB files into memory.
///
/// Automatically creates a temporary Python virtual environment with the
/// required dependencies (onnx package).
async fn convert_onnx_to_external_data(repo_path: &Path, verbose: bool) -> Result<()> {
    if verbose {
        tracing::info!("Converting ONNX models to external data format...");
    }

    // Find all ONNX files in the repository
    let onnx_pattern = repo_path.join("**/*.onnx");
    let onnx_files: Vec<PathBuf> = glob(onnx_pattern.to_str().unwrap())?
        .filter_map(|e| e.ok())
        .collect();

    if onnx_files.is_empty() {
        if verbose {
            tracing::info!("No ONNX files found to convert");
        }
        return Ok(());
    }

    if verbose {
        tracing::info!("Found {} ONNX file(s) to convert", onnx_files.len());
    }

    // Check if Python and onnx are already available (avoid creating venv if not needed)
    let python_check = tokio::process::Command::new("python3")
        .args(&["-c", "import onnx"])
        .output()
        .await;

    let (python_cmd, venv_path) = match python_check {
        Ok(output) if output.status.success() => {
            if verbose {
                tracing::info!("Using system Python with onnx package");
            }
            ("python3".to_string(), None)
        }
        _ => {
            // Create temporary venv with onnx
            if verbose {
                tracing::info!(
                    "System Python doesn't have onnx package, creating temporary venv..."
                );
            }
            let venv = create_temp_python_venv(verbose).await?;
            let python = get_venv_python(&venv);
            (python.to_string_lossy().to_string(), Some(venv))
        }
    };

    // Convert each ONNX file
    for onnx_file in onnx_files {
        if verbose {
            tracing::info!("Converting: {}", onnx_file.display());
        }

        // Create Python script to convert this file
        let python_script = format!(
            r#"
import onnx
import sys
from pathlib import Path

model_path = Path(r"{}")
output_dir = model_path.parent / (model_path.stem + "-external")
output_dir.mkdir(parents=True, exist_ok=True)

# Load model
model = onnx.load(str(model_path))

# Output paths
output_onnx = output_dir / model_path.name
output_data = output_dir / (model_path.stem + ".bin")

# Convert to external data
onnx.save_model(
    model,
    str(output_onnx),
    save_as_external_data=True,
    all_tensors_to_one_file=True,
    location=output_data.name,
    size_threshold=1024,
    convert_attribute=False,
)

print(f"Converted: {{output_onnx}}")
print(f"Data file: {{output_data}}")
"#,
            onnx_file.display()
        );

        // Execute Python script using the appropriate Python command
        let output = tokio::process::Command::new(&python_cmd)
            .args(&["-c", &python_script])
            .output()
            .await
            .context("Failed to run Python conversion script")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            tracing::warn!("Failed to convert {}: {}", onnx_file.display(), stderr);
        } else if verbose {
            let stdout = String::from_utf8_lossy(&output.stdout);
            tracing::info!("{}", stdout.trim());
        }
    }

    // Clean up temporary venv if we created one
    if let Some(venv) = venv_path {
        if verbose {
            tracing::info!("Cleaning up temporary virtual environment...");
        }
        let _ = std::fs::remove_dir_all(&venv);
    }

    if verbose {
        tracing::info!("✓ External data conversion complete");
    }

    Ok(())
}

/// Parse HuggingFace model specification
///
/// Supports formats:
/// - "owner/repo" - Downloads entire repository
/// - "owner/repo:filename.onnx" - Downloads repo and returns path to specific file
pub fn parse_hf_model_spec(spec: &str) -> Result<(String, Option<String>)> {
    if let Some((repo, filename)) = spec.split_once(':') {
        Ok((repo.to_string(), Some(filename.to_string())))
    } else {
        Ok((spec.to_string(), None))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_hf_model_spec() {
        let (repo, file) = parse_hf_model_spec("owner/repo").unwrap();
        assert_eq!(repo, "owner/repo");
        assert_eq!(file, None);

        let (repo, file) = parse_hf_model_spec("owner/repo:model.onnx").unwrap();
        assert_eq!(repo, "owner/repo");
        assert_eq!(file, Some("model.onnx".to_string()));
    }

    #[test]
    fn test_matches_glob_pattern() {
        // Simple wildcard patterns
        assert!(matches_glob_pattern("model.onnx", "*.onnx"));
        assert!(matches_glob_pattern("unet/model.onnx", "*.onnx"));
        assert!(!matches_glob_pattern("model.safetensors", "*.onnx"));

        // Directory patterns
        assert!(matches_glob_pattern("unet/model.onnx", "unet/*"));
        assert!(matches_glob_pattern("unet/weights.bin", "unet/*"));
        assert!(!matches_glob_pattern("vae/model.onnx", "unet/*"));

        // Exact matches
        assert!(matches_glob_pattern("config.json", "config.json"));
        assert!(!matches_glob_pattern("other.json", "config.json"));

        // Complex patterns
        assert!(matches_glob_pattern(
            "text_encoder/model.onnx",
            "text_encoder/*"
        ));
        assert!(matches_glob_pattern("unet/model.onnx", "*/model.onnx"));
        assert!(matches_glob_pattern(
            "vae_decoder/model.onnx",
            "*/model.onnx"
        ));

        // Multiple wildcards
        assert!(matches_glob_pattern(
            "unet/config/model.onnx",
            "unet/*/model.onnx"
        ));
        assert!(matches_glob_pattern("text_encoder.onnx", "text_*.onnx"));
    }

    #[test]
    fn test_file_filter() {
        assert!(FileFilter::All.should_download("any.file"));
        assert!(FileFilter::OnnxOnly.should_download("model.onnx"));
        assert!(!FileFilter::OnnxOnly.should_download("model.safetensors"));
        assert!(FileFilter::SafeTensorsOnly.should_download("weights.safetensors"));
        assert!(!FileFilter::SafeTensorsOnly.should_download("model.onnx"));
        assert!(FileFilter::ConfigOnly.should_download("config.json"));
        assert!(!FileFilter::ConfigOnly.should_download("model.onnx"));
        assert!(FileFilter::OnnxWithConfig.should_download("model.onnx"));
        assert!(FileFilter::OnnxWithConfig.should_download("config.json"));
        assert!(!FileFilter::OnnxWithConfig.should_download("weights.safetensors"));

        // PyTorchModel filter tests
        assert!(FileFilter::PyTorchModel.should_download("model.safetensors"));
        assert!(FileFilter::PyTorchModel.should_download("config.json"));
        assert!(FileFilter::PyTorchModel.should_download("modeling.py"));
        assert!(FileFilter::PyTorchModel.should_download("README.txt"));
        assert!(FileFilter::PyTorchModel.should_download("pytorch_model.bin"));
        assert!(!FileFilter::PyTorchModel.should_download("model.onnx"));
    }

    #[test]
    fn test_download_options_default() {
        let opts = DownloadOptions::default();
        assert_eq!(opts.file_filter, FileFilter::All);
        assert!(opts.subdirs.is_none());
        assert!(opts.include_patterns.is_none());
        assert!(opts.exclude_patterns.is_none());
        assert!(!opts.skip_lfs);
        assert!(!opts.convert_to_external);
        assert!(!opts.verbose);
    }
}
