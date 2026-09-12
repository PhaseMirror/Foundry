//! Scratch is an offer, never a requirement (S13, `CD-04`).
//!
//! Too little, none at all, or a strange amount all produce the same bytes;
//! only the traversal differs. There is no scratch error in the library's error
//! surface, because there is no scratch condition to report.

use uor_matmul_core::{AccOf, Accumulator, Alphabet, Bound, IntegerElement, Shape};

/// Working memory the caller has offered.
///
/// The library never owns this and never grows it. An empty offer is
/// well-formed and selects the streaming traversal, which is what makes the
/// library run on a target whose RAM cannot hold one decoded row.
///
/// # Two offers, not one
///
/// The panel buffer is where decoded operands are packed. The *accumulator*
/// buffer is the one that removes a classical constraint, so it deserves saying
/// why it exists.
///
/// A classical GEMM chunks the reduction so that its panels fit cache, and
/// accumulates the chunks into `C` as it goes. It can do that because its
/// accumulator and its output are the same width --- and the price is that the
/// answer depends on the chunking, which is why no two classical `sgemm`
/// implementations agree bit for bit.
///
/// This library cannot write partial sums into `C`, because `C` is the *encoded*
/// output and encoding a partial sum would round it. So without somewhere to keep
/// the exact partial sums, the panels must hold the whole of `k` --- which makes
/// the offer grow with the depth, and a caller with an astronomical `k` either
/// supplies an astronomical buffer or gets the unblocked traversal.
///
/// An accumulator buffer is that somewhere. With one, the reduction is chunked to
/// whatever the cache holds while every partial sum stays exact and full width,
/// and the offer stops growing with `k`. This is the property the exact
/// accumulator buys and a classical library cannot have: the sum is
/// order-independent, so it may be split any way the machine prefers and
/// recombined with no consequence at all.
///
/// Offering one is optional, like every other offer. Offering none gives the same
/// bytes from the full-depth traversal (`CD-04`, `CD-10`).
#[derive(Debug)]
pub struct Scratch<'s, E: IntegerElement, Bd: Bound> {
    buffer: &'s mut [Alphabet<E, Bd>],
    accumulators: &'s mut [AccOf<E>],
}

impl<'s, E: IntegerElement, Bd: Bound> Scratch<'s, E, Bd> {
    /// Offer a panel buffer.
    pub fn new(buffer: &'s mut [Alphabet<E, Bd>]) -> Self {
        Self {
            buffer,
            accumulators: &mut [],
        }
    }

    /// Offer a panel buffer and a block of exact accumulators.
    ///
    /// The accumulators let the reduction be chunked at whatever depth the panels
    /// fit the cache, instead of the panels having to hold the whole of `k`. See
    /// the type's documentation for why that is a property this library has and a
    /// classical one does not.
    pub fn with_accumulators(
        buffer: &'s mut [Alphabet<E, Bd>],
        accumulators: &'s mut [AccOf<E>],
    ) -> Self {
        Self {
            buffer,
            accumulators,
        }
    }

    /// Offer nothing.
    ///
    /// Not a degraded mode and not a fallback: the same identity, walked in a
    /// different order (R13).
    pub fn none() -> Scratch<'static, E, Bd> {
        Scratch {
            buffer: &mut [],
            accumulators: &mut [],
        }
    }

    /// How many exact accumulators were offered.
    pub fn accumulators(&self) -> usize {
        self.accumulators.len()
    }

    /// The first `n` accumulators, zeroed. The start of a block's reduction.
    pub fn take_accumulators(&mut self, n: usize) -> &mut [AccOf<E>] {
        let block = self.keep_accumulators(n);
        block.fill(<AccOf<E> as Accumulator>::ZERO);
        block
    }

    /// The first `n` accumulators, as they stand. The continuation of one.
    pub fn keep_accumulators(&mut self, n: usize) -> &mut [AccOf<E>] {
        let n = n.min(self.accumulators.len());
        &mut self.accumulators[..n]
    }

    /// Both offers at once: `panel` elements of panel room and `accs`
    /// accumulators.
    ///
    /// They are separate buffers, so a traversal that uses both needs them
    /// together rather than one after the other.
    pub fn split(
        &mut self,
        panel: usize,
        accs: usize,
    ) -> (&mut [Alphabet<E, Bd>], &mut [AccOf<E>]) {
        let p = panel.min(self.buffer.len());
        let a = accs.min(self.accumulators.len());
        (&mut self.buffer[..p], &mut self.accumulators[..a])
    }

    /// How much was offered.
    pub fn len(&self) -> usize {
        self.buffer.len()
    }

    /// Was nothing offered?
    pub fn is_empty(&self) -> bool {
        self.buffer.is_empty()
    }

    /// The largest panel this offer supports, capped at `want`.
    ///
    /// This is the whole of the library's response to a scratch amount: a
    /// panel length. A short offer shortens the panel; it never changes the
    /// arithmetic and never fails.
    pub fn panel(&self, want: usize) -> usize {
        want.min(self.buffer.len())
    }

    /// The first `n` elements of the offer, for a panel.
    pub fn take(&mut self, n: usize) -> &mut [Alphabet<E, Bd>] {
        let n = n.min(self.buffer.len());
        &mut self.buffer[..n]
    }
}

/// How much scratch would let the blocked traversal run at its intended panel
/// size for this shape.
///
/// A *query*, not a requirement. A caller who offers less gets the same bytes
/// from a shorter panel, and a caller who offers none gets the same bytes from
/// the streaming traversal (`CD-04`).
///
/// This is the amount the *full-depth* traversal wants, and measured it is the
/// faster of the two wherever a caller can afford it. A caller who cannot ---
/// because it grows with `k` --- offers instead
/// `KC * (MC + NC)` here together with [`suggested_accumulators`], which is
/// bounded, and gets the depth-chunked traversal at the same bytes.
pub fn suggested_scratch(shape: Shape) -> usize {
    use uor_matmul_core::generated::blocking;
    // One block of each operand at the full depth: `MC` rows of A and `NC`
    // columns of B. That is what the blocked traversal reuses --- the B block
    // across every row block, and the A block across every column panel --- and
    // it is the amount at which neither operand is repacked more than the
    // blocking says.
    //
    // It is never more than the operands themselves: `MC <= m` and `NC <= n`
    // after the clamps, so this is at most `k * (m + n)`. A caller who wants
    // less offers less and gets the chunked traversal, at the same bytes
    // (`CD-04`, `CD-10`).
    shape
        .k
        .saturating_mul(shape.m.min(blocking::MC) + shape.n.min(blocking::NC))
}

/// How many exact accumulators would let the chunked-depth traversal run at its
/// intended block for this shape.
///
/// A *query*, like [`suggested_scratch`]. Zero is a valid offer and gives the
/// same bytes.
///
/// The product is the output block the traversal keeps exact partial sums for:
/// `MC` rows by `NC` columns, clamped to the shape. It does not grow with `k`,
/// which is the whole point --- a caller with an astronomical depth offers this
/// once and the depth is chunked to fit the cache rather than the buffer.
pub fn suggested_accumulators(shape: Shape) -> usize {
    use uor_matmul_core::generated::blocking;
    if shape.k <= blocking::KC {
        // Nothing to chunk: the full-depth traversal already holds every partial
        // sum in a register.
        return 0;
    }
    // Paired with a panel offer of `KC * (MC + NC)` rather than the full-depth
    // one, this is the whole of what the depth-chunked traversal needs --- and
    // neither term grows with `k`.
    shape
        .m
        .min(blocking::MC)
        .saturating_mul(shape.n.min(blocking::NC))
}
