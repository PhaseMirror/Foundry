//! # Word Love Core (ADR-0031)
//!
//! Rust execution layer for the Prime-Recursive Multiplicity Substrate (ADR-0031).
//! Formalizes Hebrew semantic token representation, gematria encoding schemes,
//! prime multiplicity factorization, trajectory coupling, and substrate combination.

use std::fmt;

/// A semantic token representing a concept or word in language.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct SemanticToken {
    pub id: String,
    pub name: String,
    pub hebrew: String,
    pub transliteration: String,
    pub description: String,
}

impl SemanticToken {
    pub fn new(id: &str, name: &str, hebrew: &str, transliteration: &str, description: &str) -> Self {
        Self {
            id: id.to_string(),
            name: name.to_string(),
            hebrew: hebrew.to_string(),
            transliteration: transliteration.to_string(),
            description: description.to_string(),
        }
    }
}

/// Numerical gematria encoding schemes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum GematriaScheme {
    Standard, // Mispar Hechrechi / Ragil (Alef=1, ..., Yod=10, ..., Tav=400)
    Reduced,  // Mispar Katan (digital root reduction)
    Ordinal,  // Mispar Siduri (positional 1..22)
}

/// Digital root calculation (base 10).
pub fn digital_root(n: u64) -> u64 {
    if n == 0 {
        0
    } else {
        let r = n % 9;
        if r == 0 { 9 } else { r }
    }
}

/// Evaluate character gematria value under a given scheme.
pub fn char_gematria(scheme: GematriaScheme, c: char) -> u64 {
    match scheme {
        GematriaScheme::Standard => match c {
            'א' => 1, 'ב' => 2, 'ג' => 3, 'ד' => 4, 'ה' => 5,
            'ו' => 6, 'ז' => 7, 'ח' => 8, 'ט' => 9, 'י' => 10,
            'כ' | 'ך' => 20, 'ל' => 30, 'מ' | 'ם' => 40,
            'נ' | 'ן' => 50, 'ס' => 60, 'ע' => 70, 'פ' | 'ף' => 80,
            'צ' | 'ץ' => 90, 'ק' => 100, 'ר' => 200, 'ש' => 300,
            'ת' => 400, _ => 0,
        },
        GematriaScheme::Reduced => match c {
            'א' => 1, 'ב' => 2, 'ג' => 3, 'ד' => 4, 'ה' => 5,
            'ו' => 6, 'ז' => 7, 'ח' => 8, 'ט' => 9, 'י' => 1,
            'כ' | 'ך' => 2, 'ל' => 3, 'מ' | 'ם' => 4,
            'נ' | 'ן' => 5, 'ס' => 6, 'ע' => 7, 'פ' | 'ף' => 8,
            'צ' | 'ץ' => 9, 'ק' => 1, 'ר' => 2, 'ש' => 3,
            'ת' => 4, _ => 0,
        },
        GematriaScheme::Ordinal => match c {
            'א' => 1, 'ב' => 2, 'ג' => 3, 'ד' => 4, 'ה' => 5,
            'ו' => 6, 'ז' => 7, 'ח' => 8, 'ט' => 9, 'י' => 10,
            'כ' | 'ך' => 11, 'ל' => 12, 'מ' | 'ם' => 13,
            'נ' | 'ן' => 14, 'ס' => 15, 'ע' => 16, 'פ' | 'ף' => 17,
            'צ' | 'ץ' => 18, 'ק' => 19, 'ר' => 20, 'ש' => 21,
            'ת' => 22, _ => 0,
        },
    }
}

/// Compute gematria value of a string.
pub fn string_gematria(scheme: GematriaScheme, s: &str) -> u64 {
    match scheme {
        GematriaScheme::Standard => s.chars().map(|c| char_gematria(GematriaScheme::Standard, c)).sum(),
        GematriaScheme::Reduced => {
            let std_sum: u64 = s.chars().map(|c| char_gematria(GematriaScheme::Standard, c)).sum();
            digital_root(std_sum)
        }
        GematriaScheme::Ordinal => s.chars().map(|c| char_gematria(GematriaScheme::Ordinal, c)).sum(),
    }
}

/// An explicit numerical encoding of a semantic token under a scheme.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Encoding {
    pub token: SemanticToken,
    pub scheme: GematriaScheme,
    pub value: u64,
}

impl Encoding {
    pub fn new(token: SemanticToken, scheme: GematriaScheme) -> Option<Self> {
        let value = string_gematria(scheme, &token.hebrew);
        if value > 0 {
            Some(Self { token, scheme, value })
        } else {
            None
        }
    }
}

/// A prime factor pair: (prime, exponent).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PrimeFactor {
    pub prime: u64,
    pub exponent: u32,
}

impl fmt::Display for PrimeFactor {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}^{}", self.prime, self.exponent)
    }
}

/// Prime Multiplicity vector representation.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct PrimeMultiplicity {
    pub factors: Vec<PrimeFactor>,
}

impl PrimeMultiplicity {
    pub fn single(prime: u64, exponent: u32) -> Self {
        if exponent == 0 {
            Self { factors: Vec::new() }
        } else {
            Self {
                factors: vec![PrimeFactor { prime, exponent }],
            }
        }
    }

    pub fn val_at(&self, prime: u64) -> u32 {
        self.factors
            .iter()
            .find(|pf| pf.prime == prime)
            .map(|pf| pf.exponent)
            .unwrap_or(0)
    }

    pub fn support(&self) -> Vec<u64> {
        self.factors.iter().map(|pf| pf.prime).collect()
    }

    pub fn omega(&self) -> usize {
        self.factors.len()
    }

    pub fn omega_total(&self) -> u32 {
        self.factors.iter().map(|pf| pf.exponent).sum()
    }

    pub fn product(&self) -> u64 {
        self.factors
            .iter()
            .fold(1u64, |acc, pf| acc * pf.prime.pow(pf.exponent))
    }

    pub fn add(&self, other: &Self) -> Self {
        let mut factors = self.factors.clone();
        for f in &other.factors {
            if let Some(existing) = factors.iter_mut().find(|pf| pf.prime == f.prime) {
                existing.exponent += f.exponent;
            } else {
                factors.push(*f);
            }
        }
        factors.sort_by_key(|pf| pf.prime);
        Self { factors }
    }

    pub fn to_canonical_prime_list(&self) -> Vec<u64> {
        let mut sorted = self.factors.clone();
        sorted.sort_by(|a, b| b.prime.cmp(&a.prime)); // strictly descending
        let mut list = Vec::new();
        for pf in sorted {
            for _ in 0..pf.exponent {
                list.push(pf.prime);
            }
        }
        list
    }
}

/// Canonical sorting: sorts prime factors in monotone descending order.
pub fn canonical_prime_sort(primes: &[u64]) -> Vec<u64> {
    let mut sorted = primes.to_vec();
    sorted.sort_by(|a, b| b.cmp(a));
    sorted
}

/// PARM accumulator loop: computes p * (v + p).
fn parm_sealed_state_loop(mut v: u64, primes: &[u64]) -> u64 {
    for (i, &p) in primes.iter().enumerate() {
        if i == primes.len() - 1 {
            return (p * p) * (v + p);
        } else {
            v = p * (v + p);
        }
    }
    v
}

/// PARM sealed state: evaluates the position-aware recursive commitment root.
pub fn parm_sealed_state(primes: &[u64]) -> u64 {
    match primes.len() {
        0 => 0,
        1 => primes[0] * primes[0],
        _ => parm_sealed_state_loop(primes[0] * primes[0], &primes[1..]),
    }
}

/// Canonical PARM sealed state: guarantees permutation invariance by sorting
/// primes into canonical descending order prior to position-aware sealing.
pub fn canonical_sealed_state(primes: &[u64]) -> u64 {
    let sorted = canonical_prime_sort(primes);
    parm_sealed_state(&sorted)
}

/// Factorize an integer into its canonical prime multiplicity vector.
pub fn factorize(mut n: u64) -> PrimeMultiplicity {
    if n < 2 {
        return PrimeMultiplicity::default();
    }
    let mut factors = Vec::new();

    // Check factor 2
    let mut count_2 = 0;
    while n % 2 == 0 {
        count_2 += 1;
        n /= 2;
    }
    if count_2 > 0 {
        factors.push(PrimeFactor { prime: 2, exponent: count_2 });
    }

    // Check odd factors
    let mut d = 3u64;
    while d * d <= n {
        let mut count = 0;
        while n % d == 0 {
            count += 1;
            n /= d;
        }
        if count > 0 {
            factors.push(PrimeFactor { prime: d, exponent: count });
        }
        d += 2;
    }
    if n > 1 {
        factors.push(PrimeFactor { prime: n, exponent: 1 });
    }

    PrimeMultiplicity { factors }
}

/// A trajectory couples an explicit Encoding with its verifiable PrimeMultiplicity invariant.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Trajectory {
    pub encoding: Encoding,
    pub invariant: PrimeMultiplicity,
}

impl Trajectory {
    pub fn of_encoding(encoding: Encoding) -> Self {
        let invariant = factorize(encoding.value);
        Self { encoding, invariant }
    }

    pub fn sealed_state(&self) -> u64 {
        parm_sealed_state(&self.invariant.to_canonical_prime_list())
    }
}

/// Combine two trajectories multiplicatively.
pub fn combine_trajectories(t1: &Trajectory, t2: &Trajectory) -> PrimeMultiplicity {
    t1.invariant.add(&t2.invariant)
}

/// Event occurrence for deduplication testing.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SemanticEvent {
    pub event_id: u64,
    pub token: SemanticToken,
}

/// Count unique events in a sequence, rejecting duplicates by event_id.
pub fn count_unique_events(events: &[SemanticEvent]) -> usize {
    let mut seen = std::collections::HashSet::new();
    for e in events {
        seen.insert(e.event_id);
    }
    seen.len()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gematria_values() {
        assert_eq!(string_gematria(GematriaScheme::Standard, "אהבה"), 13);
        assert_eq!(string_gematria(GematriaScheme::Standard, "אחד"), 13);
        assert_eq!(string_gematria(GematriaScheme::Reduced, "אהבה"), 4);
        assert_eq!(string_gematria(GematriaScheme::Reduced, "אחד"), 4);
        assert_eq!(string_gematria(GematriaScheme::Standard, "חסד"), 72);
        assert_eq!(string_gematria(GematriaScheme::Standard, "אמת"), 441);
        assert_eq!(string_gematria(GematriaScheme::Standard, "שלום"), 376);
        assert_eq!(string_gematria(GematriaScheme::Standard, "חיים"), 68);
    }

    #[test]
    fn test_prime_factorization() {
        let f13 = factorize(13);
        assert_eq!(f13.factors, vec![PrimeFactor { prime: 13, exponent: 1 }]);
        assert_eq!(f13.omega(), 1);
        assert_eq!(f13.omega_total(), 1);

        let f4 = factorize(4);
        assert_eq!(f4.factors, vec![PrimeFactor { prime: 2, exponent: 2 }]);
        assert_eq!(f4.omega(), 1);
        assert_eq!(f4.omega_total(), 2);

        let f72 = factorize(72);
        assert_eq!(f72.factors, vec![
            PrimeFactor { prime: 2, exponent: 3 },
            PrimeFactor { prime: 3, exponent: 2 },
        ]);
        assert_eq!(f72.omega(), 2);
        assert_eq!(f72.omega_total(), 5);
    }

    #[test]
    fn test_orthogonality() {
        let ahavah = SemanticToken::new("ahavah", "Love", "אהבה", "ahavah", "Love");
        let echad = SemanticToken::new("echad", "One", "אחד", "echad", "Oneness");

        let enc_ahavah_std = Encoding::new(ahavah.clone(), GematriaScheme::Standard).unwrap();
        let enc_ahavah_red = Encoding::new(ahavah.clone(), GematriaScheme::Reduced).unwrap();
        let enc_echad_std = Encoding::new(echad.clone(), GematriaScheme::Standard).unwrap();

        let traj_ahavah_std = Trajectory::of_encoding(enc_ahavah_std.clone());
        let traj_ahavah_red = Trajectory::of_encoding(enc_ahavah_red.clone());
        let traj_echad_std = Trajectory::of_encoding(enc_echad_std.clone());

        // Same semantic token, distinct values and distinct prime invariants
        assert_eq!(enc_ahavah_std.token, enc_ahavah_red.token);
        assert_ne!(enc_ahavah_std.value, enc_ahavah_red.value);
        assert_ne!(traj_ahavah_std.invariant, traj_ahavah_red.invariant);

        // Distinct semantic tokens, shared prime invariant
        assert_ne!(enc_ahavah_std.token, enc_echad_std.token);
        assert_eq!(traj_ahavah_std.invariant, traj_echad_std.invariant);
    }

    #[test]
    fn test_digital_root_entropy_collapse() {
        let nums = [13u64, 22, 31, 40, 49];
        for &n in &nums {
            assert_eq!(digital_root(n), 4);
        }
        let f13 = factorize(13);
        let f22 = factorize(22);
        let f31 = factorize(31);
        let f40 = factorize(40);
        let f49 = factorize(49);
        assert_ne!(f13, f22);
        assert_ne!(f22, f31);
        assert_ne!(f31, f40);
        assert_ne!(f40, f49);
    }

    #[test]
    fn test_exponent_additivity_and_pipelines() {
        let f13_a = PrimeMultiplicity::single(13, 1);
        let f13_b = PrimeMultiplicity::single(13, 1);
        let combined = f13_a.add(&f13_b);
        assert_eq!(combined.val_at(13), 2);
        assert_eq!(combined.omega_total(), 2);
    }

    #[test]
    fn test_no_double_counting() {
        let token = SemanticToken::new("ahavah", "Love", "אהבה", "ahavah", "Love");
        let duplicate_events = vec![
            SemanticEvent { event_id: 1, token: token.clone() },
            SemanticEvent { event_id: 1, token: token.clone() },
        ];
        let distinct_events = vec![
            SemanticEvent { event_id: 1, token: token.clone() },
        ];
        assert_eq!(count_unique_events(&duplicate_events), 1);
        assert_eq!(count_unique_events(&distinct_events), 2);
    }

    #[test]
    fn test_canonical_sealing_permutation_invariance() {
        // All permutations of the 108-cycle prime factor multiset must yield 960
        let p1 = canonical_sealed_state(&[2, 2, 3, 3, 3]);
        let p2 = canonical_sealed_state(&[3, 2, 3, 2, 3]);
        let p3 = canonical_sealed_state(&[2, 3, 3, 3, 2]);
        let p4 = canonical_sealed_state(&[3, 3, 3, 2, 2]);

        assert_eq!(p1, 960);
        assert_eq!(p2, 960);
        assert_eq!(p3, 960);
        assert_eq!(p4, 960);

        // Trajectory sealing
        let ahavah = SemanticToken::new("ahavah", "Love", "אהבה", "ahavah", "Love");
        let echad = SemanticToken::new("echad", "One", "אחד", "echad", "Oneness");
        let enc_ahavah_std = Encoding::new(ahavah.clone(), GematriaScheme::Standard).unwrap();
        let enc_ahavah_red = Encoding::new(ahavah, GematriaScheme::Reduced).unwrap();
        let enc_echad_std = Encoding::new(echad, GematriaScheme::Standard).unwrap();

        let traj_ahavah_std = Trajectory::of_encoding(enc_ahavah_std);
        let traj_ahavah_red = Trajectory::of_encoding(enc_ahavah_red);
        let traj_echad_std = Trajectory::of_encoding(enc_echad_std);

        assert_eq!(traj_ahavah_std.sealed_state(), 169);
        assert_eq!(traj_ahavah_red.sealed_state(), 24);
        assert_eq!(traj_echad_std.sealed_state(), 169);
        assert_ne!(traj_ahavah_std.sealed_state(), traj_ahavah_red.sealed_state());
    }
}
