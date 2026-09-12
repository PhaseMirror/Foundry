use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TransportState {
    Disconnected,
    Connecting,
    Connected,
    Reconnecting,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TransportConfig {
    pub host: String,
    pub port: u16,
    pub use_tls: bool,
    pub timeout_seconds: u64,
    pub max_retries: u32,
    pub retry_delay_seconds: f64,
    pub metadata: HashMap<String, String>,
}

#[async_trait]
pub trait Transport: Send + Sync {
    fn state(&self) -> TransportState;
    fn is_connected(&self) -> bool {
        self.state() == TransportState::Connected
    }
    
    async fn connect(&mut self) -> anyhow::Result<()>;
    async fn disconnect(&mut self) -> anyhow::Result<()>;
    async fn send(&mut self, topic: &str, payload: serde_json::Value) -> anyhow::Result<()>;
    async fn receive(&mut self, timeout: Option<std::time::Duration>) -> anyhow::Result<serde_json::Value>;
}
