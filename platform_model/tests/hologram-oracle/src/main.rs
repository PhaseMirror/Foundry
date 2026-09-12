use hologram::archive::HoloWriter;
use hologram::space::{address_bytes, AppManifest, Layer, Realization};
use hologram_live::holo::{
    inspect_bytes, plan_bytes, HoloCatalog, HoloExecutor, HoloRuntime,
};
use hologram_live::store::ObjectStore;
use hologram_view_surface::{
    PortableViewAttachment, PortableViewSurface, SurfaceFuture, ViewAttachmentId,
    ViewIntentRequest, APPLICATION_INVOKE_INTENT, VIEW_INTENT_VERSION,
};
use serde_json::{json, Value};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};

#[derive(Default)]
struct RecordingSurface {
    attachment: Mutex<Option<PortableViewAttachment>>,
    attached: AtomicUsize,
    detached: AtomicUsize,
}

impl PortableViewSurface for RecordingSurface {
    fn attach(&self, view: PortableViewAttachment) -> SurfaceFuture<'_> {
        Box::pin(async move {
            *self
                .attachment
                .lock()
                .map_err(|_| "attachment lock poisoned".to_owned())? = Some(view);
            self.attached.fetch_add(1, Ordering::SeqCst);
            Ok(())
        })
    }

    fn detach<'a>(&'a self, _id: &'a ViewAttachmentId) -> SurfaceFuture<'a> {
        Box::pin(async move {
            self.detached.fetch_add(1, Ordering::SeqCst);
            Ok(())
        })
    }
}

fn bytes(value: &Value, field: &str) -> Result<Vec<u8>, String> {
    value[field]
        .as_array()
        .ok_or_else(|| format!("acceptance vector has no {field}"))?
        .iter()
        .map(|byte| {
            byte.as_u64()
                .and_then(|byte| u8::try_from(byte).ok())
                .ok_or_else(|| format!("acceptance {field} contains a non-byte"))
        })
        .collect()
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut arguments = std::env::args_os().skip(1);
    let archive_path = arguments.next().ok_or("archive path is required")?;
    let model_path = arguments.next().ok_or("model path is required")?;
    let wasm_path = arguments.next().ok_or("Core-Wasm path is required")?;
    if arguments.next().is_some() {
        return Err("unexpected argument".into());
    }
    let archive = std::fs::read(archive_path)?;
    let wasm = std::fs::read(wasm_path)?;
    let model: Value = serde_json::from_slice(&std::fs::read(model_path)?)?;
    let application = &model["application"];
    let vectors = application["acceptance_vectors"]
        .as_array()
        .ok_or("model has no acceptance vectors")?;
    if vectors.is_empty() {
        return Err("model acceptance corpus is empty".into());
    }

    let inspection = inspect_bytes("oracle", "Calculator.holo", &archive)?;
    if inspection.format_version != 4 || !inspection.footer_verified {
        return Err("upstream inspection did not verify Hologram v4/footer".into());
    }
    let directory = inspection
        .directory
        .as_ref()
        .ok_or("upstream inspection found no application directory")?;
    if !inspection.directory_embedded
        || directory.primary_layer != Some(0)
        || directory.layers.len() != 2
        || directory.layers[0].kind != "wasm"
        || directory.layers[0].entry != "holo_run"
        || directory.layers[0].contract.as_deref() != Some("hologram:guest/core-wasm@1")
        || directory.layers[1].kind != "view"
        || directory.layers[1].surface.as_deref() != Some("portable")
        || directory.blobs.len() != 4
    {
        return Err("upstream application directory disagrees with Calculator profile".into());
    }

    let plan = serde_json::to_value(plan_bytes(&archive)?)?;
    if plan["execution_target"] != "direct"
        || plan["runnable"] != false
        || plan["layers"][0]["provider"]["name"] != "wasmtime-direct"
        || plan["layers"][1]["provider"]["status"] != "unavailable"
        || plan["blockers"][0]["error_code"] != "LIVE_CAPABILITY_MISSING"
    {
        return Err("upstream headless plan did not report the exact portable-surface blocker".into());
    }

    let registry = Arc::new(hologram_view_surface::ViewSurfaceRegistry::new());
    let surface = Arc::new(RecordingSurface::default());
    registry.register_portable(surface.clone())?;
    let session = HoloExecutor::with_view_surfaces(registry)
        .start_session(&archive)
        .await?;
    if surface.attached.load(Ordering::SeqCst) != 1 {
        return Err("portable View did not attach exactly once".into());
    }
    let attachment = surface
        .attachment
        .lock()
        .map_err(|_| "attachment lock poisoned")?
        .clone()
        .ok_or("portable View attachment was not retained")?;
    let paths = attachment
        .assets
        .iter()
        .map(|asset| asset.path.as_str())
        .collect::<Vec<_>>();
    if attachment.entry != "index.html" || paths != ["app.css", "app.js", "index.html"] {
        return Err("attached portable View asset closure/order is not canonical".into());
    }

    let mut intent_count = 0usize;
    for vector in vectors {
        let request = bytes(vector, "request")?;
        let response = bytes(vector, "response")?;
        let direct = session.invoke(vec![request.clone()]).await?;
        if direct.outputs != vec![response.clone()] {
            return Err("upstream direct execution disagrees with a modeled vector".into());
        }
        if let (Ok(payload), Ok(expected)) = (
            String::from_utf8(request),
            String::from_utf8(response),
        ) {
            let intent = attachment
                .intents
                .handle(
                    &attachment.id,
                    ViewIntentRequest {
                        version: VIEW_INTENT_VERSION,
                        name: APPLICATION_INVOKE_INTENT.to_owned(),
                        payload,
                    },
                )
                .await?;
            if intent.version != VIEW_INTENT_VERSION || intent.outputs != vec![expected] {
                return Err("portable View intent disagrees with a modeled vector".into());
            }
            intent_count += 1;
        }
    }
    let allocation_cap = usize::try_from(
        application["guest_allocation_maximum"]
            .as_u64()
            .ok_or("model has no guest allocation cap")?,
    )?;
    let malformed_response = vectors
        .iter()
        .find(|vector| vector["request"].as_array().is_some_and(Vec::is_empty))
        .ok_or("model has no empty malformed-request vector")?;
    let malformed_response = bytes(malformed_response, "response")?;
    let at_cap = session
        .invoke(vec![vec![b'x'; allocation_cap]])
        .await?;
    if at_cap.outputs != vec![malformed_response] {
        return Err("guest allocation cap did not return the modeled malformed response".into());
    }
    if session
        .invoke(vec![vec![b'x'; allocation_cap + 1]])
        .await
        .is_ok()
    {
        return Err("first over-cap Core-Wasm request did not fail".into());
    }

    session.stop().await?;
    session.stop().await?;
    if surface.detached.load(Ordering::SeqCst) != 1 {
        return Err("portable View did not detach exactly once".into());
    }
    if attachment
        .intents
        .handle(
            &attachment.id,
            ViewIntentRequest {
                version: VIEW_INTENT_VERSION,
                name: APPLICATION_INVOKE_INTENT.to_owned(),
                payload: "1\tadd\t1\t1".to_owned(),
            },
        )
        .await
        .is_ok()
    {
        return Err("stale portable View intent remained usable after stop".into());
    }

    // Resident Hologram deliberately has a headless View provider, so use the
    // exact modeled primary bytes in an upstream-written primary-only archive.
    // The composed archive itself was already checked above, including its
    // mandatory unavailable-surface result under headless planning.
    let capabilities = hologram_live::holo_capability::empty_canonical();
    let manifest = AppManifest {
        primary: Some(0),
        requires: address_bytes(&capabilities),
        layers: vec![Layer::wasm_with_contract(
            address_bytes(&wasm),
            "holo_run",
            "hologram:guest/core-wasm@1",
        )],
        children: Vec::new(),
    };
    let addressed = [
        (address_bytes(&capabilities), capabilities.as_slice()),
        (address_bytes(&wasm), wasm.as_slice()),
    ];
    let directory = hologram_live::holo_directory::derive(
        &manifest,
        addressed
            .iter()
            .map(|(kappa, content)| (kappa.as_bytes(), *content)),
    )?;
    let mut writer = HoloWriter::new();
    writer.set_app_manifest(manifest.canonicalize());
    writer.add_extension(
        hologram_live::holo_directory::DIRECTORY_EXTENSION_KEY,
        hologram_live::holo_directory::encode(&directory)?,
    );
    for (kappa, content) in addressed {
        writer.add_content_blob(kappa.as_bytes(), content);
    }
    let resident_archive = writer.finish()?;
    let store_root = tempfile::tempdir()?;
    let store = Arc::new(ObjectStore::open(store_root.path())?);
    let catalog = Arc::new(HoloCatalog::new(store));
    let resident_kappa = catalog
        .import("Calculator-primary.holo".to_owned(), resident_archive)?
        .kappa;
    let runtime = HoloRuntime::new(catalog, 8);
    runtime.load(&resident_kappa).await?;
    for vector in vectors {
        let response = runtime
            .run(&resident_kappa, vec![bytes(vector, "request")?])
            .await?;
        if response.outputs != vec![bytes(vector, "response")?] {
            return Err("upstream resident execution disagrees with a modeled vector".into());
        }
    }
    runtime.unload(&resident_kappa).await?;
    runtime.unload(&resident_kappa).await?;

    println!(
        "{}",
        serde_json::to_string(&json!({
            "application_kappa": inspection.application_kappa,
            "archive_fingerprint": inspection.archive_fingerprint,
            "archive_kappa": session.archive_kappa(),
            "direct_vectors": vectors.len(),
            "footer_verified": true,
            "guest_allocation_boundary": "verified",
            "intent_vectors": intent_count,
            "resident_vectors": vectors.len(),
            "schema": "prismpm/hologram-oracle/1",
            "view_attached": 1,
            "view_detached": 1
        }))?
    );
    Ok(())
}
