//! Caller-driven parallelism (S12).
//!
//! The library spawns nothing. It declares a partition of the output into
//! independent tiles; the caller's executor --- rayon, embassy, web workers, a
//! bare-metal scheduler --- drives it. That is what keeps `no_std` and
//! zero-allocation intact while still being usable from a threaded host (C1).
//!
//! Every tile writes a disjoint region of `C` and reads only `A` and `B`, so
//! the tiles commute. `CD-02` asserts that the tile count and the completion
//! order do not change the output bytes, which is not a scheduling promise but
//! a consequence of the accumulator: each output element is one exact sum, and
//! no two tiles contribute to the same one.

use uor_matmul_core::Shape;

/// One independently computable region of `C`.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Tile {
    /// First row of `C`.
    pub row: usize,
    /// First column of `C`.
    pub col: usize,
    /// Rows in this tile.
    pub rows: usize,
    /// Columns in this tile.
    pub cols: usize,
}

/// A declared partition of the output into independent tiles.
///
/// An iterator rather than a slice, so the library owns no storage and the
/// caller decides how many tiles to materialize at once.
#[derive(Clone, Copy, Debug)]
pub struct Partition {
    shape: Shape,
    tile_rows: usize,
    tile_cols: usize,
    next: usize,
}

impl Partition {
    /// Partition `shape` into tiles of at most `tile_rows x tile_cols`.
    ///
    /// A zero tile dimension means "the whole extent", so `Partition::new(s, 0, 0)`
    /// is the single-tile partition and needs no special case at the call site.
    pub fn new(shape: Shape, tile_rows: usize, tile_cols: usize) -> Self {
        Self {
            shape,
            tile_rows: if tile_rows == 0 {
                shape.m.max(1)
            } else {
                tile_rows
            },
            tile_cols: if tile_cols == 0 {
                shape.n.max(1)
            } else {
                tile_cols
            },
            next: 0,
        }
    }

    /// How many tiles this partition has.
    pub fn len(&self) -> usize {
        self.rows_of_tiles() * self.cols_of_tiles()
    }

    /// Is the partition empty? True exactly when the output is.
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    fn rows_of_tiles(&self) -> usize {
        self.shape.m.div_ceil(self.tile_rows)
    }

    fn cols_of_tiles(&self) -> usize {
        self.shape.n.div_ceil(self.tile_cols)
    }

    /// The `n`th tile, in a stable order.
    ///
    /// Indexed rather than only iterated, so a work-stealing executor can claim
    /// tile `n` without walking to it --- and so `CD-02` can shuffle the order
    /// and assert the bytes are the same.
    pub fn tile(&self, n: usize) -> Option<Tile> {
        if n >= self.len() {
            return None;
        }
        let cols_of_tiles = self.cols_of_tiles();
        let (ti, tj) = (n / cols_of_tiles, n % cols_of_tiles);
        let row = ti * self.tile_rows;
        let col = tj * self.tile_cols;
        Some(Tile {
            row,
            col,
            rows: self.tile_rows.min(self.shape.m - row),
            cols: self.tile_cols.min(self.shape.n - col),
        })
    }
}

impl Iterator for Partition {
    type Item = Tile;

    fn next(&mut self) -> Option<Tile> {
        let t = self.tile(self.next)?;
        self.next += 1;
        Some(t)
    }
}

#[cfg(test)]
// R7 governs the library, not its tests: these build operands on the heap so
// that awkward shapes can be generated. `CA-01` witnesses the library's own
// zero-allocation claim with a counting allocator.
#[allow(clippy::disallowed_types)]
mod tests {
    use super::*;
    use std::vec::Vec;

    /// `CD-02`: a partition covers `C` exactly once, whatever the tile shape.
    ///
    /// This is the property that makes the tiles commute: every output element
    /// belongs to exactly one tile, so no two tiles contribute to the same
    /// exact sum and there is no order in which they could interfere.
    #[test]
    fn a_partition_covers_the_output_exactly_once_cd_02() {
        for (m, n) in [(0, 0), (1, 1), (5, 7), (13, 17), (64, 64), (97, 3)] {
            for (tr, tc) in [(0, 0), (1, 1), (2, 3), (8, 8), (64, 64), (1000, 1000)] {
                let shape = Shape { m, k: 1, n };
                let part = Partition::new(shape, tr, tc);
                let mut seen = std::vec![0u32; m * n];
                let tiles: Vec<Tile> = part.collect();
                assert_eq!(tiles.len(), part.len());
                for t in &tiles {
                    for i in t.row..t.row + t.rows {
                        for j in t.col..t.col + t.cols {
                            seen[i * n + j] += 1;
                        }
                    }
                }
                assert!(
                    seen.iter().all(|&c| c == 1),
                    "{m}x{n} tiled {tr}x{tc} does not cover exactly once"
                );
            }
        }
    }

    /// `CD-02`: indexing and iterating agree, so a work-stealing executor that
    /// claims tiles out of order sees the same tiles a sequential one does.
    #[test]
    fn indexed_and_sequential_tiles_agree_cd_02() {
        let shape = Shape { m: 13, k: 5, n: 17 };
        let part = Partition::new(shape, 4, 6);
        let sequential: Vec<Tile> = part.collect();
        let indexed: Vec<Tile> = (0..part.len()).map(|n| part.tile(n).unwrap()).collect();
        assert_eq!(sequential, indexed);
        assert_eq!(part.tile(part.len()), None);
    }
}
