// Implementation for kani harnesses

pub const ZEROS_SCALED: [u64; 32] = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
];

pub fn ideal_id(z: u64) -> u64 {
    z
}

pub fn rank_of(table: &[u64], z: u64) -> u64 {
    table.iter().position(|&x| x == z).unwrap_or(0) as u64
}

pub fn compute_trace_pi_n(n: u64) -> u64 {
    n % 10
}
