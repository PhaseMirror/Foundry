use std::collections::HashMap;
use std::fs::File;
use std::io::Write;
use serde::{Serialize, Deserialize};
use chrono::Utc;
use sha2::{Sha256, Digest};
use anyhow::Result;
use crate::l1proj::Rational;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LedgerEntry {
    pub step: usize,
    pub pi: Vec<usize>,
    #[serde(with = "rational_string")]
    pub alpha: Rational,
    #[serde(with = "rational_string")]
    pub tau: Rational,
    #[serde(with = "rational_string")]
    pub lambda_soft: Rational,
    #[serde(with = "rational_string")]
    pub l1_weight_sum: Rational,
    #[serde(with = "rational_string")]
    pub change_norm: Rational,
    pub timestamp_ms: i64,
    pub digest: String,
    pub hash_type: String,
}

mod rational_string {
    use super::*;
    use serde::{Deserializer, Serializer};

    pub fn serialize<S>(val: &Rational, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&format!("{}/{}", val.numer(), val.denom()))
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<Rational, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        let parts: Vec<&str> = s.split('/').collect();
        if parts.len() != 2 {
            return Err(serde::de::Error::custom("Invalid rational format"));
        }
        let n = parts[0].parse::<i128>().map_err(serde::de::Error::custom)?;
        let d = parts[1].parse::<i128>().map_err(serde::de::Error::custom)?;
        Ok(Rational::new(n, d))
    }
}

pub trait Ledger: std::fmt::Debug {
    fn append(&mut self, record: HashMap<String, serde_json::Value>) -> Result<String>;
    fn get_entries(&self) -> Vec<LedgerEntry>;
}

#[derive(Debug)]
pub struct DefaultLedger {
    pub filepath: Option<String>,
    pub entries: Vec<LedgerEntry>,
}

impl DefaultLedger {
    pub fn new(filepath: Option<String>) -> Self {
        Self {
            filepath,
            entries: Vec::new(),
        }
    }
}

impl Ledger for DefaultLedger {
    fn append(&mut self, mut record: HashMap<String, serde_json::Value>) -> Result<String> {
        let timestamp_ms = Utc::now().timestamp_millis();
        record.insert("timestamp_ms".to_string(), serde_json::Value::Number(timestamp_ms.into()));

        let canonical_json = serde_json::to_string(&record)?;
        
        let mut hasher = Sha256::new();
        hasher.update(canonical_json.as_bytes());
        let digest = hex::encode(hasher.finalize());
        
        record.insert("digest".to_string(), serde_json::Value::String(digest.clone()));
        record.insert("hash_type".to_string(), serde_json::Value::String("sha256".to_string()));

        let entry: LedgerEntry = serde_json::from_value(serde_json::to_value(record)?)?;
        self.entries.push(entry);

        if let Some(path) = &self.filepath {
            let mut file = File::options().append(true).create(true).open(path)?;
            writeln!(file, "{}", canonical_json)?;
        }

        Ok(digest)
    }

    fn get_entries(&self) -> Vec<LedgerEntry> {
        self.entries.clone()
    }
}

#[derive(Debug)]
pub struct PoseidonLedger {
    pub filepath: Option<String>,
    pub entries: Vec<LedgerEntry>,
}

impl PoseidonLedger {
    pub fn new(filepath: Option<String>) -> Self {
        Self {
            filepath,
            entries: Vec::new(),
        }
    }
}

impl Ledger for PoseidonLedger {
    fn append(&mut self, mut record: HashMap<String, serde_json::Value>) -> Result<String> {
        let timestamp_ms = Utc::now().timestamp_millis();
        record.insert("timestamp_ms".to_string(), serde_json::Value::Number(timestamp_ms.into()));

        let canonical_json = serde_json::to_string(&record)?;
        let hash_uint = crate::poseidon::poseidon_hash_bytes(canonical_json.as_bytes());
        let digest = format!("{:064x}", hash_uint);
        
        record.insert("digest".to_string(), serde_json::Value::String(digest.clone()));
        record.insert("hash_type".to_string(), serde_json::Value::String("poseidon_bn254".to_string()));

        let entry: LedgerEntry = serde_json::from_value(serde_json::to_value(record)?)?;
        self.entries.push(entry);

        if let Some(path) = &self.filepath {
            let mut file = File::options().append(true).create(true).open(path)?;
            writeln!(file, "{}", canonical_json)?;
        }

        Ok(digest)
    }

    fn get_entries(&self) -> Vec<LedgerEntry> {
        self.entries.clone()
    }
}
