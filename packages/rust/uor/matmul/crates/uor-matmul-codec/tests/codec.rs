//! `CK-*`: tier equivalence, transcode, and the identity the whole crate exists
//! to realize.
//!
//! Every test here is `build`, not `some-true`: it is evidence that these types
//! realize `CL-MM01`, not a proof of it. The identity itself is cited from
//! upstream and says nothing about any binary in this repository (§2, R4).

use uor_matmul_codec::{Book, Codec, CodedMatrix, Grid, Identity, Offset, Packed, Runs, Transcode};
use uor_matmul_core::{
    as_alphabet_full, dot_ref, Alphabet, Bnd, Bound, Full, IntegerElement, NotAProduct,
};

type A8 = Alphabet<i8, Full<i8>>;

/// The 16-entry i4 grid: the canonical `Grid<16>`, and one table size among
/// many rather than a privileged one.
fn i4_table() -> [A8; 16] {
    core::array::from_fn(|i| Alphabet::of((i as i8) - 8))
}

/// Decode a whole coded matrix into a dense vector, for comparing tiers.
fn decode_all<E, Bd, C>(m: &CodedMatrix<'_, E, Bd, C>) -> Vec<Alphabet<E, Bd>>
where
    E: IntegerElement,
    Bd: Bound,
    C: Codec<E, Bd>,
{
    let mut out = Vec::new();
    for r in 0..m.rows() {
        for c in 0..m.cols() {
            out.push(m.at(r, c));
        }
    }
    out
}

/// CK-01: the identity codec decodes to its input, and decoding is the copy the
/// alphabet wrap already validated.
#[test]
fn identity_decodes_to_its_input_ck_01() {
    let data = [1i8, -2, 3, i8::MIN, i8::MAX];
    let codes = as_alphabet_full(&data);
    let m = CodedMatrix::new(Identity, 1, 5, codes).unwrap();
    assert_eq!(decode_all(&m), codes.to_vec());
    // `i8::MIN` is a code like any other. Nothing rejects it (C6).
    assert_eq!(m.at(0, 3).get(), i8::MIN);
}

/// CK-02: the grid tier equals the identity tier on equal decodes.
///
/// This is `CL-MM01` at its smallest instantiation: two different codecs, two
/// different code streams, one decoded stream, one product.
#[test]
fn grid_equals_identity_on_equal_decodes_ck_02() {
    let table = i4_table();
    let grid = Grid::new(&table);

    // Codes 0..15 under the grid decode to -8..7.
    let grid_codes: Vec<u16> = (0..16u16).collect();
    let coded = CodedMatrix::new(grid, 2, 8, &grid_codes).unwrap();

    // The same decoded stream, stored as itself.
    let dense: Vec<i8> = (0..16).map(|i| (i as i8) - 8).collect();
    let dense_codes = as_alphabet_full(&dense);
    let plain = CodedMatrix::new(Identity, 2, 8, dense_codes).unwrap();

    assert_eq!(decode_all(&coded), decode_all(&plain));

    // And therefore the same product against any activation vector.
    let acts: Vec<i8> = (0..8).map(|i| (i * 13 % 127) as i8).collect();
    let a = as_alphabet_full(&acts);
    for r in 0..2 {
        let mut w1 = vec![Alphabet::ZERO; 8];
        let mut w2 = vec![Alphabet::ZERO; 8];
        assert_eq!(coded.decode_row_into(r, &mut w1), 8);
        assert_eq!(plain.decode_row_into(r, &mut w2), 8);
        assert_eq!(dot_ref(a, &w1), dot_ref(a, &w2));
    }
}

/// CK-03: `Packed` unpacks the **low sub-code first**. Normative, pinned by
/// case `nibble-order`.
///
/// A reader that took the high nibble first would decode a different matrix
/// from the same bytes, so this is fixed here rather than left to convention.
#[test]
fn packed_unpacks_low_sub_code_first_ck_03() {
    let table = i4_table();
    let packed: Packed<Grid<'_, i8, Full<i8>, 16>, 2> = Packed::new(Grid::new(&table)).unwrap();

    // 0x3A: low nibble 0xA = 10 -> 2, high nibble 0x3 = 3 -> -5.
    let bytes = [0x3Au8];
    let m = CodedMatrix::new(packed, 1, 2, &bytes).unwrap();
    assert_eq!(m.at(0, 0).get(), 2, "the low sub-code decodes first");
    assert_eq!(m.at(0, 1).get(), -5, "the high sub-code decodes second");

    // Four two-bit sub-codes per byte: the same rule, a different P.
    let quad_table: [A8; 4] = [
        Alphabet::of(0),
        Alphabet::of(1),
        Alphabet::of(2),
        Alphabet::of(3),
    ];
    let quad: Packed<Grid<'_, i8, Full<i8>, 4>, 4> = Packed::new(Grid::new(&quad_table)).unwrap();
    // 0b11_10_01_00 = 0xE4: low-to-high 0, 1, 2, 3.
    let m = CodedMatrix::new(quad, 1, 4, &[0xE4u8]).unwrap();
    assert_eq!(
        (0..4).map(|c| m.at(0, c).get()).collect::<Vec<_>>(),
        vec![0, 1, 2, 3]
    );
}

/// CK-04: `Transcode` decodes as the composite, and composition is closed.
#[test]
fn transcode_is_the_composite_ck_04() {
    let table = i4_table();
    let grid = Grid::new(&table);

    // A relabelling: outer code `c` names inner code `15 - c`.
    let flip = Transcode::<_, _, u16>::new(|c: u16| 15u16 - (c % 16), grid);

    for c in 0..16u16 {
        let direct = Codec::<i8, Full<i8>>::decode_element(&grid, 15 - c, 0);
        let composed = Codec::<i8, Full<i8>>::decode_element(&flip, c, 0);
        assert_eq!(direct, composed);
    }

    // Closed under composition: transcode a transcode.
    let twice = Transcode::<_, _, u16>::new(|c: u16| 15u16 - (c % 16), flip);
    for c in 0..16u16 {
        assert_eq!(
            Codec::<i8, Full<i8>>::decode_element(&twice, c, 0),
            Codec::<i8, Full<i8>>::decode_element(&grid, c, 0),
        );
    }
}

/// CK-05: two `CodedMatrix` values with different tiers and equal decodes
/// produce byte-identical output.
///
/// This is the load-bearing test of the whole crate. If it ever fails, the
/// codec has become an argument of the arithmetic.
#[test]
fn different_tiers_equal_decodes_identical_product_ck_05() {
    // Tier one: an 8-element codebook, one code per row of 8.
    let book_table: [[A8; 8]; 4] =
        core::array::from_fn(|n| core::array::from_fn(|i| Alphabet::of(((n * 8 + i) as i8) - 16)));
    let book = Book::<i8, Full<i8>, 4, 8>::new(&book_table);
    let book_m = CodedMatrix::new(book, 4, 8, &[0u16, 1, 2, 3]).unwrap();

    // Tier two: the same decoded stream, stored densely.
    let dense: Vec<i8> = (0..32).map(|i| (i as i8) - 16).collect();
    let plain_m = CodedMatrix::new(Identity, 4, 8, as_alphabet_full(&dense)).unwrap();

    assert_eq!(decode_all(&book_m), decode_all(&plain_m));

    // Tier three: a grid over 32 single-element codes.
    let grid_table: [A8; 32] = core::array::from_fn(|i| Alphabet::of((i as i8) - 16));
    let grid_codes: Vec<u16> = (0..32u16).collect();
    let grid_m = CodedMatrix::new(Grid::new(&grid_table), 4, 8, &grid_codes).unwrap();
    assert_eq!(decode_all(&grid_m), decode_all(&plain_m));

    // Three tiers, three block sizes, three code types --- one product.
    let acts: Vec<i8> = (0..8).map(|i| (i as i8) * 7 - 20).collect();
    let a = as_alphabet_full(&acts);
    for r in 0..4 {
        let mut w = vec![Alphabet::ZERO; 8];
        let mut x = vec![Alphabet::ZERO; 8];
        let mut y = vec![Alphabet::ZERO; 8];
        book_m.decode_row_into(r, &mut w);
        plain_m.decode_row_into(r, &mut x);
        grid_m.decode_row_into(r, &mut y);
        let expected = dot_ref(a, &x);
        assert_eq!(dot_ref(a, &w), expected);
        assert_eq!(dot_ref(a, &y), expected);
    }
}

/// CK-01: `Offset` expresses asymmetric quantization exactly, as a composition
/// and not a special case --- so it is two codecs with equal decodes, and it
/// falls under the same claim every other tier does.
#[test]
fn offset_is_asymmetric_quantization_ck_01() {
    // Unsigned 4-bit codes 0..15, zero point 8: the classic asymmetric tier.
    let unsigned: [Alphabet<i8, Bnd<15>>; 16] =
        core::array::from_fn(|i| Alphabet::new(i as i8).unwrap());
    let grid = Grid::new(&unsigned);
    let offset =
        Offset::<i8, Bnd<15>, Bnd<23>, _>::new(grid, 8).expect("15 + |8| = 23 fits Bnd<23> and i8");

    for c in 0..16u16 {
        let decoded = Codec::<i8, Bnd<23>>::decode_element(&offset, c, 0);
        assert_eq!(decoded.get(), (c as i8) - 8);
    }

    // A zero point whose image leaves the declared bound has no such codec, and
    // that is reported at construction, before any arithmetic (C6).
    assert!(Offset::<i8, Bnd<15>, Bnd<20>, _>::new(grid, 8).is_none());
}

/// CK-06: a run codec's returned counts sum to the declared row width on every
/// row, and the decoded stream is the same dense stream the inner codec gives.
///
/// This is the invariant that lets sparse storage be a *tier* rather than a
/// second algorithm: the arithmetic downstream never learns that the weights
/// were stored as runs.
#[test]
fn a_run_codecs_counts_sum_to_the_row_width_ck_06() {
    let table = i4_table();
    let grid = Grid::new(&table);

    // Two rows of twelve: four zeros (code 8 -> 0), four fours (code 12 -> 4),
    // four minus-fives (code 3 -> -5). The zeros are explicit runs, which is
    // what keeps the arithmetic dense.
    let runs = [
        (4u32, 8u16),
        (4u32, 12u16),
        (4u32, 3u16),
        (4u32, 8u16),
        (4u32, 12u16),
        (4u32, 3u16),
    ];
    let sparse: Runs<'_, i8, Full<i8>, _, 8> = Runs::new(grid, &runs).unwrap();

    // The counts sum to the row width. Twice, because there are two rows.
    assert_eq!(sparse.decoded_len(), 24);
    assert_eq!(Codec::<i8, Full<i8>>::decode_len(&sparse, 0), 4);

    let indices: Vec<u32> = (0..6u32).collect();
    let m = CodedMatrix::new(sparse, 2, 12, &indices).expect("the counts sum to 12 per row");

    let expected: Vec<i8> = (0..12)
        .map(|p| match p {
            0..=3 => 0,
            4..=7 => 4,
            _ => -5,
        })
        .collect();
    for r in 0..2 {
        let mut row = vec![Alphabet::ZERO; 12];
        assert_eq!(
            m.decode_row_into(r, &mut row),
            12,
            "the row decodes to exactly `cols`"
        );
        assert_eq!(row.iter().map(|a| a.get()).collect::<Vec<_>>(), expected);
    }

    // The residency claim is a number, not an adjective: six stored runs
    // against twenty-four decoded elements.
    assert_eq!(m.codec().run_count(), 6);

    // Counts that do not sum to the declared width describe no matrix, and
    // that is reported at construction (C6).
    let short = [(3u32, 8u16), (4u32, 12u16)];
    let bad: Runs<'_, i8, Full<i8>, _, 8> = Runs::new(grid, &short).unwrap();
    assert!(CodedMatrix::new(bad, 1, 12, &[0u32, 1]).is_none());

    // A run longer than the declared maximum, or an empty one, is not a run.
    assert!(Runs::<'_, i8, Full<i8>, _, 8>::new(grid, &[(9u32, 8u16)]).is_none());
    assert!(Runs::<'_, i8, Full<i8>, _, 8>::new(grid, &[(0u32, 8u16)]).is_none());
}

/// A shape a codec cannot describe is reported at construction, and nothing
/// else about the data can make `CodedMatrix::new` fail (§6.3, C6).
#[test]
fn only_a_shape_disagreement_is_reportable_cs_03() {
    let table = i4_table();
    let grid = Grid::new(&table);
    let codes = [0u16; 8];

    // Too few codes for the declared shape: no such matrix.
    assert!(CodedMatrix::new(grid, 2, 8, &codes).is_none());
    // A column count that is not a multiple of the block: no such matrix.
    let book_table: [[A8; 8]; 2] = [[Alphabet::of(0); 8]; 2];
    let book = Book::<i8, Full<i8>, 2, 8>::new(&book_table);
    assert!(CodedMatrix::new(book, 1, 7, &[0u16]).is_none());
    // The conforming shape constructs.
    assert!(CodedMatrix::new(grid, 1, 8, &codes).is_some());

    // The error surface of the whole library, for reference: two variants,
    // both meaning the requested object does not exist.
    let _: fn() -> NotAProduct = || NotAProduct::Nonconformant {
        a: (1, 1),
        b: (2, 2),
    };
}

/// The streaming decode agrees with the row decode, which is what lets a target
/// whose RAM cannot hold one row produce the same bytes (S13, CD-04).
#[test]
fn streaming_decode_equals_row_decode_cd_04() {
    let table = i4_table();
    let codes: Vec<u16> = (0..64u16).map(|c| c % 16).collect();
    let m = CodedMatrix::new(Grid::new(&table), 4, 16, &codes).unwrap();

    for r in 0..4 {
        let mut whole = vec![Alphabet::ZERO; 16];
        m.decode_row_into(r, &mut whole);

        // Three elements at a time, which is not a divisor of the row length.
        let mut streamed = Vec::new();
        let mut buf = [Alphabet::ZERO; 3];
        let mut c = 0;
        while c < 16 {
            let end = (c + 3).min(16);
            m.decode_range_into(r, c..end, &mut buf[..end - c]);
            streamed.extend_from_slice(&buf[..end - c]);
            c = end;
        }
        assert_eq!(whole, streamed);
    }
}

/// `CK-03`: the packed panels themselves are byte-equal across codecs that
/// decode equally --- not merely the products.
///
/// This is stronger than `CK-05` and it is the one that would catch a codec
/// whose decode is right but whose *ordering* is not. Two tiers that agree
/// element for element must fill a packed panel with the same bytes, because
/// the packing reads the decoded stream and nothing else.
#[test]
fn packed_panels_are_byte_equal_across_tiers_ck_03() {
    use uor_matmul_codec::{e8_codec, e8_table, E8_I8};

    // The E8 codebook, and a dense tier holding the same decoded stream.
    let table = e8_table::<Full<i8>>().expect("i8 admits every codeword");
    let book = e8_codec(&table);
    let codes: Vec<u16> = (0..64u16).map(|c| c * 3 % 256).collect();
    let coded = CodedMatrix::new(book, 8, 64, &codes).unwrap();

    let dense: Vec<i8> = codes
        .iter()
        .flat_map(|&c| E8_I8[c as usize % 256].iter().copied())
        .collect();
    let plain = CodedMatrix::new(Identity, 8, 64, as_alphabet_full(&dense)).unwrap();

    // Pack both, k-major, exactly as the driver's kernel path does.
    fn pack<C: Codec<i8, Full<i8>>>(
        m: &CodedMatrix<'_, i8, Full<i8>, C>,
        mr: usize,
        kc: usize,
    ) -> Vec<i8> {
        let mut out = vec![0i8; mr * kc];
        for p in 0..kc {
            for i in 0..mr {
                out[p * mr + i] = m.at(i, p).get();
            }
        }
        out
    }

    for (mr, kc) in [(1usize, 1usize), (4, 8), (6, 16), (8, 64)] {
        assert_eq!(
            pack(&coded, mr, kc),
            pack(&plain, mr, kc),
            "the E8 tier and the dense tier must pack the same bytes at {mr}x{kc}"
        );
    }

    // And the panels really are non-trivial, or the comparison is vacuous.
    let panel = pack(&coded, 8, 64);
    assert!(
        panel.iter().any(|&b| b != 0),
        "the packed panel must not be all zeros"
    );
}
