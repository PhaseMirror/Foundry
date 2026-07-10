#[cfg(test)]
mod tests {
    use crate::PARM;

    #[test]
    fn test_shalom_rq() {
        let word = "שלום";
        let shape_primes: Vec<i32> = word.chars().filter_map(|c| PARM::get_shape_map(c)).map(|p| PARM::get_prime(p as usize)).collect();
        let num_primes: Vec<i32> = word.chars().filter_map(|c| {
            let sg = PARM::small_gematria(c);
            if sg > 0 { PARM::get_small_gematria_to_prime(sg) } else { None }
        }).collect();
        
        let rq_shape = PARM::calculate_rq(&shape_primes, false);
        let rq_num = PARM::calculate_rq(&num_primes, false);
        
        // Based on Python `parm.py` reference run:
        // Word: שלום
        // RQ Shape: 1.0
        // RQ Num: 0.1716659679079163
        
        assert!((rq_shape - 1.0).abs() < 0.001, "RQ Shape {} too far from 1.0", rq_shape);
        assert!((rq_num - 0.171666).abs() < 0.001, "RQ Num {} too far from 0.171666", rq_num);
    }
}
