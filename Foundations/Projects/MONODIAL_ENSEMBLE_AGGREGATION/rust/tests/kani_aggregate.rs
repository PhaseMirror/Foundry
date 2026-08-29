#[cfg(kani)]
#[kani::proof]
#[kani::unwind(64)]
fn verify_aggregate() {
    // Choose number of ensembles (1..=3) and length (0..=5)
    let ensembles_count: u8 = kani::any();
    kani::assume(ensembles_count >= 1 && ensembles_count <= 3);
    let len: u8 = kani::any();
    kani::assume(len <= 5);
    // Create vectors of vectors
    let mut data: Vec<Vec<u64>> = Vec::new();
    let mut i = 0;
    while i < ensembles_count {
        let mut inner: Vec<u64> = Vec::new();
        let mut j = 0;
        while j < len {
            let val: u64 = kani::any();
            kani::assume(val <= 10);
            inner.push(val);
            j += 1;
        }
        data.push(inner);
        i += 1;
    }
    // Create slice-of-slices for the library function
    let slices: Vec<&[u64]> = data.iter().map(|v| v.as_slice()).collect();
    let result = monodial_ensemble_aggregation::aggregate(&slices);
    // Compute expected result directly
    let mut expected = vec![0u64; len as usize];
    for v in data.iter() {
        for (idx, &val) in v.iter().enumerate() {
            expected[idx] = expected[idx] + val;
        }
    }
    kani::assert(result == expected, "aggregate should match manual sum");
}
