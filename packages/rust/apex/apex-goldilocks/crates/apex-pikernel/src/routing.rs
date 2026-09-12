use std::collections::{HashMap, HashSet};
use crate::projectors::PiIndexGrid;

pub static CHANNEL_MAP: once_cell::sync::Lazy<HashMap<u32, &'static str>> = once_cell::sync::Lazy::new(|| {
    let mut m = HashMap::new();
    m.insert(2, "attention");
    m.insert(3, "embedding");
    m.insert(5, "loss");
    m.insert(7, "normalization");
    m.insert(11, "feedforward");
    m.insert(13, "residual");
    m
});

pub fn default_route(pi_id: &[usize], channel_primes: &[u32]) -> u32 {
    let fn_type = pi_id[0];
    channel_primes[fn_type % channel_primes.len()]
}

pub fn build_channel_blocks(
    grid: &PiIndexGrid,
    channel_primes: &[u32]
) -> (HashMap<u32, Vec<Vec<usize>>>, HashMap<u32, Vec<usize>>) {
    let mut channel_atoms = HashMap::new();

    for pi_id in &grid.pi_ids {
        let p = default_route(pi_id, channel_primes);
        channel_atoms.entry(p).or_insert_with(Vec::new).push(pi_id.clone());
    }

    let mut channel_indices = HashMap::new();
    for (p, atoms) in &channel_atoms {
        let mut indices = HashSet::new();
        for pi_id in atoms {
            if let Some(pi_indices) = grid.indices(pi_id) {
                for &idx in pi_indices {
                    indices.insert(idx);
                }
            }
        }
        let mut indices_vec: Vec<usize> = indices.into_iter().collect();
        indices_vec.sort_unstable();
        channel_indices.insert(*p, indices_vec);
    }

    (channel_atoms, channel_indices)
}
