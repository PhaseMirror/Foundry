use std::time::Duration;
use futures::StreamExt;
use url::Url;


/// Checks if a URL is allowed based on secure absolute formats, correct schemes,
/// and SSRF protection (blocking loopbacks, private networks, multicast, unspecified IPs,
/// and localhost/.local DNS domains).
pub fn is_allowed_url(url: &Url) -> bool {
    let scheme = url.scheme();
    if scheme != "http" && scheme != "https" {
        return false;
    }

    if let Some(host) = url.host() {
        match host {
            url::Host::Domain(domain) => {
                if domain.eq_ignore_ascii_case("localhost") || domain.ends_with(".local") {
                    return false;
                }
            }
            url::Host::Ipv4(ip) => {
                if ip.is_loopback()
                    || ip.is_private()
                    || ip.is_link_local()
                    || ip.is_multicast()
                    || ip.is_unspecified()
                {
                    return false;
                }
            }
            url::Host::Ipv6(ip) => {
                if ip.is_loopback()
                    || ip.is_multicast()
                    || ip.is_unspecified()
                {
                    return false;
                }
            }
        }
    } else {
        return false;
    }

    true
}

/// Securely fetches proof source data from a remote endpoint.
pub async fn fetch_proof_source(url_str: &str) -> Result<String, anyhow::Error> {
    let orig_url = Url::parse(url_str)?;
    if !is_allowed_url(&orig_url) {
        return Err(anyhow::anyhow!("Disallowed or invalid URL"));
    }

    let timeout_ms = std::env::var("FETCH_TIMEOUT_MS")
        .ok()
        .and_then(|val| val.parse::<u64>().ok())
        .unwrap_or(10000);

    let max_size = std::env::var("FETCH_MAX_BYTES")
        .ok()
        .and_then(|val| val.parse::<usize>().ok())
        .unwrap_or(1_000_000);

    // Build the request client with timeout and disabled redirects
    let client = reqwest::Client::builder()
        .timeout(Duration::from_millis(timeout_ms))
        .redirect(reqwest::redirect::Policy::none())
        .build()?;

    let resp = client.get(url_str).send().await?;

    // Ensure no silent redirects changed the origin
    let final_url = resp.url();
    if final_url.origin() != orig_url.origin() {
        return Err(anyhow::anyhow!("Redirected to unexpected origin"));
    }

    // Validate content type
    let content_type = resp
        .headers()
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|h| h.to_str().ok())
        .unwrap_or("");

    if !content_type.contains("application/json") && !content_type.contains("text/") {
        return Err(anyhow::anyhow!("Unexpected content-type"));
    }

    // Stream and limit the read length to prevent DoS/OOM
    let mut bytes = Vec::new();
    let mut stream = resp.bytes_stream();
    while let Some(chunk_result) = stream.next().await {
        let chunk = chunk_result?;
        if bytes.len() + chunk.len() > max_size {
            return Err(anyhow::anyhow!("Response too large"));
        }
        bytes.extend_from_slice(&chunk);
    }

    let text = String::from_utf8(bytes)?;
    Ok(text)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_allowed_url() {
        // Valid public URLs
        assert!(is_allowed_url(&Url::parse("https://example.com").unwrap()));
        assert!(is_allowed_url(&Url::parse("http://8.8.8.8/foo").unwrap()));

        // Invalid schemes
        assert!(!is_allowed_url(&Url::parse("ftp://example.com").unwrap()));
        assert!(!is_allowed_url(&Url::parse("file:///etc/passwd").unwrap()));

        // Localhosts & loopback IPs
        assert!(!is_allowed_url(&Url::parse("https://localhost").unwrap()));
        assert!(!is_allowed_url(&Url::parse("http://127.0.0.1/bar").unwrap()));
        assert!(!is_allowed_url(&Url::parse("http://[::1]/bar").unwrap()));

        // Private IP ranges
        assert!(!is_allowed_url(&Url::parse("http://192.168.1.1").unwrap()));
        assert!(!is_allowed_url(&Url::parse("http://10.0.0.1").unwrap()));
        assert!(!is_allowed_url(&Url::parse("http://172.16.0.1").unwrap()));
    }
}
