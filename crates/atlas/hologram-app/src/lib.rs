//! # hologram-app
//!
//! A standalone library for running local LLM inference with Ollama-compatible APIs.
//!
//! ## Usage
//!
//! ### As a Library
//! ```rust,ignore
//! use hologram_app::{HologramApp, Config};
//!
//! let config = Config::default();
//! let app = HologramApp::new(config).await?;
//!
//! // List available models
//! let models = app.models().list().await?;
//!
//! // Use chat service
//! let response = app.chat().complete(request).await?;
//! ```
//!
//! ### Starting the Server
//! ```rust,ignore
//! use hologram_app::server;
//!
//! server::run(config).await?;
//! ```

pub mod config;
pub mod error;
pub mod onnx;
pub mod services;
pub mod types;

#[cfg(feature = "server")]
pub mod server;

// Re-export key types
pub use config::Config;
pub use error::{Error, Result};
pub use services::{ChatService, GenerateService, ModelManager, ProcessManager};
pub use types::ollama::*;
pub use types::openai::*;

use std::sync::Arc;
use tokio::sync::RwLock;

/// Main application facade providing access to all services
pub struct HologramApp {
    config: Config,
    model_manager: Arc<ModelManager>,
    process_manager: Arc<RwLock<ProcessManager>>,
    chat_service: ChatService,
    generate_service: GenerateService,
}

impl HologramApp {
    /// Create a new HologramApp instance
    pub async fn new(config: Config) -> Result<Self> {
        // Ensure directories exist
        config.ensure_dirs()?;

        let model_manager = Arc::new(ModelManager::new(config.clone()));
        let process_manager = Arc::new(RwLock::new(ProcessManager::new()));

        let chat_service = ChatService::new(
            config.clone(),
            model_manager.clone(),
            process_manager.clone(),
        );
        let generate_service = GenerateService::new(
            config.clone(),
            model_manager.clone(),
            process_manager.clone(),
        );

        Ok(Self {
            config,
            model_manager,
            process_manager,
            chat_service,
            generate_service,
        })
    }

    /// Get the configuration
    pub fn config(&self) -> &Config {
        &self.config
    }

    /// Get the chat service
    pub fn chat(&self) -> &ChatService {
        &self.chat_service
    }

    /// Get the generate service
    pub fn generate(&self) -> &GenerateService {
        &self.generate_service
    }

    /// Get the model manager
    pub fn models(&self) -> &ModelManager {
        &self.model_manager
    }

    /// Get the process manager
    pub fn processes(&self) -> Arc<RwLock<ProcessManager>> {
        self.process_manager.clone()
    }
}
