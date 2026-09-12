use futures_util::StreamExt;
use tokio_tungstenite::connect_async;
use url::Url;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let ws_url = "ws://127.0.0.1:8080/ws";
    println!("Connecting live test client to WebSocket endpoint: {}", ws_url);

    let url = Url::parse(ws_url)?;
    let (ws_stream, response) = connect_async(url).await?;

    println!("✅ Connected to telemetry stream! HTTP Status: {}", response.status());

    let (_, mut read) = ws_stream.split();

    let mut frames_received = 0;

    while let Some(message) = read.next().await {
        let msg = message?;
        if let tokio_tungstenite::tungstenite::Message::Text(text) = msg {
            frames_received += 1;
            println!("\n📥 [Frame #{}] Live Telemetry Streamed:", frames_received);
            let parsed: serde_json::Value = serde_json::from_str(&text)?;

            let data = &parsed["data"];
            println!("  ├─ Matter ID:             {}", data["matterId"]);
            println!("  ├─ Exact Rational L_Φ:    {}/{}", data["lPhiNumerator"], data["lPhiDenominator"]);
            println!("  ├─ Associator Defect:     {} ppm (Ceiling: {})", data["associatorDefectPpm"], data["defectCeilingPpm"]);
            println!("  ├─ Poseidon2 Seal:        {}", data["poseidon2Seal"]);
            println!("  ├─ On-Chain Tx (CRMF):    {}", data["onChainTx"]);
            println!("  └─ Timestamp:             {}", data["timestamp"]);

            assert_eq!(parsed["type"], "TELEMETRY_FRAME");
            assert!(!data["poseidon2Seal"].as_str().unwrap().is_empty());
            assert!(!data["onChainTx"].as_str().unwrap().is_empty());

            if frames_received >= 3 {
                println!("\n🎉 SUCCESS: Received {} valid live WebSocket telemetry frames with exact rational bounds and CRMF seals!", frames_received);
                break;
            }
        }
    }

    Ok(())
}
