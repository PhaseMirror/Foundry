use serde::Deserialize;
use nats::asynk::Connection;
use tracing::info;
use std::sync::Arc;
use anyhow::Result;
use tokio_stream::StreamExt;

#[derive(Debug, Deserialize)]
struct AnomalyScore {
    timestamp: i64,
    anomaly_score: f32,
    threshold: f32,
    trigger: bool,
}

// Dummy Orchestrator type to mock the behavior
pub struct Orchestrator {}

impl Orchestrator {
    pub async fn trigger_sig_gov_kill(&self, reason: &str, details: &serde_json::Value) {
        info!("TRIGGER SIG_GOV_KILL: {} {:?}", reason, details);
    }
}

pub async fn start_vqc_listener(
    nc: Connection,
    orchestrator: Arc<Orchestrator>,
    subject: String,
) -> Result<()> {
    let mut subscription = nc.subscribe(&subject).await?;
    info!("VQC anomaly listener started on {}", subject);

    while let Some(msg) = subscription.next().await {
        let score: AnomalyScore = serde_json::from_slice(&msg.data)?;
        if score.trigger {
            info!(
                "VQC anomaly detected: score={:.3}, threshold={:.3}",
                score.anomaly_score, score.threshold
            );
            orchestrator.trigger_sig_gov_kill(
                "VQC_ANOMALY_DETECTED",
                &serde_json::json!({
                    "score": score.anomaly_score,
                    "threshold": score.threshold,
                }),
            ).await;
        }
    }
    Ok(())
}
