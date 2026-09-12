use serde::Deserialize;
use std::sync::OnceLock;

#[derive(Debug, Clone, Deserialize)]
pub struct SupportWindowLimits {
    pub trace_rows: String,
    pub trace_size: String,
    pub trace_compressed: String,
    pub proof_size: String,
    pub fri_queries: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct SupportWindow {
    pub version: u32,
    pub max_n: u64,
    pub max_trace_rows: usize,
    pub max_trace_size_bytes: usize,
    pub max_trace_size_compressed_bytes: usize,
    pub max_proof_size_bytes: usize,
    pub max_queries: u32,
    pub description: String,
    pub limits: SupportWindowLimits,
    pub updated_at: String,
}

fn load_support_window() -> SupportWindow {
    const RAW: &str = include_str!(concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/../../support_window.json"
    ));
    serde_json::from_str(RAW).expect("support_window.json must be valid JSON")
}

pub fn support_window() -> &'static SupportWindow {
    static CACHE: OnceLock<SupportWindow> = OnceLock::new();
    CACHE.get_or_init(load_support_window)
}
