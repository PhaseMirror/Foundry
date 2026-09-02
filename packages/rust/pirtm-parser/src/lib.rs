// crates/pirtm-parser/src/lib.rs

pub mod ast;
pub use ast::{BinOp, EnsembleDecl, Expr, ImportStmt, LogicalOp, Program, Stmt, Type};

use pirtm_app_lexer::{tokenize, Token};

pub struct Parser {
    pub tokens: Vec<Token>,
    pub pos: usize,
}

impl Parser {
    pub fn new(input: &str) -> Self {
        let tokens = tokenize(input);
        Self { tokens, pos: 0 }
    }

    pub fn peek(&self) -> Option<Token> {
        self.tokens.get(self.pos).cloned()
    }

    pub fn peek_ahead(&self, n: usize) -> Option<Token> {
        self.tokens.get(self.pos + n).cloned()
    }

    pub fn next(&mut self) -> Option<Token> {
        let token = self.peek();
        self.pos += 1;
        token
    }

    pub fn expect(&mut self, expected: Token) -> Result<(), String> {
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
        self.parse_or()
    }

    fn parse_or(&mut self) -> Result<Expr, String> {
        let mut left = self.parse_and()?;
        while self.peek() == Some(Token::OrOr) {
            self.next();
            let right = self.parse_and()?;
            left = Expr::LogicalOp { op: LogicalOp::Or, left: Box::new(left), right: Box::new(right) };
        }
        Ok(left)
    }

    fn parse_and(&mut self) -> Result<Expr, String> {
        let mut left = self.parse_equality()?;
        while self.peek() == Some(Token::AndAnd) {
            self.next();
            let right = self.parse_equality()?;
            left = Expr::LogicalOp { op: LogicalOp::And, left: Box::new(left), right: Box::new(right) };
        }
        Ok(left)
    }

    fn parse_equality(&mut self) -> Result<Expr, String> {
        let mut left = self.parse_comparison()?;
        while let Some(tok) = self.peek() {
            match tok {
                Token::EqEq | Token::Neq => {
                    self.next();
                    let right = self.parse_comparison()?;
                    let op = if tok == Token::EqEq { BinOp::Eq } else { BinOp::Neq };
                    left = Expr::Binary { op, left: Box::new(left), right: Box::new(right) };
                }
                _ => break,
            }
        }
        Ok(left)
    }

    fn parse_comparison(&mut self) -> Result<Expr, String> {
        let mut left = self.parse_term()?;
        while let Some(tok) = self.peek() {
            match tok {
                Token::Lt | Token::Gt | Token::Le | Token::Ge => {
                    self.next();
                    let right = self.parse_term()?;
                    let op = match tok {
                        Token::Lt => BinOp::Lt,
                        Token::Gt => BinOp::Gt,
                        Token::Le => BinOp::Le,
                        Token::Ge => BinOp::Ge,
                        _ => unreachable!(),
                    };
                    left = Expr::Binary { op, left: Box::new(left), right: Box::new(right) };
                }
                _ => break,
            }
        }
        Ok(left)
    }

    fn parse_term(&mut self) -> Result<Expr, String> {
        let mut left = self.parse_factor()?;
        while let Some(tok) = self.peek() {
            match tok {
                Token::Plus | Token::Minus => {
                    self.next();
                    let right = self.parse_factor()?;
                    let op = if tok == Token::Plus { BinOp::Add } else { BinOp::Sub };
                    left = Expr::Binary { op, left: Box::new(left), right: Box::new(right) };
                }
                _ => break,
            }
        }
        Ok(left)
    }

    fn parse_factor(&mut self) -> Result<Expr, String> {
        let mut left = self.parse_unary()?;
        while let Some(tok) = self.peek() {
            match tok {
                Token::Star | Token::Slash => {
                    self.next();
                    let right = self.parse_unary()?;
                    let op = if tok == Token::Star { BinOp::Mul } else { BinOp::Div };
                    left = Expr::Binary { op, left: Box::new(left), right: Box::new(right) };
                }
                _ => break,
            }
        }
        Ok(left)
    }

    fn parse_unary(&mut self) -> Result<Expr, String> {
        if self.peek() == Some(Token::Bang) {
            self.next();
            let expr = self.parse_unary()?;
            return Ok(Expr::Not(Box::new(expr)));
        }
        if self.peek() == Some(Token::Minus) {
            self.next();
            let expr = self.parse_unary()?;
            return Ok(Expr::Binary {
                op: BinOp::Sub,
                left: Box::new(Expr::Literal(0)),
                right: Box::new(expr),
            });
        }
        if self.peek() == Some(Token::Amp) {
            self.next();
            if self.peek() == Some(Token::Mut) {
                self.next();
            }
            let expr = self.parse_unary()?;
            return Ok(expr);
        }
        self.parse_primary()
    }

    fn parse_primary(&mut self) -> Result<Expr, String> {
        let mut base = match self.peek() {
            Some(Token::Match) => {
                self.next();
                let expr = self.parse_expression()?;
                self.expect(Token::LBrace)?;
                let mut arms = Vec::new();
                while let Some(tok) = self.peek() {
                    if tok == Token::RBrace { break; }
                    let pat = self.parse_match_pattern()?;
                    if self.peek() == Some(Token::FatArrow) {
                        self.next();
                    } else if self.peek() == Some(Token::Equal) {
                        self.next();
                        if self.peek() == Some(Token::Gt) { self.next(); }
                    } else {
                        return Err(format!("Expected '=>' in match arm, got {:?}", self.peek()));
                    }
                    let body = if self.peek() == Some(Token::LBrace) {
                        self.next(); // consume '{'
                        let blk = self.parse_block()?;
                        if self.peek() == Some(Token::Comma) { self.next(); }
                        blk
                    } else {
                        let e = self.parse_expression()?;
                        if self.peek() == Some(Token::Comma) || self.peek() == Some(Token::Semicolon) {
                            self.next();
                        }
                        vec![Stmt::Expr(e)]
                    };
                    arms.push((pat, body));
                }
                self.expect(Token::RBrace)?;
                return Ok(Expr::Match { expr: Box::new(expr), arms });
            }
            Some(Token::Ident(first)) => {
                self.next();
                let mut full_path = first;
                while self.peek() == Some(Token::ColonColon) {
                    self.next();
                    if let Some(Token::Ident(sub)) = self.next() {
                        full_path.push_str("::");
                        full_path.push_str(&sub);
                    } else {
                        return Err("Expected identifier after '::'".to_string());
                    }
                }

                if full_path == "Ap" && self.peek() == Some(Token::LPar) {
                    self.next();
                    let num = self.parse_integer()?;
                    self.expect(Token::RPar)?;
                    Expr::Atom { prime: num }
                } else if self.peek() == Some(Token::LPar) {
                    self.next();
                    let mut args = Vec::new();
                    if self.peek() != Some(Token::RPar) {
                        loop {
                            args.push(self.parse_expression()?);
                            if self.peek() == Some(Token::Comma) {
                                self.next();
                            } else {
                                break;
                            }
                        }
                    }
                    self.expect(Token::RPar)?;
                    Expr::Call { name: full_path, args }
                } else if self.peek() == Some(Token::LBrace) && full_path.chars().next().map_or(false, |c| c.is_uppercase()) {
                    self.next();
                    let mut fields = Vec::new();
                    while let Some(tok) = self.peek() {
                        if tok == Token::RBrace { break; }
                        let field_name = match self.next() {
                            Some(Token::Ident(p)) => p,
                            other => return Err(format!("Expected field name in struct init, got {:?}", other)),
                        };
                        let _ = self.expect(Token::Colon);
                        let val = self.parse_expression()?;
                        fields.push((field_name, Box::new(val)));
                        if self.peek() == Some(Token::Comma) {
                            self.next();
                        }
                    }
                    self.expect(Token::RBrace)?;
                    Expr::StructInit { name: full_path, fields }
                } else {
                    Expr::Ident(full_path)
                }
            }
            Some(Token::Integer(val)) => {
                self.next();
                Expr::Literal(val)
            }
            Some(Token::Float(val)) => {
                self.next();
                Expr::FloatLit(val)
            }
            Some(Token::CharLit(val)) => {
                self.next();
                Expr::CharLit(val)
            }
            Some(Token::StringLit(val)) => {
                self.next();
                Expr::StringLit(val)
            }
            Some(Token::LPar) => {
                self.next();
                if self.peek() == Some(Token::RPar) {
                    self.next();
                    Expr::Tuple(Vec::new())
                } else {
                    let first = self.parse_expression()?;
                    if self.peek() == Some(Token::Comma) {
                        let mut elems = vec![first];
                        while self.peek() == Some(Token::Comma) {
                            self.next();
                            if self.peek() == Some(Token::RPar) { break; }
                            elems.push(self.parse_expression()?);
                        }
                        self.expect(Token::RPar)?;
                        Expr::Tuple(elems)
                    } else {
                        self.expect(Token::RPar)?;
                        first
                    }
                }
            }
            Some(Token::If) => {
                self.next();
                let has_par = self.peek() == Some(Token::LPar);
                if has_par { self.next(); }
                let cond = self.parse_expression()?;
                if has_par { self.expect(Token::RPar)?; }
                self.expect(Token::LBrace)?;
                let then_branch = self.parse_block()?;
                let else_branch = if self.peek() == Some(Token::Else) {
                    self.next();
                    if self.peek() == Some(Token::LBrace) {
                        self.expect(Token::LBrace)?;
                        Some(self.parse_block()?)
                    } else if self.peek() == Some(Token::If) {
                        let inner_if = self.parse_statement()?;
                        Some(vec![inner_if])
                    } else {
                        None
                    }
                } else {
                    None
                };
                return Ok(Expr::If { cond: Box::new(cond), then_branch, else_branch });
            }
            other => return Err(format!("Unexpected token in expression at pos {}: {:?}", self.pos, other)),
        };

        // Postfix operations: .method(), .field, and ?
        loop {
            if self.peek() == Some(Token::Dot) {
                self.next();
                let field = match self.next() {
                    Some(Token::Ident(f)) => f,
                    other => return Err(format!("Expected field or method name after '.', got {:?}", other)),
                };
                if self.peek() == Some(Token::LPar) {
                    self.next();
                    let mut args = Vec::new();
                    if self.peek() != Some(Token::RPar) {
                        loop {
                            args.push(self.parse_expression()?);
                            if self.peek() == Some(Token::Comma) {
                                self.next();
                            } else {
                                break;
                            }
                        }
                    }
                    self.expect(Token::RPar)?;
                    base = Expr::MethodCall { obj: Box::new(base), method: field, args };
                } else {
                    base = Expr::FieldAccess { obj: Box::new(base), field };
                }
            } else if self.peek() == Some(Token::Question) {
                self.next();
                base = Expr::Try(Box::new(base));
            } else {
                break;
            }
        }

        Ok(base)
    }

    fn parse_match_pattern(&mut self) -> Result<String, String> {
        let mut pat = String::new();
        let mut depth = 0;
        while let Some(tok) = self.peek() {
            if (tok == Token::FatArrow || tok == Token::Equal) && depth == 0 {
                break;
            }
            if tok == Token::LPar || tok == Token::LBrace || tok == Token::LBracket {
                depth += 1;
            } else if tok == Token::RPar || tok == Token::RBrace || tok == Token::RBracket {
                if depth > 0 { depth -= 1; }
            }
            let tok_str = match self.next().unwrap() {
                Token::Ident(s) => s,
                Token::Integer(n) => n.to_string(),
                Token::Float(f) => f.to_string(),
                Token::CharLit(c) => format!("'{}'", c),
                Token::StringLit(s) => format!("\"{}\"", s),
                Token::ColonColon => "::".to_string(),
                Token::LPar => "(".to_string(),
                Token::RPar => ")".to_string(),
                Token::Comma => ", ".to_string(),
                Token::Minus => "-".to_string(),
                Token::If => " if ".to_string(),
                Token::EqEq => " == ".to_string(),
                Token::OrOr => " || ".to_string(),
                Token::AndAnd => " && ".to_string(),
                _ => " ".to_string(),
            };
            pat.push_str(&tok_str);
        }
        Ok(pat.trim().to_string())
    }

    fn parse_integer(&mut self) -> Result<u64, String> {
        match self.next() {
            Some(Token::Integer(val)) => Ok(val),
            other => Err(format!("Expected integer literal, got {:?}", other)),
        }
    }

    pub fn parse_block(&mut self) -> Result<Vec<Stmt>, String> {
        let mut stmts = Vec::new();
        while let Some(tok) = self.peek() {
            if tok == Token::RBrace {
                self.next();
                return Ok(stmts);
            }
            stmts.push(self.parse_statement()?);
        }
        Err("Unclosed block, expected '}'".to_string())
    }

    pub fn parse_statement(&mut self) -> Result<Stmt, String> {
        match self.peek() {
            Some(Token::Ensemble) => {
                self.next();
                let name = match self.next() {
                    Some(Token::Ident(id)) => id,
                    other => return Err(format!("Expected identifier after ensemble, got {:?}", other)),
                };
                let version = match self.next() {
                    Some(Token::Ident(id)) if id.starts_with('v') => id[1..].to_string(),
                    Some(Token::StringLit(s)) => s,
                    other => return Err(format!("Expected version after ensemble name, got {:?}", other)),
                };
                let mut prime = 0;
                while let Some(tok) = self.peek() {
                    if tok == Token::Semicolon { self.next(); break; }
                    if let Token::Ident(key) = tok {
                        self.next();
                        if key == "prime" {
                            self.expect(Token::Equal)?;
                            prime = self.parse_integer()?;
                        }
                    } else {
                        self.next();
                    }
                }
                Ok(Stmt::Ensemble(EnsembleDecl { name, version, prime }))
            }
            Some(Token::Use) => {
                self.next();
                let mut path = match self.next() {
                    Some(Token::Ident(id)) => id,
                    other => return Err(format!("Expected path after use, got {:?}", other)),
                };
                while self.peek() == Some(Token::ColonColon) {
                    self.next();
                    if let Some(Token::Ident(sub)) = self.next() {
                        path.push_str("::");
                        path.push_str(&sub);
                    }
                }
                let mut alias = None;
                let mut spectral_budget = None;
                if self.peek() == Some(Token::As) {
                    self.next();
                    if let Some(Token::Ident(id)) = self.next() {
                        alias = Some(id);
                    }
                }
                if self.peek() == Some(Token::With) {
                    self.next();
                    while let Some(tok) = self.peek() {
                        if tok == Token::Semicolon { break; }
                        if let Token::Ident(key) = tok {
                            self.next();
                            if key == "spectral_budget" {
                                self.expect(Token::Equal)?;
                                if let Some(Token::Float(f)) = self.next() {
                                    spectral_budget = Some(f);
                                }
                            }
                        } else {
                            self.next();
                        }
                    }
                }
                if self.peek() == Some(Token::Semicolon) { self.next(); }
                Ok(Stmt::Import(ImportStmt { path, alias, spectral_budget }))
            }
            Some(Token::Let) => {
                self.next();
                let is_mut = if self.peek() == Some(Token::Mut) {
                    self.next();
                    true
                } else {
                    false
                };
                let name = match self.next() {
                    Some(Token::Ident(id)) => id,
                    other => return Err(format!("Expected identifier after let, got {:?}", other)),
                };
                self.expect(Token::Equal)?;
                let expr = self.parse_expression()?;
                if self.peek() == Some(Token::Semicolon) { self.next(); }
                if is_mut {
                    Ok(Stmt::LetMut { name, expr })
                } else {
                    Ok(Stmt::Let { name, expr })
                }
            }
            Some(Token::Return) => {
                self.next();
                let expr = if self.peek() == Some(Token::Semicolon) {
                    None
                } else {
                    Some(self.parse_expression()?)
                };
                if self.peek() == Some(Token::Semicolon) { self.next(); }
                Ok(Stmt::Return(expr))
            }
            Some(Token::Break) => {
                self.next();
                if self.peek() == Some(Token::Semicolon) { self.next(); }
                Ok(Stmt::Break)
            }
            Some(Token::Continue) => {
                self.next();
                if self.peek() == Some(Token::Semicolon) { self.next(); }
                Ok(Stmt::Continue)
            }
            Some(Token::Match) => {
                let expr = self.parse_expression()?;
                if self.peek() == Some(Token::Semicolon) { self.next(); }
                Ok(Stmt::Expr(expr))
            }
            Some(Token::If) => {
                self.next();
                let has_par = self.peek() == Some(Token::LPar);
                if has_par { self.next(); }
                let cond = self.parse_expression()?;
                if has_par { self.expect(Token::RPar)?; }
                self.expect(Token::LBrace)?;
                let then_branch = self.parse_block()?;
                let else_branch = if self.peek() == Some(Token::Else) {
                    self.next();
                    if self.peek() == Some(Token::LBrace) {
                        self.expect(Token::LBrace)?;
                        Some(self.parse_block()?)
                    } else if self.peek() == Some(Token::If) {
                        let inner_if = self.parse_statement()?;
                        Some(vec![inner_if])
                    } else {
                        None
                    }
                } else {
                    None
                };
                Ok(Stmt::If { cond, then_branch, else_branch })
            }
            Some(Token::While) => {
                self.next();
                let cond = if self.peek() == Some(Token::Let) {
                    self.next();
                    let pat = self.parse_match_pattern()?;
                    self.expect(Token::Equal)?;
                    let rhs = self.parse_expression()?;
                    Expr::Binary {
                        op: BinOp::Eq,
                        left: Box::new(Expr::Ident(pat)),
                        right: Box::new(rhs),
                    }
                } else {
                    let has_par = self.peek() == Some(Token::LPar);
                    if has_par { self.next(); }
                    let c = self.parse_expression()?;
                    if has_par { self.expect(Token::RPar)?; }
                    c
                };
                self.expect(Token::LBrace)?;
                let body = self.parse_block()?;
                Ok(Stmt::Loop { cond: Some(cond), body })
            }
            Some(Token::Loop) => {
                self.next();
                self.expect(Token::LBrace)?;
                let body = self.parse_block()?;
                Ok(Stmt::Loop { cond: None, body })
            }
            Some(Token::Fn) => {
                self.next();
                let name = match self.next() {
                    Some(Token::Ident(id)) => id,
                    other => return Err(format!("Expected function name, got {:?}", other)),
                };
                let generics = self.parse_generics_decl()?;
                self.expect(Token::LPar)?;
                let mut params = Vec::new();
                while let Some(tok) = self.peek() {
                    if tok == Token::RPar { break; }
                    if self.peek() == Some(Token::Amp) {
                        self.next();
                        let is_mut = if self.peek() == Some(Token::Mut) {
                            self.next();
                            true
                        } else {
                            false
                        };
                        if self.peek() == Some(Token::Ident("self".to_string())) {
                            self.next();
                            params.push(("self".to_string(), Type::Reference {
                                is_mut,
                                inner: Box::new(Type::Simple("Self".to_string())),
                            }));
                            if self.peek() == Some(Token::Comma) { self.next(); }
                            continue;
                        }
                        let pname = match self.next() {
                            Some(Token::Ident(id)) => id,
                            other => return Err(format!("Expected parameter name, got {:?}", other)),
                        };
                        self.expect(Token::Colon)?;
                        let ty = self.parse_type()?;
                        params.push((pname, Type::Reference { is_mut, inner: Box::new(ty) }));
                        if self.peek() == Some(Token::Comma) { self.next(); }
                        continue;
                    } else if self.peek() == Some(Token::Ident("self".to_string())) {
                        self.next();
                        params.push(("self".to_string(), Type::Simple("Self".to_string())));
                        if self.peek() == Some(Token::Comma) { self.next(); }
                        continue;
                    } else {
                        let pname = match self.next() {
                            Some(Token::Ident(id)) => id,
                            other => return Err(format!("Expected parameter name, got {:?}", other)),
                        };
                        self.expect(Token::Colon)?;
                        let ty = self.parse_type()?;
                        params.push((pname, ty));
                        if self.peek() == Some(Token::Comma) { self.next(); }
                        continue;
                    }
                }
                self.expect(Token::RPar)?;
                let return_type = if self.peek() == Some(Token::Arrow) {
                    self.next();
                    Some(self.parse_type()?)
                } else if self.peek() == Some(Token::Minus) {
                    self.next();
                    self.expect(Token::Gt)?;
                    Some(self.parse_type()?)
                } else {
                    None
                };
                self.expect(Token::LBrace)?;
                let body = self.parse_block()?;
                Ok(Stmt::FnDef { name, generics, params, return_type, body })
            }
            Some(Token::Struct) => {
                self.next();
                let name = match self.next() {
                    Some(Token::Ident(id)) => id,
                    other => return Err(format!("Expected struct name, got {:?}", other)),
                };
                let generics = self.parse_generics_decl()?;
                self.expect(Token::LBrace)?;
                let mut fields = Vec::new();
                while let Some(tok) = self.peek() {
                    if tok == Token::RBrace { break; }
                    let field_name = match self.next() {
                        Some(Token::Ident(id)) => id,
                        other => return Err(format!("Expected field name, got {:?}", other)),
                    };
                    self.expect(Token::Colon)?;
                    let field_type = self.parse_type()?;
                    fields.push((field_name, field_type));
                    if self.peek() == Some(Token::Comma) { self.next(); }
                }
                self.expect(Token::RBrace)?;
                Ok(Stmt::StructDef { name, generics, fields })
            }
            Some(Token::Enum) => {
                self.next();
                let name = match self.next() {
                    Some(Token::Ident(id)) => id,
                    other => return Err(format!("Expected enum name, got {:?}", other)),
                };
                let generics = self.parse_generics_decl()?;
                self.expect(Token::LBrace)?;
                let mut variants = Vec::new();
                while let Some(tok) = self.peek() {
                    if tok == Token::RBrace { break; }
                    let var_name = match self.next() {
                        Some(Token::Ident(id)) => id,
                        other => return Err(format!("Expected variant name, got {:?}", other)),
                    };
                    let var_type = if self.peek() == Some(Token::LPar) {
                        self.next();
                        let ty = self.parse_type()?;
                        self.expect(Token::RPar)?;
                        Some(ty)
                    } else {
                        None
                    };
                    variants.push((var_name, var_type));
                    if self.peek() == Some(Token::Comma) { self.next(); }
                }
                self.expect(Token::RBrace)?;
                Ok(Stmt::EnumDef { name, generics, variants })
            }
            Some(Token::Impl) => {
                self.next();
                let target = match self.next() {
                    Some(Token::Ident(id)) => id,
                    other => return Err(format!("Expected type name after impl, got {:?}", other)),
                };
                let generics = self.parse_generics_decl()?;
                self.expect(Token::LBrace)?;
                let mut methods = Vec::new();
                while let Some(tok) = self.peek() {
                    if tok == Token::RBrace { break; }
                    methods.push(self.parse_statement()?);
                }
                self.expect(Token::RBrace)?;
                Ok(Stmt::ImplDef { target, generics, methods })
            }
            Some(Token::Extern) => {
                self.next();
                let abi = match self.next() {
                    Some(Token::StringLit(s)) => s,
                    other => return Err(format!("Expected ABI string literal after extern, got {:?}", other)),
                };
                self.expect(Token::Fn)?;
                let name = match self.next() {
                    Some(Token::Ident(id)) => id,
                    other => return Err(format!("Expected function name, got {:?}", other)),
                };
                self.expect(Token::LPar)?;
                let mut params = Vec::new();
                while let Some(tok) = self.peek() {
                    if tok == Token::RPar { break; }
                    let param_name = match self.next() {
                        Some(Token::Ident(id)) => id,
                        other => return Err(format!("Expected parameter name, got {:?}", other)),
                    };
                    self.expect(Token::Colon)?;
                    let param_type = self.parse_type()?;
                    params.push((param_name, param_type));
                    if self.peek() == Some(Token::Comma) { self.next(); }
                }
                self.expect(Token::RPar)?;
                let return_type = if self.peek() == Some(Token::Arrow) {
                    self.next();
                    Some(self.parse_type()?)
                } else if self.peek() == Some(Token::Minus) {
                    self.next();
                    self.expect(Token::Gt)?;
                    Some(self.parse_type()?)
                } else {
                    None
                };
                if self.peek() == Some(Token::Semicolon) { self.next(); }
                Ok(Stmt::ExternFn { name, params, return_type, abi })
            }
            Some(Token::LBrace) => {
                self.next();
                let inner = self.parse_block()?;
                Ok(Stmt::Block(inner))
            }
            Some(Token::Ident(_)) => {
                let mut look = 1;
                while self.peek_ahead(look) == Some(Token::Dot) {
                    look += 2;
                }
                if self.peek_ahead(look) == Some(Token::Equal) {
                    let lhs = self.parse_expression()?;
                    self.expect(Token::Equal)?;
                    let expr = self.parse_expression()?;
                    if self.peek() == Some(Token::Semicolon) { self.next(); }
                    match lhs {
                        Expr::Ident(n) => Ok(Stmt::Assign { name: n, expr }),
                        Expr::FieldAccess { obj, field } => {
                            Ok(Stmt::Assign { name: format!("{}.{}", obj, field), expr })
                        }
                        _ => Err(format!("Invalid assignment target: {:?}", lhs)),
                    }
                } else {
                    let expr = self.parse_expression()?;
                    if self.peek() == Some(Token::Semicolon) { self.next(); }
                    Ok(Stmt::Expr(expr))
                }
            }
            _ => {
                let expr = self.parse_expression()?;
                if self.peek() == Some(Token::Semicolon) { self.next(); }
                Ok(Stmt::Expr(expr))
            }
        }
    }

    pub fn parse_generics_decl(&mut self) -> Result<Vec<String>, String> {
        if self.peek() == Some(Token::Lt) {
            self.next();
            let mut params = Vec::new();
            while let Some(tok) = self.peek() {
                if tok == Token::Gt { break; }
                if let Token::Ident(param_name) = self.next().unwrap() {
                    params.push(param_name);
                    if self.peek() == Some(Token::Comma) { self.next(); }
                } else {
                    return Err("Expected generic parameter name".to_string());
                }
            }
            self.expect(Token::Gt)?;
            Ok(params)
        } else {
            Ok(Vec::new())
        }
    }

    pub fn parse_type(&mut self) -> Result<Type, String> {
        if self.peek() == Some(Token::Star) {
            self.next();
            let is_mut = if self.peek() == Some(Token::Mut) {
                self.next();
                true
            } else if matches!(self.peek(), Some(Token::Ident(ref s)) if s == "const") {
                self.next();
                false
            } else {
                false
            };
            let inner = self.parse_type()?;
            return Ok(Type::Reference { is_mut, inner: Box::new(inner) });
        }

        if self.peek() == Some(Token::Amp) {
            self.next();
            let is_mut = if self.peek() == Some(Token::Mut) {
                self.next();
                true
            } else {
                false
            };
            let inner = self.parse_type()?;
            return Ok(Type::Reference { is_mut, inner: Box::new(inner) });
        }

        if self.peek() == Some(Token::LPar) {
            self.next();
            let mut elems = Vec::new();
            while let Some(tok) = self.peek() {
                if tok == Token::RPar { break; }
                elems.push(self.parse_type()?);
                if self.peek() == Some(Token::Comma) {
                    self.next();
                } else {
                    break;
                }
            }
            self.expect(Token::RPar)?;
            return Ok(Type::Tuple(elems));
        }

        if self.peek() == Some(Token::Fn) {
            self.next();
            self.expect(Token::LPar)?;
            let mut args = Vec::new();
            while let Some(tok) = self.peek() {
                if tok == Token::RPar { break; }
                args.push(self.parse_type()?);
                if self.peek() == Some(Token::Comma) { self.next(); }
            }
            self.expect(Token::RPar)?;
            let ret = if self.peek() == Some(Token::Arrow) {
                self.next();
                Box::new(self.parse_type()?)
            } else if self.peek() == Some(Token::Minus) {
                self.next();
                self.expect(Token::Gt)?;
                Box::new(self.parse_type()?)
            } else {
                Box::new(Type::Simple("unit".to_string()))
            };
            return Ok(Type::Function(args, ret));
        }

        let name = match self.next() {
            Some(Token::Ident(id)) => id,
            other => return Err(format!("Expected type name, got {:?}", other)),
        };

        if self.peek() == Some(Token::Lt) {
            self.next();
            let mut params = Vec::new();
            while let Some(tok) = self.peek() {
                if tok == Token::Gt { break; }
                params.push(self.parse_type()?);
                if self.peek() == Some(Token::Comma) { self.next(); }
            }
            self.expect(Token::Gt)?;
            Ok(Type::Generic(name, params))
        } else {
            Ok(Type::Simple(name))
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

// ---------------------------------------------------------------------------
// PIRTM EBNF Decoder Parser (Mirroring pirtm/csc.py)
// ---------------------------------------------------------------------------

pub use ast::Statement;

#[derive(Debug, Clone, PartialEq)]
enum EBNFToken {
    Keyword(String),
    Lambda,
    Ident(String),
    Prime(String),
    Float(f64),
    Op(String),
}

pub struct PIRTMDecoderParser {
    tokens: Vec<EBNFToken>,
    pos: usize,
}

impl PIRTMDecoderParser {
    pub fn new(source: &str) -> Result<Self, String> {
        let tokens = Self::tokenize(source)?;
        Ok(Self { tokens, pos: 0 })
    }

    fn tokenize(source: &str) -> Result<Vec<EBNFToken>, String> {
        let mut tokens = Vec::new();
        let chars: Vec<char> = source.chars().collect();
        let mut i = 0;
        let n = chars.len();

        while i < n {
            let c = chars[i];
            if c.is_whitespace() {
                i += 1;
                continue;
            }
            if c == '#' {
                while i < n && chars[i] != '\n' {
                    i += 1;
                }
                continue;
            }
            if c == '\\' && i + 8 < n && &chars[i..i + 9] == &['\\', 'L', 'a', 'm', 'b', 'd', 'a', '_', 'm'] {
                tokens.push(EBNFToken::Lambda);
                i += 9;
                continue;
            }
            if c == 'Λ' && i + 2 < n && &chars[i..i + 3] == &['Λ', '_', 'm'] {
                tokens.push(EBNFToken::Lambda);
                i += 3;
                continue;
            }
            if c == '|' && i + 1 < n && chars[i + 1] == '>' {
                tokens.push(EBNFToken::Op("|>".to_string()));
                i += 2;
                continue;
            }
            if c == '[' || c == ']' || c == '(' || c == ')' || c == ',' || c == ';' || c == '*' || c == '<' || c == '>' {
                tokens.push(EBNFToken::Op(c.to_string()));
                i += 1;
                continue;
            }
            if c.is_ascii_digit() {
                let start = i;
                while i < n && (chars[i].is_ascii_digit() || chars[i] == '.') {
                    i += 1;
                }
                let s: String = chars[start..i].iter().collect();
                if let Ok(f) = s.parse::<f64>() {
                    tokens.push(EBNFToken::Float(f));
                } else {
                    return Err(format!("Invalid numeric literal: {}", s));
                }
                continue;
            }
            if c.is_ascii_alphabetic() || c == '_' {
                let start = i;
                while i < n && (chars[i].is_ascii_alphanumeric() || chars[i] == '_') {
                    i += 1;
                }
                let s: String = chars[start..i].iter().collect();
                if s == "tensor" || s == "assert_contractive" {
                    tokens.push(EBNFToken::Keyword(s));
                } else if s.starts_with("p_") && s[2..].chars().all(|ch| ch.is_ascii_digit()) {
                    tokens.push(EBNFToken::Prime(s));
                } else {
                    tokens.push(EBNFToken::Ident(s));
                }
                continue;
            }
            return Err(format!("Unexpected character: {}", c));
        }
        Ok(tokens)
    }

    fn peek(&self) -> Option<&EBNFToken> {
        self.tokens.get(self.pos)
    }

    fn next_token(&mut self) -> Option<EBNFToken> {
        if self.pos < self.tokens.len() {
            let tok = self.tokens[self.pos].clone();
            self.pos += 1;
            Some(tok)
        } else {
            None
        }
    }

    pub fn parse_source(&mut self) -> Result<Vec<Statement>, String> {
        let mut stmts = Vec::new();
        while self.peek().is_some() {
            stmts.push(self.parse_statement()?);
        }
        Ok(stmts)
    }

    fn parse_statement(&mut self) -> Result<Statement, String> {
        match self.peek() {
            Some(EBNFToken::Keyword(k)) if k == "tensor" => self.parse_tensor_declaration(),
            Some(EBNFToken::Keyword(k)) if k == "assert_contractive" => self.parse_contractivity_assertion(),
            Some(EBNFToken::Ident(_)) => self.parse_operator_application(),
            Some(other) => Err(format!("Unexpected token starting statement: {:?}", other)),
            None => Err("Unexpected EOF".to_string()),
        }
    }

    fn parse_tensor_declaration(&mut self) -> Result<Statement, String> {
        self.next_token();
        let ident = match self.next_token() {
            Some(EBNFToken::Ident(id)) => id,
            other => return Err(format!("Expected identifier after tensor, got {:?}", other)),
        };
        match self.next_token() {
            Some(EBNFToken::Op(ref op)) if op == "[" => {}
            other => return Err(format!("Expected '[' after tensor identifier, got {:?}", other)),
        }
        let mut primes = Vec::new();
        loop {
            match self.next_token() {
                Some(EBNFToken::Prime(p)) => primes.push(p),
                other => return Err(format!("Expected prime token p_N, got {:?}", other)),
            }
            match self.peek() {
                Some(EBNFToken::Op(ref op)) if op == "," => {
                    self.next_token();
                }
                _ => break,
            }
        }
        match self.next_token() {
            Some(EBNFToken::Op(ref op)) if op == "]" => {}
            other => return Err(format!("Expected ']' closing tensor primes, got {:?}", other)),
        }
        match self.next_token() {
            Some(EBNFToken::Op(ref op)) if op == ";" => {}
            other => return Err(format!("Expected ';' ending tensor declaration, got {:?}", other)),
        }
        Ok(Statement::TensorDeclaration { identifier: ident, primes })
    }

    fn parse_operator_application(&mut self) -> Result<Statement, String> {
        let ident = match self.next_token() {
            Some(EBNFToken::Ident(id)) => id,
            other => return Err(format!("Expected identifier, got {:?}", other)),
        };
        match self.next_token() {
            Some(EBNFToken::Op(ref op)) if op == "|>" => {}
            other => return Err(format!("Expected '|>' after identifier, got {:?}", other)),
        }
        let has_lambda = if let Some(EBNFToken::Lambda) = self.peek() {
            self.next_token();
            match self.next_token() {
                Some(EBNFToken::Op(ref op)) if op == "*" => {}
                other => return Err(format!("Expected '*' after \\Lambda_m, got {:?}", other)),
            }
            true
        } else {
            false
        };
        let mut prime_chain = Vec::new();
        loop {
            match self.next_token() {
                Some(EBNFToken::Prime(p)) => prime_chain.push(p),
                other => return Err(format!("Expected prime token in chain, got {:?}", other)),
            }
            match self.peek() {
                Some(EBNFToken::Op(ref op)) if op == "*" => {
                    self.next_token();
                }
                _ => break,
            }
        }
        match self.next_token() {
            Some(EBNFToken::Op(ref op)) if op == ";" => {}
            other => return Err(format!("Expected ';' ending operator application, got {:?}", other)),
        }
        Ok(Statement::OperatorApplication { identifier: ident, has_lambda, prime_chain })
    }

    fn parse_contractivity_assertion(&mut self) -> Result<Statement, String> {
        self.next_token();
        match self.next_token() {
            Some(EBNFToken::Op(ref op)) if op == "(" => {}
            other => return Err(format!("Expected '(' after assert_contractive, got {:?}", other)),
        }
        let ident = match self.next_token() {
            Some(EBNFToken::Ident(id)) => id,
            other => return Err(format!("Expected identifier inside assert_contractive, got {:?}", other)),
        };
        match self.next_token() {
            Some(EBNFToken::Op(ref op)) if op == ")" => {}
            other => return Err(format!("Expected ')' closing assert_contractive, got {:?}", other)),
        }
        match self.next_token() {
            Some(EBNFToken::Op(ref op)) if op == "<" => {}
            other => return Err(format!("Expected '<' after assert_contractive(...), got {:?}", other)),
        }
        let bound = match self.next_token() {
            Some(EBNFToken::Float(f)) => f,
            other => return Err(format!("Expected float bound, got {:?}", other)),
        };
        match self.next_token() {
            Some(EBNFToken::Op(ref op)) if op == ";" => {}
            other => return Err(format!("Expected ';' ending contractivity assertion, got {:?}", other)),
        }
        Ok(Statement::ContractivityAssertion { identifier: ident, bound })
    }
}

pub fn parse_ebnf_statements(input: &str) -> Result<Vec<Statement>, String> {
    let mut parser = PIRTMDecoderParser::new(input)?;
    parser.parse_source()
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

    #[test]
    fn test_ebnf_tensor_declaration() {
        let stmts = parse_ebnf_statements("tensor T_0 [p_2, p_3, p_5];").unwrap();
        assert_eq!(stmts.len(), 1);
        assert_eq!(
            stmts[0],
            Statement::TensorDeclaration {
                identifier: "T_0".to_string(),
                primes: vec!["p_2".to_string(), "p_3".to_string(), "p_5".to_string()],
            }
        );
    }

    #[test]
    fn test_ebnf_operator_application() {
        let stmts = parse_ebnf_statements("T_1 |> \\Lambda_m * p_11 * p_13;").unwrap();
        assert_eq!(stmts.len(), 1);
        assert_eq!(
            stmts[0],
            Statement::OperatorApplication {
                identifier: "T_1".to_string(),
                has_lambda: true,
                prime_chain: vec!["p_11".to_string(), "p_13".to_string()],
            }
        );
    }

    #[test]
    fn test_ebnf_contractivity_assertion() {
        let stmts = parse_ebnf_statements("assert_contractive(T_0) < 0.85;").unwrap();
        assert_eq!(stmts.len(), 1);
        assert_eq!(
            stmts[0],
            Statement::ContractivityAssertion {
                identifier: "T_0".to_string(),
                bound: 0.85,
            }
        );
    }

    #[test]
    fn test_parse_if() {
        let source = "if (x) { let y = 1; } else { let y = 2; }";
        let program = parse(source).unwrap();
        assert_eq!(program.stmts.len(), 1);
        assert!(matches!(program.stmts[0], Stmt::If { .. }));
    }

    #[test]
    fn test_parse_while() {
        let source = "while (x) { let y = 1; }";
        let program = parse(source).unwrap();
        assert_eq!(program.stmts.len(), 1);
        assert!(matches!(program.stmts[0], Stmt::Loop { cond: Some(_), .. }));
    }

    #[test]
    fn test_parse_loop() {
        let source = "loop { let y = 1; }";
        let program = parse(source).unwrap();
        assert_eq!(program.stmts.len(), 1);
        assert!(matches!(program.stmts[0], Stmt::Loop { cond: None, .. }));
    }

    #[test]
    fn test_parse_fn() {
        let source = "fn add(a: int, b: int) { let c = a; }";
        let mut parser = Parser::new(source);
        let program = parser.parse_program().unwrap();
        assert_eq!(program.stmts.len(), 1);
        if let Stmt::FnDef { name, params, generics, .. } = &program.stmts[0] {
            assert_eq!(name, "add");
            assert!(generics.is_empty());
            assert_eq!(params.len(), 2);
        } else {
            panic!("Expected FnDef");
        }
    }

    #[test]
    fn test_parse_struct_def() {
        let source = "struct Point { x: int, y: int }";
        let mut parser = Parser::new(source);
        let program = parser.parse_program().unwrap();
        match &program.stmts[0] {
            Stmt::StructDef { name, fields, .. } => {
                assert_eq!(name, "Point");
                assert_eq!(fields.len(), 2);
                assert_eq!(fields[0], ("x".to_string(), Type::Simple("int".to_string())));
                assert_eq!(fields[1], ("y".to_string(), Type::Simple("int".to_string())));
            }
            _ => panic!("Expected StructDef"),
        }
    }

    #[test]
    fn test_parse_struct_empty() {
        let source = "struct Empty {}";
        let mut parser = Parser::new(source);
        let program = parser.parse_program().unwrap();
        match &program.stmts[0] {
            Stmt::StructDef { name, fields, .. } => {
                assert_eq!(name, "Empty");
                assert!(fields.is_empty());
            }
            _ => panic!("Expected StructDef"),
        }
    }

    #[test]
    fn test_parse_enum_def() {
        let source = "enum Option { None, Some(int) }";
        let mut parser = Parser::new(source);
        let program = parser.parse_program().unwrap();
        match &program.stmts[0] {
            Stmt::EnumDef { name, variants, .. } => {
                assert_eq!(name, "Option");
                assert_eq!(variants.len(), 2);
                assert_eq!(variants[0], ("None".to_string(), None));
                assert_eq!(variants[1], ("Some".to_string(), Some(Type::Simple("int".to_string()))));
            }
            _ => panic!("Expected EnumDef"),
        }
    }

    #[test]
    fn test_parse_enum_empty() {
        let source = "enum Empty {}";
        let mut parser = Parser::new(source);
        let program = parser.parse_program().unwrap();
        match &program.stmts[0] {
            Stmt::EnumDef { name, variants, .. } => {
                assert_eq!(name, "Empty");
                assert!(variants.is_empty());
            }
            _ => panic!("Expected EnumDef"),
        }
    }

    #[test]
    fn test_parse_impl_block() {
        let source = "struct Parser { input: str } impl Parser { fn peek(&self) -> str { self.input } }";
        let mut parser = Parser::new(source);
        let program = parser.parse_program().unwrap();
        assert_eq!(program.stmts.len(), 2);
        assert!(matches!(program.stmts[1], Stmt::ImplDef { .. }));
    }
}
