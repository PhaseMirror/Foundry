#[cfg(test)]
mod tests {
    use crate::lexer::Lexer;
    use crate::parser::Parser;
    use crate::evaluator::Evaluator;
    #[test]
    fn test_rational_normalization() {
        use crate::Rational;
        let r = Rational::new(10, 20);
        assert_eq!(r.num, 1);
        assert_eq!(r.den, 2);

        let r2 = Rational::new(-10, 20);
        assert_eq!(r2.num, -1);
        assert_eq!(r2.den, 2);
    }

#[test]
fn test_class_system() {
    use crate::class_system::{ClassSystem, Transform};

    let byte = ClassSystem::encode_components_to_byte(1, 2, 3);
    assert_eq!(ClassSystem::decode_byte_to_components(byte), (1, 2, 3));

    let rotated = ClassSystem::apply_transform(byte, Transform::Rotate);
    assert_eq!(ClassSystem::decode_byte_to_components(rotated), (1, 3, 2));
}

#[test]
fn test_parser_evaluator_integration() {
    let source = "c1 c2 merge";
    let mut lexer = Lexer::new(source);
    let tokens = lexer.tokenize();

    let mut parser = Parser::new(tokens);
    let exprs = parser.parse().unwrap();

    let mut evaluator = Evaluator::new();
    let result = evaluator.evaluate(exprs).unwrap();

    // c1 + c2 = 3
    assert_eq!(result[0].to_integer(), 3);
}
}

