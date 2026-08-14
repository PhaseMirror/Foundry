use criterion::{black_box, criterion_group, criterion_main, Criterion};
use prime_rust::completion::{complete, PartialSystem, MAX_TERMS};

fn bench_completion_empty(c: &mut Criterion) {
    c.bench_function("completion_empty", |b| {
        b.iter(|| {
            let sys = PartialSystem::default();
            complete(black_box(&sys))
        })
    });
}

fn bench_completion_small(c: &mut Criterion) {
    c.bench_function("completion_small_3", |b| {
        b.iter(|| {
            let mut sys = PartialSystem::default();
            sys.vars = 3;
            sys.comp_def[0] = (0, 1, Some(2));
            sys.close_def[0] = (0, Some(1));
            complete(black_box(&sys))
        })
    });
}

fn bench_completion_medium(c: &mut Criterion) {
    c.bench_function("completion_medium_8", |b| {
        b.iter(|| {
            let mut sys = PartialSystem::default();
            sys.vars = 8;
            for i in 0..8 {
                sys.comp_def[i] = (i as u8, ((i + 1) % 8) as u8, Some(((i + 2) % 8) as u8));
                sys.close_def[i] = (i as u8, Some(i as u8));
            }
            complete(black_box(&sys))
        })
    });
}

fn bench_completion_saturated(c: &mut Criterion) {
    c.bench_function("completion_saturated_32", |b| {
        b.iter(|| {
            let mut sys = PartialSystem::default();
            sys.vars = MAX_TERMS as u8;
            for i in 0..MAX_TERMS {
                sys.comp_def[i] = (
                    (i % MAX_TERMS) as u8,
                    ((i + 1) % MAX_TERMS) as u8,
                    Some(((i + 2) % MAX_TERMS) as u8),
                );
                sys.close_def[i] = ((i % MAX_TERMS) as u8, Some((i % MAX_TERMS) as u8));
            }
            complete(black_box(&sys))
        })
    });
}

fn bench_union_find_operations(c: &mut Criterion) {
    use prime_rust::union_find::UnionFind;
    use prime_rust::term::Term;

    c.bench_function("union_find_100_unions", |b| {
        b.iter(|| {
            let mut uf = UnionFind::new();
            for i in 0..100 {
                uf.add_node(Term::Var((i % 32) as u8));
            }
            for i in 0..99 {
                uf.union(i, i + 1);
            }
            for i in 0..100 {
                black_box(uf.find(i));
            }
        })
    });
}

criterion_group!(
    benches,
    bench_completion_empty,
    bench_completion_small,
    bench_completion_medium,
    bench_completion_saturated,
    bench_union_find_operations,
);
criterion_main!(benches);
