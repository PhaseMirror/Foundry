use serde::{Deserialize, Serialize};
use std::error::Error;
use std::collections::HashMap;
use crate::PARM;
use rand::prelude::*;
use rand_distr::{Zipf, Distribution};

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct RootData {
    pub root: String,
    pub gloss: String,
    pub rq_shape: f64,
    pub rq_num: f64,
    pub c_resonance: f64,
    pub delta: f64,
    pub ratio: f64,
    pub freq: Option<i32>,
    pub f_c: Option<f64>,
}

pub fn process_corpus(input_path: &str, output_path: &str) -> Result<(), Box<dyn Error>> {
    let mut rdr = csv::Reader::from_path(input_path)?;
    let mut wtr = csv::Writer::from_path(output_path)?;
    
    for result in rdr.deserialize() {
        let record: HashMap<String, String> = result?;
        let root = record.get("root").ok_or("Missing root")?;
        let gloss = record.get("gloss").unwrap_or(&"".to_string()).clone();
        
        let clean_root: String = root.chars().filter(|c| ('\u{05D0}'..='\u{05EA}').contains(c)).collect();
        if clean_root.is_empty() { continue; }
        
        let analysis = analyze_word_rs(&clean_root);
        
        let row = RootData {
            root: clean_root,
            gloss,
            rq_shape: analysis.rq_shape,
            rq_num: analysis.rq_num,
            c_resonance: analysis.c_resonance,
            delta: analysis.rq_num - analysis.rq_shape,
            ratio: if analysis.rq_shape > 0.0 { analysis.rq_num / analysis.rq_shape } else { f64::INFINITY },
            freq: None,
            f_c: None,
        };
        wtr.serialize(row)?;
    }
    wtr.flush()?;
    Ok(())
}

pub fn simulate_and_analyze(data: &mut [RootData]) -> Result<(), Box<dyn Error>> {
    let n = data.len();
    if n == 0 { return Ok(()); }

    let mut rng = rand::rng();
    let zipf = Zipf::new(n as f64, 1.05)?;

    let mut frequencies: Vec<i32> = (0..n).map(|_| zipf.sample(&mut rng) as i32).collect();
    frequencies.shuffle(&mut rng);

    for (i, row) in data.iter_mut().enumerate() {
        let freq = frequencies[i].clamp(1, 10000);
        row.freq = Some(freq);
        row.f_c = Some(freq as f64 * row.c_resonance);
    }

    data.sort_by(|a, b| b.f_c.partial_cmp(&a.f_c).unwrap_or(std::cmp::Ordering::Equal));

    Ok(())
}


pub struct WordAnalysis {
    pub rq_shape: f64,
    pub rq_num: f64,
    pub c_resonance: f64,
}

pub fn analyze_word_rs(word: &str) -> WordAnalysis {
    let shape_primes: Vec<i32> = word.chars().filter_map(|c| PARM::get_shape_map(c)).map(|p| PARM::get_prime(p as usize)).collect();
    let num_primes: Vec<i32> = word.chars().filter_map(|c| {
        let sg = PARM::small_gematria(c);
        if sg > 0 { PARM::get_small_gematria_to_prime(sg) } else { None }
    }).collect();
    
    let rq_shape = PARM::calculate_rq(&shape_primes, false);
    let rq_num = PARM::calculate_rq(&num_primes, false);
    let c_resonance = (rq_shape * rq_num).sqrt();
    
    WordAnalysis { rq_shape, rq_num, c_resonance }
}
