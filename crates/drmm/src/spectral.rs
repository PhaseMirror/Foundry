use rustfft::{FftPlanner, num_complex::Complex};
use ndarray::{Array1, ArrayView1};

/// Spectral transformation utilities for DRMM.
pub struct SpectralTransform {
    planner: FftPlanner<f64>,
}

impl Default for SpectralTransform {
    fn default() -> Self {
        Self::new()
    }
}

impl SpectralTransform {
    pub fn new() -> Self {
        Self {
            planner: FftPlanner::new(),
        }
    }

    /// Perform a spectral decomposition using FFT.
    /// Returns the spectrum, padded size, and original size.
    pub fn forward(&mut self, gradient: ArrayView1<f64>) -> (Array1<Complex<f64>>, usize, usize) {
        let original_size = gradient.len();
        let padded_size = (original_size.max(2)).next_power_of_two();
        
        let mut buffer: Vec<Complex<f64>> = vec![Complex::new(0.0, 0.0); padded_size];
        for (i, &val) in gradient.iter().enumerate() {
            buffer[i] = Complex::new(val, 0.0);
        }

        let fft = self.planner.plan_fft_forward(padded_size);
        fft.process(&mut buffer);

        // For real inputs, we only need the first padded_size / 2 + 1 elements.
        // But to keep it simple and match common Rust FFT usage, we'll keep it full or handle it.
        // The Python rfft returns floor(N/2) + 1.
        let spectrum_size = padded_size / 2 + 1;
        let spectrum = Array1::from_vec(buffer[..spectrum_size].to_vec());

        (spectrum, padded_size, original_size)
    }

    /// Perform an inverse spectral transformation.
    pub fn inverse(&mut self, spectrum: ArrayView1<Complex<f64>>, padded_size: usize, original_size: usize) -> Array1<f64> {
        let mut buffer: Vec<Complex<f64>> = vec![Complex::new(0.0, 0.0); padded_size];
        
        // Reconstruct full spectrum for complex-to-real inverse FFT
        // spectrum has padded_size / 2 + 1 elements
        for i in 0..spectrum.len() {
            buffer[i] = spectrum[i];
        }
        for i in 1..(padded_size - spectrum.len() + 1) {
            let src_idx = spectrum.len() - 1 - i;
            if src_idx < spectrum.len() {
                buffer[spectrum.len() - 1 + i] = spectrum[src_idx].conj();
            }
        }

        let fft = self.planner.plan_fft_inverse(padded_size);
        fft.process(&mut buffer);

        let scale = 1.0 / (padded_size as f64);
        let mut out = Array1::zeros(original_size);
        for i in 0..original_size {
            out[i] = buffer[i].re * scale;
        }

        out
    }
}

pub fn compute_bin_energies(spectrum: ArrayView1<Complex<f64>>, num_bins: usize) -> Array1<f64> {
    let magnitudes: Array1<f64> = spectrum.mapv(|c| c.norm_sqr());
    let total = magnitudes.len();
    let usable_bins = num_bins.min(total).max(1);
    
    let mut energies = Vec::with_capacity(usable_bins);
    for index in 0..usable_bins {
        let start = (index * total) / usable_bins;
        let end = ((index + 1) * total) / usable_bins;
        let slice = magnitudes.slice(ndarray::s![start..end]);
        let mean = if slice.is_empty() { 0.0 } else { slice.mean().unwrap_or(0.0) };
        energies.push(mean);
    }
    
    Array1::from_vec(energies)
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn test_fft_roundtrip() {
        let mut transform = SpectralTransform::new();
        let input = array![1.0, 2.0, 3.0, 4.0];
        let (spectrum, padded, orig) = transform.forward(input.view());
        let output = transform.inverse(spectrum.view(), padded, orig);
        
        for (a, b) in input.iter().zip(output.iter()) {
            assert!((a - b).abs() < 1e-10);
        }
    }
}
