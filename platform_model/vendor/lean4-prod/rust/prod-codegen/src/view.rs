//! Closed Foundation.View.V1 projections for Hologram intent and browsers.

use alloc::collections::BTreeSet;
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;
use sha2::{Digest, Sha256};

use crate::{Error, GeneratedPackage, PackageFile};

/// One modeled operation option. `rust_variant` is validated as an identifier
/// before it is used in the generated adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ViewOperation {
    pub label: String,
    pub request_name: String,
    pub rust_variant: String,
    pub discriminant: u8,
}

/// Closed, evaluated value exported from `Foundation.View.V1`.
///
/// There is deliberately no raw HTML, CSS, JavaScript, URL, or callback field.
/// The target owns escaping, DOM construction, behavior, and transport.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EvaluatedViewV1 {
    pub title: String,
    pub heading: String,
    pub left_label: String,
    pub right_label: String,
    pub operation_label: String,
    pub submit_label: String,
    pub input_error: String,
    pub division_by_zero_error: String,
    pub overflow_error: String,
    pub operations: Vec<ViewOperation>,
    pub initial_operation: u8,
    pub model_id: String,
    pub view_model_id: String,
    pub generated_core_sha256: String,
}

/// Registry dependency and public generated-core names for the Pages adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BrowserAdapterBinding {
    pub package_name: String,
    pub package_version: String,
    pub core_crate_name: String,
    pub core_crate_version: String,
    pub core_operation_type: String,
    pub core_error_type: String,
    pub core_function: String,
}

/// Both deterministic View projections and the separate wasm-bindgen adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GeneratedViewV1 {
    pub hologram_assets: Vec<PackageFile>,
    /// Canonical Hologram `HOLOVIEW` v1 payload for `hologram_assets`.
    pub hologram_bundle: PackageFile,
    pub browser_assets: Vec<PackageFile>,
    pub browser_adapter: GeneratedPackage,
    pub view_manifest: PackageFile,
}

fn file(path: &str, text: String) -> PackageFile {
    PackageFile {
        path: path.to_string(),
        bytes: text.into_bytes(),
    }
}

fn sha256(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}

fn write_u32(output: &mut Vec<u8>, value: usize, description: &str) -> Result<(), Error> {
    let value = u32::try_from(value)
        .map_err(|_| Error::OpaqueType(format!("{description} exceeds HOLOVIEW v1")))?;
    output.extend_from_slice(&value.to_be_bytes());
    Ok(())
}

/// Encode the exact Hologram portable-View v1 bundle for an ordered asset set.
pub fn generate_holoview_bundle(files: &[PackageFile]) -> Result<PackageFile, Error> {
    if files.is_empty()
        || files.len() > 4_096
        || !files.iter().any(|file| file.path == "index.html")
    {
        return Err(Error::OpaqueType(
            "invalid HOLOVIEW v1 file set".to_string(),
        ));
    }
    let mut previous: Option<&str> = None;
    let mut folded = BTreeSet::new();
    let mut total = 0_u64;
    for item in files {
        let valid_path = !item.path.is_empty()
            && item.path.len() <= 1_024
            && item.path.split('/').all(|component| {
                !component.is_empty()
                    && component != "."
                    && component != ".."
                    && !component.ends_with('.')
                    && component.bytes().all(|byte| {
                        byte.is_ascii_alphanumeric() || matches!(byte, b'-' | b'_' | b'.')
                    })
            });
        let length = u64::try_from(item.bytes.len())
            .map_err(|_| Error::OpaqueType("HOLOVIEW asset is too large".to_string()))?;
        total = total
            .checked_add(length)
            .ok_or_else(|| Error::OpaqueType("HOLOVIEW size overflow".to_string()))?;
        if !valid_path
            || previous.is_some_and(|value| value >= item.path.as_str())
            || !folded.insert(item.path.to_ascii_lowercase())
            || length > 64 * 1_024 * 1_024
            || total > 256 * 1_024 * 1_024
        {
            return Err(Error::OpaqueType(
                "noncanonical HOLOVIEW v1 file set".to_string(),
            ));
        }
        previous = Some(&item.path);
    }

    let mut bytes = Vec::new();
    bytes.extend_from_slice(b"HOLOVIEW");
    bytes.extend_from_slice(&1_u16.to_be_bytes());
    write_u32(&mut bytes, "index.html".len(), "HOLOVIEW entry")?;
    bytes.extend_from_slice(b"index.html");
    write_u32(&mut bytes, files.len(), "HOLOVIEW file count")?;
    for item in files {
        write_u32(&mut bytes, item.path.len(), "HOLOVIEW path")?;
        bytes.extend_from_slice(item.path.as_bytes());
        bytes.extend_from_slice(&(item.bytes.len() as u64).to_be_bytes());
        bytes.extend_from_slice(&item.bytes);
    }
    Ok(PackageFile {
        path: "view.holoview".to_string(),
        bytes,
    })
}

fn valid_ident(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= 128
        && value.bytes().enumerate().all(|(index, byte)| {
            byte.is_ascii_alphabetic() || byte == b'_' || (index > 0 && byte.is_ascii_digit())
        })
}

fn valid_package(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= 64
        && value.bytes().all(|byte| {
            byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'-' || byte == b'_'
        })
        && value.as_bytes()[0].is_ascii_lowercase()
}

fn valid_version(value: &str) -> bool {
    let fields: Vec<&str> = value.split('.').collect();
    fields.len() == 3
        && fields.iter().all(|field| {
            !field.is_empty()
                && field.bytes().all(|byte| byte.is_ascii_digit())
                && (*field == "0" || !field.starts_with('0'))
        })
}

fn valid_digest(value: &str) -> bool {
    value.len() == 64
        && value
            .bytes()
            .all(|byte| byte.is_ascii_hexdigit() && !byte.is_ascii_uppercase())
}

fn html(value: &str) -> String {
    let mut out = String::new();
    for character in value.chars() {
        match character {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            '\'' => out.push_str("&#39;"),
            other => out.push(other),
        }
    }
    out
}

fn json(value: &str) -> String {
    let mut out = String::from("\"");
    for character in value.chars() {
        match character {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            value if value < ' ' => out.push_str(&format!("\\u{:04x}", value as u32)),
            other => out.push(other),
        }
    }
    out.push('"');
    out
}

fn validate(view: &EvaluatedViewV1, binding: &BrowserAdapterBinding) -> Result<(), Error> {
    if view.title.is_empty()
        || view.heading.is_empty()
        || view.operations.is_empty()
        || view.operations.len() > 256
        || !valid_digest(&view.generated_core_sha256)
        || !valid_digest(&view.model_id)
        || !valid_digest(&view.view_model_id)
    {
        return Err(Error::OpaqueType(
            "invalid evaluated Foundation.View.V1 value".to_string(),
        ));
    }
    if !valid_package(&binding.package_name)
        || !valid_package(&binding.core_crate_name)
        || !valid_version(&binding.package_version)
        || !valid_version(&binding.core_crate_version)
        || !valid_ident(&binding.core_operation_type)
        || !valid_ident(&binding.core_error_type)
        || !valid_ident(&binding.core_function)
    {
        return Err(Error::OpaqueType(
            "invalid browser adapter binding".to_string(),
        ));
    }
    let mut labels = BTreeSet::new();
    let mut names = BTreeSet::new();
    let mut variants = BTreeSet::new();
    let mut discriminants = BTreeSet::new();
    for operation in &view.operations {
        if operation.label.is_empty()
            || operation.request_name.is_empty()
            || !operation
                .request_name
                .bytes()
                .all(|byte| byte.is_ascii_lowercase() || byte == b'-')
            || !valid_ident(&operation.rust_variant)
            || !labels.insert(&operation.label)
            || !names.insert(&operation.request_name)
            || !variants.insert(&operation.rust_variant)
            || !discriminants.insert(operation.discriminant)
        {
            return Err(Error::OpaqueType(
                "invalid or duplicate View operation".to_string(),
            ));
        }
    }
    if !discriminants.contains(&view.initial_operation) {
        return Err(Error::OpaqueType(
            "initial View operation is absent".to_string(),
        ));
    }
    Ok(())
}

fn index_html(view: &EvaluatedViewV1) -> String {
    let options = view
        .operations
        .iter()
        .map(|operation| {
            let selected = if operation.discriminant == view.initial_operation {
                " selected"
            } else {
                ""
            };
            format!(
                "<option value=\"{}\" data-request=\"{}\"{}>{}</option>",
                operation.discriminant,
                html(&operation.request_name),
                selected,
                html(&operation.label)
            )
        })
        .collect::<Vec<_>>()
        .join("");
    format!(
        "<!doctype html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>{}</title><link rel=\"stylesheet\" href=\"app.css\"></head><body><main><h1>{}</h1><form id=\"application-form\" novalidate><div class=\"field\"><label for=\"left\">{}</label><input id=\"left\" name=\"left\" inputmode=\"numeric\" autocomplete=\"off\"></div><div class=\"field\"><label for=\"operation\">{}</label><select id=\"operation\" name=\"operation\">{}</select></div><div class=\"field\"><label for=\"right\">{}</label><input id=\"right\" name=\"right\" inputmode=\"numeric\" autocomplete=\"off\"></div><button id=\"submit\" type=\"submit\">{}</button></form><output id=\"result\" role=\"status\" aria-live=\"polite\" aria-atomic=\"true\"></output></main><script type=\"module\" src=\"app.js\"></script></body></html>\n",
        html(&view.title),
        html(&view.heading),
        html(&view.left_label),
        html(&view.operation_label),
        options,
        html(&view.right_label),
        html(&view.submit_label),
    )
}

fn css() -> String {
    "*{box-sizing:border-box}body{margin:0;background:#f6f7fb;color:#172033;font-family:ui-sans-serif,system-ui,sans-serif}main{width:min(36rem,calc(100% - 2rem));margin:4rem auto;padding:2rem;border:1px solid #c9d1df;border-radius:.75rem;background:#fff;box-shadow:0 .5rem 2rem #17203318}h1{margin-top:0}form{display:grid;grid-template-columns:1fr auto 1fr;gap:.75rem;align-items:end}.field{display:grid;gap:.35rem;min-width:0}label{font-weight:600}input,select,button{width:100%;min-height:2.75rem;border:1px solid #77839a;border-radius:.4rem;padding:.55rem;font:inherit}button{grid-column:1/-1;background:#234fdb;color:#fff;border-color:#234fdb;font-weight:700;cursor:pointer}input:focus,select:focus,button:focus{outline:3px solid #9bb4ff;outline-offset:2px}output{display:block;min-height:2rem;margin-top:1.25rem;font-weight:700}@media(max-width:36rem){form{grid-template-columns:1fr}}\n".to_string()
}

fn shared_javascript(view: &EvaluatedViewV1) -> String {
    format!(
        "const form=document.getElementById('application-form');const left=document.getElementById('left');const right=document.getElementById('right');const operation=document.getElementById('operation');const result=document.getElementById('result');const INPUT_ERROR={};const DIVISION_ERROR={};const OVERFLOW_ERROR={};const MIN=-9223372036854775808n;const MAX=9223372036854775807n;function operand(value){{if(!/^(?:0|-[1-9][0-9]*|[1-9][0-9]*)$/.test(value))return null;const parsed=BigInt(value);return parsed<MIN||parsed>MAX?null:value;}}function show(value){{result.textContent=value;}}",
        json(&view.input_error),
        json(&view.division_by_zero_error),
        json(&view.overflow_error),
    )
}

fn hologram_javascript(view: &EvaluatedViewV1) -> String {
    format!(
        "{}form.addEventListener('submit',async event=>{{event.preventDefault();const a=operand(left.value),b=operand(right.value);if(a===null||b===null){{show(INPUT_ERROR);return;}}const request='1\\t'+operation.selectedOptions[0].dataset.request+'\\t'+a+'\\t'+b;try{{const response=await fetch('/_hologram/intent',{{method:'POST',headers:{{'content-type':'application/json'}},body:JSON.stringify({{version:1,name:'application.invoke',payload:request}})}});const envelope=await response.json();if(!response.ok||envelope.version!==1||!Array.isArray(envelope.outputs)||envelope.outputs.length!==1)throw new Error('intent');const fields=envelope.outputs[0].split('\\t');if(fields.length!==3||fields[0]!=='1')throw new Error('protocol');if(fields[1]==='ok'&&operand(fields[2])===fields[2])show(fields[2]);else if(fields[1]==='error'&&fields[2]==='division-by-zero')show(DIVISION_ERROR);else if(fields[1]==='error'&&fields[2]==='overflow')show(OVERFLOW_ERROR);else throw new Error('protocol');}}catch(_){{show(INPUT_ERROR);}}}});\n",
        shared_javascript(view)
    )
}

fn browser_javascript(view: &EvaluatedViewV1, binding: &BrowserAdapterBinding) -> String {
    let module = binding.core_crate_name.replace('-', "_");
    format!(
        "import init,{{calculate}}from'./{module}.js';{}await init();form.addEventListener('submit',event=>{{event.preventDefault();const a=operand(left.value),b=operand(right.value);if(a===null||b===null){{show(INPUT_ERROR);return;}}const answer=calculate(Number(operation.value),a,b);if(answer.kind==='ok')show(answer.value);else if(answer.error==='division-by-zero')show(DIVISION_ERROR);else if(answer.error==='overflow')show(OVERFLOW_ERROR);else show(INPUT_ERROR);}});\n",
        shared_javascript(view),
    )
}

fn adapter(view: &EvaluatedViewV1, binding: &BrowserAdapterBinding) -> GeneratedPackage {
    let dependency = binding.core_crate_name.replace('-', "_");
    let arms = view
        .operations
        .iter()
        .map(|operation| {
            format!(
                "        {} => {}::{}::{},",
                operation.discriminant,
                dependency,
                binding.core_operation_type,
                operation.rust_variant
            )
        })
        .collect::<Vec<_>>()
        .join("\n");
    let cargo = format!(
        "[package]\nname = \"{}\"\nversion = \"{}\"\nedition = \"2021\"\npublish = false\n\n[lib]\ncrate-type = [\"cdylib\"]\n\n[dependencies]\njs-sys = \"=0.3.99\"\nwasm-bindgen = \"=0.2.122\"\n{} = \"={}\"\n",
        binding.package_name,
        binding.package_version,
        binding.core_crate_name,
        binding.core_crate_version,
    );
    let source = format!(
        "use wasm_bindgen::prelude::*;\n\nfn field(object:&js_sys::Object,name:&str,value:&str){{js_sys::Reflect::set(object,&JsValue::from_str(name),&JsValue::from_str(value)).expect(\"new object accepts string fields\");}}\nfn operand(value:&str)->Option<i64>{{if value.is_empty()||value.starts_with('+')||value.bytes().any(|byte|!byte.is_ascii_digit()&&byte!=b'-')||value[1..].contains('-'){{return None;}}let parsed:i64=value.parse().ok()?;if parsed.to_string()!=value{{return None;}}Some(parsed)}}\n\n#[wasm_bindgen]\npub fn calculate(operation:u8,left_decimal:&str,right_decimal:&str)->JsValue{{\n    let left=match operand(left_decimal){{Some(value)=>value,None=>return JsValue::UNDEFINED}};\n    let right=match operand(right_decimal){{Some(value)=>value,None=>return JsValue::UNDEFINED}};\n    let operation=match operation{{\n{}\n        _=>return JsValue::UNDEFINED,\n    }};\n    let object=js_sys::Object::new();\n    match {}::{}(operation,left,right){{\n        Ok(value)=>{{field(&object,\"kind\",\"ok\");field(&object,\"value\",&value.to_string());}},\n        Err({}::{}::DivisionByZero)=>{{field(&object,\"kind\",\"error\");field(&object,\"error\",\"division-by-zero\");}},\n        Err({}::{}::Overflow)=>{{field(&object,\"kind\",\"error\");field(&object,\"error\",\"overflow\");}},\n    }}\n    object.into()\n}}\n",
        arms,
        dependency,
        binding.core_function,
        dependency,
        binding.core_error_type,
        dependency,
        binding.core_error_type,
    );
    let mut files = vec![file("Cargo.toml", cargo), file("src/lib.rs", source)];
    let records = files
        .iter()
        .map(|item| {
            format!(
                "{{\"path\":{},\"sha256\":\"{}\"}}",
                json(&item.path),
                sha256(&item.bytes)
            )
        })
        .collect::<Vec<_>>()
        .join(",");
    files.push(file(
        "generation-manifest.json",
        format!(
            "{{\"core_crate\":{},\"core_version\":{},\"files\":[{}],\"generated_core_sha256\":{},\"model_id\":{},\"schema\":\"lean4-prod/browser-adapter/1\",\"view_model_id\":{}}}\n",
            json(&binding.core_crate_name),
            json(&binding.core_crate_version),
            records,
            json(&view.generated_core_sha256),
            json(&view.model_id),
            json(&view.view_model_id),
        ),
    ));
    files.sort_by(|left, right| left.path.as_bytes().cmp(right.path.as_bytes()));
    GeneratedPackage { files }
}

/// Render one evaluated, typed View value into both target transports.
pub fn generate_view_v1(
    view: &EvaluatedViewV1,
    binding: &BrowserAdapterBinding,
) -> Result<GeneratedViewV1, Error> {
    validate(view, binding)?;
    let html = index_html(view);
    let styles = css();
    let mut hologram_assets = vec![
        file("app.css", styles.clone()),
        file("app.js", hologram_javascript(view)),
        file("index.html", html.clone()),
    ];
    let mut browser_assets = vec![
        file("app.css", styles),
        file("app.js", browser_javascript(view, binding)),
        file("index.html", html),
    ];
    hologram_assets.sort_by(|left, right| left.path.as_bytes().cmp(right.path.as_bytes()));
    browser_assets.sort_by(|left, right| left.path.as_bytes().cmp(right.path.as_bytes()));
    let target_records = |name: &str, files: &[PackageFile]| {
        format!(
            "{{\"files\":[{}],\"target\":{}}}",
            files
                .iter()
                .map(|item| format!(
                    "{{\"path\":{},\"sha256\":\"{}\"}}",
                    json(&item.path),
                    sha256(&item.bytes)
                ))
                .collect::<Vec<_>>()
                .join(","),
            json(name)
        )
    };
    let hologram_bundle = generate_holoview_bundle(&hologram_assets)?;
    let view_manifest = file(
        "view-manifest.json",
        format!(
            "{{\"generated_core_sha256\":{},\"hologram_bundle\":{{\"path\":{},\"sha256\":\"{}\"}},\"model_id\":{},\"projections\":[{},{}],\"schema\":\"lean4-prod/view-projection/1\",\"view_model_id\":{}}}\n",
            json(&view.generated_core_sha256),
            json(&hologram_bundle.path),
            sha256(&hologram_bundle.bytes),
            json(&view.model_id),
            target_records("browser-wasm-bindgen", &browser_assets),
            target_records("hologram-intent-v1", &hologram_assets),
            json(&view.view_model_id),
        ),
    );
    Ok(GeneratedViewV1 {
        hologram_assets,
        hologram_bundle,
        browser_assets,
        browser_adapter: adapter(view, binding),
        view_manifest,
    })
}
