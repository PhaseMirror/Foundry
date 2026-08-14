use std::sync::Arc;

use tokio::sync::RwLock;

use crate::services::{ChatService, GenerateService, ModelManager, ProcessManager};
use crate::{Config, HologramApp, Result};

/// Shared application state for the HTTP server
#[derive(Clone)]
pub struct AppState {
    inner: Arc<AppStateInner>,
}

struct AppStateInner {
    pub config: Config,
    pub app: HologramApp,
}

impl AppState {
    pub async fn new(config: Config) -> Result<Self> {
        let app = HologramApp::new(config.clone()).await?;

        Ok(Self {
            inner: Arc::new(AppStateInner { config, app }),
        })
    }

    pub fn config(&self) -> &Config {
        &self.inner.config
    }

    pub fn chat(&self) -> &ChatService {
        self.inner.app.chat()
    }

    pub fn generate(&self) -> &GenerateService {
        self.inner.app.generate()
    }

    pub fn models(&self) -> &ModelManager {
        self.inner.app.models()
    }

    pub fn processes(&self) -> Arc<RwLock<ProcessManager>> {
        self.inner.app.processes()
    }
}
