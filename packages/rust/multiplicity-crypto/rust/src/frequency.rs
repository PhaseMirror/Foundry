//! Classical/quantum frequency mapping.
//!
//! Mirrors `ts/src/frequency.ts` `computeFrequency`: maps a classical payload
//! to 32-bin frequencies and a quantum state to 16-bin phase frequencies,
//! then concatenates into `F_t`.

/// Input to the frequency mapper.
#[derive(Debug, Clone)]
pub struct FrequencyInput {
    pub x_t: Vec<u8>,
    pub psi_t: Vec<u8>,
}

/// Output of the frequency mapper.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrequencyOutput {
    pub f_c: Vec<u8>,
    pub f_q: Vec<u8>,
    pub f_t: Vec<u8>,
}

const CLASSICAL_BINS: usize = 32;
const QUANTUM_BINS: usize = 16;

/// Map classical payload bytes to 32-bin frequencies (`b % 32`).
#[must_use]
pub fn frequency_classical(x_t: &[u8]) -> Vec<u8> {
    x_t.iter().map(|&b| b % CLASSICAL_BINS as u8).collect()
}

/// Map quantum state bytes to 16-bin phase frequencies (`b % 16`).
#[must_use]
pub fn frequency_quantum(psi_t: &[u8]) -> Vec<u8> {
    psi_t.iter().map(|&b| b % QUANTUM_BINS as u8).collect()
}

/// Compute the combined frequency mapping `F_t = F_c || F_q`.
#[must_use]
pub fn compute_frequency(input: &FrequencyInput) -> FrequencyOutput {
    let f_c = frequency_classical(&input.x_t);
    let f_q = frequency_quantum(&input.psi_t);
    let mut f_t = f_c.clone();
    f_t.extend_from_slice(&f_q);
    FrequencyOutput { f_c, f_q, f_t }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classical_mapping_matches_spec() {
        let f_c = frequency_classical(&[0, 1, 32, 33, 64, 65]);
        assert_eq!(f_c, vec![0, 1, 0, 1, 0, 1]);
    }

    #[test]
    fn quantum_mapping_matches_spec() {
        let f_q = frequency_quantum(&[0, 1, 16, 17]);
        assert_eq!(f_q, vec![0, 1, 0, 1]);
    }

    #[test]
    fn combined_frequency_concatenates() {
        let input = FrequencyInput {
            x_t: vec![0, 32, 64],
            psi_t: vec![0, 16],
        };
        let out = compute_frequency(&input);
        assert_eq!(out.f_c, vec![0, 0, 0]);
        assert_eq!(out.f_q, vec![0, 0]);
        assert_eq!(out.f_t, vec![0, 0, 0, 0, 0]);
    }

    #[test]
    fn frequency_output_f_t_is_f_c_concat_f_q() {
        let input = FrequencyInput {
            x_t: vec![42, 17, 99],
            psi_t: vec![5, 11],
        };
        let out = compute_frequency(&input);
        let mut expected = out.f_c.clone();
        expected.extend_from_slice(&out.f_q);
        assert_eq!(out.f_t, expected);
    }
}
