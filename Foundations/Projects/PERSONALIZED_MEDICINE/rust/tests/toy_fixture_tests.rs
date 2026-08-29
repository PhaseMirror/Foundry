use personalized_medicine::toy_fixture::ToyFixture;

#[test]
fn test_f10_evaluation_and_lipschitz() {
    assert_eq!(ToyFixture::f10(10, 2), 42);
    assert_eq!(ToyFixture::f10(-5, 0), -20);
    assert!(ToyFixture::verify_f10_lipschitz(15, 7, 3));
    assert!(ToyFixture::verify_f10_lipschitz(-4, 6, -1));
}

#[test]
fn test_f_scaled_evaluation_and_lipschitz() {
    let out = ToyFixture::f_scaled(10.0, 2.0);
    assert!((out - 4.2).abs() < 1e-9);
    assert!(ToyFixture::verify_f_scaled_lipschitz(15.0, 7.0, 3.0));
}
