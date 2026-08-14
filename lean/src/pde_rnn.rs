use ndarray::{Array1, Array2};

pub struct PdeRnn {
    pub a: Array2<f32>,  // -α I
    pub b: Array2<f32>,  // spectral norm ≤ b_target
    pub c: Array2<f32>,  // spectral norm ≤ c_target
    pub u: Array2<f32>,
    pub dt: f32,
    pub gamma: f32,
}

impl PdeRnn {
    pub fn step(&mut self, h: &Array1<f32>, x: &Array1<f32>) -> Array1<f32> {
        let nonlinear = self.c.dot(h) + self.u.dot(x);
        
        // Kani stub for tanh if we're doing model checking
        #[cfg(kani)]
        let sigma = nonlinear.mapv(|_| kani::any::<f32>());
        #[cfg(not(kani))]
        let sigma = nonlinear.mapv(|v| v.tanh());
        
        h + self.dt * (self.a.dot(h) + self.b.dot(&sigma) - self.gamma * h)
    }

    #[cfg(kani)]
    #[kani::proof]
    fn verify_step_bounds() {
        use ndarray::{arr1, arr2};
        
        // Exhaustively check boundedness for n = 2 as an example (n ≤ 8 is typical)
        let mut pde = PdeRnn {
            a: arr2(&[[-1.0, 0.0], [0.0, -1.0]]),
            b: arr2(&[[0.5, 0.0], [0.0, 0.5]]),
            c: arr2(&[[0.5, 0.0], [0.0, 0.5]]),
            u: arr2(&[[1.0, 0.0], [0.0, 1.0]]),
            dt: 0.1,
            gamma: 0.1,
        };
        
        // We use symbolic bounded values for input
        let h = arr1(&[kani::any::<f32>(), kani::any::<f32>()]);
        let x = arr1(&[kani::any::<f32>(), kani::any::<f32>()]);
        
        // Assume bounds for float stability
        kani::assume(h[0] >= -10.0 && h[0] <= 10.0);
        kani::assume(h[1] >= -10.0 && h[1] <= 10.0);
        kani::assume(x[0] >= -10.0 && x[0] <= 10.0);
        kani::assume(x[1] >= -10.0 && x[1] <= 10.0);
        
        let next_h = pde.step(&h, &x);
        
        // Invariant: no panics or Inf/NaN generated
        assert!(next_h[0].is_finite());
        assert!(next_h[1].is_finite());
    }
}
