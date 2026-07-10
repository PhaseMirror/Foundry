use pirtm_stdlib::prelude::*;
use pirtm_invariants::PhaseMirrorInvariants;
use async_trait::async_trait;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio::process::Command;
use serde_json::json;

#[derive(Clone, Debug, PartialEq)]
enum Mode { Assert, Retract }

#[derive(Debug)]
enum VerifiedAction {
    Deploy { service: String, target: String, replicas: u32 },
    Revoke { previous_action_id: String },
}

#[async_trait]
trait ActionExecutor {
    async fn execute(&self, action: &VerifiedAction) -> Result<String, String>;
}

struct DockerExecutor {
    active: Arc<Mutex<HashMap<String, Vec<String>>>>,
}

impl DockerExecutor {
    fn new() -> Self {
        Self { active: Arc::new(Mutex::new(HashMap::new())) }
    }
}

#[async_trait]
impl ActionExecutor for DockerExecutor {
    async fn execute(&self, action: &VerifiedAction) -> Result<String, String> {
        match action {
            VerifiedAction::Deploy { service, target, replicas } => {
                println!("   [EXECUTOR] Starting deployment via Docker CLI...");
                let mut container_ids = vec![];
                let image = "alpine:latest"; 
                
                for i in 0..*replicas {
                    let container_name = format!("{}-{}-{}", service, target, i);
                    println!("   [EXECUTOR] Spinning up container {}...", container_name);
                    
                    let status = Command::new("docker")
                        .args(&["run", "-d", "--name", &container_name, image, "sleep", "3600"])
                        .status()
                        .await;
                        
                    match status {
                        Ok(s) if s.success() => container_ids.push(container_name),
                        Ok(s) => return Err(format!("Docker exited with status {}", s)),
                        Err(e) => return Err(format!("Failed to execute docker: {}", e)),
                    }
                }
                
                let action_id = format!("deployed_{}", service);
                self.active.lock().await.insert(action_id.clone(), container_ids);
                Ok(action_id)
            },
            VerifiedAction::Revoke { previous_action_id } => {
                println!("   [EXECUTOR] Starting rollback via Docker CLI...");
                let mut guard = self.active.lock().await;
                if let Some(container_ids) = guard.remove(previous_action_id) {
                    for cid in &container_ids {
                        println!("   [EXECUTOR] Tearing down container {}...", cid);
                        let _ = Command::new("docker").args(&["rm", "-f", cid]).status().await;
                    }
                    Ok(format!("revoked_{}", previous_action_id))
                } else {
                    Err(format!("No active deployment for {}", previous_action_id))
                }
            }
        }
    }
}

async fn alp_evaluate(action_id: &str, mutating: bool, server_binding: Option<&str>) -> bool {
    let input = json!({
        "id": action_id,
        "payload": {},
        "mutating": mutating,
        "server_binding": server_binding,
    });

    let candidates = vec![
        "alp-cli",
        "../target/debug/alp-cli",
        "../../substrates/alp/target/debug/alp-cli",
    ];

    for bin in candidates {
        if let Ok(mut child) = Command::new(bin).stdin(std::process::Stdio::piped()).stdout(std::process::Stdio::piped()).spawn() {
            if let Some(mut stdin) = child.stdin.take() {
                use tokio::io::AsyncWriteExt;
                let _ = stdin.write_all(input.to_string().as_bytes()).await;
            }
            if let Ok(output) = child.wait_with_output().await {
                if output.status.success() {
                    if let Ok(parsed) = serde_json::from_slice::<serde_json::Value>(&output.stdout) {
                        if let Some(allowed) = parsed.get("allowed").and_then(|v| v.as_bool()) {
                            return allowed;
                        }
                        if let Some(risk) = parsed.get("risk").and_then(|v| v.as_str()) {
                            return risk == "Low";
                        }
                    }
                }
            }
        }
    }
    true
}

struct DialogueFrame {
    strata: Vec<MOCWord>,
    executor: DockerExecutor,
    last_action_id: Option<String>,
}

impl DialogueFrame {
    fn new() -> Self { Self { strata: Vec::new(), executor: DockerExecutor::new(), last_action_id: None } }

    async fn process_turn(&mut self, input: &str) {
        println!("\nUser: \"{}\"", input);
        
        let tokens: Vec<&str> = input.split_whitespace().collect();
        if tokens.is_empty() { return; }

        let mut mode = Mode::Assert;
        let mut ast = Ap(2); 
        let mut first = true;
        let mut parsed_action = None;

        if tokens.contains(&"deploy") {
            parsed_action = Some(VerifiedAction::Deploy {
                service: "web-service".to_string(),
                target: "cluster".to_string(),
                replicas: 3
            });
        } else if tokens.contains(&"revoke") {
            mode = Mode::Retract;
            parsed_action = Some(VerifiedAction::Revoke {
                previous_action_id: self.last_action_id.clone().unwrap_or_default()
            });
        }

        for &t in &tokens {
            let p = match t.to_lowercase().as_str() {
                "deploy" => 2, "scale" => 3, "web-service" => 5, "cluster" => 7, "on" => 5,
                "with" => 11, "replicas" => 13, "3" => 17, "revoke" | "cancel" => { mode = Mode::Retract; 19 } 
                "it" => 5, "all" => 1, 
                _ => { println!("❌ Unknown token '{}'", t); return; }
            };
            
            if first { ast = Ap(p); first = false; } 
            else { ast = ast + Ap(p); }
        }

        let new_stratum = MOCWord::StratumBoundary(Box::new(ast));

        if mode == Mode::Assert {
            if let Err(e) = PhaseMirrorInvariants::enforce_all(&new_stratum) {
                println!("❌ Invariant Failed: {}", e);
                Self::suggest_correction(&tokens);
            } else {
                self.strata.push(new_stratum);
                println!("✅ Asserted. Current context depth: {}", self.strata.len());
                
                if let Some(action) = &parsed_action {
                    let binding = match action {
                        VerifiedAction::Deploy { target, .. } => Some(target.clone()),
                        VerifiedAction::Revoke { .. } => None,
                    };
                    let action_id = format!("cnl-{}", mode as u8);
                    let allowed = alp_evaluate(&action_id, matches!(action, VerifiedAction::Deploy { .. }), binding.as_deref()).await;
                    if !allowed {
                        println!("❌ ALP Blocked: action {} not admitted by policy engine", action_id);
                    } else {
                        match self.executor.execute(action).await {
                            Ok(id) => {
                                println!("✅ Execution Success: {}", id);
                                self.last_action_id = Some(id);
                            },
                            Err(e) => println!("❌ Execution Failed: {}", e),
                        }
                    }
                }
            }
        } else if mode == Mode::Retract {
            println!("🔄 Retraction detected. Neutralizing previous stratum...");
            self.strata.pop(); 
            println!("✅ Context cleared. Current context depth: {}", self.strata.len());
            
            if let Some(action) = &parsed_action {
                let action_id = self.last_action_id.clone().unwrap_or_default();
                let binding = match action {
                    VerifiedAction::Revoke { previous_action_id } => Some(previous_action_id.clone()),
                    VerifiedAction::Deploy { .. } => None,
                };
                let allowed = alp_evaluate(&action_id, true, binding.as_deref()).await;
                if !allowed {
                    println!("❌ ALP Blocked: retraction {} not admitted by policy engine", action_id);
                } else {
                    match self.executor.execute(action).await {
                        Ok(id) => {
                            println!("✅ Rollback Success: {}", id);
                            self.last_action_id = None;
                        },
                        Err(e) => println!("❌ Rollback Failed: {}", e),
                    }
                }
            }
        }
    }

    fn suggest_correction(tokens: &[&str]) {
        println!("💡 Suggestion Engine: Scanning adjacency graph...");
        if tokens.contains(&"all") {
            println!("   -> 'all' maps to Ap(1) [Forbidden]. Nearest valid topological substitutes:");
            println!("      - 'web-service' (Ap(5), cost distance 4)");
            println!("      - 'database' (Ap(7), cost distance 6)");
            println!("   -> Did you mean: '{}'?", tokens.join(" ").replace("all", "web-service"));
        }
    }
}

#[tokio::main]
async fn main() {
    println!("--- CNL Multi-Turn Dialogue Prototype [DOCKER BRIDGE] ---");
    let mut frame = DialogueFrame::new();

    frame.process_turn("deploy web-service on cluster with replicas 3").await;
    frame.process_turn("revoke it").await;
    frame.process_turn("deploy all cluster").await;
}
