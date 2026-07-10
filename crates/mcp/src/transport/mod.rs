use std::sync::Arc;
use multiplicity_commander_core::CommanderCore;
use async_trait::async_trait;

pub mod stdio;
pub mod http;

#[async_trait]
pub trait McpTransport: Send + Sync {
    async fn run(&self, core: Arc<CommanderCore>) -> anyhow::Result<()>;
}
