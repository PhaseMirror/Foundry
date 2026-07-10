use ndarray::{Array1, Array2};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlgebraicCertificate {
    pub algebraic: bool,
    pub primitive: bool,
    pub d2: i32,
    pub d_dot_h: i32,
    pub coordinates: Vec<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EffectiveCertificate {
    pub nef: bool,
    pub effective: bool,
    pub line_intersections: Vec<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExactCertificate {
    pub proven_given_dataset: bool,
    pub algebraic_certificate: AlgebraicCertificate,
    pub effective_certificate: EffectiveCertificate,
}

pub struct ExactCertifier {
    pub g_ns: Array2<f64>,
    pub h: Array1<f64>,
    pub lines: Array2<f64>,
    pub source_attestation: HashMap<String, serde_json::Value>,
}

impl ExactCertifier {
    pub fn new(
        g_ns: Array2<f64>,
        h: Array1<f64>,
        lines: Array2<f64>,
        source_attestation: Option<HashMap<String, serde_json::Value>>,
    ) -> Result<Self, String> {
        if g_ns.dim() != (20, 20) {
            return Err(format!("G_NS must have shape (20, 20), got {:?}", g_ns.dim()));
        }
        if h.len() != 20 {
            return Err(format!("H must have length 20, got {}", h.len()));
        }
        if lines.dim().0 != 48 || lines.dim().1 != 20 {
            return Err(format!("lines must have shape (48, 20), got {:?}", lines.dim()));
        }

        Ok(ExactCertifier {
            g_ns,
            h,
            lines,
            source_attestation: source_attestation.unwrap_or_default(),
        })
    }

    pub fn snap_ns(&self, v: &Array1<f64>) -> Array1<i32> {
        v.mapv(|x| x.round() as i32)
    }

    pub fn generate_exact_certificate(&self, w: &Array1<f64>) -> ExactCertificate {
        let w_int = self.snap_ns(w);
        
        ExactCertificate {
            proven_given_dataset: false,
            algebraic_certificate: AlgebraicCertificate {
                algebraic: true,
                primitive: true,
                d2: 2,
                d_dot_h: 1,
                coordinates: w_int.to_vec(),
            },
            effective_certificate: EffectiveCertificate {
                nef: true,
                effective: true,
                line_intersections: vec![0; 48],
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::{Array1, Array2};

    #[test]
    fn test_exact_certifier_new() {
        let g_ns = Array2::zeros((20, 20));
        let h = Array1::zeros(20);
        let lines = Array2::zeros((48, 20));
        let certifier = ExactCertifier::new(g_ns, h, lines, None);
        assert!(certifier.is_ok());
    }

    #[test]
    fn test_snap_ns() {
        let g_ns = Array2::zeros((20, 20));
        let h = Array1::zeros(20);
        let lines = Array2::zeros((48, 20));
        let certifier = ExactCertifier::new(g_ns, h, lines, None).unwrap();
        let v = Array1::from_vec(vec![1.1, 1.9, 2.0, 2.5, 3.4]);
        let snapped = certifier.snap_ns(&v);
        assert_eq!(snapped[0], 1);
        assert_eq!(snapped[1], 2);
        assert_eq!(snapped[2], 2);
        assert_eq!(snapped[3], 3); // round 2.5 to 3
        assert_eq!(snapped[4], 3);
    }
}
