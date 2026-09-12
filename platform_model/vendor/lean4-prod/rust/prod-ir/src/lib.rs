//! prod-ir: Intermediate Representation for Lean 4 → Rust extraction
//!
//! Defines the AST types and a `nom` parser for a compact sexp-like IR format
//! that Lean 4 exports. This crate is `#![no_std]` (with `alloc`) so it can
//! run on wasm32 and embedded targets.

#![no_std]

extern crate alloc;

pub mod parser;

use alloc::boxed::Box;
use alloc::string::String;
use alloc::vec::Vec;
use serde::{Deserialize, Serialize};

/// A typed definition exported from Lean 4
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Definition {
    pub name: String,
    pub params: Vec<(String, Type)>,
    pub ret: Type,
    pub body: Expr,
}

/// Lean types mapped to Rust-targeted types
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum Type {
    Nat,
    /// Mathematical, unbounded Lean `Int`. Runtime code generation rejects
    /// it unless a target explicitly supplies an exact representation.
    Int,
    Int8,
    Int16,
    Int32,
    Int64,
    UInt8,
    UInt16,
    UInt32,
    UInt64,
    String,
    Bytes,
    Ordering,
    Bool,
    /// A type declared in this module's `types` list, by full Lean name.
    /// Renders as a generated Rust struct or enum.
    Named(String),
    Option(Box<Type>),
    Result {
        ok: Box<Type>,
        error: Box<Type>,
    },
    Vec(Box<Type>),
    /// Lean `List α`. Allocation-free by policy, so the rendering depends on
    /// position: a parameter becomes a borrowed `&[α]` slice (matched with
    /// slice patterns), and a return type becomes a caller-owned
    /// `output: &mut [α]` buffer plus a written-length result. See
    /// `prod_codegen` for the lowering.
    List(Box<Type>),
    Tuple(Vec<Type>),
    /// Unmapped or complex type requiring manual handling
    Opaque(String),
}

/// A match alternative: `(alt "CtorName" (binders...) <body>)`
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Alt {
    pub ctor: String,
    pub binders: Vec<String>,
    pub body: Expr,
}

/// Expression AST — a simplified lambda calculus with constants,
/// extended with LCNF-flavored nodes (cases/ctor/proj/jp/jmp/unreachable)
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum Expr {
    Nat(u64),
    Int(i64),
    String(String),
    Bool(bool),
    Var(String),
    Param(usize), // De Bruijn-style parameter index
    Add(Box<Expr>, Box<Expr>),
    Sub(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
    /// Checked fixed-width operations return `Option`; unlike the older Nat
    /// operators they are values, not `ComputeError` control flow.
    CheckedAdd(Box<Expr>, Box<Expr>),
    CheckedSub(Box<Expr>, Box<Expr>),
    CheckedMul(Box<Expr>, Box<Expr>),
    CheckedNeg(Box<Expr>),
    CheckedDiv(Box<Expr>, Box<Expr>),
    BitAnd(Box<Expr>, Box<Expr>),
    BitOr(Box<Expr>, Box<Expr>),
    BitXor(Box<Expr>, Box<Expr>),
    BitNot(Box<Expr>),
    CheckedShl(Box<Expr>, Box<Expr>),
    CheckedShr(Box<Expr>, Box<Expr>),
    CheckedConvert(Box<Expr>),
    Append(Box<Expr>, Box<Expr>),
    Length(Box<Expr>),
    Index(Box<Expr>, Box<Expr>),
    Slice(Box<Expr>, Box<Expr>, Box<Expr>),
    Utf8Encode(Box<Expr>),
    Utf8Decode(Box<Expr>),
    CompareBytes(Box<Expr>, Box<Expr>),
    SplitExact(Box<Expr>, Box<Expr>, Box<Expr>),
    Join(Box<Expr>, Box<Expr>),
    ParseDecimal(Box<Expr>),
    FormatDecimal(Box<Expr>),
    Quotient(Box<Expr>, Box<Expr>, Box<Expr>),
    Remainder(Box<Expr>, Box<Expr>, Box<Expr>),
    Negate(Box<Expr>),
    Div(Box<Expr>, Box<Expr>),
    Mod(Box<Expr>, Box<Expr>),
    Shl(Box<Expr>, Box<Expr>),
    /// `Nat.shiftRight`: total and infallible (`a >>> b = 0` for `b >= 64`
    /// when `a` fits `u64`), unlike `Shl`/`Pow` which can overflow.
    Shr(Box<Expr>, Box<Expr>),
    Pow(Box<Expr>, Box<Expr>),
    Eq(Box<Expr>, Box<Expr>),
    Lt(Box<Expr>, Box<Expr>),
    Le(Box<Expr>, Box<Expr>),
    Gt(Box<Expr>, Box<Expr>),
    If(Box<Expr>, Box<Expr>, Box<Expr>),
    Let(String, Box<Expr>, Box<Expr>),
    Call(String, Vec<Expr>),
    /// LCNF `cases_on`: scrutinee, constructor alternatives, optional default
    Match {
        scrut: Box<Expr>,
        alts: Vec<Alt>,
        default: Option<Box<Expr>>,
    },
    /// Constructor application: `(ctor "Name" args...)`
    Ctor(String, Vec<Expr>),
    /// Structure projection: `(proj "TypeName" "fieldName" <expr>)`.
    ///
    /// The field *name*, not an index: the exporter resolves it against Lean's
    /// own structure info, so the declaration and the projection cannot
    /// disagree. An index-based form would need a second table in codegen that
    /// has to be kept in sync, and getting that wrong swaps fields silently.
    Proj(String, String, Box<Expr>),
    /// LCNF join point declaration: `(jp <name> (params...) <body>)`
    Jp {
        name: String,
        params: Vec<String>,
        body: Box<Expr>,
    },
    /// LCNF jump to a join point: `(jmp <name> args...)`
    Jmp(String, Vec<Expr>),
    /// LCNF `Unreachable` (dead branch)
    Unreachable,
    /// Placeholder for unhandled constructs
    Opaque(String),
    /// A call the exporter could not resolve: the callee is neither
    /// `@[prod]`-tagged nor on the operator whitelist. Deliberately distinct
    /// from `Call` so codegen rejects it instead of emitting a Rust call to a
    /// function that does not exist.
    Extern(String, Vec<Expr>),
}

impl Expr {
    /// The direct subexpressions of this node, in source order.
    ///
    /// The single traversal every consumer recurses with: `prod-codegen`'s
    /// fallibility fixpoint and join-point analysis, and `prod-cli`'s extern
    /// collection. It lived in `prod-codegen` and was hand-copied into
    /// `prod-cli`, where the copy promptly fell behind by a variant; there is
    /// one copy now, and it is here because `Expr` is here.
    ///
    /// The match below is deliberately **exhaustive**, listing the leaves
    /// explicitly rather than ending in a `_ => {}` arm: a new `Expr` variant
    /// must then be classified here as a leaf or as a recursive position, and
    /// the compiler says so. A wildcard would silently treat it as a leaf and
    /// make every consumer stop looking inside it.
    ///
    /// Returns an owned iterator over borrows (a `Vec` walk) rather than a
    /// bespoke iterator type: the crate is `#![no_std] + alloc`, and the
    /// allocation is confined to host-side analysis, never to generated code.
    pub fn children(&self) -> impl Iterator<Item = &Expr> {
        let mut out: Vec<&Expr> = Vec::new();
        match self {
            Expr::Proj(_, _, e) => out.push(e),
            Expr::Add(a, b)
            | Expr::Sub(a, b)
            | Expr::Mul(a, b)
            | Expr::CheckedAdd(a, b)
            | Expr::CheckedSub(a, b)
            | Expr::CheckedMul(a, b)
            | Expr::CheckedDiv(a, b)
            | Expr::BitAnd(a, b)
            | Expr::BitOr(a, b)
            | Expr::BitXor(a, b)
            | Expr::CheckedShl(a, b)
            | Expr::CheckedShr(a, b)
            | Expr::Append(a, b)
            | Expr::Index(a, b)
            | Expr::CompareBytes(a, b)
            | Expr::Join(a, b)
            | Expr::Div(a, b)
            | Expr::Mod(a, b)
            | Expr::Shl(a, b)
            | Expr::Shr(a, b)
            | Expr::Pow(a, b)
            | Expr::Eq(a, b)
            | Expr::Lt(a, b)
            | Expr::Le(a, b)
            | Expr::Gt(a, b) => {
                out.push(a);
                out.push(b);
            }
            Expr::CheckedNeg(value)
            | Expr::BitNot(value)
            | Expr::CheckedConvert(value)
            | Expr::Length(value)
            | Expr::Utf8Encode(value)
            | Expr::Utf8Decode(value)
            | Expr::ParseDecimal(value)
            | Expr::FormatDecimal(value) => out.push(value),
            Expr::Negate(value) => out.push(value),
            Expr::If(c, t, f)
            | Expr::Slice(c, t, f)
            | Expr::SplitExact(c, t, f)
            | Expr::Quotient(c, t, f)
            | Expr::Remainder(c, t, f) => {
                out.push(c);
                out.push(t);
                out.push(f);
            }
            Expr::Let(_, v, b) => {
                out.push(v);
                out.push(b);
            }
            Expr::Call(_, args)
            | Expr::Ctor(_, args)
            | Expr::Jmp(_, args)
            | Expr::Extern(_, args) => out.extend(args.iter()),
            Expr::Match {
                scrut,
                alts,
                default,
            } => {
                out.push(scrut);
                out.extend(alts.iter().map(|a| &a.body));
                if let Some(d) = default {
                    out.push(d);
                }
            }
            Expr::Jp { body, .. } => out.push(body),
            // Leaves: no subexpressions. Listed, not wildcarded — see above.
            Expr::Nat(_)
            | Expr::Int(_)
            | Expr::String(_)
            | Expr::Bool(_)
            | Expr::Var(_)
            | Expr::Param(_)
            | Expr::Unreachable
            | Expr::Opaque(_) => {}
        }
        out.into_iter()
    }
}

/// One constructor of a generated type: `(ctor "Full.Name.mk" (field Type)...)`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CtorDecl {
    /// Full Lean constructor name, e.g. `UorAtlas.Instance.mk`.
    pub name: String,
    /// Value fields in declaration order. `Prop` fields are erased by the
    /// exporter and never appear here.
    pub fields: Vec<(String, Type)>,
}

/// A Lean inductive rendered as a Rust type: one ctor means a struct, several
/// mean an enum with named-field variants.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TypeDecl {
    /// Full Lean type name, e.g. `UorAtlas.Instance`.
    pub name: String,
    pub ctors: Vec<CtorDecl>,
    /// Set when the exporter reached this type but cannot describe it, with
    /// the reason. The type is still declared so that codegen can reject a
    /// reference to it *precisely* rather than reporting a generic unknown
    /// name. `ctors` is empty when this is set.
    pub unsupported: Option<String>,
}

/// A module is a collection of definitions
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Module {
    pub name: String,
    /// Type declarations, emitted before the definitions that use them.
    pub types: Vec<TypeDecl>,
    pub definitions: Vec<Definition>,
}

impl Module {
    pub fn find_def(&self, name: &str) -> Option<&Definition> {
        self.definitions.iter().find(|d| d.name == name)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use alloc::vec;

    /// Every `Expr` variant, by name. `variant` below maps an `Expr` to one of
    /// these with an exhaustive match, so adding a variant is a compile error
    /// there; the assertions then force it into the `children()` table too.
    const ALL_VARIANTS: &[&str] = &[
        "Add",
        "Append",
        "BitAnd",
        "BitNot",
        "BitOr",
        "BitXor",
        "Bool",
        "Call",
        "CheckedAdd",
        "CheckedConvert",
        "CheckedDiv",
        "CheckedMul",
        "CheckedNeg",
        "CheckedShl",
        "CheckedShr",
        "CheckedSub",
        "CompareBytes",
        "Ctor",
        "Div",
        "Eq",
        "Extern",
        "FormatDecimal",
        "Gt",
        "If",
        "Index",
        "Int",
        "Jmp",
        "Join",
        "Jp",
        "Le",
        "Length",
        "Let",
        "Lt",
        "Match",
        "Mod",
        "Mul",
        "Nat",
        "Negate",
        "Opaque",
        "Param",
        "ParseDecimal",
        "Pow",
        "Proj",
        "Quotient",
        "Remainder",
        "Shl",
        "Shr",
        "Slice",
        "SplitExact",
        "String",
        "Sub",
        "Unreachable",
        "Utf8Decode",
        "Utf8Encode",
        "Var",
    ];

    fn variant(e: &Expr) -> &'static str {
        match e {
            Expr::Nat(_) => "Nat",
            Expr::Int(_) => "Int",
            Expr::String(_) => "String",
            Expr::Bool(_) => "Bool",
            Expr::Var(_) => "Var",
            Expr::Param(_) => "Param",
            Expr::Add(..) => "Add",
            Expr::Sub(..) => "Sub",
            Expr::Mul(..) => "Mul",
            Expr::CheckedAdd(..) => "CheckedAdd",
            Expr::CheckedSub(..) => "CheckedSub",
            Expr::CheckedMul(..) => "CheckedMul",
            Expr::CheckedNeg(..) => "CheckedNeg",
            Expr::CheckedDiv(..) => "CheckedDiv",
            Expr::BitAnd(..) => "BitAnd",
            Expr::BitOr(..) => "BitOr",
            Expr::BitXor(..) => "BitXor",
            Expr::BitNot(..) => "BitNot",
            Expr::CheckedShl(..) => "CheckedShl",
            Expr::CheckedShr(..) => "CheckedShr",
            Expr::CheckedConvert(..) => "CheckedConvert",
            Expr::Append(..) => "Append",
            Expr::Length(..) => "Length",
            Expr::Index(..) => "Index",
            Expr::Slice(..) => "Slice",
            Expr::Utf8Encode(..) => "Utf8Encode",
            Expr::Utf8Decode(..) => "Utf8Decode",
            Expr::CompareBytes(..) => "CompareBytes",
            Expr::SplitExact(..) => "SplitExact",
            Expr::Join(..) => "Join",
            Expr::ParseDecimal(..) => "ParseDecimal",
            Expr::FormatDecimal(..) => "FormatDecimal",
            Expr::Quotient(..) => "Quotient",
            Expr::Remainder(..) => "Remainder",
            Expr::Negate(..) => "Negate",
            Expr::Div(..) => "Div",
            Expr::Mod(..) => "Mod",
            Expr::Shl(..) => "Shl",
            Expr::Shr(..) => "Shr",
            Expr::Pow(..) => "Pow",
            Expr::Eq(..) => "Eq",
            Expr::Lt(..) => "Lt",
            Expr::Le(..) => "Le",
            Expr::Gt(..) => "Gt",
            Expr::If(..) => "If",
            Expr::Let(..) => "Let",
            Expr::Call(..) => "Call",
            Expr::Match { .. } => "Match",
            Expr::Ctor(..) => "Ctor",
            Expr::Proj(..) => "Proj",
            Expr::Jp { .. } => "Jp",
            Expr::Jmp(..) => "Jmp",
            Expr::Unreachable => "Unreachable",
            Expr::Opaque(_) => "Opaque",
            Expr::Extern(..) => "Extern",
        }
    }

    fn v(name: &str) -> Expr {
        Expr::Var(String::from(name))
    }

    fn bx(name: &str) -> Box<Expr> {
        Box::new(v(name))
    }

    /// `children()` must reach every recursive position of every variant: a
    /// missed one silently truncates the analyses built on top of it (extern
    /// collection, the fallibility fixpoint, join-point counting), and the
    /// symptom is a wrong answer, not a crash.
    #[test]
    fn children_reaches_every_recursive_position() {
        let cases: Vec<(Expr, Vec<&str>)> = vec![
            // Leaves.
            (Expr::Nat(1), vec![]),
            (Expr::Int(-1), vec![]),
            (Expr::String(String::from("text")), vec![]),
            (Expr::Bool(true), vec![]),
            (v("x"), vec![]),
            (Expr::Param(0), vec![]),
            (Expr::Unreachable, vec![]),
            (Expr::Opaque(String::from("o")), vec![]),
            // Unary.
            (
                Expr::Proj(String::from("T"), String::from("f"), bx("a")),
                vec!["a"],
            ),
            (Expr::CheckedNeg(bx("a")), vec!["a"]),
            (Expr::BitNot(bx("a")), vec!["a"]),
            (Expr::CheckedConvert(bx("a")), vec!["a"]),
            (Expr::Length(bx("a")), vec!["a"]),
            (Expr::Utf8Encode(bx("a")), vec!["a"]),
            (Expr::Utf8Decode(bx("a")), vec!["a"]),
            (Expr::ParseDecimal(bx("a")), vec!["a"]),
            (Expr::FormatDecimal(bx("a")), vec!["a"]),
            (Expr::Negate(bx("a")), vec!["a"]),
            // Binary.
            (Expr::Add(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Sub(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Mul(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::CheckedAdd(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::CheckedSub(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::CheckedMul(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::CheckedDiv(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::BitAnd(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::BitOr(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::BitXor(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::CheckedShl(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::CheckedShr(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Append(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Index(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::CompareBytes(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Join(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Div(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Mod(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Shl(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Shr(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Pow(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Eq(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Lt(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Le(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Gt(bx("a"), bx("b")), vec!["a", "b"]),
            (Expr::Slice(bx("a"), bx("b"), bx("c")), vec!["a", "b", "c"]),
            (
                Expr::SplitExact(bx("a"), bx("b"), bx("c")),
                vec!["a", "b", "c"],
            ),
            (
                Expr::Quotient(bx("a"), bx("b"), bx("c")),
                vec!["a", "b", "c"],
            ),
            (
                Expr::Remainder(bx("a"), bx("b"), bx("c")),
                vec!["a", "b", "c"],
            ),
            // Control flow and binders.
            (Expr::If(bx("c"), bx("t"), bx("f")), vec!["c", "t", "f"]),
            (
                Expr::Let(String::from("x"), bx("v"), bx("b")),
                vec!["v", "b"],
            ),
            (
                Expr::Match {
                    scrut: bx("s"),
                    alts: vec![Alt {
                        ctor: String::from("C"),
                        binders: vec![],
                        body: v("a"),
                    }],
                    default: Some(bx("d")),
                },
                vec!["s", "a", "d"],
            ),
            (
                Expr::Jp {
                    name: String::from("j"),
                    params: vec![],
                    body: bx("a"),
                },
                vec!["a"],
            ),
            // Argument lists.
            (
                Expr::Call(String::from("f"), vec![v("a"), v("b")]),
                vec!["a", "b"],
            ),
            (
                Expr::Ctor(String::from("C"), vec![v("a"), v("b")]),
                vec!["a", "b"],
            ),
            (
                Expr::Jmp(String::from("j"), vec![v("a"), v("b")]),
                vec!["a", "b"],
            ),
            (
                Expr::Extern(String::from("F.g"), vec![v("a"), v("b")]),
                vec!["a", "b"],
            ),
        ];

        for (expr, expected) in &cases {
            let seen: Vec<&str> = expr
                .children()
                .map(|c| match c {
                    Expr::Var(n) => n.as_str(),
                    other => panic!("unexpected child {:?}", other),
                })
                .collect();
            assert_eq!(&seen, expected, "children of {}", variant(expr));
        }

        let mut covered: Vec<&'static str> = cases.iter().map(|(e, _)| variant(e)).collect();
        covered.sort_unstable();
        covered.dedup();
        assert_eq!(
            covered, ALL_VARIANTS,
            "every Expr variant needs a case above"
        );
    }
}
