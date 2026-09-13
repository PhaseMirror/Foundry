//! Port of `config.py` (github_adapter).
//!
//! The Python module reads OS environment variables (after `load_dotenv()`);
//! this port reads `std::env` directly. No `.env` file loader is pulled in —
//! the run command is expected to export the variables.

/// Environment-driven configuration for the adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Config {
    /// `GITHUB_WEBHOOK_SECRET` (default `"secret"`).
    pub github_webhook_secret: String,
    /// `GITHUB_ACCESS_TOKEN` (default `""`).
    pub github_access_token: String,
    /// `MCP_HOST`, e.g. `"mcp-server"` (None when unset).
    pub mcp_host: Option<String>,
    /// `MCP_PORT` (None when unset; note: the Python makes the default
    /// depend on whether the variable is present at all).
    pub mcp_port: Option<u16>,
    /// `MCP_SERVER_CMD` split on whitespace (None when unset).
    pub mcp_server_cmd: Option<Vec<String>>,
    /// `EVALUATION_MODE` (default `"simulate"`; `"commit"` is the binding
    /// alternative).
    pub evaluation_mode: String,
}

impl Config {
    /// `Config::from_env()` — mirror of the Python class attribute reads.
    pub fn from_env() -> Self {
        let get = |k: &str| std::env::var(k).ok();

        let mcp_host = get("MCP_HOST");
        let mcp_port = get("MCP_PORT").and_then(|p| p.parse::<u16>().ok());
        let mcp_server_cmd =
            get("MCP_SERVER_CMD").map(|cmd| cmd.split_whitespace().map(str::to_string).collect());

        Self {
            github_webhook_secret: get("GITHUB_WEBHOOK_SECRET")
                .unwrap_or_else(|| String::from("secret")),
            github_access_token: get("GITHUB_ACCESS_TOKEN").unwrap_or_default(),
            mcp_host,
            mcp_port,
            mcp_server_cmd,
            evaluation_mode: get("EVALUATION_MODE").unwrap_or_else(|| String::from("simulate")),
        }
    }
}

/// `"simulate" if Config.EVALUATION_MODE == "simulate" else "commit"`.
///
/// Exactly mirrors main.py's mode normalization.
pub fn evaluation_mode(config: &Config) -> String {
    if config.evaluation_mode == "simulate" {
        String::from("simulate")
    } else {
        String::from("commit")
    }
}
