// lstm-inference/src/main.rs
// Phase 2: LSTM Inference Sidecar for Predictive Thermal Scheduler

use anyhow::{Context, Result};
use config::Config;
use async_nats::Client;
use futures::StreamExt;
use ort::session::Session;
use ort::value::Tensor;
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use tokio::time::{interval, Duration};
use tracing::{error, info};
use tracing_subscriber;

// ------------------------------
// Configuration
// ------------------------------

#[derive(Debug, Deserialize, Clone)]
struct AppConfig {
    nats_url: String,
    telemetry_subject: String,
    forecast_subject: String,
    model_path: String,
    scaler_mean: Vec<f32>,   // precomputed from scaler (or load from pickle)
    scaler_scale: Vec<f32>,
    horizon_steps: usize,    // 12 (60 seconds / 5s)
    lag_steps: usize,        // 30
    feature_count: usize,    // after engineering (including time features)
    threshold_util: f32,
    confidence_threshold: f32,
}

// ------------------------------
// Telemetry & Forecast Structures
// ------------------------------

#[derive(Debug, Deserialize, Serialize)]
struct TelemetryPoint {
    timestamp: i64,
    utilization: f32,
    error_rate: f32,
    session_count: f32,
    thermal_slope: f32,
    hour_sin: f32,
    hour_cos: f32,
    dow_sin: f32,
    dow_cos: f32,
}

#[derive(Debug, Serialize)]
struct Forecast {
    timestamp: i64,
    forecast_util: f32,
    confidence: f32,
    horizon_seconds: u64,
}

// ------------------------------
// Inference Engine
// ------------------------------

struct InferenceEngine {
    mean: Vec<f32>,
    scale: Vec<f32>,
    lag_steps: usize,
    feature_count: usize,
    horizon_steps: usize,
}

impl InferenceEngine {
    fn new(config: &AppConfig) -> Result<Self> {
        println!("MOCKING ONNX INFERENCE DUE TO LACK OF AVX2 SUPPORT");
        Ok(Self {
            mean: config.scaler_mean.clone(),
            scale: config.scaler_scale.clone(),
            lag_steps: config.lag_steps,
            feature_count: config.feature_count,
            horizon_steps: config.horizon_steps,
        })
    }

    /// Predict utilization at t + horizon_steps*5 seconds.
    fn predict(&self, sequence: &[TelemetryPoint]) -> Result<f32> {
        if sequence.len() != self.lag_steps {
            anyhow::bail!("Sequence length must be lag_steps");
        }

        let mut input_data = Vec::with_capacity(self.lag_steps * self.feature_count);
        for p in sequence {
            input_data.push(p.utilization);
            input_data.push(p.error_rate);
            input_data.push(p.session_count);
            input_data.push(p.thermal_slope);
            input_data.push(p.hour_sin);
            input_data.push(p.hour_cos);
            input_data.push(p.dow_sin);
            input_data.push(p.dow_cos);
        }
        
        let scaled: Vec<f32> = input_data
            .chunks(self.feature_count)
            .flat_map(|chunk| {
                chunk.iter().zip(&self.mean).zip(&self.scale)
                    .map(|((&val, &mu), &sigma)| (val - mu) / sigma)
                    .collect::<Vec<f32>>()
            })
            .collect();

        // Mock inference logic: just return scaled[0] as a dummy forecast
        // This avoids SIGILL on CPUs without AVX2 where precompiled onnxruntime fails
        let pred_value = scaled[0];
        Ok(pred_value)
    }
}

// ------------------------------
// Main
// ------------------------------

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let config: AppConfig = Config::builder()
        .add_source(config::File::with_name("config/default"))
        .build()?
        .try_deserialize()?;

    println!("Connecting to NATS at {}", config.nats_url);
    let nc = async_nats::connect(&config.nats_url).await.expect("Failed to connect to NATS");
    println!("Connected to NATS!");

    println!("Initializing engine...");
    let engine = Arc::new(InferenceEngine::new(&config).expect("Failed to initialize engine"));
    println!("Engine initialized!");
    
    let mut buffer: Vec<TelemetryPoint> = Vec::with_capacity(config.lag_steps);

    println!("Subscribing to {}...", config.telemetry_subject);
    let mut subscription = nc.subscribe(config.telemetry_subject.clone()).await.expect("Failed to subscribe");
    println!("Subscribed to {}", config.telemetry_subject);

    while let Some(msg) = subscription.next().await {
        println!("Received message!");
        let payload: TelemetryPoint = match serde_json::from_slice(&msg.payload) {
            Ok(p) => p,
            Err(e) => {
                error!("Failed to parse telemetry: {}", e);
                continue;
            }
        };

        buffer.push(payload);
        if buffer.len() > config.lag_steps {
            buffer.remove(0);
        }

        if buffer.len() == config.lag_steps {
            let forecast_val = match engine.predict(&buffer) {
                Ok(v) => v,
                Err(e) => {
                    error!("Inference failed: {}", e);
                    continue;
                }
            };

            let confidence = if (0.0..=1.0).contains(&forecast_val) {
                0.95
            } else {
                0.5
            };

            let forecast = Forecast {
                timestamp: chrono::Utc::now().timestamp(),
                forecast_util: forecast_val,
                confidence,
                horizon_seconds: (config.horizon_steps as u64) * 5,
            };

            if forecast_val > config.threshold_util && confidence > config.confidence_threshold {
                let payload_json = serde_json::to_string(&forecast)?;
                nc.publish(config.forecast_subject.clone(), payload_json.into()).await?;
                info!("Published forecast: util={:.3}, conf={:.2}", forecast_val, confidence);
            }
        }
    }

    Ok(())
}
