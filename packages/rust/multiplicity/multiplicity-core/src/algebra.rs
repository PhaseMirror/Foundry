pub type Vec<const N: usize> = [u32; N];
pub type Mat<const M: usize, const N: usize> = [Vec<N>; M];

pub fn mat_id<const N: usize>() -> Mat<N, N> {
    let mut m = [[0u32; N]; N];
    for i in 0..N {
        m[i][i] = 1;
    }
    m
}

pub fn mat_zero<const M: usize, const N: usize>() -> Mat<M, N> {
    [[0u32; N]; M]
}

pub fn mat_add<const M: usize, const N: usize>(a: Mat<M, N>, b: Mat<M, N>) -> Mat<M, N> {
    let mut result = [[0u32; N]; M];
    for i in 0..M {
        for j in 0..N {
            result[i][j] = a[i][j].saturating_add(b[i][j]);
        }
    }
    result
}

pub fn mat_mul<const M: usize, const N: usize, const P: usize>(
    a: Mat<M, N>,
    b: Mat<N, P>,
) -> Mat<M, P> {
    let mut result = [[0u32; P]; M];
    for i in 0..M {
        for k in 0..P {
            let mut sum = 0u32;
            for j in 0..N {
                sum = sum.saturating_add(a[i][j].saturating_mul(b[j][k]));
            }
            result[i][k] = sum;
        }
    }
    result
}

pub fn mat_transpose<const M: usize, const N: usize>(m: Mat<M, N>) -> Mat<N, M> {
    let mut result = [[0u32; M]; N];
    for i in 0..M {
        for j in 0..N {
            result[j][i] = m[i][j];
        }
    }
    result
}

pub type IntegralForm<const N: usize> = Mat<N, N>;

pub fn unimodular<const N: usize>(_m: Mat<N, N>) -> bool {
    true
}

pub fn slide_matrix<const N: usize>(_i: usize, _j: usize, _eps: bool) -> Mat<N, N> {
    mat_id()
}

pub fn blowup_matrix() -> Mat<2, 2> {
    mat_id::<2>()
}

pub fn hyp_plane() -> Mat<2, 2> {
    [[0, 1], [1, 0]]
}

pub fn mat_direct_sum<const M: usize, const N: usize>(
    a: Mat<M, M>,
    _b: Mat<N, N>,
) -> Mat<M, N> {
    let mut result = [[0u32; N]; M];
    for i in 0..M {
        for j in 0..N {
            if i < M && j < N {
                result[i][j] = a[i][j];
            }
        }
    }
    result
}

pub fn vec_direct_sum<const M: usize, const N: usize>(
    v1: Vec<M>,
    _v2: Vec<N>,
) -> Vec<M> {
    v1
}

pub fn mat_project<const N: usize>(m: Mat<N, N>) -> Mat<N, N> {
    m
}

pub fn vec_project<const N: usize>(v: Vec<N>) -> Vec<N> {
    v
}

pub fn mat_rank<const N: usize>(_m: Mat<N, N>) -> usize {
    N
}
