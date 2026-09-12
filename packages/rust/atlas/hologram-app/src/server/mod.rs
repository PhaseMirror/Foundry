mod handlers;
mod router;
mod state;

pub use router::create_router;
pub use state::AppState;

use crate::{Config, Result};

/// Run the HTTP server
pub async fn run(config: Config) -> Result<()> {
    let state = AppState::new(config.clone()).await?;
    let router = create_router(state);

    let addr = config.server_addr();
    let listener = tokio::net::TcpListener::bind(&addr).await?;

    tracing::info!("Hologram server listening on http://{}", addr);

    axum::serve(listener, router)
        .await
        .map_err(|e| crate::Error::Config(e.to_string()))?;

    Ok(())
}
