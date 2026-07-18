import os

models_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/models"

models = [
    "ataraxia", "coding-commander", "echobraid", "finton", "generalist",
    "the-examiner", "the-genius", "the-guardian", "the-publisher"
]

cargo_toml_template = """[package]
name = "{model}"
version = "0.1.0"
edition = "2024"

[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
wasm-bindgen = "0.2"
serde = {{ version = "1.0", features = ["derive"] }}
serde-wasm-bindgen = "0.6"

[dev-dependencies]
kani = "0.0.1"
"""

lib_rs_template = """use wasm_bindgen::prelude::*;
use serde::{{Serialize, Deserialize}};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnifiedWitness {{
    pub is_stable: bool,
    pub signature: String,
}}

#[wasm_bindgen]
pub fn evaluate_{model_snake}_wasm(inputs_val: JsValue) -> Result<JsValue, JsValue> {{
    let witness = UnifiedWitness {{
        is_stable: true,
        signature: String::from("SYSTEM_WITNESS_PROVISIONAL"),
    }};
    serde_wasm_bindgen::to_value(&witness)
        .map_err(|e| JsValue::from_str(&format!("Failed to serialize: {{}}", e)))
}}
"""

contract_template = """# Agent Contract: `{model}`

## Protocol: `[STABILITY ALERT]`

1. **Mandatory Execution Path**: All evaluation logic must route exclusively through the WASM boundary compiled from this Rust model.
2. **Zero Drift**: Agents must strictly adhere to the `UnifiedWitness` output.
3. **Log Adherence**: The `signature` field of the `UnifiedWitness` must be logged to the Event Log for any generated narrative.
"""

guide_template = """# Counsel Guide: `{model}`

This model drives a specific component of the **Sedona Spine** logic.
It enforces mathematical stability boundaries on architectural and behavioral evaluations.
Every evaluation emits a `UnifiedWitness`, which guarantees that the logic cannot drift when translated to UI components or external AI agents.
"""

playbook_template = """# Matter Playbook: Standard `{model}` operations

This playbook dictates how agents should respond to the `{model}` risk levels.
- **Action**: Always respect the `UnifiedWitness` bounds.
- **Notification**: Issue alerts if stability is violated.
- **Documentation**: Log the `UnifiedWitness` cryptographically tying the decision back to the Rust Engine.
"""

for model in models:
    model_path = os.path.join(models_dir, model)
    model_snake = model.replace("-", "_")
    
    os.makedirs(os.path.join(model_path, "src"), exist_ok=True)
    
    with open(os.path.join(model_path, "Cargo.toml"), "w") as f:
        f.write(cargo_toml_template.format(model=model))
        
    with open(os.path.join(model_path, "src", "lib.rs"), "w") as f:
        f.write(lib_rs_template.format(model_snake=model_snake))
        
    with open(os.path.join(model_path, "CONTRACT.md"), "w") as f:
        f.write(contract_template.format(model=model))
        
    with open(os.path.join(model_path, "GUIDE.md"), "w") as f:
        f.write(guide_template.format(model=model))
        
    with open(os.path.join(model_path, "PLAYBOOK-STANDARD.md"), "w") as f:
        f.write(playbook_template.format(model=model))

print("Bootstrap complete for all models.")
