//! The shape and data corpus every differential test walks.
//!
//! Shapes are chosen to be awkward on purpose: zero, one, primes, powers of two
//! plus one, and depths on both sides of every narrow-register threshold. A
//! corpus of round numbers would agree with anything.

/// One case: a shape and a deterministic fill.
#[derive(Clone, Copy, Debug)]
pub struct Case {
    /// Rows of A.
    pub m: usize,
    /// Depth.
    pub k: usize,
    /// Columns of B.
    pub n: usize,
    /// The seed the fill is derived from, recorded so a failure is reproducible.
    pub seed: u64,
}

impl Case {
    /// Deterministic `i8` fill.
    ///
    /// A small xorshift rather than a dependency: the sample is recorded by its
    /// seed, and a generator whose behaviour could change with a minor version
    /// bump would make that record worthless.
    pub fn fill_i8(&self, len: usize, salt: u64) -> Vec<i8> {
        let mut s = self.seed ^ salt.wrapping_mul(0x9E37_79B9_7F4A_7C15);
        (0..len)
            .map(|_| {
                s ^= s << 13;
                s ^= s >> 7;
                s ^= s << 17;
                (s >> 33) as i8
            })
            .collect()
    }

    /// The same fill widened, for an oracle that only speaks `i32`.
    pub fn widen(xs: &[i8]) -> Vec<i32> {
        xs.iter().map(|&x| x as i32).collect()
    }
}

/// The standing corpus.
#[derive(Clone, Debug)]
pub struct Corpus {
    /// Every case.
    pub cases: Vec<Case>,
}

impl Corpus {
    /// The corpus every `CX-*` and `CB-*` test walks.
    pub fn standard(seed: u64) -> Self {
        let shapes: &[(usize, usize, usize)] = &[
            // Degenerate. Not special cases; they take the same path (CT-04).
            (0, 0, 0),
            (0, 5, 7),
            (5, 0, 7),
            (5, 7, 0),
            (1, 1, 1),
            // Primes, so no block size divides anything.
            (3, 7, 11),
            (13, 17, 19),
            (23, 29, 31),
            (1, 97, 1),
            (97, 1, 97),
            // One either side of a power of two, where a padded kernel would
            // show its seams.
            (7, 8, 9),
            (15, 16, 17),
            (31, 32, 33),
            (63, 64, 65),
            // Rectangular extremes.
            (1, 1024, 1),
            (128, 3, 128),
            (2, 4096, 2),
        ];
        Self {
            cases: shapes
                .iter()
                .enumerate()
                .map(|(i, &(m, k, n))| Case {
                    m,
                    k,
                    n,
                    seed: seed.wrapping_add(i as u64),
                })
                .collect(),
        }
    }
}
