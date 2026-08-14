// pirtm-compiler/src/orchestrator/thermal_forecast.rs
// Handles LSTM forecasts and triggers pre‑emptive throttling

use crate::orchestrator::{Orchestrator, SessionPriority};
use anyhow::Result;
use async_nats::Client;
use futures::StreamExt;
use serde::Deserialize;
use std::sync::Arc;
use tokio::task;
use tracing::{info, warn};

#[derive(Debug, Deserialize)]
struct Forecast {
    timestamp: i64,
    forecast_util: f32,
    confidence: f32,
    horizon_seconds: u64,
}

pub async fn start_thermal_forecast_listener(
    nc: Client,
    orchestrator: Arc<Orchestrator>,
    subject: String,
) -> Result<()> {
    let mut subscription = nc.subscribe(subject.clone()).await?;
    info!("Thermal forecast listener started on {}", subject);

    while let Some(msg) = subscription.next().await {
        let forecast: Forecast = match serde_json::from_slice(&msg.data) {
            Ok(f) => f,
            Err(e) => {
                warn!("Failed to parse forecast: {}", e);
                continue;
            }
        };

        if forecast.forecast_util > 0.85 && forecast.confidence > 0.90 {
            info!(
                "Forecast breach: util={:.3}, conf={:.2}. Throttling low-priority sessions.",
                forecast.forecast_util, forecast.confidence
            );

            let low_priority = orchestrator.get_sessions_by_priority(SessionPriority::Low);
            if !low_priority.is_empty() {
                for session_id in low_priority {
                    orchestrator.downgrade_session(session_id).await;
                }
                orchestrator.log_governance_event(
                    "thermal_throttle",
                    &serde_json::json!({
                        "forecast_util": forecast.forecast_util,
                        "confidence": forecast.confidence,
                        "sessions_downgraded": low_priority.len(),
                    }),
                ).await;
            } else {
                warn!("No low-priority sessions to downgrade.");
            }
        }
    }

    Ok(())
}
