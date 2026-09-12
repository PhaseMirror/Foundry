use rand::RngExt;

pub struct Share {
    pub idx: u8,
    pub data: Vec<u8>,
}

pub fn split(secret: &[u8], k: u8, n: u8) -> Vec<Share> {
    if k < 2 || k > n || n > 255 {
        panic!("invalid params");
    }
    let mut shares: Vec<Share> = (1..=n)
        .map(|i| Share {
            idx: i,
            data: vec![0u8; secret.len()],
        })
        .collect();

    let mut rng = rand::rng();
    for b in 0..secret.len() {
        let mut coeffs = vec![0u8; k as usize];
        coeffs[0] = secret[b];
        for i in 1..k as usize {
            coeffs[i] = rng.random();
        }
        for i in 0..n as usize {
            shares[i].data[b] = poly_eval(&coeffs, shares[i].idx);
        }
    }
    shares
}

pub fn combine(shares: &[Share]) -> Vec<u8> {
    let len = shares[0].data.len();
    let mut secret = vec![0u8; len];
    for b in 0..len {
        let points: Vec<(u8, u8)> = shares.iter().map(|s| (s.idx, s.data[b])).collect();
        secret[b] = lagrange_at_zero(&points);
    }
    secret
}

const EXP: [u8; 510] = {
    let mut table = [0u8; 510];
    let mut x = 1u16;
    let mut i = 0;
    while i < 255 {
        table[i] = x as u8;
        x <<= 1;
        if x & 0x100 != 0 {
            x ^= 0x11d;
        }
        i += 1;
    }
    let mut i = 255;
    while i < 510 {
        table[i] = table[i - 255];
        i += 1;
    }
    table
};

const LOG: [u8; 256] = {
    let mut table = [0u8; 256];
    let mut x = 1u16;
    let mut i = 0;
    while i < 255 {
        table[x as usize] = i as u8;
        x <<= 1;
        if x & 0x100 != 0 {
            x ^= 0x11d;
        }
        i += 1;
    }
    table
};

fn gf_mul(a: u8, b: u8) -> u8 {
    if a == 0 || b == 0 {
        return 0;
    }
    EXP[LOG[a as usize] as usize + LOG[b as usize] as usize]
}

fn gf_div(a: u8, b: u8) -> u8 {
    if b == 0 {
        panic!("div0");
    }
    if a == 0 {
        return 0;
    }
    EXP[(LOG[a as usize] as usize + 255 - LOG[b as usize] as usize) % 255]
}

fn poly_eval(coeffs: &[u8], x: u8) -> u8 {
    let mut y = 0u8;
    for i in (0..coeffs.len()).rev() {
        y = gf_mul(y, x) ^ coeffs[i];
    }
    y
}

fn lagrange_at_zero(points: &[(u8, u8)]) -> u8 {
    let mut sum = 0u8;
    for i in 0..points.len() {
        let mut term = points[i].1;
        for j in 0..points.len() {
            if i != j {
                term = gf_mul(term, gf_div(points[j].0, points[j].0 ^ points[i].0));
            }
        }
        sum ^= term;
    }
    sum
}
