pub const MAX_TERMS: usize = 32;

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum Term {
    Var(u8),
    Comp(u8, u8),
    Close(u8),
}

impl Term {
    pub fn is_var(&self) -> bool {
        matches!(self, Term::Var(_))
    }

    pub fn is_comp(&self) -> bool {
        matches!(self, Term::Comp(_, _))
    }

    pub fn is_close(&self) -> bool {
        matches!(self, Term::Close(_))
    }

    pub fn var_index(&self) -> Option<u8> {
        match self {
            Term::Var(i) => Some(*i),
            _ => None,
        }
    }

    pub fn comp_args(&self) -> Option<(u8, u8)> {
        match self {
            Term::Comp(a, b) => Some((*a, *b)),
            _ => None,
        }
    }

    pub fn close_arg(&self) -> Option<u8> {
        match self {
            Term::Close(a) => Some(*a),
            _ => None,
        }
    }

    pub fn size(&self) -> usize {
        match self {
            Term::Var(_) => 1,
            Term::Comp(a, b) => 1 + Term::Var(*a).size() + Term::Var(*b).size(),
            Term::Close(a) => 1 + Term::Var(*a).size(),
        }
    }

    pub fn depth(&self) -> usize {
        match self {
            Term::Var(_) => 0,
            Term::Comp(a, b) => 1 + Term::Var(*a).depth().max(Term::Var(*b).depth()),
            Term::Close(a) => 1 + Term::Var(*a).depth(),
        }
    }
}

impl std::fmt::Display for Term {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Term::Var(i) => write!(f, "v{}", i),
            Term::Comp(a, b) => write!(f, "({}, {})", a, b),
            Term::Close(a) => write!(f, "α({})", a),
        }
    }
}
