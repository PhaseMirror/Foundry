use kube::{
    api::{Api},
    runtime::{
        controller::{Action, Controller},
        watcher::Config,
    },
    Client, CustomResource,
};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::info;
use futures::StreamExt;

mod reconciler;
use reconciler::{reconcile, PhaseMirrorContext};

mod ws_broadcast;
use ws_broadcast::{OperatorState, OperatorEvent};

#[derive(CustomResource, Deserialize, Serialize, Clone, Debug, JsonSchema)]
#[kube(
    kind = "PhaseMirrorCommand",
    group = "phase-mirror.io",
    version = "v1",
    namespaced,
    status = "PhaseMirrorStatus",
    shortname = "pmc"
)]
pub struct PhaseMirrorSpec {
    pub command: String,
    #[serde(default, rename = "governanceMode")]
    pub governance_mode: Option<String>,
    #[serde(default)]
    pub lexicon: Option<String>,
    #[serde(default)]
    pub consensus_witness: Option<ConsensusWitness>,
    #[serde(default)]
    pub execution_target: Option<String>,
}

#[derive(Deserialize, Serialize, Clone, Debug, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub struct ConsensusWitness {
    pub unified_witness: Option<String>,
    pub consensus_proof: Option<String>,
}

#[derive(Deserialize, Serialize, Clone, Debug, JsonSchema, Default)]
#[serde(rename_all = "camelCase")]
pub struct PhaseMirrorStatus {
    pub phase: Option<String>,
    pub message: Option<String>,
    pub c_bound: Option<f64>,
    pub rsc: Option<f64>,
    pub execution_receipt: Option<String>,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();
    
    let ws_port = std::env::var("WS_PORT").unwrap_or_else(|_| "3030".to_string()).parse().unwrap();
    let ws_state = ws_broadcast::start_ws_server(ws_port).await;

    let client = Client::try_default().await?;
    let crd_api: Api<PhaseMirrorCommand> = Api::all(client.clone());

    let context = Arc::new(PhaseMirrorContext::new(ws_state).await?);

    info!("Starting PhaseMirror Operator");

    Controller::new(crd_api, Config::default())
        .run(reconcile, error_policy, context)
        .for_each(|res| async move {
            match res {
                Ok(o) => info!("Reconciled: {:?}", o),
                Err(e) => tracing::error!("Reconciliation error: {:?}", e),
            }
        })
        .await;

    Ok(())
}

fn error_policy(
    _object: Arc<PhaseMirrorCommand>,
    _err: &kube::Error,
    _ctx: Arc<PhaseMirrorContext>,
) -> Action {
    Action::requeue(std::time::Duration::from_secs(10))
}
