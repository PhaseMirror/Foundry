//! GEMM against a coded operand (§6.3).
//!
//! Not a second driver. The weights arrive as codes instead of as alphabet
//! elements, they are decoded, and from there this is the same accumulation the
//! dense driver runs --- which is the whole content of `CL-MM01` and what
//! `CK-05` measures.

use uor_matmul_codec::{Codec, CodedMatrix};
use uor_matmul_core::{
    AccOf, Accumulator, Alphabet, Bound, Element, EncodeFrom, IntegerElement, MatView, MatViewMut,
    NotAProduct, Shape,
};

use crate::driver::GemmOptions;
use crate::epilogue::Epilogue;

/// The conformant triple with a coded right operand.
///
/// The library's second and last fallible constructor, with the same signature
/// and the same two failures as [`uor_matmul_core::Triple::new`] (§5.5).
pub struct CodedTriple<'a, 'b, 'c, E: IntegerElement, Bd: Bound, C: Codec<E, Bd>, O> {
    a: MatView<'a, Alphabet<E, Bd>>,
    b: CodedMatrix<'b, E, Bd, C>,
    c: MatViewMut<'c, O>,
}

impl<'a, 'b, 'c, E: IntegerElement, Bd: Bound, C: Codec<E, Bd>, O>
    CodedTriple<'a, 'b, 'c, E, Bd, C, O>
{
    /// Report non-existence once, before any arithmetic is named.
    pub fn new(
        a: MatView<'a, Alphabet<E, Bd>>,
        b: CodedMatrix<'b, E, Bd, C>,
        c: MatViewMut<'c, O>,
    ) -> Result<Self, NotAProduct> {
        if a.cols() != b.rows() || c.rows() != a.rows() || c.cols() != b.cols() {
            return Err(NotAProduct::Nonconformant {
                a: (a.rows(), a.cols()),
                b: (b.rows(), b.cols()),
            });
        }
        let s = c.strides();
        if self_aliases(c.rows(), c.cols(), s.rs, s.cs) {
            return Err(NotAProduct::OutputAliasesItself {
                m: c.rows(),
                n: c.cols(),
                rs: s.rs,
                cs: s.cs,
            });
        }
        Ok(Self { a, b, c })
    }

    /// The shape of the product, which exists because this value does.
    pub fn shape(&self) -> Shape {
        Shape {
            m: self.a.rows(),
            k: self.a.cols(),
            n: self.b.cols(),
        }
    }
}

/// The same aliasing question [`uor_matmul_core::Strides`] answers, asked here
/// because a `CodedTriple` builds its own output view.
fn self_aliases(rows: usize, cols: usize, rs: isize, cs: isize) -> bool {
    if rows == 0 || cols == 0 {
        // An empty output has no two distinct coordinates to collide.
        return false;
    }
    if rows <= 1 && cols <= 1 {
        return false;
    }
    if rows > 1 && rs == 0 {
        return true;
    }
    if cols > 1 && cs == 0 {
        return true;
    }
    if rows <= 1 || cols <= 1 {
        return false;
    }
    let (mut a, mut b) = (rs.unsigned_abs(), cs.unsigned_abs());
    while b != 0 {
        let t = a % b;
        a = b;
        b = t;
    }
    let g = a;
    (cs.unsigned_abs() / g) < rows && (rs.unsigned_abs() / g) < cols
}

/// `C := epilogue(A * decode(B), C)`.
///
/// Returns `()`, for the same reason [`crate::gemm`] does.
///
/// The decode is streamed one element at a time, so this needs no scratch at
/// all --- not even one decoded row. A caller with memory to spare gets the
/// same bytes from [`CodedMatrix::decode_row_into`]; `CD-04` asserts it.
pub fn coded_gemm<E, Bd, C, O, Ep>(
    triple: &mut CodedTriple<'_, '_, '_, E, Bd, C, O>,
    epilogue: &Ep,
    options: GemmOptions,
) where
    E: IntegerElement,
    Bd: Bound,
    C: Codec<E, Bd>,
    O: Element + EncodeFrom<AccOf<E>>,
    Ep: Epilogue<E, O>,
{
    let shape = triple.shape();
    if shape.m == 0 || shape.n == 0 {
        return;
    }
    let reads_c = epilogue.reads_c();

    for i in 0..shape.m {
        for j in 0..shape.n {
            let mut acc = <AccOf<E> as Accumulator>::ZERO;
            for p in 0..shape.k {
                // Decode, then accumulate exactly. The codec is not an argument
                // of the arithmetic below it.
                let w = triple.b.at(p, j);
                E::mac(&mut acc, triple.a.at(i, p).get(), w.get());
            }
            let prior = if reads_c {
                Some(*triple.c.at(i, j))
            } else {
                None
            };
            *triple.c.at_mut(i, j) = epilogue.finish(acc, prior, options.encode);
        }
    }
}
