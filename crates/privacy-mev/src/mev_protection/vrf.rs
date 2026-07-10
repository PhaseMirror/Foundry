use crate::utils::keccak::{viem_to_hex_str, viem_keccak256};

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct OrderingRequest {
    pub tx_hash: String,
    pub sender: String,
    pub nonce: u64,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct OrderedTransaction {
    pub tx_hash: String,
    pub sender: String,
    pub nonce: u64,
    pub order_index: usize,
    pub vrf_proof: String,
}

pub struct VRFOrdering;

impl VRFOrdering {
    pub fn determine_order(
        requests: &[OrderingRequest],
        seed: &str,
    ) -> Result<Vec<OrderedTransaction>, anyhow::Error> {
        determine_order(requests, seed)
    }

    pub fn verify_order(
        ordered_tx: &OrderedTransaction,
        seed: &str,
        total_count: usize,
    ) -> Result<bool, anyhow::Error> {
        verify_order(ordered_tx, seed, total_count)
    }
}

/// Simulates a VRF-based ordering mechanism using hashing.
/// Score = Hash(seed + txHash + sender + nonce)
pub fn determine_order(
    requests: &[OrderingRequest],
    seed: &str,
) -> Result<Vec<OrderedTransaction>, anyhow::Error> {
    let mut scored: Vec<(&OrderingRequest, String)> = requests
        .iter()
        .map(|req| {
            let input = format!("{}:{}:{}:{}", seed, req.tx_hash, req.sender, req.nonce);
            let score = viem_keccak256(&viem_to_hex_str(&input));
            (req, score)
        })
        .collect();

    // Sort by score ascending lexicographically (since hex string sorting is equivalent to bigint sorting)
    scored.sort_by(|a, b| a.1.cmp(&b.1));

    let ordered = scored
        .into_iter()
        .enumerate()
        .map(|(index, (req, _score))| OrderedTransaction {
            tx_hash: req.tx_hash.clone(),
            sender: req.sender.clone(),
            nonce: req.nonce,
            order_index: index,
            vrf_proof: format!("vrf_proof_for_{}_at_index_{}", req.tx_hash, index),
        })
        .collect();

    Ok(ordered)
}

/// Verifies that the ordered transaction is valid relative to total transactions count.
pub fn verify_order(
    ordered_tx: &OrderedTransaction,
    _seed: &str,
    total_count: usize,
) -> Result<bool, anyhow::Error> {
    let has_proof = !ordered_tx.vrf_proof.is_empty();
    let valid_index = ordered_tx.order_index < total_count;
    Ok(has_proof && valid_index)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_determine_order() {
        let requests = vec![
            OrderingRequest {
                tx_hash: "0xtx1".to_string(),
                sender: "0xalice".to_string(),
                nonce: 0,
            },
            OrderingRequest {
                tx_hash: "0xtx2".to_string(),
                sender: "0xbob".to_string(),
                nonce: 0,
            },
        ];

        let seed = "myseed";
        let ordered = determine_order(&requests, seed).unwrap();
        assert_eq!(ordered.len(), 2);
        assert_eq!(ordered[0].order_index, 0);
        assert_eq!(ordered[1].order_index, 1);

        assert!(verify_order(&ordered[0], seed, 2).unwrap());
        assert!(!verify_order(&ordered[0], seed, 0).unwrap());
    }
}
