use logos::Logos;

#[derive(Logos, Debug, PartialEq, Clone)]
pub enum Token {
    // Keywords
    #[token("let")]
    Let,
    #[token("fn")]
    Fn,
    #[token("if")]
    If,
    #[token("else")]
    Else,
    #[token("return")]
    Return,
    #[token("ensemble")]
    Ensemble,
    #[token("use")]
    Use,

    // Operators
    #[token("+")]
    Plus,
    #[token("-")]
    Minus,
    #[token("*")]
    Star,
    #[token("/")]
    Slash,
    #[token("=")]
    Equal,
    #[token("==")]
    EqEq,
    #[token("!=")]
    Neq,
    #[token("<")]
    Lt,
    #[token(">")]
    Gt,
    #[token("<=")]
    Le,
    #[token(">=")]
    Ge,

    // Punctuation
    #[token("(")]
    LPar,
    #[token(")")]
    RPar,
    #[token("{")]
    LBrace,
    #[token("}")]
    RBrace,
    #[token(",")]
    Comma,
    #[token(";")]
    Semicolon,
    #[token("::")]
    ColonColon,
    #[token(".")]
    Dot,
    #[token("with")]
    With,
    #[token("as")]
    As,

    // Identifiers — captures the string
    #[regex("[a-zA-Z_][a-zA-Z0-9_]*", |lex| lex.slice().to_string())]
    Ident(String),

    // Integers — captures the value
    #[regex("[0-9]+", |lex| lex.slice().parse::<u64>().unwrap())]
    Integer(u64),

    // Whitespace and comments (skip)
    #[regex(r"[ \t\n\f]+", logos::skip)]
    Whitespace,
    #[regex(r"//[^\n]*", logos::skip)]
    Comment,

    Error,
}

pub fn tokenize(input: &str) -> Vec<Token> {
    Token::lexer(input)
        .map(|res| res.unwrap_or(Token::Error))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tokenize_simple() {
        let input = "let x = 42;";
        let tokens = tokenize(input);
        assert_eq!(
            tokens,
            vec![
                Token::Let,
                Token::Ident("x".to_string()),
                Token::Equal,
                Token::Integer(42),
                Token::Semicolon,
            ]
        );
    }
}
