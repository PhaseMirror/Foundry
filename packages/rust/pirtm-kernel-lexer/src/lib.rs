use logos::Logos;

#[derive(Logos, Debug, PartialEq, Clone)]
#[logos(skip r"[ \t\n\f]+")]
#[logos(skip r"//.*")]
#[logos(skip r"/\*([^*]|\*[^/])*\*/")]
pub enum Token {
    #[token("tensor")] Tensor,
    #[token("assert_contractive")] AssertContractive,
    #[token("|>")] PipeRight,
    
    // Some regex for Ap(n)
    #[regex(r"Ap\([0-9]+\)", |lex| {
        let s = lex.slice();
        s[3..s.len()-1].parse::<u64>().unwrap()
    })]
    Ap(u64),

    // Some regex for \Lambda_m
    #[regex(r"\\Lambda_[a-zA-Z0-9]+", |lex| {
        let s = lex.slice();
        s[8..].to_string()
    })]
    Lambda(String),

    // Some regex for p_N
    #[regex(r"p_[A-Za-z0-9]+", |lex| {
        let s = lex.slice();
        s[2..].to_string()
    })]
    PNode(String),

    #[regex("[a-zA-Z_][a-zA-Z0-9_]*", |lex| lex.slice().to_string())]
    Ident(String),

    #[regex("[0-9]+", |lex| lex.slice().parse::<u64>().unwrap())]
    Integer(u64),

    #[regex("[0-9]+\\.[0-9]+", |lex| lex.slice().parse::<f64>().unwrap())]
    Float(f64),
}

pub fn tokenize(source: &str) -> Vec<Token> {
    let mut tokens = Vec::new();
    let mut lexer = Token::lexer(source);
    while let Some(tok) = lexer.next() {
        if let Ok(t) = tok {
            tokens.push(t);
        }
    }
    tokens
}
