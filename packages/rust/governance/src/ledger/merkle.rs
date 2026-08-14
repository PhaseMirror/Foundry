use sha2::{Sha256, Digest};
use std::path::{Path, PathBuf};
use std::fs;
use regex::Regex;
use std::sync::LazyLock;

static GOVERNANCE_POINTER_FILE_SUFFIX: &str = "contracts/shared/constants.py";
static GOVERNANCE_POINTER_LINE: &str = "GOVERNANCE_MERKLE_ROOT_TX_ID: int = 0";

static POINTER_RE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"(?m)^\s*GOVERNANCE_MERKLE_ROOT_TX_ID\s*(?::\s*int\s*)?=\s*\d+\s*$").unwrap()
});

pub fn is_governance_pointer_file(file_path: &Path) -> bool {
    file_path.to_string_lossy().replace('\\', "/").ends_with(GOVERNANCE_POINTER_FILE_SUFFIX)
}

pub fn canonicalize_governance_pointer(content: &[u8], file_path: &Path) -> Vec<u8> {
    if !is_governance_pointer_file(file_path) {
        return content.to_vec();
    }

    if let Ok(text) = std::str::from_utf8(content) {
        let canonicalized = POINTER_RE.replace_all(text, GOVERNANCE_POINTER_LINE);
        return canonicalized.as_bytes().to_vec();
    }
    content.to_vec()
}

pub fn sha256_bytes(content: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(content);
    hex::encode(hasher.finalize())
}

pub fn governance_root_hash_details(file_path: &Path) -> Result<serde_json::Value, String> {
    let content = fs::read(file_path).map_err(|e| format!("Failed to read file: {}", e))?;
    let raw_hash = sha256_bytes(&content);

    if is_governance_pointer_file(file_path) {
        let root_input_bytes = canonicalize_governance_pointer(&content, file_path);
        let root_input_hash = sha256_bytes(&root_input_bytes);
        return Ok(serde_json::json!({
            "raw_hash": raw_hash,
            "root_input_hash": root_input_hash,
            "is_canonicalized": raw_hash != root_input_hash,
            "hash_semantics": "canonicalized_governance_pointer",
        }));
    }

    Ok(serde_json::json!({
        "raw_hash": raw_hash,
        "root_input_hash": raw_hash,
        "is_canonicalized": false,
        "hash_semantics": "raw_bytes",
    }))
}

pub fn merkle_tree(hashes: &[String]) -> (String, serde_json::Value) {
    if hashes.is_empty() {
        let root = sha256_bytes(&[]);
        return (root.clone(), serde_json::json!({"root": root, "type": "empty"}));
    }

    if hashes.len() == 1 {
        return (hashes[0].clone(), serde_json::json!({"root": &hashes[0], "type": "single_leaf"}));
    }

    let mut tree = serde_json::Map::new();
    for (i, h) in hashes.iter().enumerate() {
        tree.insert(format!("leaf_{}", i), serde_json::json!(h));
    }

    let mut current_level = hashes.to_vec();
    let mut level_num = 0;

    while current_level.len() > 1 {
        level_num += 1;
        let mut next_level = Vec::new();

        for i in (0..current_level.len()).step_by(2) {
            let left = &current_level[i];
            let right = if i + 1 < current_level.len() { &current_level[i + 1] } else { left };

            let mut hasher = Sha256::new();
            hasher.update(format!("{}{}", left, right).as_bytes());
            let parent = hex::encode(hasher.finalize());
            next_level.push(parent.clone());

            tree.insert(format!("level_{}_node_{}", level_num, next_level.len() - 1), serde_json::json!({
                "left": left,
                "right": right,
                "parent": parent,
            }));
        }
        current_level = next_level;
    }

    let root = current_level[0].clone();
    tree.insert("root".to_string(), serde_json::json!(root));
    (root, serde_json::Value::Object(tree))
}

pub fn compute_governance_root(
    immutable_files: &[PathBuf],
    governance_critical_tools: Option<&[PathBuf]>,
) -> Result<String, String> {
    let mut all_files = immutable_files.to_vec();
    if let Some(extra) = governance_critical_tools {
        all_files.extend_from_slice(extra);
    }
    
    // Deduplicate and sort
    let mut seen = std::collections::HashSet::new();
    all_files.retain(|p| seen.insert(p.clone()));
    all_files.sort_by(|a, b| a.to_string_lossy().cmp(&b.to_string_lossy()));

    if all_files.is_empty() {
        return Ok(sha256_bytes(&[]));
    }

    let mut hashes = Vec::new();
    for file_path in all_files {
        let details = governance_root_hash_details(&file_path)?;
        hashes.push(details["root_input_hash"].as_str().unwrap().to_string());
    }

    let (root, _) = merkle_tree(&hashes);
    Ok(root)
}
