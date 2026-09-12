#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Rational {
    pub num: i64,
    pub den: i64,
}

impl Rational {
    pub fn new(num: i64, den: i64) -> Self {
        assert!(den != 0);
        let g = gcd(num.abs(), den.abs());
        Rational {
            num: num / g * den.signum(),
            den: den.abs() / g,
        }
    }

    pub fn to_integer(&self) -> i64 {
        assert!(self.den == 1);
        self.num
    }

    pub fn reduce(&mut self) {
        let g = gcd(self.num.abs(), self.den.abs());
        self.num /= g;
        self.den /= g;
    }

    /// Converts the rational to a scaled integer (e.g., for matrix operations).
    /// value = (num * q) / den
    pub fn to_scaled_int(&self, q: i64) -> i64 {
        self.num.checked_mul(q).expect("Overflow in scaling") / self.den
    }
}

fn gcd(a: i64, b: i64) -> i64 {
    let mut x = a.abs();
    let mut y = b.abs();
    while y != 0 {
        let t = y;
        y = x % y;
        x = t;
    }
    x
}
