use serde_json::Value;
/// Barrett reduction linter - recomputes full MR64 execution and compares with trace
/// This validates that the trace represents actual correct Miller-Rabin arithmetic
use std::fs;
use uint::construct_uint;

construct_uint! {
    pub struct U256(4);
}

fn mu_for(n: u64) -> (u64, u64) {
    let mu = (U256::one() << 128) / U256::from(n);
    let mu_lo = mu.low_u128() as u64;
    let mu_hi = (mu >> 64).low_u128() as u64;
    (mu_lo, mu_hi)
}

fn barrett_mulred(u: u64, v: u64, n: u64, mu: (u64, u64)) -> (u64, u64, u64, u64, u64, u64, u64) {
    let n256 = U256::from(n);
    let t = U256::from(u) * U256::from(v);
    let mu256 = (U256::from(mu.1) << 64) + U256::from(mu.0);
    let q = (t * mu256) >> 128;
    let mut r = t - q * n256;

    if r >= n256 {
        r -= n256;
    }
    if r >= n256 {
        r -= n256;
    }

    let t_lo = t.low_u128() as u64;
    let t_hi = (t >> 64).low_u128() as u64;
    let q_lo = q.low_u128() as u64;
    let q_hi = (q >> 64).low_u128() as u64;
    let r_lo = r.low_u128() as u64;
    let r_hi = (r >> 64).low_u128() as u64;
    let result = r_lo;

    (result, t_lo, t_hi, q_lo, q_hi, r_lo, r_hi)
}

fn factor_power_of_two(mut num: u64) -> (u32, u64) {
    let mut s = 0u32;
    while num % 2 == 0 {
        num /= 2;
        s += 1;
    }
    (s, num)
}

/// Re-execute MR64 for given n and bases, return expected trace rows
fn recompute_mr64(n: u64, bases: &[u64]) -> Vec<(u64, u64, u64, u64, u64, u64, u64, u64)> {
    let (s, d) = factor_power_of_two(n - 1);
    let mu = mu_for(n);
    let mut expected_rows = Vec::new();

    for (round, &a) in bases.iter().enumerate() {
        let mut x = 1u64;
        let mut base = a % n;
        let mut e = d;
        let round = round as u64;

        // Round start marker (no operation)
        expected_rows.push((round, 0, 0, 0, 0, 0, 0, 0));

        // Compute x = a^d mod n
        while e > 0 {
            if e & 1 == 1 {
                let (result, t_lo, t_hi, q_lo, _, r_lo, _) = barrett_mulred(x, base, n, mu);
                expected_rows.push((round, 1, 0, result, t_lo, t_hi, q_lo, r_lo));
                x = result;
            }

            let (sq, t_lo, t_hi, q_lo, _, r_lo, _) = barrett_mulred(base, base, n, mu);
            expected_rows.push((round, 0, 1, sq, t_lo, t_hi, q_lo, r_lo));
            base = sq;
            e >>= 1;
        }

        // s squarings for MR check
        for _ in 0..s {
            let (x_new, t_lo, t_hi, q_lo, _, r_lo, _) = barrett_mulred(x, x, n, mu);
            expected_rows.push((round, 0, 1, x_new, t_lo, t_hi, q_lo, r_lo));
            x = x_new;
            if x == 1 || x == n - 1 {
                break;
            }
        }
    }

    expected_rows
}

#[test]
fn lint_barrett_full_recomputation_n17() {
    let n = 17u64;
    let bases = vec![2u64, 3u64];

    // Load actual trace
    let contents = fs::read_to_string("../../test-vectors/n17/trace.col.json")
        .expect("Failed to read trace file");
    let trace: Value = serde_json::from_str(&contents).unwrap();
    let rows = trace["rows"].as_array().unwrap();

    // Recompute expected trace
    let expected = recompute_mr64(n, &bases);

    let mut errors = Vec::new();
    let mut expected_idx = 0;

    for (i, row_val) in rows.iter().enumerate() {
        let row = row_val.as_array().unwrap();
        let is_mul = row[3].as_u64().unwrap();
        let is_square = row[4].as_u64().unwrap();

        // Skip pure header rows (is_round_start with no operation)
        if is_mul == 0 && is_square == 0 {
            expected_idx += 1;
            continue;
        }

        if expected_idx >= expected.len() {
            errors.push(format!("Row {}: unexpected extra row in trace", i));
            continue;
        }

        let exp = &expected[expected_idx];
        let (exp_round, exp_is_mul, exp_is_square, exp_acc, exp_t_lo, exp_t_hi, exp_q, exp_r) =
            *exp;

        let round = row[0].as_u64().unwrap();
        let acc = row[10].as_u64().unwrap();
        let t_lo = row[12].as_u64().unwrap();
        let t_hi = row[13].as_u64().unwrap();
        let q = row[14].as_u64().unwrap();
        let r = row[15].as_u64().unwrap();

        // Verify round
        if round != exp_round {
            errors.push(format!(
                "Row {}: round mismatch: expected {}, got {}",
                i, exp_round, round
            ));
        }

        // Verify operation flags
        if is_mul != exp_is_mul || is_square != exp_is_square {
            errors.push(format!(
                "Row {}: operation mismatch: expected (mul={}, sq={}), got (mul={}, sq={})",
                i, exp_is_mul, exp_is_square, is_mul, is_square
            ));
        }

        // Verify Barrett arithmetic results
        if acc != exp_acc {
            errors.push(format!(
                "Row {}: acc mismatch: expected {}, got {}",
                i, exp_acc, acc
            ));
        }

        if t_lo != exp_t_lo {
            errors.push(format!(
                "Row {}: t_lo mismatch: expected {:#x}, got {:#x}",
                i, exp_t_lo, t_lo
            ));
        }

        if t_hi != exp_t_hi {
            errors.push(format!(
                "Row {}: t_hi mismatch: expected {:#x}, got {:#x}",
                i, exp_t_hi, t_hi
            ));
        }

        if q != exp_q {
            errors.push(format!(
                "Row {}: q mismatch: expected {:#x}, got {:#x}",
                i, exp_q, q
            ));
        }

        if r != exp_r {
            errors.push(format!(
                "Row {}: r mismatch: expected {:#x}, got {:#x}",
                i, exp_r, r
            ));
        }

        expected_idx += 1;
    }

    if !errors.is_empty() {
        eprintln!("=== Barrett Full Recomputation Errors (n=17) ===");
        for err in &errors {
            eprintln!("  {}", err);
        }
        panic!("Found {} arithmetic mismatches", errors.len());
    }
}

#[test]
fn lint_barrett_full_recomputation_n561() {
    let n = 561u64;
    let bases = vec![2u64, 3u64];

    let contents = fs::read_to_string("../../test-vectors/n561/trace.col.json")
        .expect("Failed to read trace file");
    let trace: Value = serde_json::from_str(&contents).unwrap();
    let rows = trace["rows"].as_array().unwrap();

    let expected = recompute_mr64(n, &bases);

    let mut errors = Vec::new();
    let mut expected_idx = 0;

    for (i, row_val) in rows.iter().enumerate() {
        let row = row_val.as_array().unwrap();
        let is_mul = row[3].as_u64().unwrap();
        let is_square = row[4].as_u64().unwrap();

        if is_mul == 0 && is_square == 0 {
            expected_idx += 1;
            continue;
        }

        if expected_idx >= expected.len() {
            continue;
        }

        let exp = &expected[expected_idx];
        let acc = row[10].as_u64().unwrap();

        if acc != exp.3 {
            errors.push(format!(
                "Row {}: acc mismatch: expected {}, got {}",
                i, exp.3, acc
            ));
        }

        expected_idx += 1;
    }

    if !errors.is_empty() {
        eprintln!("=== Barrett Full Recomputation Errors (n=561) ===");
        for err in &errors {
            eprintln!("  {}", err);
        }
        panic!("Found {} arithmetic mismatches", errors.len());
    }
}

#[test]
fn lint_essential_properties() {
    let contents = fs::read_to_string("../../test-vectors/n17/trace.col.json").unwrap();
    let trace: Value = serde_json::from_str(&contents).unwrap();
    let rows = trace["rows"].as_array().unwrap();

    let mut errors = Vec::new();

    for (i, row_val) in rows.iter().enumerate() {
        let row = row_val.as_array().unwrap();
        let is_mul = row[3].as_u64().unwrap();
        let is_square = row[4].as_u64().unwrap();
        let mu_lo = row[16].as_u64().unwrap();
        let mu_hi = row[17].as_u64().unwrap();

        if is_mul == 0 && is_square == 0 {
            continue;
        }

        if mu_lo == 0 && mu_hi == 0 {
            errors.push(format!("Row {}: mu is zero", i));
        }

        if (is_mul ^ is_square) != 1 {
            errors.push(format!("Row {}: XOR violation", i));
        }
    }

    assert!(errors.is_empty(), "Found {} errors", errors.len());
}
