use crate::{PhaseMirrorCommand, PhaseMirrorStatus, ConsensusWitness};
use anyhow::{Context, Result, anyhow};
use kube::{
    api::{Api, DeleteParams, PostParams, ResourceExt},
    runtime::controller::Action,
    Client,
};
use pirtm_apps::cnl::{compile_command, CompilationResult, VerifiedAction as CnlVerifiedAction};
use std::sync::Arc;
use tracing::{info, error};

// --- Consensus Verifier ---
// In production, this wraps commander-core::ConsensusVerifier.
// For now, it is a stub to satisfy the operator structure without
// requiring the full commander-core workspace graph.
pub struct ConsensusVerifier;

impl ConsensusVerifier {
    pub fn new() -> Self {
        Self
    }

    pub async fn verify_consensus(
        &self,
        _unified: &serde_json::Value,
        _proof: Option<&[u8]>,
    ) -> Result<bool> {
        Ok(true)
    }
}

// --- Execution Mapper ---
pub enum K8sAction {
    Deploy {
        service: String,
        target: String,
        replicas: u32,
    },
    Scale {
        name: String,
        replicas: u32,
    },
    Destroy {
        name: String,
    },
    Revoke {
        target_action_id: String,
    },
}

impl From<CnlVerifiedAction> for K8sAction {
    fn from(action: CnlVerifiedAction) -> Self {
        match action {
            CnlVerifiedAction::Deploy {
                service,
                target,
                replicas,
            } => K8sAction::Deploy {
                service,
                target,
                replicas,
            },
            CnlVerifiedAction::Scale { service, replicas } => K8sAction::Scale {
                name: service,
                replicas,
            },
            CnlVerifiedAction::Destroy { service } => K8sAction::Destroy { name: service },
            CnlVerifiedAction::Revoke { previous_action_id } => {
                K8sAction::Revoke {
                    target_action_id: previous_action_id,
                }
            }
        }
    }
}

use crate::ws_broadcast::{OperatorState, OperatorEvent};

pub struct PhaseMirrorContext {
    pub client: Client,
    pub consensus_verifier: ConsensusVerifier,
    pub ws_state: Arc<OperatorState>,
}

impl PhaseMirrorContext {
    pub async fn new(ws_state: Arc<OperatorState>) -> Result<Self> {
        let client = Client::try_default().await?;
        let consensus_verifier = ConsensusVerifier::new();
        Ok(PhaseMirrorContext {
            client,
            consensus_verifier,
            ws_state,
        })
    }
}

pub async fn reconcile(
    pmc: Arc<PhaseMirrorCommand>,
    ctx: Arc<PhaseMirrorContext>,
) -> Result<Action, kube::Error> {
    if let Some(ref status) = pmc.status {
        if let Some(phase) = &status.phase {
            if matches!(
                phase.as_str(),
                "Succeeded" | "Failed" | "Vetoed" | "Executing"
            ) {
                return Ok(Action::await_change());
            }
        }
    }

    let command = pmc.spec.command.clone();
    let namespace = pmc.namespace().unwrap_or_else(|| "default".to_string());
    let governance_mode = pmc
        .spec
        .governance_mode
        .clone()
        .unwrap_or_else(|| "permissive".to_string());

    info!(%command, %namespace, ?governance_mode, "Reconciling PhaseMirrorCommand");

    let _ = ctx.ws_state.emit(OperatorEvent::UserInput { text: command.clone() });

    // 1. Compile CNL command using real compiler
    let compilation = {
        let cmd = command.clone();
        tokio::task::spawn_blocking(move || compile_command(&cmd))
            .await
            .unwrap()
            .map_err(|e| anyhow!("CNL compilation error: {}", e))?
    };

    let _ = ctx.ws_state.emit(OperatorEvent::Compiled {
        mocword: format!("{:?}", compilation.moc_word),
        c: compilation.c,
        rsc: compilation.rsc,
    });

    // 2. Enforce Phase Mirror invariants
    if !compilation.invariants_passed() {
        let _ = ctx.ws_state.emit(OperatorEvent::InvariantFail {
            diagnostic: compilation.diagnostic.clone().unwrap_or_default(),
            suggestion: "Try a specific object instead of 'all'".into(),
        });

        let suggestion = compile_command(&command)
            .ok()
            .and_then(|r| {
                r.verified_action.ok().and_then(|_| {
                    pirtm_apps::cnl::suggest_correction(
                        &command.split_whitespace().collect::<Vec<&str>>(),
                    )
                    .get(0)
                    .cloned()
                })
            })
            .unwrap_or_default();

        let message = if suggestion.is_empty() {
            format!(
                "Invariant violation: {}",
                compilation.diagnostic.unwrap_or_default()
            )
        } else {
            format!(
                "Invariant violation: {} | Suggestion: {}",
                compilation.diagnostic.unwrap_or_default(),
                suggestion
            )
        };

        let status = PhaseMirrorStatus {
            phase: Some("Failed".into()),
            message: Some(message),
            c_bound: Some(compilation.c),
            rsc: Some(compilation.rsc),
            execution_receipt: None,
        };
        update_status(&ctx.client, &pmc, status).await?;
        return Ok(Action::await_change());
    }

    // 3. Consensus verification (strict mode)
    if governance_mode == "strict" {
        let witness_data = pmc.spec.consensus_witness.as_ref()
            .ok_or_else(|| anyhow!("Strict governance mode requires consensusWitness"))?;
        let unified: serde_json::Value = serde_json::from_str(
            witness_data.unified_witness.as_deref().unwrap_or("{}")
        )?;
        let proof_bytes = witness_data.consensus_proof.as_deref()
            .map(hex::decode)
            .transpose()?;

        let valid = ctx.consensus_verifier.verify_consensus(&unified, proof_bytes.as_deref())
            .await?;
        if !valid {
            let status = PhaseMirrorStatus {
                phase: Some("Vetoed".into()),
                message: Some("Consensus proof invalid or threshold not met".into()),
                c_bound: Some(compilation.c),
                rsc: Some(compilation.rsc),
                execution_receipt: None,
            };
            update_status(&ctx.client, &pmc, status).await?;
            return Ok(Action::await_change());
        }
    }

    // 4. Map to K8s action and execute
    let k8s_action = match compilation.verified_action {
        Ok(ref action) => K8sAction::from(action.clone()),
        Err(ref e) => {
            let status = PhaseMirrorStatus {
                phase: Some("Failed".into()),
                message: Some(format!("Action mapping failed: {}", e)),
                c_bound: Some(compilation.c),
                rsc: Some(compilation.rsc),
                execution_receipt: None,
            };
            update_status(&ctx.client, &pmc, status).await?;
            return Ok(Action::await_change());
        }
    };

    let _ = ctx.ws_state.emit(OperatorEvent::ExecStart {
        action: format!("{:?}", k8s_action),
    });

    match execute_k8s_action(&ctx.client, &k8s_action, &namespace).await {
        Ok(receipt) => {
            let event = match k8s_action {
                K8sAction::Revoke { ref target_action_id } => OperatorEvent::Rollback {
                    action_id: target_action_id.clone(),
                    result: receipt.clone(),
                },
                _ => OperatorEvent::ExecSuccess {
                    action_id: receipt.clone(),
                    message: "Command executed".into(),
                },
            };
            let _ = ctx.ws_state.emit(event);

            let status = PhaseMirrorStatus {
                phase: Some("Succeeded".into()),
                message: Some("Command executed successfully".into()),
                c_bound: Some(compilation.c),
                rsc: Some(compilation.rsc),
                execution_receipt: Some(receipt),
            };
            update_status(&ctx.client, &pmc, status).await?;
        }
        Err(e) => {
            let _ = ctx.ws_state.emit(OperatorEvent::ExecFailure {
                error: format!("{}", e),
            });
            error!(?e, "Execution failed");

            let status = PhaseMirrorStatus {
                phase: Some("Failed".into()),
                message: Some(format!("Execution error: {:#}", e)),
                c_bound: Some(compilation.c),
                rsc: Some(compilation.rsc),
                execution_receipt: None,
            };
            update_status(&ctx.client, &pmc, status).await?;
        }
    }

    Ok(Action::await_change())
}

async fn update_status(
    client: &Client,
    pmc: &PhaseMirrorCommand,
    status: PhaseMirrorStatus,
) -> Result<()> {
    let crd_api: Api<PhaseMirrorCommand> =
        Api::namespaced(client.clone(), &pmc.namespace().unwrap_or_default());
    let mut latest = crd_api.get(&pmc.name_any()).await?;
    latest.status = Some(status);
    crd_api.replace_status(
        &pmc.name_any(),
        &PostParams::default(),
        serde_json::to_vec(&latest)?,
    )
    .await?;
    Ok(())
}

async fn execute_k8s_action(
    client: &Client,
    action: &K8sAction,
    namespace: &str,
) -> Result<String> {
    match action {
        K8sAction::Deploy {
            service,
            target,
            replicas,
        } => {
            let deployment = serde_json::json!({
                "apiVersion": "apps/v1",
                "kind": "Deployment",
                "metadata": {
                    "name": format!("{}-{}", service, target),
                    "namespace": namespace,
                    "labels": {
                        "phase-mirror.io/managed": "true",
                        "phase-mirror.io/action-id": format!("deployed_{}", service)
                    }
                },
                "spec": {
                    "replicas": replicas,
                    "selector": {
                        "matchLabels": { "app": service }
                    },
                    "template": {
                        "metadata": { "labels": { "app": service } },
                        "spec": {
                            "containers": [{
                                "name": service,
                                "image": "alpine:latest",
                                "command": ["sleep", "infinity"]
                            }]
                        }
                    }
                }
            });

            let deployments: Api<k8s_openapi::api::apps::v1::Deployment> =
                Api::namespaced(client.clone(), namespace);
            let params = PostParams::default();
            deployments
                .create(&params, &serde_json::from_value(deployment)?)
                .await?;

            Ok(format!("deployed_{}", service))
        }
        K8sAction::Scale { name, replicas } => {
            let deployments: Api<k8s_openapi::api::apps::v1::Deployment> =
                Api::namespaced(client.clone(), namespace);
            let mut patch = serde_json::Map::new();
            let mut spec = serde_json::Map::new();
            let mut replicas_map = serde_json::Map::new();
            replicas_map.insert("replicas".to_string(), serde_json::json!(replicas));
            spec.insert("spec".to_string(), serde_json::Value::Object(replicas_map));
            patch.insert("spec".to_string(), serde_json::Value::Object(spec));

            deployments
                .patch(name, &PostParams::default(), &serde_json::Value::Object(patch))
                .await?;

            Ok(format!("scaled_{}", name))
        }
        K8sAction::Destroy { name } => {
            let deployments: Api<k8s_openapi::api::apps::v1::Deployment> =
                Api::namespaced(client.clone(), namespace);
            deployments
                .delete(name, &DeleteParams::default())
                .await?;

            Ok(format!("destroyed_{}", name))
        }
        K8sAction::Revoke { target_action_id } => {
            let deployments: Api<k8s_openapi::api::apps::v1::Deployment> =
                Api::namespaced(client.clone(), namespace);

            if let Some(name) = target_action_id.strip_prefix("deployed_") {
                let _ = deployments
                    .delete(name, &DeleteParams::default())
                    .await
                    .ok();
            }

            Ok(format!("revoked_{}", target_action_id))
        }
    }
}
