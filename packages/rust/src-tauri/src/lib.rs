use hologram_app::{ChatRequest, Config, HologramApp, Message, ModelInfo};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tauri::{
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    Emitter, Manager, State, WindowEvent,
};
use tokio::sync::RwLock;

type AppState = Arc<RwLock<HologramApp>>;

#[derive(Clone, Serialize)]
struct StreamChunk {
    content: String,
    done: bool,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

/// List all available models
#[tauri::command]
async fn list_models(state: State<'_, AppState>) -> Result<Vec<ModelInfo>, String> {
    let app = state.read().await;
    app.models().list().await.map_err(|e| e.to_string())
}

/// Send a chat message and stream the response
#[tauri::command]
async fn send_message(
    app_handle: tauri::AppHandle,
    model: String,
    messages: Vec<ChatMessage>,
    state: State<'_, AppState>,
) -> Result<(), String> {
    let hologram = state.read().await;

    let ollama_messages: Vec<Message> = messages
        .iter()
        .map(|m| Message {
            role: m.role.clone(),
            content: m.content.clone(),
            images: None,
        })
        .collect();

    let request = ChatRequest {
        model,
        messages: ollama_messages,
        stream: false,
        format: None,
        options: None,
        keep_alive: None,
    };

    match hologram.chat().complete(request).await {
        Ok(response) => {
            // Emit the response
            let _ = app_handle.emit(
                "chat-response",
                StreamChunk {
                    content: response.message.content,
                    done: true,
                },
            );
            Ok(())
        }
        Err(e) => {
            let _ = app_handle.emit(
                "chat-error",
                serde_json::json!({ "error": e.to_string() }),
            );
            Err(e.to_string())
        }
    }
}

/// Pull a model from HuggingFace
#[tauri::command]
async fn pull_model(
    app_handle: tauri::AppHandle,
    name: String,
    state: State<'_, AppState>,
) -> Result<(), String> {
    let hologram = state.read().await;

    let mut rx = hologram
        .models()
        .pull(&name)
        .await
        .map_err(|e| e.to_string())?;

    // Spawn task to forward progress updates
    tokio::spawn(async move {
        while let Ok(progress) = rx.recv().await {
            let _ = app_handle.emit("pull-progress", &progress);
        }
    });

    Ok(())
}

/// Delete a model
#[tauri::command]
async fn delete_model(name: String, state: State<'_, AppState>) -> Result<(), String> {
    let app = state.read().await;
    app.models().delete(&name).await.map_err(|e| e.to_string())
}

/// Get app version
#[tauri::command]
fn get_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    // Create tokio runtime for async operations
    let runtime = tokio::runtime::Runtime::new().expect("Failed to create Tokio runtime");

    // Initialize HologramApp
    let app_state: AppState = runtime.block_on(async {
        let config = Config::default();
        Arc::new(RwLock::new(
            HologramApp::new(config)
                .await
                .expect("Failed to initialize HologramApp"),
        ))
    });

    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .manage(app_state)
        .setup(|app| {
            // Build the system tray
            let _tray = TrayIconBuilder::new()
                .icon(app.default_window_icon().unwrap().clone())
                .tooltip("Hologram")
                .on_tray_icon_event(|tray, event| {
                    if let TrayIconEvent::Click {
                        button: MouseButton::Left,
                        button_state: MouseButtonState::Up,
                        ..
                    } = event
                    {
                        let app = tray.app_handle();
                        if let Some(window) = app.get_webview_window("main") {
                            if window.is_visible().unwrap_or(false) {
                                let _ = window.hide();
                            } else {
                                let _ = window.show();
                                let _ = window.set_focus();
                            }
                        }
                    }
                })
                .build(app)?;

            // Handle window focus loss (optional: auto-hide)
            if let Some(window) = app.get_webview_window("main") {
                let window_clone = window.clone();
                window.on_window_event(move |event| {
                    if let WindowEvent::Focused(false) = event {
                        // Uncomment to auto-hide on focus loss:
                        // let _ = window_clone.hide();
                        let _ = &window_clone; // Suppress unused warning
                    }
                });
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            list_models,
            send_message,
            pull_model,
            delete_model,
            get_version,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
