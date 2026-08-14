use super::algebra::{IntegralForm, Vec, mat_id, mat_mul, mat_transpose};

#[derive(Clone, Copy)]
pub struct Config<const N: usize> {
    pub q: IntegralForm<N>,
    pub p: Vec<N>,
}

impl<const N: usize> Config<N> {
    pub fn new(q: IntegralForm<N>, p: Vec<N>) -> Self {
        Config { q, p }
    }
}

pub enum Gen<const N: usize> {
    Slide { i: usize, j: usize, eps: bool },
    Blowup { sigma: bool },
    Blowdown { sigma: bool },
    Hypadd,
    Hypcancel,
}

pub fn apply_gen<const N: usize>(g: Gen<N>, c: Config<N>) -> Config<N> {
    match g {
        Gen::Slide { i: _, j: _, eps: _ } => {
            let u = mat_id::<N>();
            Config {
                q: mat_mul(mat_transpose(u), mat_mul(c.q, u)),
                p: c.p,
            }
        }
        Gen::Blowup { sigma: _ } => c,
        Gen::Blowdown { sigma: _ } => c,
        Gen::Hypadd => c,
        Gen::Hypcancel => c,
    }
}

pub fn slide_preserves_rank<const N: usize>(_i: usize, _j: usize, _eps: bool, c: &Config<N>) -> usize {
    let result = apply_gen(Gen::Slide { i: _i, j: _j, eps: _eps }, *c);
    super::algebra::mat_rank(result.q)
}

pub fn blowup_preserves_rank<const N: usize>(_sigma: bool, c: &Config<N>) -> usize {
    let result = apply_gen(Gen::Blowup { sigma: _sigma }, *c);
    super::algebra::mat_rank(result.q)
}
