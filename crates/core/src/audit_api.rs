use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
    routing::get,
    Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::Mutex;
use crate::jubilee::{JubileeBridge, MerkleProofResponse, RtaHealth};
use crate::witness::CRMFWitness;

pub struct AuditState {
    pub bridge: Arc<Mutex<JubileeBridge>>,
    pub signing_key: k256::ecdsa::SigningKey,
}

#[derive(Deserialize)]
pub struct TransitionQuery {
    pub from: Option<DateTime<Utc>>,
    pub to: Option<DateTime<Utc>>,
    pub limit: Option<usize>,
    pub offset: Option<usize>,
}

#[derive(Serialize)]
pub struct TransitionList {
    pub operator_id: String,
    pub count: usize,
    pub transitions: Vec<CRMFWitness>,
}

#[derive(Serialize)]
pub struct AuditBundleMetadata {
    pub operator_id: String,
    pub from: DateTime<Utc>,
    pub to: DateTime<Utc>,
    pub witness_count: usize,
    pub bundle_hash: String,
    pub signature: String,
}

async fn list_transitions(
    Path(operator_id): Path<String>,
    Query(query): Query<TransitionQuery>,
    State(state): State<Arc<AuditState>>,
) -> Result<Json<TransitionList>, StatusCode> {
    let bridge = state.bridge.lock().await;
    let all = bridge.get_transitions(
        &operator_id,
        query.from.unwrap_or(DateTime::<Utc>::MIN_UTC),
        query.to.unwrap_or(DateTime::<Utc>::MAX_UTC),
    );
    let count = all.len();
    let offset = query.offset.unwrap_or(0);
    let limit = query.limit.unwrap_or(100);
    let page = all.into_iter().skip(offset).take(limit).collect();
    Ok(Json(TransitionList { operator_id, count, transitions: page }))
}

async fn get_witness_proof(
    Path((operator_id, transform_id)): Path<(String, String)>,
    State(state): State<Arc<AuditState>>,
) -> Result<Json<MerkleProofResponse>, StatusCode> {
    let bridge = state.bridge.lock().await;
    bridge.generate_witness_proof(&operator_id, &transform_id)
        .map(Json)
        .ok_or(StatusCode::NOT_FOUND)
}

async fn export_audit_bundle(
    Path(operator_id): Path<String>,
    Query(query): Query<TransitionQuery>,
    State(state): State<Arc<AuditState>>,
) -> Result<Json<AuditBundleMetadata>, StatusCode> {
    let bridge = state.bridge.lock().await;
    let from = query.from.unwrap_or(DateTime::<Utc>::MIN_UTC);
    let to = query.to.unwrap_or(DateTime::<Utc>::MAX_UTC);
    let zip_bytes = bridge.export_audit_bundle(&operator_id, from, to, &state.signing_key)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    use sha2::{Sha256, Digest};
    let bundle_hash = hex::encode(Sha256::digest(&zip_bytes));
    let signature = state.signing_key.sign_prehash_recoverable(Sha256::digest(bundle_hash.as_bytes()).as_ref())
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    let signature_hex = hex::encode(signature.0.to_bytes());
    let count = bridge.get_transitions(&operator_id, from, to).len();
    Ok(Json(AuditBundleMetadata { operator_id, from, to, witness_count: count, bundle_hash, signature: signature_hex }))
}

// ---- New Ṛta endpoints ----
async fn get_rta_health(
    Path(operator_id): Path<String>,
    State(state): State<Arc<AuditState>>,
) -> Result<Json<RtaHealth>, StatusCode> {
    let bridge = state.bridge.lock().await;
    let health = bridge.get_current_rta_health(&operator_id)
        .ok_or(StatusCode::NOT_FOUND)?;
    Ok(Json(health))
}

async fn get_rta_history(
    Path(operator_id): Path<String>,
    Query(query): Query<TransitionQuery>,
    State(state): State<Arc<AuditState>>,
) -> Json<Vec<RtaHealth>> {
    let bridge = state.bridge.lock().await;
    let history = bridge.get_rta_history(
        &operator_id,
        query.from.unwrap_or(DateTime::<Utc>::MIN_UTC),
        query.to.unwrap_or(DateTime::<Utc>::MAX_UTC),
    );
    Json(history)
}

#[derive(Serialize)]
pub struct LanglandsDistanceResponse {
    pub operator_id: String,
    pub l_dist_to_bindu: f64,
    pub timestamp: u64,
}

async fn get_rta_langlands(
    Path(operator_id): Path<String>,
    State(state): State<Arc<AuditState>>,
) -> Result<Json<LanglandsDistanceResponse>, StatusCode> {
    let bridge = state.bridge.lock().await;
    let health = bridge.get_current_rta_health(&operator_id)
        .ok_or(StatusCode::NOT_FOUND)?;
    Ok(Json(LanglandsDistanceResponse {
        operator_id,
        l_dist_to_bindu: health.l_dist_to_bindu,
        timestamp: health.timestamp,
    }))
}

pub fn audit_router(state: Arc<AuditState>) -> Router {
    Router::new()
        .route("/audit/v1/:operator_id/transitions", get(list_transitions))
        .route("/audit/v1/:operator_id/witness/:transform_id/proof", get(get_witness_proof))
        .route("/audit/v1/:operator_id/export", axum::routing::post(export_audit_bundle))
        .route("/audit/v1/:operator_id/rta/health", get(get_rta_health))
        .route("/audit/v1/:operator_id/rta/history", get(get_rta_history))
        .route("/audit/v1/:operator_id/rta/langlands", get(get_rta_langlands))
        .with_state(state)
}
