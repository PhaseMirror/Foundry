use std::collections::HashSet;
use itertools::Itertools;

mod tests;
pub mod lexicon;
pub mod analysis;

pub struct PARM;

impl PARM {
    pub fn get_small_gematria_to_prime(g: i32) -> Option<i32> {
        match g {
            1 => Some(2),
            2 => Some(3),
            3 => Some(5),
            4 => Some(7),
            5 => Some(11),
            6 => Some(13),
            7 => Some(17),
            8 => Some(19),
            9 => Some(23),
            _ => None,
        }
    }

    pub fn get_standard_gematria(letter: char) -> i32 {
        match letter {
            'א' => 1, 'ב' => 2, 'ג' => 3, 'ד' => 4, 'ה' => 5,
            'ו' => 6, 'ז' => 7, 'ח' => 8, 'ט' => 9, 'י' => 10,
            'כ' | 'ך' => 20, 'ל' => 30, 'מ' | 'ם' => 40,
            'נ' | 'ן' => 50, 'ס' => 60, 'ע' => 70, 'פ' | 'ף' => 80,
            'צ' | 'ץ' => 90, 'ק' => 100, 'ר' => 200,
            'ש' => 300, 'ת' => 400,
            _ => 0,
        }
    }

    pub fn get_shape_map(letter: char) -> Option<i32> {
        match letter {
            'א' => Some(1), 'ב' => Some(2), 'ג' => Some(3), 'ד' => Some(4), 'ה' => Some(5),
            'ו' => Some(6), 'ז' => Some(7), 'ח' => Some(8), 'ט' => Some(9), 'י' => Some(10),
            'כ' => Some(11), 'ל' => Some(12), 'מ' => Some(13), 'נ' => Some(14), 'ס' => Some(15),
            'ע' => Some(16), 'פ' => Some(17), 'צ' => Some(18), 'ק' => Some(19), 'ר' => Some(20),
            'ש' => Some(21), 'ת' => Some(22),
            'ך' => Some(23), 'ם' => Some(24), 'ן' => Some(25), 'ף' => Some(26), 'ץ' => Some(27),
            _ => None,
        }
    }

    pub fn get_phonetic_map(letter: char) -> Option<i32> {
        match letter {
            'ב' | 'ו' | 'מ' | 'ם' | 'פ' | 'ף' => Some(2),
            'ד' | 'ט' | 'ת' | 'ל' | 'נ' | 'ן' | 'ר' => Some(3),
            'ג' | 'כ' | 'ך' | 'ק' => Some(5),
            'א' | 'ה' | 'ח' | 'ע' => Some(7),
            'ז' | 'ס' | 'צ' | 'ץ' | 'ש' => Some(11),
            _ => None,
        }
    }

    pub fn get_prime(n: usize) -> i32 {
        let mut primes = Vec::new();
        let mut num = 2;
        while primes.len() < n {
            let is_prime = primes.iter().all(|&p| num % p != 0);
            if is_prime {
                primes.push(num);
            }
            num += 1;
        }
        primes[n - 1]
    }

    pub fn small_gematria(letter: char) -> i32 {
        let mut val = Self::get_standard_gematria(letter);
        if val == 0 {
            return 0;
        }
        while val > 9 {
            val = val.to_string().chars().map(|c| c.to_digit(10).unwrap() as i32).sum();
        }
        val
    }

    pub fn sealed_state(primes: &[i32]) -> i64 {
        let n = primes.len();
        if n == 0 {
            return 0;
        }
        
        let mut v = (primes[0] as i64).pow(2);
        if n == 1 {
            return v;
        }
        
        for &p in &primes[1..n - 1] {
            v = (p as i64) * (v + p as i64);
        }
        
        let p_last = primes[n - 1] as i64;
        v = p_last.pow(2) * (v + p_last);
        
        v
    }
    
    pub fn calculate_rq(primes: &[i32], exact_fallback: bool) -> f64 {
        let n = primes.len();
        let unique_primes: HashSet<_> = primes.iter().collect();
        if n == 0 || unique_primes.len() <= 1 {
            return 0.5;
        }
        
        let v_actual = Self::sealed_state(primes);
        
        let (v_min, v_max) = if exact_fallback && n <= 6 {
            let mut v_values = primes.iter().cloned().permutations(n).map(|p| Self::sealed_state(&p)).collect::<Vec<_>>();
            v_values.sort();
            (*v_values.first().unwrap(), *v_values.last().unwrap())
        } else {
            let mut sorted_p = primes.to_vec();
            sorted_p.sort();
            
            let min_cand = [&sorted_p[1..], &sorted_p[0..1]].concat();
            let v_min = Self::sealed_state(&min_cand);
            
            let mut max_cand = sorted_p[..n-1].to_vec();
            max_cand.reverse();
            max_cand.push(sorted_p[n-1]);
            let v_max = Self::sealed_state(&max_cand);
            
            (v_min, v_max)
        };
        
        if v_max == v_min {
            return 0.5;
        }
        
        (v_actual - v_min) as f64 / (v_max - v_min) as f64
    }

    pub fn calculate_coupled_rq(primes1: &[i32], primes2: &[i32], exact_fallback: bool) -> f64 {
        let n = primes1.len();
        if n == 0 || n != primes2.len() {
            return 0.5;
        }
        
        let weights: Vec<i32> = primes1.iter().zip(primes2.iter()).map(|(&p1, &p2)| p1 * p2).collect();
        let unique_weights: HashSet<_> = weights.iter().collect();
        if unique_weights.len() <= 1 {
            return 0.5;
        }
        
        let v_actual = Self::sealed_state(&weights);
        
        let (v_min, v_max) = if exact_fallback && n <= 6 {
            let mut v_values = weights.iter().cloned().permutations(n).map(|p| Self::sealed_state(&p)).collect::<Vec<_>>();
            v_values.sort();
            (*v_values.first().unwrap(), *v_values.last().unwrap())
        } else {
            let mut sorted_w = weights.clone();
            sorted_w.sort();
            
            let min_cand = [&sorted_w[1..], &sorted_w[0..1]].concat();
            let v_min = Self::sealed_state(&min_cand);
            
            let mut max_cand = sorted_w[..n-1].to_vec();
            max_cand.reverse();
            max_cand.push(sorted_w[n-1]);
            let v_max = Self::sealed_state(&max_cand);
            
            (v_min, v_max)
        };
        
        if v_max == v_min {
            return 0.5;
        }
        
        (v_actual - v_min) as f64 / (v_max - v_min) as f64
    }
}
