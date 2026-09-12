//! The dense driver (§5.5, S7--S13).

use uor_matmul_core::{
    AccOf, Accumulator, Alphabet, Backend, Bound, Element, EncodeFrom, EncodeMode, IntegerElement,
    Traversal, Triple,
};

use crate::epilogue::Epilogue;
use crate::scratch::Scratch;

/// What a caller may choose. None of it changes the value computed.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct GemmOptions {
    /// Which order to walk the output in.
    pub traversal: Traversal,
    /// Which factorization of the identity to run.
    pub backend: Backend,
    /// How the single encode step presents the exact accumulator.
    pub encode: EncodeMode,
}

/// `C := epilogue(A * B, C)`.
///
/// Returns `()`. Nothing about the data, the size, or the host can make this
/// fail: the requested product exists, because a [`Triple`] exists (R14, C6).
///
/// # Totality
///
/// - Any `m`, `k`, `n`, including 0, 1, primes, and shapes far past any block
///   size. Zero padding is exact, so an unaligned shape takes this path and not
///   a different one (S8).
/// - Any strides, including negative and zero on the inputs. Transposition is a
///   stride (S7).
/// - Any magnitude, at any depth. The accumulator cannot overflow (§3.2).
/// - Any scratch amount, including none (S13, `CD-04`).
///
/// # Examples
///
/// ```
/// # use uor_matmul_core::{as_alphabet_full, MatView, MatViewMut, Triple};
/// # use uor_matmul_gemm::{gemm, GemmOptions, Linear, Scratch};
/// let a = [1i8, 2, 3, 4];
/// let b = [5i8, 6, 7, 8];
/// let mut c = [0i32; 4];
///
/// let av = MatView::row_major(as_alphabet_full(&a), 2, 2).unwrap();
/// let bv = MatView::row_major(as_alphabet_full(&b), 2, 2).unwrap();
/// let cv = MatViewMut::row_major(&mut c, 2, 2).unwrap();
/// let mut t = Triple::new(av, bv, cv).unwrap();
///
/// gemm(&mut t, &Linear::OVERWRITE, GemmOptions::default(), &mut Scratch::none());
/// assert_eq!(c, [19, 22, 43, 50]);
/// ```
pub fn gemm<E, Bd, O, Ep>(
    triple: &mut Triple<'_, '_, '_, Alphabet<E, Bd>, O>,
    epilogue: &Ep,
    options: GemmOptions,
    scratch: &mut Scratch<'_, E, Bd>,
) where
    E: IntegerElement,
    Bd: Bound,
    O: Element + EncodeFrom<AccOf<E>>,
    Ep: Epilogue<E, O>,
{
    // The backend is not consulted here. Every backend computes the same
    // integer, so selecting one is a question about instructions and never
    // about which function is being computed (R13). The portable factorization
    // below is the reference every other one is validated against (R6).
    let _ = options.backend;

    let shape = triple.shape();
    if shape.m == 0 || shape.n == 0 {
        // Nothing to write. Not a special case: the loops below would do the
        // same thing, and saying so costs one comparison.
        return;
    }

    let panel = match options.traversal {
        // Streaming: one output element at a time, no packed panel at all.
        Traversal::OutputMajor => 0,
        // Blocked: as long a k-panel as the offer supports.
        Traversal::Blocked => scratch.panel(shape.k),
    };

    let (a, b, c) = triple.parts();
    let reads_c = epilogue.reads_c();

    for i in 0..shape.m {
        for j in 0..shape.n {
            let mut acc = <AccOf<E> as Accumulator>::ZERO;

            if panel == 0 {
                for p in 0..shape.k {
                    E::mac(&mut acc, a.at(i, p).get(), b.at(p, j).get());
                }
            } else {
                // The same accumulation, in panels. `combine` is associative on
                // every value that can arise, so the panel length is invisible
                // in the result --- which is what `CD-01` and `CD-04` assert.
                let mut p = 0;
                while p < shape.k {
                    let end = shape.k.min(p + panel);
                    let mut part = <AccOf<E> as Accumulator>::ZERO;
                    for q in p..end {
                        E::mac(&mut part, a.at(i, q).get(), b.at(q, j).get());
                    }
                    acc = acc.combine(part);
                    p = end;
                }
            }

            // The single encode step, exactly once per output element. `prior`
            // is `None` when the epilogue does not read `C`, so an
            // uninitialised output buffer is admissible (`CS-04`).
            let prior = if reads_c { Some(*c.at(i, j)) } else { None };
            *c.at_mut(i, j) = epilogue.finish(acc, prior, options.encode);
        }
    }
}

#[cfg(test)]
// R7 governs the library, not its tests: these build operands on the heap so
// that awkward shapes can be generated. `CA-01` witnesses the library's own
// zero-allocation claim with a counting allocator instead.
#[allow(clippy::disallowed_types)]
mod tests {
    use super::*;
    use crate::epilogue::Linear;
    use crate::scratch::Scratch;
    use std::vec;
    use std::vec::Vec;
    use uor_matmul_core::{as_alphabet_full, MatView, MatViewMut, Strides};

    fn product(m: usize, k: usize, n: usize, traversal: Traversal, panel: usize) -> Vec<i32> {
        let a: Vec<i8> = (0..m * k).map(|i| ((i * 37) % 255) as i8).collect();
        let b: Vec<i8> = (0..k * n).map(|i| ((i * 53) % 255) as i8).collect();
        let mut c = vec![0i32; m * n];
        let mut buf = vec![Alphabet::ZERO; panel];

        let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
        let bv = MatView::row_major(as_alphabet_full(&b), k, n).unwrap();
        let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        gemm(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions {
                traversal,
                ..Default::default()
            },
            &mut Scratch::new(&mut buf),
        );
        c
    }

    /// CD-04, CD-05: every traversal and every scratch amount, including none,
    /// produce the same bytes. Only the traversal differs.
    #[test]
    fn traversal_and_scratch_are_invisible_cd_04() {
        // A prime depth, so no panel length divides it evenly.
        let reference = product(5, 97, 7, Traversal::OutputMajor, 0);
        for panel in [0usize, 1, 2, 3, 13, 96, 97, 98, 1000] {
            assert_eq!(
                product(5, 97, 7, Traversal::Blocked, panel),
                reference,
                "panel {panel}"
            );
        }
        assert_eq!(product(5, 97, 7, Traversal::OutputMajor, 1000), reference);
    }

    /// `CD-10`: `Scratch::none`, one element, `suggested_scratch - 1`,
    /// `suggested_scratch`, and ten times it all give the same bytes.
    ///
    /// Scratch is an offer. The library's whole response to the amount is a
    /// panel length, and a panel length is invisible in an exact sum.
    #[test]
    fn every_scratch_amount_gives_the_same_bytes_cd_10() {
        let (m, k, n) = (5usize, 97usize, 7usize);
        let suggested = crate::suggested_scratch(uor_matmul_core::Shape { m, k, n });
        let reference = product(m, k, n, Traversal::Blocked, 0);
        for amount in [0, 1, suggested.saturating_sub(1), suggested, suggested * 10] {
            assert_eq!(
                product(m, k, n, Traversal::Blocked, amount),
                reference,
                "scratch = {amount} (suggested = {suggested})"
            );
        }
        // And the query is a query: offering less is not an error.
        assert!(
            suggested > 0,
            "a non-degenerate shape suggests some scratch"
        );
    }

    /// CS-04: `beta = 0` overwrites `C` without reading it, so an output buffer
    /// holding a signalling pattern is admissible.
    #[test]
    fn beta_zero_overwrites_without_reading_cs_04() {
        let a = [1i8, 2, 3, 4];
        let b = [5i8, 6, 7, 8];
        let mut c = [i32::MIN; 4];
        let av = MatView::row_major(as_alphabet_full(&a), 2, 2).unwrap();
        let bv = MatView::row_major(as_alphabet_full(&b), 2, 2).unwrap();
        let cv = MatViewMut::row_major(&mut c, 2, 2).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        assert!(!Epilogue::<i8, i32>::reads_c(&Linear::OVERWRITE));
        gemm(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions::default(),
            &mut Scratch::none(),
        );
        assert_eq!(c, [19, 22, 43, 50]);
    }

    /// CS-05: alpha and beta are applied exactly, in the accumulator's width,
    /// once per output element.
    #[test]
    fn alpha_and_beta_are_exact_cs_05() {
        let a = [1i8, 2, 3, 4];
        let b = [5i8, 6, 7, 8];
        let mut c = [100i32, 200, 300, 400];
        let av = MatView::row_major(as_alphabet_full(&a), 2, 2).unwrap();
        let bv = MatView::row_major(as_alphabet_full(&b), 2, 2).unwrap();
        let cv = MatViewMut::row_major(&mut c, 2, 2).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        gemm(
            &mut t,
            &Linear { alpha: 3, beta: -2 },
            GemmOptions::default(),
            &mut Scratch::none(),
        );
        assert_eq!(c, [3 * 19 - 200, 3 * 22 - 400, 3 * 43 - 600, 3 * 50 - 800]);
    }

    /// CT-04: 0, 1, and prime dimensions take this path and not a different one.
    #[test]
    fn degenerate_and_prime_shapes_take_the_same_path_ct_04() {
        assert!(product(0, 5, 5, Traversal::Blocked, 4).is_empty());
        assert!(product(5, 0, 5, Traversal::Blocked, 4)
            .iter()
            .all(|&x| x == 0));
        assert_eq!(product(1, 1, 1, Traversal::Blocked, 4).len(), 1);
        assert_eq!(product(13, 17, 19, Traversal::Blocked, 5).len(), 13 * 19);
    }

    /// CS-02, CS-06: a transposed operand is a stride, and produces the
    /// transpose of the row-major product.
    #[test]
    fn transposed_operands_are_strides_cs_06() {
        let a = [1i8, 2, 3, 4, 5, 6]; // 2x3 row-major
        let b = [1i8, 2, 3, 4, 5, 6]; // 3x2 row-major
        let mut c = [0i32; 4];
        let av = MatView::row_major(as_alphabet_full(&a), 2, 3).unwrap();
        let bv = MatView::row_major(as_alphabet_full(&b), 3, 2).unwrap();
        let cv = MatViewMut::row_major(&mut c, 2, 2).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        gemm(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions::default(),
            &mut Scratch::none(),
        );
        assert_eq!(c, [22, 28, 49, 64]);

        // The same B, read as its own transpose by swapping the strides.
        let mut d = [0i32; 9];
        let av = MatView::new(as_alphabet_full(&a), 3, 2, Strides { rs: 1, cs: 3 }).unwrap();
        let bv = MatView::row_major(as_alphabet_full(&b), 2, 3).unwrap();
        let cv = MatViewMut::row_major(&mut d, 3, 3).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        gemm(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions::default(),
            &mut Scratch::none(),
        );
        // A^T (3x2) * B (2x3), computed by hand:
        //   [[1,4],[2,5],[3,6]] * [[1,2,3],[4,5,6]]
        assert_eq!(d, [17, 22, 27, 22, 29, 36, 27, 36, 45]);
    }

    /// CT-01: a depth past every narrow-register threshold is exact, because
    /// there is no threshold on the answer.
    #[test]
    fn depth_past_every_threshold_is_exact_ct_01() {
        const K: usize = 150_000;
        let a = vec![i8::MIN; K];
        let b = vec![i8::MIN; K];
        let mut c = [0i64; 1];
        let av = MatView::row_major(as_alphabet_full(&a), 1, K).unwrap();
        let bv = MatView::row_major(as_alphabet_full(&b), K, 1).unwrap();
        let cv = MatViewMut::row_major(&mut c, 1, 1).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        gemm(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions::default(),
            &mut Scratch::none(),
        );
        assert_eq!(c[0], (K as i64) * 128 * 128);
    }
}
