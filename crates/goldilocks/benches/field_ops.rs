use criterion::{black_box, criterion_group, criterion_main, Criterion};
use goldilocks::GoldilocksField;

#[cfg(target_arch = "x86_64")]
use goldilocks::sse::SSEGoldilocks;

#[cfg(all(target_arch = "x86_64", target_feature = "avx2"))]
use goldilocks::avx2::Avx2Goldilocks;

fn bench_scalar_ops(c: &mut Criterion) {
    let a = GoldilocksField::new(123456789);
    let b = GoldilocksField::new(987654321);
    
    c.bench_function("scalar_add_x100", |b_bench| {
        b_bench.iter(|| {
            let mut res = black_box(a);
            for _ in 0..100 {
                res = res.add(&b);
            }
            res
        })
    });

    c.bench_function("scalar_mul_x100", |b_bench| {
        b_bench.iter(|| {
            let mut res = black_box(a);
            for _ in 0..100 {
                res = res.mul(&b);
            }
            res
        })
    });
}

#[cfg(target_arch = "x86_64")]
fn bench_sse_ops(c: &mut Criterion) {
    let a_vals = [123456789, 987654321];
    let b_vals = [987654321, 123456789];
    
    unsafe {
        let a = SSEGoldilocks::load(&a_vals);
        let b = SSEGoldilocks::load(&b_vals);

        c.bench_function("sse_add_x100", |b_bench| {
            b_bench.iter(|| {
                let mut res = black_box(a);
                for _ in 0..100 {
                    res = SSEGoldilocks::add(res, b);
                }
                res
            })
        });

        c.bench_function("sse_mul_x100", |b_bench| {
            b_bench.iter(|| {
                let mut res = black_box(a);
                for _ in 0..100 {
                    res = SSEGoldilocks::mul(res, b);
                }
                res
            })
        });
    }
}

#[cfg(not(target_arch = "x86_64"))]
fn bench_sse_ops(_c: &mut Criterion) {}

#[cfg(all(target_arch = "x86_64", target_feature = "avx2"))]
fn bench_avx2_ops(c: &mut Criterion) {
    let a_vals = [123456789, 987654321, 123456789, 987654321];
    let b_vals = [987654321, 123456789, 987654321, 123456789];
    
    unsafe {
        let a = Avx2Goldilocks::load(&a_vals);
        let b = Avx2Goldilocks::load(&b_vals);

        c.bench_function("avx2_add_x100", |b_bench| {
            b_bench.iter(|| {
                let mut res = black_box(a);
                for _ in 0..100 {
                    res = Avx2Goldilocks::add(res, b);
                }
                res
            })
        });

        c.bench_function("avx2_mul_x100", |b_bench| {
            b_bench.iter(|| {
                let mut res = black_box(a);
                for _ in 0..100 {
                    res = Avx2Goldilocks::mul(res, b);
                }
                res
            })
        });
    }
}

#[cfg(not(all(target_arch = "x86_64", target_feature = "avx2")))]
fn bench_avx2_ops(_c: &mut Criterion) {}

use goldilocks::polynomial::{ntt, intt};

fn bench_ntt(c: &mut Criterion) {
    let n = 1024;
    let coeffs: Vec<GoldilocksField> = (0..n).map(|i| GoldilocksField::new(i as u64)).collect();
    
    c.bench_function("ntt_1024", |b| {
        b.iter(|| {
            let mut values = black_box(coeffs.clone());
            ntt(&mut values);
            values
        })
    });
}

criterion_group!(benches, bench_scalar_ops, bench_sse_ops, bench_avx2_ops, bench_ntt);
criterion_main!(benches);
