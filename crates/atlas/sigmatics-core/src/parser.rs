use crate::lexer::{Token, TokenType};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Expr {
    Class(u32),
    Generator(String, Vec<Expr>),
    Rotate,
    Triality,
    Twist,
}

pub struct Parser {
    tokens: Vec<Token>,
    position: usize,
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Self {
        Self { tokens, position: 0 }
    }

    pub fn parse(&mut self) -> Result<Vec<Expr>, String> {
        let mut exprs = Vec::new();
        while self.position < self.tokens.len() && self.tokens[self.position].token_type != TokenType::Eof {
            exprs.push(self.parse_expr()?);
        }
        Ok(exprs)
    }

    fn parse_expr(&mut self) -> Result<Expr, String> {
        let token = self.consume()?;
        match token.token_type {
            TokenType::Class => {
                let id = token.value[1..].parse::<u32>().map_err(|_| "Invalid class ID")?;
                Ok(Expr::Class(id))
            }
            TokenType::Generator => {
                Ok(Expr::Generator(token.value, Vec::new()))
            }
            TokenType::Rotate => Ok(Expr::Rotate),
            TokenType::Triality => Ok(Expr::Triality),
            TokenType::Twist => Ok(Expr::Twist),
            _ => Err(format!("Unexpected token: {:?}", token)),
        }
    }

    fn consume(&mut self) -> Result<Token, String> {
        if self.position < self.tokens.len() {
            let token = self.tokens[self.position].clone();
            self.position += 1;
            Ok(token)
        } else {
            Err("Unexpected EOF".to_string())
        }
    }
}
