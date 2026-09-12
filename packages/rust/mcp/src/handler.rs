// crates/mcp/src/handler.rs
use crate::archivum::Archivum;
use crate::schema::{EvaluateTransitionRequest, EvaluateTransitionResponse, EvaluationMode};
use sigma::{SigmaKernel, DissonanceError};
use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::{error, info, info_span, warn};

/// Handles the `evaluate_transition` MCP tool request.
pub async fn handle_evaluate_transition(
    kernel: &Arc<Mutex<SigmaKernel>>,
    archivum: &Arc<dyn Archivum>,
    req: EvaluateTransitionRequest,
) -> EvaluateTransitionResponse {
    // --- 1. Create a tracing span with the agent's correlation ID ---
    let span = info_span!(
        "mcp.evaluate_transition",
        agent_request_id = %req.agent_request_id,
        mode = ?req.mode,
        pweh_hash = tracing::field::Empty,
    );
    let _enter = span.enter();

    info!("Received evaluate_transition request from agent");

    // --- 2. Clone references for the blocking task ---
    let kernel_clone = Arc::clone(kernel);
    let transition = req.transition_data.clone();
    let mode = req.mode;

    // --- 3. Offload kernel evaluation to a blocking thread ---
    let evaluate_result = tokio::task::spawn_blocking(move || {
        let mut guard = kernel_clone.blocking_lock();
        guard.evaluate(transition) // Note: evaluate takes StateTransition by value in SigmaKernel
    })
    .await
    .expect("Blocking task panicked")
    .map_err(|err: DissonanceError| err);

    // --- 4. Map the result to the appropriate MCP response ---
    match evaluate_result {
        Ok(block) => {
            // If block has a pweh_hash method, uncomment: span.record("pweh_hash", &block.pweh_hash());

            match mode {
                EvaluationMode::Commit => {
                    match archivum.stamp(&block).await {
                        Ok(witness_id) => {
                            info!(witness_id = %witness_id, "Transition ratified and stamped");
                            EvaluateTransitionResponse::Ratified {
                                witness_id,
                                ratified_block: block,
                            }
                        }
                        Err(stamp_err) => {
                            error!(error = %stamp_err, "Failed to stamp committed block");
                            EvaluateTransitionResponse::DissonanceTrap {
                                breach_type: "archivum_stamp_failure".to_string(),
                                details: format!("Ledger stamp failed: {}", stamp_err),
                                conflict_log_id: None,
                            }
                        }
                    }
                }
                EvaluationMode::Simulate => {
                    info!("Simulation completed successfully (no witness stamped)");
                    EvaluateTransitionResponse::Simulated { ratified_block: block }
                }
            }
        }
        Err(err) => {
            let breach_type = err.breach_type().to_string();
            let details = err.to_string();

            let conflict_log_id = if mode == EvaluationMode::Commit {
                match archivum.log_conflict(&err, &req.agent_request_id).await {
                    Ok(id) => {
                        warn!(conflict_log_id = %id, breach_type = %breach_type, "Dissonance trap logged");
                        Some(id)
                    }
                    Err(log_err) => {
                        error!(error = %log_err, "Failed to log conflict to Archivum");
                        None
                    }
                }
            } else {
                warn!(breach_type = %breach_type, "Dissonance trap triggered in simulation");
                None
            };

            EvaluateTransitionResponse::DissonanceTrap {
                breach_type,
                details,
                conflict_log_id,
            }
        }
    }
}
