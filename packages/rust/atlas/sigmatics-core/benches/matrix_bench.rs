use criterion::{black_box, criterion_group, criterion_main, Criterion};
use sigmatics_core::MatrixRuntime;

pub fn criterion_benchmark(c: &mut Criterion) {
    let runtime = MatrixRuntime::new();
    
    c.bench_function("matrix_pack_unpack", |b| b.iter(|| {
        let (orbit, index) = MatrixRuntime::pack(black_box(17), black_box(42));
        let (p, b_res) = MatrixRuntime::unpack(orbit, index);
        assert_eq!(p, 17);
        assert_eq!(b_res, 42);
    }));

    c.bench_function("matrix_act_u", |b| b.iter(|| {
        runtime.act_u(black_box(17), black_box(42), black_box(0x555))
    }));

    c.bench_function("matrix_to_scaled_tensor", |b| b.iter(|| {
        runtime.to_scaled_tensor(black_box(1000000))
    }));
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
