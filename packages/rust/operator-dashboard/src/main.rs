use leptos::*;
use wasm_bridge::WasmSigmaKernel;

#[component]
fn App() -> impl IntoView {
    let (status, set_status) = create_signal("IDLE".to_string());
    let (witness_json, set_witness_json) = create_signal("".to_string());

    let trigger_evaluation = move |_| {
        set_status.set("EVALUATING...".to_string());
        
        let kernel = WasmSigmaKernel::new(47.06998778, 1.0);
        let transition_payload = r#"{"id": "tx-108", "r_sc": 47.06998778, "l_eff": 0.15}"#;
        
        match kernel.evaluate_and_sign(transition_payload, "operator-key", "kernel-key") {
            Ok(witness) => {
                set_status.set("LOCKED & WITNESSED".to_string());
                set_witness_json.set(witness);
            },
            Err(err) => {
                set_status.set(format!("ERROR: {:?}", err.as_string().unwrap_or_default()));
                set_witness_json.set("".to_string());
            }
        }
    };

    let sync_crdt = move |_| {
        set_status.set("SYNCING SWARM CRDT...".to_string());
        // Mocking a successful distributed merge state across agents
        set_timeout(move || {
            set_status.set("SWARM SYNC COMPLETE".to_string());
        }, std::time::Duration::from_millis(800));
    };

    view! {
        <div class="glass-panel" style="max-width: 800px; width: 100%;">
            <h1>"PhaseSpace OS | Operator Zero"</h1>
            <h2 class=move || {
                if status.get().starts_with("ERROR") {
                    "error"
                } else if status.get() == "LOCKED & WITNESSED" {
                    "success"
                } else {
                    ""
                }
            }>
                {status}
            </h2>
            
            <div style="margin-top: 24px; display: flex; gap: 16px;">
                <button class="btn" on:click=trigger_evaluation>
                    "Evaluate Transition (WASM)"
                </button>
                <button class="btn" style="background: #10b981;" on:click=sync_crdt>
                    "Sync Swarm CRDT"
                </button>
            </div>
            
            <div style="margin-top: 32px; display: grid; grid-template-columns: 1fr 1fr; gap: 24px;">
                <div>
                    <h3 class="metrics">"Runtime Telemetry"</h3>
                    <p>"τ_R Threshold: 47.0699"</p>
                    <p>"L_eff Upper Bound: 1.0"</p>
                    <p>"WASM Opt Payload: 157 KB"</p>
                </div>
                <div>
                    <h3 class="metrics">"Active Swarm Topology"</h3>
                    <p>"🟢 Agent A (Leader) - Term 42"</p>
                    <p>"🟢 Agent B (Follower) - Term 42"</p>
                    <p>"🔴 Agent C (Offline)"</p>
                </div>
            </div>
            
            <Show when=move || !witness_json.get().is_empty() fallback=|| view! { <div></div> }>
                <div style="margin-top: 24px; padding: 12px; background: #1e293b; border-radius: 4px;">
                    <code>{witness_json}</code>
                </div>
            </Show>
        </div>
    }
}

fn main() {
    mount_to_body(|| view! { <App/> })
}
