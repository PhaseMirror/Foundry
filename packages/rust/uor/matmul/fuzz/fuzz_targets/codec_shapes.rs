//! `CK-06`, `CS-03`: a codec either describes a matrix or reports that it does
//! not, and never anything else.
//!
//! The interesting inputs here are the *malformed* ones: run lists whose counts
//! do not sum to the row width, shapes that disagree with the code count,
//! blocks that do not divide. Every one of them must produce a `None` at
//! construction, and none may reach the arithmetic.

#![no_main]

use libfuzzer_sys::fuzz_target;
use uor_matmul::prelude::*;
use uor_matmul_codec::Runs;
use uor_matmul_core::Full;

fuzz_target!(|data: &[u8]| {
    if data.len() < 8 {
        return;
    }
    let rows = (data[0] % 9) as usize;
    let cols = (data[1] % 33) as usize;

    let table: [Alphabet<i8, Full<i8>>; 16] =
        core::array::from_fn(|i| Alphabet::of((i as i8) - 8));
    let grid = Grid::new(&table);

    // A grid codec: fixed width, so only the shape can disagree.
    let codes: Vec<u16> = data[2..].iter().map(|&b| b as u16).collect();
    if let Some(m) = CodedMatrix::new(grid, rows, cols, &codes) {
        // If it constructed, every element decodes and the row decode fills
        // exactly `cols`.
        let mut out = vec![Alphabet::ZERO; cols];
        for r in 0..rows {
            assert_eq!(m.decode_row_into(r, &mut out), cols);
        }
    }

    // A run codec: variable width, so the counts must sum to the row width.
    let runs: Vec<(u32, u16)> = data[2..]
        .chunks_exact(2)
        .map(|c| ((c[0] % 9) as u32, c[1] as u16))
        .collect();
    if let Some(sparse) = Runs::<'_, i8, Full<i8>, _, 8>::new(grid, &runs) {
        let indices: Vec<u32> = (0..runs.len() as u32).collect();
        if let Some(m) = CodedMatrix::new(sparse, rows, cols, &indices) {
            // CK-06: if it constructed, the counts sum to the row width.
            let mut out = vec![Alphabet::ZERO; cols];
            for r in 0..rows {
                assert_eq!(m.decode_row_into(r, &mut out), cols);
            }
        }
    }
});
