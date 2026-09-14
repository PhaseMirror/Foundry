//! Port of `materia_commons/mcp_server/github_adapter.py` — a stdio proxy
//! in front of `npx -y @modelcontextprotocol/server-github`.
//!
//! Requests arriving on our stdin are funnelled to the GitHub MCP subprocess;
//! `tools/call` requests are intercepted first so their `_sat` attestation can
//! be verified before delegation. The child's stdout is forwarded back to our
//! stdout line-by-line, mirroring the Python forwarding thread.

use crate::gate::{check_sat, strip_sat, SatOutcome};
use crate::jsonrpc::error_response;
use serde_json::{json, Value};
use std::io;
use tokio::io::{AsyncBufReadExt, AsyncRead, AsyncWrite, AsyncWriteExt, BufReader as AsyncBufReader, BufWriter as AsyncBufWriter};
use tokio::process::Command;

/// `tools/call` error message when `_sat` is absent.
pub const MISSING_SAT_MESSAGE: &str = "Missing _sat in arguments. GitHub Adapter requires an In-band SAT.";
/// `tools/call` error message when `_sat` fails verification.
pub const INVALID_SAT_MESSAGE: &str = "Invalid _sat signature. Access denied.";
/// npm package spawned as the upstream MCP server.
pub const GITHUB_SERVER_PACKAGE: &str = "@modelcontextprotocol/server-github";

/// What the proxy does with one client request line.
#[derive(Debug, Clone, PartialEq)]
pub enum LineAction {
    /// Respond to the client directly with this serialized JSON-RPC message.
    Emit(String),
    /// Delegate this JSON-RPC request to the upstream GitHub server.
    Forward(Value),
}

/// Classify one client request line under the SAT gate.
///
/// * non-`tools/call` methods: forwarded verbatim,
/// * `tools/call` without `_sat`: rejected with `-32602`,
/// * `tools/call` with an invalid signature: rejected with `-32602`,
/// * `tools/call` with a valid signature: forwarded with `_sat` stripped.
///
/// Returns `Err` only on malformed JSON.
pub fn process_line(line: &str, pub_key_hex: &str) -> io::Result<Option<LineAction>> {
    let req: Value = serde_json::from_str(line).map_err(|e| {
        io::Error::new(io::ErrorKind::InvalidData, format!("failed to parse JSON-RPC: {e}"))
    })?;
    let method = req.get("method").and_then(Value::as_str).unwrap_or("");
    if method != "tools/call" {
        return Ok(Some(LineAction::Forward(req)));
    }
    let id = req.get("id").cloned().unwrap_or(Value::Null);
    let arguments = req
        .get("params")
        .and_then(|p| p.get("arguments"))
        .cloned()
        .unwrap_or(json!({}));
    let action = match check_sat(&arguments, pub_key_hex) {
        SatOutcome::Missing => LineAction::Emit(serialize(&error_response(id, -32602, MISSING_SAT_MESSAGE))?),
        SatOutcome::Invalid => LineAction::Emit(serialize(&error_response(id, -32602, INVALID_SAT_MESSAGE))?),
        SatOutcome::Pass => {
            let clean = strip_sat(&arguments);
            let mut forward = req;
            if let Some(params) = forward.get_mut("params").and_then(Value::as_object_mut) {
                params.insert("arguments".to_string(), clean);
            }
            LineAction::Forward(forward)
        }
    };
    Ok(Some(action))
}

fn serialize(value: &Value) -> io::Result<String> {
    serde_json::to_string(value)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, format!("failed to serialize: {e}")))
}

async fn write_line(writer: &mut AsyncBufWriter<impl AsyncWrite + Unpin>, bytes: &[u8]) -> io::Result<()> {
    writer.write_all(bytes).await?;
    writer.write_all(b"\n").await?;
    writer.flush().await
}

/// Drive the proxying loop over abstract streams.
///
/// * `client_stdin` — our stdin (one JSON-RPC per line),
/// * `child_stdin` / `child_stdout` — the upstream server's pipe ends,
/// * `client_stdout` — our stdout.
///
/// Both read streams are polled with `select!`, so child output is forwarded
/// while client input is being processed, exactly like the Python
/// forwarding thread.
pub async fn run_loop<Si, Ci, Ro, Wo>(
    client_stdin: Si,
    child_stdin: Ci,
    child_stdout: Ro,
    client_stdout: Wo,
    pub_key_hex: &str,
) -> io::Result<()>
where
    Si: AsyncRead + Unpin,
    Ci: AsyncWrite + Unpin,
    Ro: AsyncRead + Unpin,
    Wo: AsyncWrite + Unpin,
{
    let mut client_in = AsyncBufReader::new(client_stdin);
    let mut child_in = AsyncBufWriter::new(child_stdin);
    let mut child_out = AsyncBufReader::new(child_stdout);
    let mut client_out = AsyncBufWriter::new(client_stdout);

    let mut line = String::new();
    let mut child_line = String::new();
    let mut child_closed = false;
    #[cfg(test)]
    let t0 = std::time::Instant::now();
    #[cfg(test)]
    let mut dbg = |m: &str, v: &str| {
        eprintln!("[{}ms] {m} {} {}", t0.elapsed().as_millis(), v.len(), v.chars().take(60).collect::<String>())
    };

    loop {
        line.clear();
        child_line.clear();
        tokio::select! {
            read = client_in.read_line(&mut line) => {
                #[cfg(test)]
                dbg("client-arm-fired:", &line);
                let n = read?;
                if n == 0 {
                    #[cfg(test)]
                    eprintln!("[{}ms] client-EOF", t0.elapsed().as_millis());
                    break;
                }
                if line.trim().is_empty() {
                    continue;
                }
                match process_line(&line, pub_key_hex)? {
                    Some(LineAction::Emit(response)) => {
                        #[cfg(test)]
                        eprintln!("[{}ms] Emit begin", t0.elapsed().as_millis());
                        write_line(&mut client_out, response.as_bytes()).await?;
                        #[cfg(test)]
                        eprintln!("[{}ms] Emit done", t0.elapsed().as_millis());
                    }
                    Some(LineAction::Forward(request)) => {
                        #[cfg(test)]
                        eprintln!("[{}ms] Forward begin", t0.elapsed().as_millis());
                        let serialized = serialize(&request)?;
                        // The child may already have exited (broken pipe); the
                        // proxy stays up for the remaining client traffic.
                        if let Err(e) = write_line(&mut child_in, serialized.as_bytes()).await {
                            eprintln!("Error forwarding to GitHub server: {e}");
                        }
                        #[cfg(test)]
                        eprintln!("[{}ms] Forward done", t0.elapsed().as_millis());
                    }
                    None => {}
                }
            }
            read = child_out.read_line(&mut child_line), if !child_closed => {
                #[cfg(test)]
                eprintln!("[{}ms] child-arm-fired", t0.elapsed().as_millis());
                let n = read?;
                if n == 0 {
                    #[cfg(test)]
                    eprintln!("[{}ms] child-EOF", t0.elapsed().as_millis());
                    child_closed = true;
                    continue;
                }
                #[cfg(test)]
                eprintln!("[{}ms] child-arm-forwarding", t0.elapsed().as_millis());
                client_out.write_all(child_line.as_bytes()).await?;
                client_out.flush().await?;
            }
        }
    }
    Ok(())
}

/// Spawn `npx -y @modelcontextprotocol/server-github` and proxy over the real
/// stdio. Returns once our stdin reaches EOF, then reaps the child.
pub async fn run(pub_key_hex: &str) -> io::Result<()> {
    let mut child = Command::new("npx")
        .arg("-y")
        .arg(GITHUB_SERVER_PACKAGE)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::inherit())
        .kill_on_drop(true)
        .spawn()?;
    let child_stdin = child.stdin.take().ok_or_else(|| io::Error::other("child stdin not piped"))?;
    let child_stdout = child.stdout.take().ok_or_else(|| io::Error::other("child stdout not piped"))?;
    let result = run_loop(tokio::io::stdin(), child_stdin, child_stdout, tokio::io::stdout(), pub_key_hex).await;
    let _status = child.wait().await?;
    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::signature::canonical_payload;
    use ed25519_dalek::{Signer as _, SigningKey};
    use serde_json::json;
    use tokio::io::{AsyncReadExt, AsyncWriteExt, DuplexStream};

    fn signed_sat(claims: Value) -> Value {
        let key = SigningKey::from_bytes(&[13u8; 32]);
        let payload = canonical_payload(&claims).unwrap();
        let signature = key.sign(payload.as_bytes());
        let mut token = claims;
        token["signature"] = Value::String(hex::encode(signature.to_bytes()));
        token
    }

    fn pub_key_hex() -> String {
        hex::encode(SigningKey::from_bytes(&[13u8; 32]).verifying_key().to_bytes())
    }

    #[test]
    fn non_tools_call_is_forwarded_verbatim() {
        let line = r#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}"#;
        match process_line(line, &pub_key_hex()).unwrap().unwrap() {
            LineAction::Forward(req) => {
                assert_eq!(req["method"], "initialize");
                assert_eq!(req["id"], 1);
            }
            _ => panic!("expected forward"),
        }
    }

    #[test]
    fn tools_call_without_sat_is_rejected() {
        let line = r#"{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_pr","arguments":{"repo":"a/b"}}}"#;
        match process_line(line, &pub_key_hex()).unwrap().unwrap() {
            LineAction::Emit(resp) => {
                let v: Value = serde_json::from_str(&resp).unwrap();
                assert_eq!(v["error"]["code"], -32602);
                assert_eq!(v["error"]["message"], MISSING_SAT_MESSAGE);
            }
            _ => panic!("expected emit"),
        }
    }

    #[test]
    fn tools_call_with_invalid_sat_is_rejected() {
        let line = r#"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_pr","arguments":{"_sat":{"signature":"aa"}}}}"#;
        match process_line(line, &pub_key_hex()).unwrap().unwrap() {
            LineAction::Emit(resp) => {
                let v: Value = serde_json::from_str(&resp).unwrap();
                assert_eq!(v["error"]["message"], INVALID_SAT_MESSAGE);
            }
            _ => panic!("expected emit"),
        }
    }

    #[test]
    fn tools_call_with_valid_sat_forwards_stripped() {
        let sat = signed_sat(json!({"agent": "ace"}));
        let args = json!({"_sat": sat, "repo": "a/b"});
        let line = format!(r#"{{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{{"name":"get_pr","arguments":{args}}}}}"#);
        match process_line(&line, &pub_key_hex()).unwrap().unwrap() {
            LineAction::Forward(req) => {
                assert_eq!(req["params"]["arguments"]["repo"], "a/b");
                assert!(req["params"]["arguments"].get("_sat").is_none());
            }
            _ => panic!("expected forward"),
        }
    }

    #[test]
    fn malformed_json_is_an_error() {
        assert!(process_line("not-json", &pub_key_hex()).is_err());
    }

    async fn read_line(stream: &mut DuplexStream) -> Vec<u8> {
        let mut buf = Vec::new();
        let mut byte = [0u8; 1];
        loop {
            let n = stream.read(&mut byte).await.unwrap();
            if n == 0 {
                break;
            }
            buf.push(byte[0]);
            if byte[0] == b'\n' {
                break;
            }
        }
        buf
    }

    #[tokio::test]
    async fn duplex_end_to_end() {
        let (mut client_write, client_stdin) = tokio::io::duplex(4096);
        let (client_stdout, mut stdout_read) = tokio::io::duplex(4096);
        let (child_stdin, mut child_read) = tokio::io::duplex(4096);
        let (mut child_write, child_stdout) = tokio::io::duplex(4096);

        let pk = pub_key_hex();
        let handle = tokio::spawn(async move {
            run_loop(client_stdin, child_stdin, child_stdout, client_stdout, &pk)
                .await
                .unwrap();
        });

        // 1. initialize is forwarded to the child verbatim.
        let t0 = std::time::Instant::now();
        eprintln!("[{}ms] STEP1 write", t0.elapsed().as_millis());
        client_write
            .write_all(b"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\"}\n")
            .await
            .unwrap();
        eprintln!("[{}ms] STEP1 read", t0.elapsed().as_millis());
        assert_eq!(
            read_line(&mut child_read).await,
            b"{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"initialize\"}\n"
        );
        eprintln!("[{}ms] STEP1 done", t0.elapsed().as_millis());

        // 2. tools/call with a valid SAT is forwarded with _sat stripped.
        eprintln!("[{}ms] STEP2 write", t0.elapsed().as_millis());
        let sat = signed_sat(json!({"agent": "ace"}));
        let args = json!({"_sat": sat, "repo": "a/b"});
        let line = format!(r#"{{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{{"name":"get_pr","arguments":{args}}}}}"#);
        client_write.write_all(line.as_bytes()).await.unwrap();
        eprintln!("[{}ms] STEP2 read", t0.elapsed().as_millis());
        let forwarded = read_line(&mut child_read).await;
        let v: Value = serde_json::from_slice(forwarded.trim_ascii()).unwrap();
        assert!(v["params"]["arguments"].get("_sat").is_none());
        assert_eq!(v["params"]["arguments"]["repo"], "a/b");
        eprintln!("[{}ms] STEP2 done", t0.elapsed().as_millis());

        // 3. tools/call without a SAT is answered by the proxy.
        eprintln!("[{}ms] STEP3 write", t0.elapsed().as_millis());
        client_write
            .write_all(b"{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"get_pr\",\"arguments\":{\"repo\":\"c/d\"}}}\n")
            .await
            .unwrap();
        eprintln!("[{}ms] STEP3 read", t0.elapsed().as_millis());
        let resp = read_line(&mut stdout_read).await;
        let v: Value = serde_json::from_slice(resp.trim_ascii()).unwrap();
        assert_eq!(v["error"]["message"], MISSING_SAT_MESSAGE);
        eprintln!("[{}ms] STEP3 done", t0.elapsed().as_millis());

        // 4. Child output is forwarded to our stdout.
        eprintln!("[{}ms] STEP4 child write", t0.elapsed().as_millis());
        child_write
            .write_all(b"{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{\"ok\":true}}\n")
            .await
            .unwrap();
        eprintln!("[{}ms] STEP4 read", t0.elapsed().as_millis());
        let forwarded = read_line(&mut stdout_read).await;
        assert!(forwarded.starts_with(b"{\"jsonrpc\":\"2.0\""));
        eprintln!("[{}ms] STEP4 done", t0.elapsed().as_millis());

        // 5. Closing our stdin ends the loop.
        eprintln!("[{}ms] STEP5 drop", t0.elapsed().as_millis());
        drop(client_write);
        handle.await.unwrap();
        eprintln!("[{}ms] STEP5 done", t0.elapsed().as_millis());
    }
}