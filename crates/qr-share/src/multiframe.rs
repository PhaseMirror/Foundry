use serde::{Deserialize, Serialize};
use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine};
use crc32fast::Hasher;
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Frame {
    pub ver: String,
    pub kind: String,
    pub bundle: String,
    pub seq: usize,
    pub total: usize,
    pub data_b64: String,
    pub chunk_crc32: String,
    pub payload_crc32: String,
}

pub struct Aggregator {
    map: HashMap<String, AggregatedData>,
}

struct AggregatedData {
    total: usize,
    payload_crc32: String,
    chunks: Vec<Option<Vec<u8>>>,
    received: Vec<bool>,
}

impl Aggregator {
    pub fn new() -> Self {
        Aggregator { map: HashMap::new() }
    }

    pub fn add(&mut self, frame: Frame) -> Result<(String, usize, usize, String, Vec<bool>), String> {
        if frame.ver != "LP2" || frame.kind != "share" {
            return Err("unsupported frame".to_string());
        }
        
        let bytes = URL_SAFE_NO_PAD.decode(&frame.data_b64).map_err(|e| e.to_string())?;
        if format!("{:08x}", crc32(&bytes)) != frame.chunk_crc32 {
            return Err("chunk checksum mismatch".to_string());
        }

        let key = format!("{}:{}", frame.bundle, frame.payload_crc32);
        let agg = self.map.entry(key).or_insert_with(|| AggregatedData {
            total: frame.total,
            payload_crc32: frame.payload_crc32.clone(),
            chunks: vec![None; frame.total],
            received: vec![false; frame.total],
        });

        agg.chunks[frame.seq] = Some(bytes);
        agg.received[frame.seq] = true;
        
        let have = agg.received.iter().filter(|&&r| r).count();
        Ok((frame.bundle, agg.total, have, agg.payload_crc32.clone(), agg.received.clone()))
    }

    pub fn complete(&self, bundle: &str, payload_crc32: &str) -> bool {
        self.map.get(&format!("{}:{}", bundle, payload_crc32))
            .map(|agg| agg.received.iter().all(|&r| r))
            .unwrap_or(false)
    }

    pub fn assemble(&self, bundle: &str, payload_crc32: &str) -> Result<Vec<u8>, String> {
        let agg = self.map.get(&format!("{}:{}", bundle, payload_crc32))
            .ok_or("bundle not found")?;
        
        if !agg.received.iter().all(|&r| r) {
            return Err("incomplete".to_string());
        }
        
        let mut bytes = Vec::new();
        for chunk in &agg.chunks {
            bytes.extend_from_slice(chunk.as_ref().unwrap());
        }
        
        if format!("{:08x}", crc32(&bytes)) != agg.payload_crc32 {
            return Err("payload checksum mismatch".to_string());
        }
        
        Ok(bytes)
    }
}

pub fn crc32(bytes: &[u8]) -> u32 {
    let mut hasher = Hasher::new();
    hasher.update(bytes);
    hasher.finalize()
}
