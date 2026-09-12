pub trait ContractiveOperator {
    fn forward(&self, x: &ndarray::Array1<f64>) -> ndarray::Array1<f64>;
    fn lipschitz_constant(&self) -> f64;
}
