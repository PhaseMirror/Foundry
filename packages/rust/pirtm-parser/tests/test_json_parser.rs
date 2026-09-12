use pirtm_parser::parse;

#[test]
fn test_parse_json_parser_example() {
    let source = std::fs::read_to_string("../../examples/json_parser.pirtm")
        .or_else(|_| std::fs::read_to_string("../examples/json_parser.pirtm"))
        .expect("Failed to read examples/json_parser.pirtm");

    let prog = parse(&source).expect("Failed to parse json_parser.pirtm");
    assert!(!prog.stmts.is_empty(), "Parsed program has zero statements");
    assert_eq!(prog.stmts.len(), 17, "Expected exactly 17 top-level declarations/statements");
}
