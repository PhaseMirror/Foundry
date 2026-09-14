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
use tokio::io::{AsyncRead, AsyncReadExt as _, AsyncWrite, AsyncWriteExt, BufWriter as AsyncBufWriter};
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
/// Mirrors the Python adapter's architecture: a dedicated forwarding task
/// drains `child_stdout` line by line and feeds a channel, while the main loop
/// selects between our stdin and that channel. The main loop writes to
/// `client_stdout` exclusively, so output ordering is preserved.
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
    Ro: AsyncRead + Unpin + Send + 'static,
    Wo: AsyncWrite + Unpin,
{
    let mut client_in = client_stdin;
    let mut child_in = AsyncBufWriter::new(child_stdin);
    let mut client_out = AsyncBufWriter::new(client_stdout);

    // Child -> client forwarding task. Keeps the upstream blob out of the way
    // so the main select only multiplexes our stdin with channel traffic.
    let (tx, mut rx) = tokio::sync::mpsc::channel::<Vec<u8>>(32);
    let mut child_out = child_stdout;
    let forwarder = tokio::spawn(async move {
        let mut child_line = Vec::new();
        loop {
            child_line.clear();
            match read_line_into(&mut child_out, &mut child_line).await {
                Ok(0) => break,
                Ok(_) => {
                    if tx.send(child_line.clone()).await.is_err() {
                        break;
                    }
                }
                Err(_) => break,
            }
        }
    });
    drop(forwarder);

    let mut line = Vec::new();
    loop {
        line.clear();
        tokio::select! {
            read = read_line_into(&mut client_in, &mut line) => {
                let n = read?;
                if n == 0 {
                    break;
                }
                if line.iter().all(|b| b.is_ascii_whitespace()) {
                    continue;
                }
                let line_str = std::str::from_utf8(&line)
                    .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, format!("non-UTF8 on stdin: {e}")))?;
                match process_line(line_str, pub_key_hex)? {
                    Some(LineAction::Emit(response)) => {
                        write_line(&mut client_out, response.as_bytes()).await?;
                    }
                    Some(LineAction::Forward(request)) => {
                        let serialized = serialize(&request)?;
                        // The child may already have exited (broken pipe); the
                        // proxy stays up for the remaining client traffic.
                        if let Err(e) = write_line(&mut child_in, serialized.as_bytes()).await {
                            eprintln!("Error forwarding to GitHub server: {e}");
                        }
                    }
                    None => {}
                }
            }
            child_line = rx.recv() => {
                if let Some(child_line) = child_line {
                    client_out.write_all(&child_line).await?;
                    client_out.flush().await?;
                }
            }
        }
    }
    Ok(())
}

/// Read a single `\n`-terminated line from `reader` into `buf`.
///
/// Reads one byte at a time so the future can be freely multiplexed with
/// `tokio::select!` without relying on `AsyncBufReader` internal buffering.
/// Returns the number of bytes written, or `0` on EOF (an unterminated final
/// line is delivered as written).
async fn read_line_into(reader: &mut (impl AsyncRead + Unpin), buf: &mut Vec<u8>) -> io::Result<usize> {
    buf.clear();
    let mut byte = [0u8; 1];
    loop {
        let n = reader.read(&mut byte).await?;
        if n == 0 {
            return Ok(buf.len());
        }
        buf.push(byte[0]);
        if byte[0] == b'\n' {
            return Ok(buf.len());
        }
    }
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
    use std::time::Duration;
    use tokio::io::{AsyncRead, AsyncWriteExt};

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

    async fn read_line(stream: &mut (impl AsyncRead + Unpin)) -> Vec<u8> {
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

    /// Drive `run_loop` over real OS pipes (no in-memory `tokio::io::duplex`).
    /// A line-echo shell loop (`sh`) plays the role of the upstream GitHub MCP
    /// server: it echoes every forwarded request back immediately, exercising
    /// the child->client path (plain `cat` would buffer its pipe output).
    #[cfg(unix)]
    #[tokio::test]
    async fn run_loop_over_real_pipes() {
        use tokio::net::unix::pipe;
        use tokio::process::Command;

        let (mut client_write, client_stdin) = pipe::pipe().unwrap();
        let (client_stdout, mut stdout_read) = pipe::pipe().unwrap();

        let mut child = Command::new("sh")
            .args(["-c", "while IFS= read -r l; do printf '%s\\n' \"$l\"; done"])
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::null())
            .kill_on_drop(true)
            .spawn()
            .unwrap();
        let child_stdin = child.stdin.take().unwrap();
        let child_stdout = child.stdout.take().unwrap();

        let pk = pub_key_hex();
        let handle = tokio::spawn(async move {
            run_loop(client_stdin, child_stdin, child_stdout, client_stdout, &pk)
                .await
                .unwrap();
        });

        // 1. initialize is forwarded to the child; the echo loop returns it.
        let line = r#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}
"#;
        client_write.write_all(line.as_bytes()).await.unwrap();
        let echoed = tokio::time::timeout(Duration::from_secs(5), read_line(&mut stdout_read))
            .await
            .expect("initialize not forwarded to client");
        let v: Value = serde_json::from_slice(&echoed).unwrap();
        assert_eq!(v["id"], 1);
        assert_eq!(v["method"], "initialize");

        // 2. tools/call with a valid SAT is forwarded with _sat stripped.
        let sat = signed_sat(json!({"agent": "ace"}));
        let args = json!({"_sat": sat, "repo": "a/b"});
        let mut line = format!(
            r#"{{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{{"name":"get_pr","arguments":{args}}}}}"#
        );
        line.push('\n');
        client_write.write_all(line.as_bytes()).await.unwrap();
        let echoed = tokio::time::timeout(Duration::from_secs(5), read_line(&mut stdout_read))
            .await
            .expect("stripped tools/call not forwarded");
        let v: Value = serde_json::from_slice(&echoed).unwrap();
        assert_eq!(v["id"], 2);
        assert!(v["params"]["arguments"].get("_sat").is_none());
        assert_eq!(v["params"]["arguments"]["repo"], "a/b");

        // 3. tools/call without a SAT is answered by the proxy, not cat.
        client_write
            .write_all(b"{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"get_pr\",\"arguments\":{\"repo\":\"c/d\"}}}\n")
            .await
            .unwrap();
        let resp = tokio::time::timeout(Duration::from_secs(5), read_line(&mut stdout_read))
            .await
            .expect("missing-sat error not emitted");
        let v: Value = serde_json::from_slice(&resp).unwrap();
        assert_eq!(v["id"], 3);
        assert_eq!(v["error"]["code"], -32602);
        assert_eq!(v["error"]["message"], MISSING_SAT_MESSAGE);

        // 4. Closing our stdin ends the loop; the child is reaped.
        drop(client_write);
        tokio::time::timeout(Duration::from_secs(5), handle)
            .await
            .expect("run_loop did not exit on client EOF")
            .unwrap();
        let _status = tokio::time::timeout(Duration::from_secs(5), child.wait()).await;
    }
}