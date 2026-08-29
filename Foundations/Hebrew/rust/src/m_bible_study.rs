use super::Nat;

/// Very small prime mapping for a subset of ASCII letters.
fn prime_of_char(c: u8) -> Nat {
    match c {
        b'a' | b'A' => Nat(2),
        b'b' | b'B' => Nat(3),
        b'c' | b'C' => Nat(5),
        b'd' | b'D' => Nat(7),
        _ => Nat(2), // default fallback
    }
}

/// Encode a word (as a byte slice) by multiplying the primes of its characters.
pub fn encode_word(bytes: &[u8]) -> Nat {
    let mut acc = Nat(1);
    for &b in bytes {
        let p = prime_of_char(b);
        acc = super::mul(acc, p);
    }
    acc
}

#[cfg(test)]
mod tests {
    use super::*;
    use kani::proof;

    #[proof]
    fn encode_commutes() {
        // Two short literal strings – order should not affect the product.
        let w1 = b"ab"; // 2 * 3 = 6
        let w2 = b"cd"; // 5 * 7 = 35
        let enc1 = encode_word(&[w1, w2].concat());
        let enc2 = encode_word(&[w2, w1].concat());
        assert_eq!(enc1, enc2);
    }
}

