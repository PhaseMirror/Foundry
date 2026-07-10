# hologram-onnx-downloader

Advanced HuggingFace model downloader with resumable downloads and automatic PyTorch to ONNX conversion.

## Features

### 🚀 Resumable Downloads (from rustyface)
- **Streaming downloads** - Chunked reading, no full file in memory
- **HTTP Range header support** - Automatic resume from interruption point
- **Incremental SHA256 verification** - Hash computed during streaming
- **Automatic retry** - Infinite loop with 1-second delays
- **Error recovery** - Seamless resume without losing progress

### 🔍 Advanced Filtering (like hf CLI)
- **7 file type filters**: `All`, `OnnxOnly`, `SafeTensorsOnly`, `ConfigOnly`, `OnnxWithConfig`, `SafeTensorsWithConfig`, `PyTorchModel`
- **Include patterns**: Like `hf download --include "text_encoder/*"`
- **Exclude patterns**: Like `hf download --exclude "*.md"`
- **Subdirectory filtering**: Download specific components only
- **Glob pattern matching**: Supports `*.onnx`, `unet/*`, `*/model.onnx`, etc.

### 🔄 Automatic PyTorch to ONNX Conversion
- **Auto-detects model type**: Stable Diffusion, Transformers (BERT, GPT, etc.)
- **Converts all components**: U-Net, VAE, Text Encoder, etc.
- **Fully automatic venv management**: Creates temp venv, installs packages, cleans up
- **Zero manual setup**: Just enable `auto_convert_pytorch: true`

### 📦 External Data Format Conversion
- **Converts ONNX to external data format**: Weights in separate `.bin` files
- **Enables streaming**: Memory-mapped loading without full file in RAM
- **Automatic venv creation**: No need to install `onnx` package manually
- **Smart detection**: Uses system Python if `onnx` is already available

## Quick Start

```rust
use hologram_onnx_downloader::{download_onnx_model, DownloadOptions, FileFilter};
use std::path::Path;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Simple download
    let repo_path = download_onnx_model(
        "onnxruntime/sd-turbo",
        None,
        None,
    ).await?;

    // Advanced download with filtering
    let options = DownloadOptions {
        file_filter: FileFilter::OnnxWithConfig,
        subdirs: Some(vec!["unet".to_string(), "vae".to_string()]),
        include_patterns: Some(vec!["*/model.onnx".to_string()]),
        exclude_patterns: Some(vec!["*.md".to_string()]),
        auto_convert_pytorch: true,  // Convert PyTorch to ONNX if needed
        convert_to_external: true,    // Convert to external data format
        verbose: true,
        ..Default::default()
    };

    let repo_path = download_model_with_options(
        "IDKiro/sdxs-512-0.9",
        None,
        Some(Path::new("./models")),
        &options,
    ).await?;

    Ok(())
}
```

## File Type Filters

```rust
pub enum FileFilter {
    All,                      // All files
    OnnxOnly,                 // *.onnx
    SafeTensorsOnly,          // *.safetensors
    ConfigOnly,               // *.json
    OnnxWithConfig,          // *.onnx + *.json
    SafeTensorsWithConfig,   // *.safetensors + *.json
    PyTorchModel,            // *.safetensors + *.json + *.py + *.txt + *.bin
}
```

## Auto-Convert PyTorch to ONNX

When `auto_convert_pytorch` is enabled:

1. Downloads the model from HuggingFace
2. Checks if ONNX files exist
3. If not, automatically:
   - Detects model type (Stable Diffusion, Transformer, etc.)
   - Creates temp Python venv
   - Installs required packages (torch, transformers, diffusers, onnx)
   - Converts each component to ONNX
   - Cleans up venv

**Supported Model Types:**
- **Stable Diffusion**: U-Net, VAE, Text Encoder components
- **Transformers**: BERT, GPT, ViT, etc.

## Pattern Matching

Include/exclude patterns support simple glob syntax:

```rust
let options = DownloadOptions {
    include_patterns: Some(vec![
        "*.onnx".to_string(),           // All ONNX files
        "unet/*".to_string(),           // All files in unet dir
        "*/model.onnx".to_string(),     // model.onnx in any subdir
    ]),
    exclude_patterns: Some(vec![
        "*.md".to_string(),             // No markdown files
        "test_*".to_string(),           // No test files
    ]),
    ..Default::default()
};
```

## Examples

See `../../examples/download_with_filtering.rs` for comprehensive examples.

## Requirements

- **Rust**: 1.70+
- **Python 3**: Only for PyTorch conversion (auto-managed)

## Architecture

```
crates/downloader/
├── src/
│   └── lib.rs                 # Main implementation
├── scripts/
│   ├── convert-onnx-external-data.py
│   └── pytorch_to_onnx.py
├── Cargo.toml
└── README.md
```

## License

MIT OR Apache-2.0
