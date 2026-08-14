pub mod ast;
pub use ast::{BinOp, EnsembleDecl, Expr, ImportStmt, Program, Stmt};

use pirtm_lexer::{tokenize, Token};

pub struct Parser {
    tokens: Vec<Token>,
    pos: usize,
}

impl Parser {
    pub fn new(input: &str) -> Self {
        let tokens = tokenize(input);
        Self { tokens, pos: 0 }
    }

    fn peek(&self) -> Option<Token> {
        self.tokens.get(self.pos).cloned()
    }

    fn next(&mut self) -> Option<Token> {
        let token = self.peek();
        self.pos += 1;
        token
    }

    fn expect(&mut self, expected: Token) -> Result<(), String> {
        if let Some(tok) = self.next() {
            if tok == expected {
                Ok(())
            } else {
                Err(format!("Expected {:?}, got {:?}", expected, tok))
            }
        } else {
            Err(format!("Expected {:?}, got EOF", expected))
        }
    }

    pub fn parse_expression(&mut self) -> Result<Expr, String> {
        let left = self.parse_primary()?;

        match self.peek() {
            Some(Token::Plus) => {
                self.next();
                let right = self.parse_expression()?;
                Ok(Expr::Binary {
                    op: BinOp::Add,
                    left: Box::new(left),
                    right: Box::new(right),
                })
            }
            Some(Token::Minus) => {
                self.next();
                let right = self.parse_expression()?;
                Ok(Expr::Binary {
                    op: BinOp::Sub,
                    left: Box::new(left),
                    right: Box::new(right),
                })
            }
            _ => Ok(left),
        }
    }

    fn parse_primary(&mut self) -> Result<Expr, String> {
        match self.peek() {
            Some(Token::Ident(name)) => {
                self.next();
                if name == "Ap" {
                    self.expect(Token::LPar)?;
                    let num = self.parse_integer()?;
                    self.expect(Token::RPar)?;
                    Ok(Expr::Atom { prime: num })
                } else if let Some(Token::LPar) = self.peek() {
                    // Function call
                    self.next(); // consume '('
                    let mut args = Vec::new();
                    // Allow empty argument list
                    if let Some(Token::RPar) = self.peek() {
                        self.next(); // consume ')'
                    } else {
                        loop {
                            let expr = self.parse_expression()?;
                            args.push(expr);
                            match self.peek() {
                                Some(Token::Comma) => {
                                    self.next();
                                }
                                Some(Token::RPar) => {
                                    self.next();
                                    break;
                                }
                                Some(tok) => {
                                    return Err(format!("Unexpected token in call args: {:?}", tok))
                                }
                                None => return Err("Unexpected EOF in call args".to_string()),
                            }
                        }
                    }
                    Ok(Expr::Call { name, args })
                } else {
                    Ok(Expr::Ident(name))
                }
            }
            Some(Token::If) => {
                // if (cond) { then } else { else }
                self.next(); // consume 'if'
                self.expect(Token::LPar)?;
                let cond = self.parse_expression()?;
                self.expect(Token::RPar)?;
                self.expect(Token::LBrace)?;
                let then_branch = self.parse_block()?;
                let else_branch = if let Some(Token::Else) = self.peek() {
                    self.next(); // consume 'else'
                    self.expect(Token::LBrace)?;
                    Some(self.parse_block()?)
                } else {
                    None
                };
                Ok(Expr::If {
                    cond: Box::new(cond),
                    then_branch,
                    else_branch,
                })
            }
            Some(Token::Integer(val)) => {
                self.next();
                Ok(Expr::Literal(val))
            }
            Some(Token::LPar) => {
                self.next();
                let expr = self.parse_expression()?;
                self.expect(Token::RPar)?;
                Ok(expr)
            }
            Some(tok) => Err(format!("Unexpected token in expression: {:?}", tok)),
            None => Err("Unexpected EOF".to_string()),
        }
    }

    fn parse_integer(&mut self) -> Result<u64, String> {
        match self.next() {
            Some(Token::Integer(v)) => Ok(v),
            _ => Err("Expected integer".to_string()),
        }
    }

    fn parse_block(&mut self) -> Result<Vec<Stmt>, String> {
        // Expect opening brace already consumed
        let mut stmts = Vec::new();
        while let Some(tok) = self.peek() {
            match tok {
                Token::RBrace => {
                    self.next(); // consume closing brace
                    break;
                }
                _ => {
                    stmts.push(self.parse_statement()?);
                }
            }
        }
        Ok(stmts)
    }

    fn parse_ensemble_path(&mut self) -> Result<String, String> {
        let mut path = String::new();
        match self.next() {
            Some(Token::Ident(id)) => path.push_str(&id),
            other => {
                return Err(format!(
                    "Expected identifier in ensemble path, got {:?}",
                    other
                ))
            }
        }
        while let Some(Token::Minus) = self.peek() {
            self.next();
            path.push('-');
            match self.next() {
                Some(Token::Ident(id)) => path.push_str(&id),
                other => return Err(format!("Expected identifier after '-', got {:?}", other)),
            }
        }
        Ok(path)
    }

    fn parse_item_path(&mut self) -> Result<String, String> {
        let mut path = self.parse_ensemble_path()?;
        while let Some(Token::ColonColon) = self.peek() {
            self.next();
            path.push_str("::");
            match self.next() {
                Some(Token::Ident(id)) => path.push_str(&id),
                other => return Err(format!("Expected identifier after '::', got {:?}", other)),
            }
        }
        Ok(path)
    }

    fn parse_version(&mut self) -> Result<String, String> {
        let mut raw = String::new();
        while let Some(tok) = self.peek() {
            if tok == Token::Ident("prime".to_string()) || tok == Token::Semicolon {
                break;
            }
            match self.next() {
                Some(Token::Ident(s)) => raw.push_str(&s),
                Some(Token::Integer(i)) => raw.push_str(&i.to_string()),
                Some(Token::Dot) => raw.push('.'),
                _ => {}
            }
        }
        Ok(raw)
    }

    pub fn parse_statement(&mut self) -> Result<Stmt, String> {
        match self.peek() {
            Some(Token::Ensemble) => {
                self.next(); // consume 'ensemble'
                let name = self.parse_ensemble_path()?;
                let version = self.parse_version()?;
                let prime = match self.next() {
                    Some(Token::Ident(ref s)) if s == "prime" => {
                        self.expect(Token::Equal)?;
                        self.parse_integer()?
                    }
                    other => return Err(format!("Expected 'prime' identifier, got {:?}", other)),
                };
                self.expect(Token::Semicolon)?;
                Ok(Stmt::Ensemble(EnsembleDecl {
                    name,
                    version,
                    prime,
                }))
            }
            Some(Token::Use) => {
                self.next(); // consume 'use'
                let path = self.parse_item_path()?;

                let mut alias = None;
                if let Some(Token::As) = self.peek() {
                    self.next();
                    if let Some(Token::Ident(id)) = self.next() {
                        alias = Some(id);
                    } else {
                        return Err("Expected identifier after 'as'".into());
                    }
                }

                let mut spectral_budget = None;
                if let Some(Token::With) = self.peek() {
                    self.next();
                    if let Some(Token::Ident(ref s)) = self.next() {
                        if s == "spectral_budget" {
                            self.expect(Token::Equal)?;
                            // Expect float
                            let int_part = self.parse_integer()?;
                            self.expect(Token::Dot)?;
                            let frac_part = self.parse_integer()?;
                            let float_str = format!("{}.{}", int_part, frac_part);
                            spectral_budget = float_str.parse::<f64>().ok();
                        } else {
                            return Err("Expected 'spectral_budget'".into());
                        }
                    } else {
                        return Err("Expected 'spectral_budget'".into());
                    }
                }

                self.expect(Token::Semicolon)?;
                Ok(Stmt::Import(ImportStmt {
                    path,
                    alias,
                    spectral_budget,
                }))
            }
            Some(Token::Let) => {
                self.next();
                let name = match self.next() {
                    Some(Token::Ident(id)) => id,
                    other => return Err(format!("Expected identifier after let, got {:?}", other)),
                };
                self.expect(Token::Equal)?;
                let expr = self.parse_expression()?;
                self.expect(Token::Semicolon)?;
                Ok(Stmt::Let { name, expr })
            }
            Some(Token::LBrace) => {
                self.next(); // consume '{'
                let inner = self.parse_block()?;
                Ok(Stmt::Block(inner))
            }
            _ => {
                let expr = self.parse_expression()?;
                if let Some(Token::Semicolon) = self.peek() {
                    self.next();
                }
                Ok(Stmt::Expr(expr))
            }
        }
    }

    pub fn parse_program(&mut self) -> Result<Program, String> {
        let mut stmts = Vec::new();
        while self.peek().is_some() {
            stmts.push(self.parse_statement()?);
        }
        Ok(Program { stmts })
    }
}

pub fn parse(input: &str) -> Result<Program, String> {
    let mut parser = Parser::new(input);
    parser.parse_program()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_integer_expr() {
        let prog = parse("42").unwrap();
        assert_eq!(prog.stmts.len(), 1);
        match &prog.stmts[0] {
            Stmt::Expr(Expr::Literal(v)) => assert_eq!(*v, 42),
            _ => panic!("Expected literal expr"),
        }
    }

    #[test]
    fn parses_let_statement() {
        let prog = parse("let x = Ap(2); x + 3").unwrap();
        assert_eq!(prog.stmts.len(), 2);
        match &prog.stmts[0] {
            Stmt::Let { name, expr } => {
                assert_eq!(name, "x");
                assert!(matches!(expr, Expr::Atom { prime: 2 }));
            }
            _ => panic!("Expected let stmt"),
        }
    }
}
