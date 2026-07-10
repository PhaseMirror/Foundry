use criterion::{black_box, criterion_group, criterion_main, Criterion};
use goldilocks_arithmetic_kernel::{GoldilocksField, MODULUS};

fn bench_arithmetic(c: &mut Criterion) {
    let mut group = c.benchmark_group("Goldilocks Arithmetic");
    let a = GoldilocksField::new(123456789);
    let b = GoldilocksField::new(987654321);

    group.bench_function("add", |bencher| {
        bencher.iter(|| black_box(a) + black_box(b))
    });

    group.bench_function("sub", |bencher| {
        bencher.iter(|| black_box(a) - black_box(b))
    });

    group.bench_function("mul", |bencher| {
        bencher.iter(|| black_box(a) * black_box(b))
    });

    group.finish();
}

criterion_group!(benches, bench_arithmetic);
criterion_main!(benches);
