use futures_util::{SinkExt, StreamExt};
use pirtm_telemetry::{GardenTelemetry, GeniusV2PracticeModel};
use serde_json::json;
use std::net::SocketAddr;
use tokio::net::{TcpListener, TcpStream};
use tokio_tungstenite::accept_async;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr = "127.0.0.1:8080";
    let listener = TcpListener::bind(addr).await?;
    println!("📡 Telemetry WebSocket Server listening on ws://{}", addr);

    while let Ok((stream, peer)) = listener.accept().await {
        println!("🔗 Connection accepted from {}", peer);
        tokio::spawn(handle_connection(stream, peer));
    }

    Ok(())
}

async fn handle_connection(stream: TcpStream, peer: SocketAddr) {
    let ws_stream = match accept_async(stream).await {
        Ok(ws) => ws,
        Err(e) => {
            eprintln!("Error during WebSocket handshake from {}: {}", peer, e);
            return;
        }
    };

    println!("✅ WebSocket handshake completed with {}", peer);
    let (mut ws_sender, mut ws_receiver) = ws_stream.split();

    let mut model = GeniusV2PracticeModel::new();
    let mut step = 0;

    let mut interval = tokio::time::interval(tokio::time::Duration::from_millis(1000));

    loop {
        tokio::select! {
            _ = interval.tick() => {
                step += 1;

                // Telemetry values evolving within exact contractive rational bounds
                let moisture = 50 + (step % 5);
                let temp = 50 - (step % 3);
                let solar = 50 + (step % 4);
                let civic = 50;

                let telemetry = GardenTelemetry::new((moisture, 100), (temp, 100), (solar, 100), (civic, 100));

                let receipt = match model.ingest_telemetry(&telemetry) {
                    Ok(r) => r,
                    Err(e) => {
                        eprintln!("Telemetry ingestion error: {}", e);
                        continue;
                    }
                };

                let l_phi_num = receipt.r_t_ratio.0;
                let l_phi_den = receipt.r_t_ratio.1;
                let defect_ppm = ((receipt.drift_ratio.0 as f64 / receipt.drift_ratio.1 as f64) * 1_000_000.0) as u64;

                let frame = json!({
                    "type": "TELEMETRY_FRAME",
                    "data": {
                        "matterId": "MATTER-2026-FT01-ESI",
                        "lPhiNumerator": l_phi_num,
                        "lPhiDenominator": l_phi_den,
                        "associatorDefectPpm": defect_ppm,
                        "defectCeilingPpm": 41000,
                        "poseidon2Seal": receipt.poseidon_commitment,
                        "p5QuarantineLeakage": 0.0,
                        "isL0Halted": !receipt.is_contractive,
                        "onChainTx": format!("0x{}", &receipt.seal_hash[..32]),
                        "timestamp": receipt.timestamp
                    }
                });

                let msg = tokio_tungstenite::tungstenite::Message::Text(frame.to_string());
                if let Err(e) = ws_sender.send(msg).await {
                    println!("Client disconnected (peer {}): {}", peer, e);
                    break;
                }
            }
            msg = ws_receiver.next() => {
                if msg.is_none() {
                    break;
                }
            }
        }
    }
}
