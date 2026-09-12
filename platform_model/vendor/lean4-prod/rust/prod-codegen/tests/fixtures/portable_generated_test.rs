use core::cmp::Ordering;

#[test]
fn real_lexlean_portable_operations_execute_with_exact_rust_semantics() {
    assert_eq!(portable_expanded::checkedAddInt64(i64::MAX, 1), None);
    assert_eq!(portable_expanded::checkedAddInt64(40, 2), Some(42));
    assert_eq!(portable_expanded::checkedSubtractInt64(i64::MIN, 1), None);
    assert_eq!(portable_expanded::checkedMultiplyInt64(i64::MAX, 2), None);
    assert_eq!(portable_expanded::checkedNegateInt64(i64::MIN), None);
    assert_eq!(portable_expanded::checkedQuotientInt64(7, 0), None);
    assert_eq!(portable_expanded::checkedQuotientInt64(i64::MIN, -1), None);
    assert_eq!(portable_expanded::checkedQuotientInt64(-7, 2), Some(-3));

    assert_eq!(portable_expanded::andUInt64(12, 10), 8);
    assert_eq!(portable_expanded::orUInt64(12, 10), 14);
    assert_eq!(portable_expanded::xorUInt64(12, 10), 6);
    assert_eq!(portable_expanded::notUInt64(0), u64::MAX);
    assert_eq!(portable_expanded::shiftUInt64(1, 63), Some(1 << 63));
    assert_eq!(portable_expanded::shiftUInt64(1, 64), None);
    assert_eq!(portable_expanded::shiftRightUInt64(8, 3), Some(1));

    assert_eq!(portable_expanded::appendBytes(vec![1, 2], vec![3]), vec![1, 2, 3]);
    assert_eq!(portable_expanded::byteLength(vec![1, 2, 3]), 3);
    assert_eq!(portable_expanded::byteAt(vec![1, 2, 3], 1), Some(2));
    assert_eq!(portable_expanded::byteAt(vec![1], u64::MAX), None);
    assert_eq!(portable_expanded::sliceBytes(vec![1, 2, 3], 1, 2), Some(vec![2, 3]));
    assert_eq!(portable_expanded::sliceBytes(vec![1], 1, 1), None);
    assert_eq!(portable_expanded::compareByteStrings(vec![1], vec![2]), Ordering::Less);

    let text = String::from("portable ✓");
    let encoded = portable_expanded::encodeUtf8(text.clone());
    assert_eq!(portable_expanded::decodeUtf8(encoded), Some(text));
    assert_eq!(portable_expanded::decodeUtf8(vec![0xff]), None);
    assert_eq!(portable_expanded::parseInt64(String::from("-42")), Some(-42));
    assert_eq!(portable_expanded::parseInt64(String::from("+42")), None);
    assert_eq!(portable_expanded::parseInt64(String::from("042")), None);
    assert_eq!(portable_expanded::formatInt64(i64::MIN), i64::MIN.to_string());
    assert_eq!(
        portable_expanded::splitBounded(String::from("a\tb"), String::from("\t"), 2),
        Some(vec![String::from("a"), String::from("b")])
    );
    assert_eq!(
        portable_expanded::splitBounded(String::from("a\tb"), String::from("\t"), 1),
        None
    );
    assert_eq!(
        portable_expanded::joinStrings(&[String::from("a"), String::from("b")], String::from("\t")),
        String::from("a\tb")
    );
}
