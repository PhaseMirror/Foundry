use std::error::Error;
use std::env;
use tokio::net::TcpStream;
use tokio::io::{AsyncWriteExt, AsyncReadExt};

pub struct TeeAttestationVerifier;

impl TeeAttestationVerifier {
    /// Queries the guest attestation verifier sidecar to check if the proxy
    /// is executing inside a hardware-isolated Confidential TEE.
    pub async fn verify_environment() -> Result<(), Box<dyn Error>> {
        let binding_enabled = env::var("TEE_BINDING_ENABLED").unwrap_or_default() == "true";
        if !binding_enabled {
            println!("[WARN] [TEE] Hardware attestation binding is disabled. Operating in software-only mode.");
            return Ok(());
        }

        let endpoint = env::var("TEE_ATTESTATION_ENDPOINT")
            .unwrap_or_else(|_| "http://localhost:8081/v1/attestation".to_string());
        
        println!("[INFO] [TEE] Initiating TEE remote attestation check against {}...", endpoint);

        // Parse host and port from endpoint URL
        let url = endpoint.strip_prefix("http://").unwrap_or(&endpoint);
        let parts: Vec<&str> = url.split('/').collect();
        let host_port = parts[0];
        
        let (host, port) = if let Some(pos) = host_port.find(':') {
            (&host_port[..pos], host_port[pos+1..].parse::<u16>().unwrap_or(8081))
        } else {
            (host_port, 8081)
        };

        // Open TCP connection to the attestation sidecar
        let mut stream = TcpStream::connect(format!("{}:{}", host, port)).await
            .map_err(|e| format!("Failed to connect to attestation endpoint {}:{}: {}", host, port, e))?;

        // Send a simple HTTP GET request
        let request = format!(
            "GET /v1/attestation HTTP/1.1\r\nHost: {}\r\nConnection: close\r\n\r\n",
            host
        );
        stream.write_all(request.as_bytes()).await?;

        // Read response
        let mut response_bytes = Vec::new();
        stream.read_to_end(&mut response_bytes).await?;
        let response_str = String::from_utf8_lossy(&response_bytes);

        // Find start of JSON payload
        if let Some(json_start) = response_str.find("\r\n\r\n") {
            let json_body = &response_str[json_start + 4..];
            
            #[derive(serde::Deserialize)]
            struct AttestationResponse {
                status: String,
                quote: Option<String>,
                apo_root: Option<String>,
            }

            let res: AttestationResponse = serde_json::from_str(json_body)
                .map_err(|e| format!("Failed to parse attestation response JSON: {}. Response body: {}", e, json_body))?;

            if res.status != "SUCCESS" {
                return Err(format!("TEE Attestation failed with status: {}", res.status).into());
            }

            let quote_str = res.quote.unwrap_or_default();
            let apo_root = res.apo_root.unwrap_or_default();
            println!("[INFO] [TEE] Remote attestation validated successfully.");
            println!("[DEBUG] [TEE] Enclave Quote: {}...", &quote_str.get(..20).unwrap_or(""));
            println!("[DEBUG] [TEE] Enclave APO Root: {}", apo_root);

            Ok(())
        } else {
            Err("Malformed HTTP response from attestation endpoint".into())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::net::TcpListener;

    #[tokio::test]
    async fn test_tee_attestation_success() {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();

        tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut buf = [0u8; 1024];
            let n = socket.read(&mut buf).await.unwrap();
            let request = String::from_utf8_lossy(&buf[..n]);
            assert!(request.contains("GET /v1/attestation"));

            let response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{\n  \"status\": \"SUCCESS\",\n  \"quote\": \"01000000000000001234567890\",\n  \"apo_root\": \"d9b4d94345cfefdc7178d0f0d6c0a3ebce90732358765f7d93fa8f86d0a5ca37\"\n}";
            socket.write_all(response.as_bytes()).await.unwrap();
        });

        unsafe {
            env::set_var("TEE_BINDING_ENABLED", "true");
            env::set_var("TEE_ATTESTATION_ENDPOINT", format!("http://{}", addr));
        }

        let res = TeeAttestationVerifier::verify_environment().await;
        assert!(res.is_ok(), "Attestation verification failed: {:?}", res);

        unsafe {
            env::remove_var("TEE_BINDING_ENABLED");
            env::remove_var("TEE_ATTESTATION_ENDPOINT");
        }
    }

    #[tokio::test]
    async fn test_tee_attestation_failure() {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();

        tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut buf = [0u8; 1024];
            let _n = socket.read(&mut buf).await.unwrap();

            let response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{\n  \"status\": \"FAILURE\"\n}";
            socket.write_all(response.as_bytes()).await.unwrap();
        });

        unsafe {
            env::set_var("TEE_BINDING_ENABLED", "true");
            env::set_var("TEE_ATTESTATION_ENDPOINT", format!("http://{}", addr));
        }

        let res = TeeAttestationVerifier::verify_environment().await;
        assert!(res.is_err());
        assert!(res.unwrap_err().to_string().contains("Attestation failed"));

        unsafe {
            env::remove_var("TEE_BINDING_ENABLED");
            env::remove_var("TEE_ATTESTATION_ENDPOINT");
        }
    }
}
