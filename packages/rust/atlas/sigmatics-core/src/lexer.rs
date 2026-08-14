#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TokenType {
    Class,
    Generator,
    Dot,
    Parallel,
    LParen,
    RParen,
    At,
    Caret,
    Tilde,
    Plus,
    Minus,
    Number,
    Rotate,
    Triality,
    Twist,
    Eof,
    Error,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Token {
    pub token_type: TokenType,
    pub value: String,
    pub position: usize,
    pub length: usize,
}

pub struct Lexer {
    position: usize,
    chars: Vec<char>,
}

impl Lexer {
    pub fn new(source: &str) -> Self {
        Self {
            position: 0,
            chars: source.chars().collect(),
        }
    }

    pub fn tokenize(&mut self) -> Vec<Token> {
        let mut tokens = Vec::new();
        while self.position < self.chars.len() {
            self.skip_whitespace_and_comments();
            if self.position >= self.chars.len() {
                break;
            }
            
            let token = self.next_token();
            if token.token_type == TokenType::Error {
                // In a real implementation, handle errors more robustly.
                // For now, we follow the TS error behavior.
                panic!("Lexer error at position {}: unexpected '{}'", token.position, token.value);
            }
            tokens.push(token);
        }

        tokens.push(Token {
            token_type: TokenType::Eof,
            value: String::new(),
            position: self.position,
            length: 0,
        });

        tokens
    }

    fn next_token(&mut self) -> Token {
        let start = self.position;
        let c = self.chars[self.position];

        match c {
            '.' => { self.position += 1; return self.make_token(TokenType::Dot, ".", start); }
            '(' => { self.position += 1; return self.make_token(TokenType::LParen, "(", start); }
            ')' => { self.position += 1; return self.make_token(TokenType::RParen, ")", start); }
            '@' => { self.position += 1; return self.make_token(TokenType::At, "@", start); }
            '^' => { self.position += 1; return self.make_token(TokenType::Caret, "^", start); }
            '~' => { self.position += 1; return self.make_token(TokenType::Tilde, "~", start); }
            '+' => { self.position += 1; return self.make_token(TokenType::Plus, "+", start); }
            '-' => { self.position += 1; return self.make_token(TokenType::Minus, "-", start); }
            _ => {}
        }

        if c == '|' && self.peek(1) == Some('|') {
            self.position += 2;
            return self.make_token(TokenType::Parallel, "||", start);
        }

        if c == 'c' && self.peek(1).map_or(false, |p| p.is_ascii_digit()) {
            return self.read_class_sigil(start);
        }

        if c.is_alphabetic() {
            return self.read_identifier(start);
        }

        if c.is_ascii_digit() {
            return self.read_number(start);
        }

        self.position += 1;
        self.make_token(TokenType::Error, &c.to_string(), start)
    }

    fn read_identifier(&mut self, start: usize) -> Token {
        let mut value = String::new();
        while self.position < self.chars.len() && self.chars[self.position].is_alphanumeric() {
            value.push(self.chars[self.position]);
            self.position += 1;
        }

        match value.as_str() {
            "R" => self.make_token(TokenType::Rotate, &value, start),
            "D" => self.make_token(TokenType::Triality, &value, start),
            "T" => self.make_token(TokenType::Twist, &value, start),
            v if ["mark", "copy", "swap", "merge", "split", "quote", "evaluate"].contains(&v) => {
                self.make_token(TokenType::Generator, &value, start)
            }
            _ => self.make_token(TokenType::Error, &value, start),
        }
    }

    fn read_number(&mut self, start: usize) -> Token {
        let mut value = String::new();
        while self.position < self.chars.len() && self.chars[self.position].is_ascii_digit() {
            value.push(self.chars[self.position]);
            self.position += 1;
        }
        self.make_token(TokenType::Number, &value, start)
    }

    fn read_class_sigil(&mut self, start: usize) -> Token {
        let mut value = String::from('c');
        self.position += 1; // skip 'c'
        while self.position < self.chars.len() && self.chars[self.position].is_ascii_digit() {
            value.push(self.chars[self.position]);
            self.position += 1;
        }
        self.make_token(TokenType::Class, &value, start)
    }

    fn skip_whitespace_and_comments(&mut self) {
        while self.position < self.chars.len() {
            let c = self.chars[self.position];
            if c.is_whitespace() {
                self.position += 1;
                continue;
            }
            if c == '/' && self.peek(1) == Some('/') {
                self.position += 2;
                while self.position < self.chars.len() && self.chars[self.position] != '\n' {
                    self.position += 1;
                }
                continue;
            }
            break;
        }
    }

    fn peek(&self, offset: usize) -> Option<char> {
        if self.position + offset < self.chars.len() {
            Some(self.chars[self.position + offset])
        } else {
            None
        }
    }

    fn make_token(&self, token_type: TokenType, value: &str, start: usize) -> Token {
        Token {
            token_type,
            value: value.to_string(),
            position: start,
            length: self.position - start,
        }
    }
}
