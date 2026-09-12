//! prod-codegen: renders `prod-ir` modules as Rust source text.
//!
//! This crate is `#![no_std]` (with `alloc`) and host-independent: it renders
//! Rust code as a plain `String`, never as `proc_macro2::TokenStream`, so it
//! can run on wasm32 or inside other hosts. `prod-macros` and `prod-cli` are
//! thin drivers on top of [`generate_module`].
//!
//! # Code generation policy
//!
//! The generated code targets the project's production standard: it must not
//! panic on caller-controlled input, and it must not allocate. Those two rules
//! drive everything below.
//!
//! ## Memory profile: no heap, ever
//!
//! Nothing rendered here can allocate. Lean `List α` is the only type that
//! would naïvely need a heap, so its lowering is position-dependent:
//!
//! - **Parameter position** → `&[α]`. `List.nil` match arms render as the
//!   slice pattern `[]` and `List.cons (h t)` as `[h, t @ ..]`, so structural
//!   recursion passes the tail sub-slice directly — no rebinding, no copying.
//! - **Return position** → a caller-owned output buffer. The signature gains a
//!   trailing `output: &mut [α]` and returns `Result<usize, ComputeError>`,
//!   the length of the initialized prefix. The body is rendered in *builder
//!   mode*: `List.nil` becomes `Ok(0)`; `List.cons h t` splits one element off
//!   the front of the buffer (`split_first_mut`, so exhaustion is an `Err`,
//!   never an index panic), writes the head, recurses the tail into the
//!   remainder, and returns `1 +` the tail's length. `if`/`let`/`cases`
//!   recurse into builder mode; `let`-bound list values (LCNF emits lists in
//!   A-normal form) are resolved through a scoped environment rather than
//!   materialized.
//! - **Zero-argument definitions returning a list** (the golden values) →
//!   `&'static [α]` built from a promoted array literal.
//!
//! A list value that reaches any other position — an intermediate value used
//! as something other than a builder tail, or a list nested inside another
//! type — is an [`Error::UnsupportedList`]: an honest codegen failure rather
//! than a silently allocating fallback. `Type::Vec` is rejected outright as
//! [`Error::HeapType`].
//!
//! ## Error contract: fallibility is precise, not uniform
//!
//! Lean `Nat` maps to bounded `u64`, fixed-width Lean `Int64` maps to `i64`,
//! and mathematical Lean `Int` is rejected as [`Error::UnboundedInt`] rather
//! than silently narrowed. The partial operations report failure instead of panicking: addition, multiplication,
//! shifts, and powers render as `checked_*(..).ok_or(crate::ComputeError::X)?`
//! (with the shift/power exponent narrowed through
//! `u32::try_from(..).map_err(..)?`). Subtraction saturates at zero (Lean Nat
//! subtraction) and division/modulo by zero return zero (Lean Nat's total
//! operations), so neither is fallible. There is no bignum fallback, so this
//! is exact only while values fit in `u64`.
//!
//! A definition returns `Result<T, crate::ComputeError>` **only if it needs
//! to**: if its body contains a checked operation, or calls a definition that
//! is itself fallible, or builds a list into a caller buffer. That is a least
//! fixpoint over the module's call graph ([`Shape`]), so leaf definitions and
//! the zero-argument goldens keep their plain return types. Calls to fallible
//! definitions render as `f(args)?`.
//!
//! ## Other lowerings
//!
//! - **LCNF nodes**:
//!   - `Match` renders as a Rust `match`, with `default` becoming the `_` arm.
//!     The Nat structural-recursion ctors are special-cased: `Nat.zero` renders
//!     as the literal pattern `0`, and `Nat.succ k` as the `_` arm with
//!     `k` bound to `(scrut).saturating_sub(1)` (exact, since the zero arm
//!     matches first). `Bool.true`/`Bool.false` → `true`/`false` patterns, and
//!     `Option.none`/`Option.some v` → `None`/`Some(v)` patterns. The List
//!     ctors use the slice patterns described above.
//!   - `Ctor` renders as tuple-style construction `Name(args...)` (bare `Name`
//!     when there are no args), except `Prod.mk`, which renders as a Rust
//!     tuple `(a, b)` — nested for right-nested pairs — and the Bool/Option
//!     ctors, which render as `true`/`false` and `None`/`Some(x)`.
//!   - `Proj` renders straight through: `(proj "Type" "field" e)` becomes
//!     `e.field` (raw-escaped if `field` is a Rust keyword). The field name
//!     is resolved once, in `Lower.lean`, against Lean's own structure info
//!     — codegen holds no type-keyed lookup table, so there is no second
//!     copy of the declaration that could disagree with the first and swap
//!     fields silently. `crate::Instance` is generated like any other type
//!     and mirrors the Lean structure's own field spelling (`q`, `T`, `O`)
//!     for exactly this reason.
//!
//!   - `Type::Tuple` renders as a Rust tuple type, so
//!     `(Tuple Nat (Tuple Nat Nat))` becomes `(u64, (u64, u64))`.
//!   - `Unreachable` renders as `unreachable!()`.
//!   - **Jp/Jmp policy**: an acyclic join point with one or more `jmp` callers
//!     is inlined independently at every jump site as
//!     `{ let p = arg; ...; <jp body> }`, and the declaration site renders as
//!     `()`. A join point with no callers renders its body in place. Anything
//!     cyclic is rejected as
//!     [`Error::UnsupportedJoinPoint`], because it would need real control
//!     flow. This used to emit a `loop {}` skeleton with a "manual port
//!     required" comment, which did not compile: the join point's parameters
//!     were never bound, and each jump site had type `()` where its arm
//!     needed a value.
//!
//! ## Recursion
//!
//! Generated recursion is structurally bounded by a fuel or data argument (the
//! Lean side must already be terminating for LCNF to emit it), so stack depth
//! is a function of the caller's inputs, not of unbounded search.

#![no_std]

extern crate alloc;

mod c_abi;
mod core_wasm;
mod package;
mod sdk;
mod view;

use alloc::collections::{BTreeMap, BTreeSet};
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use core::fmt;
use prod_ir::{Alt, CtorDecl, Definition, Expr, Module, Type, TypeDecl};

pub use c_abi::{generate_c_bindings, CAbiError, CBindings};
pub use core_wasm::{generate_core_wasm_package, CoreWasmSpec};
pub use package::{
    generate_cargo_package, CargoDependency, CargoPackageSpec, GeneratedPackage, PackageFile,
};
pub use sdk::{generate_sdks, SdkBindings};
pub use view::{
    generate_holoview_bundle, generate_view_v1, BrowserAdapterBinding, EvaluatedViewV1,
    GeneratedViewV1, ViewOperation,
};

/// Errors that can occur during code generation
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Error {
    /// Code generation is not possible for an opaque expression
    OpaqueExpr(String),
    /// `(param n)` refers to a parameter index outside the definition's list
    ParamOutOfBounds(usize),
    /// A list value appears somewhere the allocation-free lowering cannot
    /// render it: nested inside another type, or used as an intermediate
    /// value rather than flowing into the output buffer.
    UnsupportedList(String),
    /// A type that would require a heap allocation in generated code.
    HeapType(String),
    /// A type is defined in terms of itself; needs the tier-1 memory profile.
    RecursiveType(String),
    /// A type takes type parameters; needs monomorphization (S5).
    PolymorphicType(String),
    /// A field's type cannot appear in an allocation-free generated type.
    UnsupportedFieldType(String),
    /// Two Lean types share a last name component, so they would collide.
    DuplicateTypeName(String),
    /// A type reached codegen with no rendering.
    OpaqueType(String),
    /// Mathematical Lean `Int` has no exact fixed-width Rust representation.
    UnboundedInt,
    /// The exporter could not resolve a callee to a generated definition.
    UnresolvedCall(String),
    /// A projection names a field the declared type does not have. Catches a
    /// declaration and a projection disagreeing within one IR file.
    UnknownField(String, String),
    /// A join point that jumps to itself. Acyclic join points are duplicated
    /// at their call sites; cycles would need real control flow.
    UnsupportedJoinPoint(String),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::OpaqueExpr(s) => write!(f, "cannot generate code for opaque expression: {}", s),
            Error::ParamOutOfBounds(i) => write!(f, "parameter index {} is out of bounds", i),
            Error::UnsupportedList(s) => {
                write!(f, "list value cannot be rendered without allocating: {}", s)
            }
            Error::HeapType(s) => write!(
                f,
                "type would require a heap allocation in generated code: {}",
                s
            ),
            Error::RecursiveType(s) => write!(
                f,
                "recursive type `{}` cannot be rendered allocation-free (needs the tier-1 profile)",
                s
            ),
            Error::PolymorphicType(s) => write!(
                f,
                "type `{}` has type parameters; monomorphization is not implemented",
                s
            ),
            Error::UnsupportedFieldType(s) => {
                write!(f, "field type is not allowed in a generated type: {}", s)
            }
            Error::DuplicateTypeName(s) => {
                write!(f, "two Lean types share the last name component `{}`", s)
            }
            Error::OpaqueType(s) => write!(f, "no Rust rendering for type: {}", s),
            Error::UnboundedInt => write!(
                f,
                "mathematical Lean `Int` is unbounded and cannot be represented by a fixed-width Rust integer"
            ),
            Error::UnresolvedCall(s) => write!(
                f,
                "`{}` is neither @[prod]-tagged nor a whitelisted operator, so there is nothing to call",
                s
            ),
            Error::UnknownField(ty, field) => {
                write!(f, "type `{}` declares no field `{}`", ty, field)
            }
            Error::UnsupportedJoinPoint(name) => write!(
                f,
                "join point `{}` has several callers or jumps to itself; only the single-caller form has a lowering",
                name
            ),
        }
    }
}

/// The rejections the generator makes, for the published subset contract
/// (`prod subset`, `specs/lean-for-production.md`). One entry per `Error`
/// variant, in declaration order; keep in step with `Error` above — the
/// contract is rendered from this list, so a variant missing here is a
/// rejection the published contract silently fails to disclose.
pub const REJECTIONS: &[(&str, &str)] = &[
    (
        "OpaqueExpr",
        "an expression with no Rust rendering",
    ),
    (
        "ParamOutOfBounds",
        "a parameter index outside the definition's parameter list",
    ),
    (
        "UnsupportedList",
        "a list value outside a supported position: nested inside another type, or used as an intermediate value rather than a slice parameter/output buffer",
    ),
    (
        "HeapType",
        "a type that would require a heap allocation in generated code",
    ),
    (
        "RecursiveType",
        "an inductive refers to itself (directly, or through one level of indirection); needs the tier-1 memory profile",
    ),
    (
        "PolymorphicType",
        "an inductive has type parameters; monomorphization is not implemented",
    ),
    (
        "UnsupportedFieldType",
        "a field type not allowed in an allocation-free generated type (e.g. a list or vector field, which would need owned storage)",
    ),
    (
        "DuplicateTypeName",
        "two Lean types share a last name component, so they would collide in Rust",
    ),
    (
        "OpaqueType",
        "a type reached codegen with no Rust rendering",
    ),
    (
        "UnboundedInt",
        "mathematical Lean Int reaches a fixed-width runtime target",
    ),
    (
        "UnresolvedCall",
        "the callee is neither @[prod]-tagged nor a whitelisted operator, so there is nothing to call",
    ),
    (
        "UnknownField",
        "a projection names a field the declared type does not have",
    ),
    (
        "UnsupportedJoinPoint",
        "a join point with several callers, or one that jumps to itself; only the single-caller form, which inlines at its jump site, has a lowering",
    ),
];

/// How a generated definition presents itself to its callers.
///
/// Computed for the whole module up front, because a call site cannot know
/// whether to append `?` until the callee's shape is known.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Shape {
    /// Plain value: `fn f(..) -> T`.
    Value,
    /// Fallible: `fn f(..) -> Result<T, ComputeError>`; call sites append `?`.
    Fallible,
    /// List builder: `fn f(.., output: &mut [E]) -> Result<usize, ComputeError>`.
    Buffer,
    /// Zero-argument list golden: `fn f() -> &'static [E]`.
    StaticList,
}

/// Definition name → [`Shape`], for one module.
type Signatures<'m> = BTreeMap<&'m str, Shape>;

/// Rust keywords that a Lean field or constructor name may legitimately be.
/// Escaped with the raw-identifier prefix rather than renamed, so the Rust
/// name still matches the Lean name exactly.
const RUST_KEYWORDS: &[&str] = &[
    "as", "async", "await", "break", "const", "continue", "crate", "dyn", "else", "enum", "extern",
    "false", "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod", "move", "mut", "pub",
    "ref", "return", "self", "static", "struct", "super", "trait", "true", "type", "unsafe", "use",
    "where", "while", "abstract", "become", "box", "do", "final", "macro", "override", "priv",
    "typeof", "unsized", "virtual", "yield", "try", "gen",
];

/// A Lean identifier as a Rust identifier, raw-escaped if it is a keyword.
fn rust_ident(name: &str) -> String {
    if RUST_KEYWORDS.contains(&name) {
        format!("r#{}", name)
    } else {
        String::from(name)
    }
}

/// A Lean binder/local as a Rust local. Path keywords such as `self` cannot
/// be written as raw identifiers, so all keywords receive a stable prefix.
fn rust_local_ident(name: &str) -> String {
    if RUST_KEYWORDS.contains(&name) {
        format!("__prod_{name}")
    } else {
        String::from(name)
    }
}

/// Last dot-separated component of a full Lean name.
fn last_component(name: &str) -> &str {
    name.rsplit('.').next().unwrap_or(name)
}

/// Full Lean type name → its declaration, for the module being rendered.
type TypeTable<'m> = BTreeMap<&'m str, &'m TypeDecl>;

fn type_table(types: &[TypeDecl]) -> Result<TypeTable<'_>, Error> {
    let mut by_full: TypeTable = BTreeMap::new();
    let mut short_seen: BTreeMap<&str, &str> = BTreeMap::new();
    for decl in types {
        let short = last_component(&decl.name);
        if let Some(previous) = short_seen.insert(short, &decl.name) {
            if previous != decl.name {
                return Err(Error::DuplicateTypeName(String::from(short)));
            }
        }
        by_full.insert(decl.name.as_str(), decl);
    }
    Ok(by_full)
}

/// Render one type declaration: a struct if it has exactly one constructor,
/// otherwise an enum with named-field variants.
///
fn copy_type(ty: &Type, table: &TypeTable, visiting: &mut BTreeSet<String>) -> bool {
    match ty {
        Type::String | Type::Bytes | Type::List(_) | Type::Vec(_) => false,
        Type::Named(name) => {
            if !visiting.insert(name.clone()) {
                return false;
            }
            let result = table.get(name.as_str()).is_some_and(|declaration| {
                declaration.ctors.iter().all(|constructor| {
                    constructor
                        .fields
                        .iter()
                        .all(|(_, field)| copy_type(field, table, visiting))
                })
            });
            visiting.remove(name);
            result
        }
        Type::Option(inner) => copy_type(inner, table, visiting),
        Type::Result { ok, error } => {
            copy_type(ok, table, visiting) && copy_type(error, table, visiting)
        }
        Type::Tuple(items) => items.iter().all(|item| copy_type(item, table, visiting)),
        _ => true,
    }
}

fn generate_type_decl(decl: &TypeDecl, table: &TypeTable) -> Result<String, Error> {
    // The exporter reached this type but could not describe it. It is declared
    // anyway so that the rejection names a reason instead of an unknown type.
    if let Some(reason) = &decl.unsupported {
        return Err(match reason.as_str() {
            "type parameters" => Error::PolymorphicType(decl.name.clone()),
            "recursive" => Error::RecursiveType(decl.name.clone()),
            other => Error::OpaqueType(format!("{} ({})", decl.name, other)),
        });
    }
    for ctor in &decl.ctors {
        for (field, ty) in &ctor.fields {
            check_field_type(ty, &decl.name, field, table)?;
        }
    }

    let is_copy = decl.ctors.iter().all(|constructor| {
        constructor
            .fields
            .iter()
            .all(|(_, field)| copy_type(field, table, &mut BTreeSet::new()))
    });
    let mut out = if is_copy {
        String::from("#[derive(Debug, Clone, Copy, PartialEq, Eq)]\n")
    } else {
        String::from("#[derive(Debug, Clone, PartialEq, Eq)]\n")
    };
    let short = last_component(&decl.name);

    if decl.ctors.len() == 1 {
        let ctor = &decl.ctors[0];
        out.push_str(&format!("pub struct {} {{\n", rust_ident(short)));
        for (name, ty) in &ctor.fields {
            out.push_str(&format!(
                "    pub {}: {},\n",
                rust_ident(name),
                type_to_rust(ty)?
            ));
        }
        out.push_str("}\n");
        return Ok(out);
    }

    let fieldless = decl
        .ctors
        .iter()
        .all(|constructor| constructor.fields.is_empty());
    if fieldless && decl.ctors.len() <= (u8::MAX as usize) + 1 {
        out.push_str("#[repr(u8)]\n");
    }
    out.push_str(&format!("pub enum {} {{\n", rust_ident(short)));
    for (index, ctor) in decl.ctors.iter().enumerate() {
        let variant = rust_ident(last_component(&ctor.name));
        if ctor.fields.is_empty() {
            if fieldless && decl.ctors.len() <= (u8::MAX as usize) + 1 {
                out.push_str(&format!("    {} = {},\n", variant, index));
            } else {
                out.push_str(&format!("    {},\n", variant));
            }
            continue;
        }
        let mut fields = Vec::with_capacity(ctor.fields.len());
        for (name, ty) in &ctor.fields {
            fields.push(format!("{}: {}", rust_ident(name), type_to_rust(ty)?));
        }
        out.push_str(&format!("    {} {{ {} }},\n", variant, fields.join(", ")));
    }
    out.push_str("}\n");
    Ok(out)
}

/// A field type must be renderable and must not make the type recursive.
///
/// `owner` and `field` are the Lean constant and field name responsible, and
/// they appear in the rejection message: the point of this milestone is that a
/// failure names the declaration that caused it, and "a list field would need
/// owned storage" on its own leaves the reader to grep for which one.
fn check_field_type(ty: &Type, owner: &str, field: &str, table: &TypeTable) -> Result<(), Error> {
    match ty {
        Type::Named(n) => {
            if n == owner {
                return Err(Error::RecursiveType(String::from(owner)));
            }
            match table.get(n.as_str()) {
                // One level of indirection is enough to catch the mutual case
                // too: B referring back to A makes A reachable from A.
                Some(other) => {
                    for ctor in &other.ctors {
                        for (_, inner) in &ctor.fields {
                            if let Type::Named(m) = inner {
                                if m == owner {
                                    return Err(Error::RecursiveType(String::from(owner)));
                                }
                            }
                        }
                    }
                    Ok(())
                }
                None => Err(Error::OpaqueType(n.clone())),
            }
        }
        Type::List(inner) => check_field_type(inner, owner, field, table),
        Type::Vec(_) => Err(Error::UnsupportedFieldType(format!(
            "`{}.{}`: a vector field would need heap storage",
            owner, field
        ))),
        Type::Tuple(items) => {
            for item in items {
                check_field_type(item, owner, field, table)?;
            }
            Ok(())
        }
        Type::Option(inner) => check_field_type(inner, owner, field, table),
        Type::Result { ok, error } => {
            check_field_type(ok, owner, field, table)?;
            check_field_type(error, owner, field, table)
        }
        _ => Ok(()),
    }
}

/// Render a whole module: one `pub fn` per definition.
pub fn generate_module(module: &Module) -> Result<String, Error> {
    let table = type_table(&module.types)?;
    let shapes = signatures(&module.definitions);
    let mut out = String::new();
    for decl in &module.types {
        out.push_str(&generate_type_decl(decl, &table)?);
        out.push('\n');
    }
    for def in &module.definitions {
        out.push_str(&generate_def_in(def, &module.definitions, &shapes, &table)?);
        out.push('\n');
    }
    Ok(out)
}

/// Render a single definition as a `pub fn`.
///
/// Calls to definitions outside `def` itself are assumed infallible, since
/// there is no module to resolve them against; use [`generate_module`] when
/// cross-definition fallibility matters. With no module, there is no type
/// table either, so any `(named ...)` type in `def`'s signature is opaque.
pub fn generate_def(def: &Definition) -> Result<String, Error> {
    let one = core::slice::from_ref(def);
    let table: TypeTable = BTreeMap::new();
    generate_def_in(def, one, &signatures(one), &table)
}

/// Compute every definition's [`Shape`] as a least fixpoint over the call
/// graph: seed everything infallible, then promote until nothing changes.
/// Monotone (shapes only ever move `Value` → `Fallible`), so it terminates.
fn signatures<'m>(defs: &'m [Definition]) -> Signatures<'m> {
    let mut shapes: Signatures<'m> = defs
        .iter()
        .map(|def| {
            let shape = match &def.ret {
                Type::List(_) if def.params.is_empty() => Shape::StaticList,
                Type::List(_) => Shape::Buffer,
                _ => Shape::Value,
            };
            (def.name.as_str(), shape)
        })
        .collect();

    loop {
        let mut changed = false;
        for def in defs {
            if shapes.get(def.name.as_str()) != Some(&Shape::Value) {
                continue;
            }
            if is_fallible(&def.body, &shapes) {
                shapes.insert(def.name.as_str(), Shape::Fallible);
                changed = true;
            }
        }
        if !changed {
            return shapes;
        }
    }
}

/// Does this expression perform, or reach, an operation that can fail?
fn is_fallible(expr: &Expr, shapes: &Signatures) -> bool {
    let here = match expr {
        Expr::Add(..) | Expr::Mul(..) | Expr::Shl(..) | Expr::Pow(..) => true,
        Expr::Call(name, _) => matches!(
            shapes.get(name.as_str()),
            Some(Shape::Fallible) | Some(Shape::Buffer)
        ),
        _ => false,
    };
    here || expr.children().any(|child| is_fallible(child, shapes))
}

fn count_var_uses(expr: &Expr, name: &str) -> usize {
    let here = usize::from(matches!(expr, Expr::Var(candidate) if candidate == name));
    here + expr
        .children()
        .map(|child| count_var_uses(child, name))
        .sum::<usize>()
}

/// Whether a binding expression produces a known non-`Copy` Rust value.
///
/// This deliberately answers `false` when the type is not recoverable from
/// the typed IR node. The exporter emits constructors, calls, projections,
/// and literals for the shared values this analysis targets; those cases all
/// retain enough type information for an exact answer.
fn expression_is_non_copy(
    expr: &Expr,
    definitions: &[Definition],
    table: &TypeTable<'_>,
    non_copy_locals: &BTreeSet<String>,
) -> bool {
    let non_copy_type = |ty: &Type| !copy_type(ty, table, &mut BTreeSet::new());
    match expr {
        Expr::String(_) => true,
        Expr::Var(name) => non_copy_locals.contains(name),
        Expr::Call(name, _) => definitions
            .iter()
            .find(|definition| definition.name == *name)
            .is_some_and(|definition| non_copy_type(&definition.ret)),
        Expr::Proj(owner, field, _) => table
            .get(owner.as_str())
            .and_then(|declaration| {
                declaration
                    .ctors
                    .iter()
                    .flat_map(|constructor| constructor.fields.iter())
                    .find_map(|(candidate, ty)| (candidate == field).then_some(ty))
            })
            .is_some_and(non_copy_type),
        Expr::Ctor(name, _)
            if matches!(
                name.as_str(),
                "List.nil"
                    | "List.cons"
                    | "Option.none"
                    | "Option.some"
                    | "Except.ok"
                    | "Except.error"
            ) =>
        {
            true
        }
        Expr::Ctor(name, _) => table.values().any(|declaration| {
            declaration
                .ctors
                .iter()
                .any(|constructor| constructor.name == *name)
                && non_copy_type(&Type::Named(declaration.name.clone()))
        }),
        // These operations have an owned string/byte/list-shaped result.
        Expr::Append(..)
        | Expr::Utf8Encode(..)
        | Expr::Utf8Decode(..)
        | Expr::SplitExact(..)
        | Expr::Join(..)
        | Expr::FormatDecimal(..) => true,
        Expr::Let(name, value, body) => {
            let mut nested = non_copy_locals.clone();
            if expression_is_non_copy(value, definitions, table, non_copy_locals) {
                nested.insert(name.clone());
            }
            expression_is_non_copy(body, definitions, table, &nested)
        }
        Expr::If(_, then_value, else_value) => {
            expression_is_non_copy(then_value, definitions, table, non_copy_locals)
                || expression_is_non_copy(else_value, definitions, table, non_copy_locals)
        }
        _ => false,
    }
}

fn repeated_non_copy_locals(
    expr: &Expr,
    definitions: &[Definition],
    table: &TypeTable<'_>,
    params: &[(String, Type)],
    returns_boolean: bool,
) -> BTreeSet<String> {
    fn walk(
        expr: &Expr,
        definitions: &[Definition],
        table: &TypeTable<'_>,
        non_copy_locals: &BTreeSet<String>,
        output: &mut BTreeSet<String>,
    ) {
        match expr {
            Expr::Let(name, value, body) => {
                walk(value, definitions, table, non_copy_locals, output);
                let mut nested = non_copy_locals.clone();
                if expression_is_non_copy(value, definitions, table, non_copy_locals) {
                    nested.insert(name.clone());
                    // Projections of non-Copy fields are already borrows and
                    // may be reused without cloning the underlying value.
                    if !matches!(value.as_ref(), Expr::Proj(..)) && count_var_uses(body, name) > 1 {
                        output.insert(name.clone());
                    }
                }
                walk(body, definitions, table, &nested, output);
            }
            Expr::Match { .. } => {
                for child in expr.children() {
                    walk(child, definitions, table, non_copy_locals, output);
                }
            }
            Expr::Jp {
                params: join_params,
                body,
                ..
            } => {
                for parameter in join_params {
                    if count_var_uses(body, parameter) > 1 {
                        output.insert(parameter.clone());
                    }
                }
                walk(body, definitions, table, non_copy_locals, output);
            }
            _ => {
                for child in expr.children() {
                    walk(child, definitions, table, non_copy_locals, output);
                }
            }
        }
    }

    let mut output = BTreeSet::new();
    for (name, ty) in params {
        if !borrowed_parameter(ty, table, returns_boolean)
            && !copy_type(ty, table, &mut BTreeSet::new())
            && count_var_uses(expr, name) > 1
        {
            output.insert(name.clone());
        }
    }
    walk(expr, definitions, table, &BTreeSet::new(), &mut output);
    output
}

fn inline_bindings(expr: &Expr) -> BTreeMap<String, &Expr> {
    fn walk<'a>(expr: &'a Expr, output: &mut BTreeMap<String, &'a Expr>) {
        if let Expr::Let(name, value, _) = expr {
            if matches!(value.as_ref(), Expr::String(_))
                || matches!(
                    value.as_ref(),
                    Expr::Ctor(constructor, arguments)
                        if arguments.is_empty()
                            && matches!(constructor.as_str(), "List.nil" | "Option.none")
                )
            {
                // `List.nil` and `Option.none` are polymorphic in Lean. LCNF
                // can CSE one closed value across uses with different element
                // types, but one Rust local cannot have several monomorphic
                // types. String literals are also inlined so borrowed
                // comparison/call positions stay allocation-free while owned
                // record fields still materialize a String at their use.
                output.insert(name.clone(), value);
            }
        }
        for child in expr.children() {
            walk(child, output);
        }
    }

    let mut output = BTreeMap::new();
    walk(expr, &mut output);
    output
}

fn generate_def_in<'m>(
    def: &'m Definition,
    definitions: &'m [Definition],
    shapes: &Signatures<'m>,
    table: &TypeTable<'m>,
) -> Result<String, Error> {
    let shape = shapes
        .get(def.name.as_str())
        .copied()
        .unwrap_or(Shape::Value);
    let renderer = Renderer {
        shapes,
        definitions,
        params: &def.params,
        ctx: JpContext::collect(&def.body),
        types: table,
        clone_locals: repeated_non_copy_locals(
            &def.body,
            definitions,
            table,
            &def.params,
            def.ret == Type::Bool,
        ),
        inline_values: inline_bindings(&def.body),
    };

    let mut params = String::new();
    for (i, (name, ty)) in def.params.iter().enumerate() {
        if i > 0 {
            params.push_str(", ");
        }
        params.push_str(&format!(
            "{}: {}",
            rust_local_ident(name),
            param_type_to_rust(ty, table, def.ret == Type::Bool)?
        ));
    }
    check_named_type(&def.ret, table)?;
    let return_type = if returns_borrowed_projection(&def.body, &def.ret, table) {
        format!("&{}", type_to_rust(&def.ret)?)
    } else {
        type_to_rust(&def.ret)?
    };

    match shape {
        Shape::StaticList => {
            let elem = list_element(&def.ret)?;
            if is_fallible(&def.body, shapes) {
                return Err(Error::UnsupportedList(format!(
                    "`{}` computes its list elements, so it cannot be a promoted &'static slice",
                    def.name
                )));
            }
            let mut items = Vec::new();
            renderer.static_list(&def.body, &[], &mut items)?;
            Ok(format!(
                "pub fn {}() -> &'static [{}] {{\n    &[{}]\n}}\n",
                def.name,
                type_to_rust(elem)?,
                items.join(", ")
            ))
        }
        Shape::Buffer => {
            let elem = list_element(&def.ret)?;
            if !params.is_empty() {
                params.push_str(", ");
            }
            params.push_str(&format!("output: &mut [{}]", type_to_rust(elem)?));
            let body = renderer.render(
                &def.body,
                &Mode::Builder {
                    out: "output",
                    env: &[],
                    depth: 0,
                },
            )?;
            Ok(format!(
                "pub fn {}({}) -> Result<usize, crate::ComputeError> {{\n    {}\n}}\n",
                def.name, params, body
            ))
        }
        Shape::Fallible => Ok(format!(
            "pub fn {}({}) -> Result<{}, crate::ComputeError> {{\n    Ok({})\n}}\n",
            def.name,
            params,
            return_type,
            renderer.value(&def.body)?
        )),
        Shape::Value => Ok(format!(
            "pub fn {}({}) -> {} {{\n    {}\n}}\n",
            def.name,
            params,
            return_type,
            renderer.value(&def.body)?
        )),
    }
}

/// Whether a definition is the compiler-generated shape of an accessor for a
/// non-`Copy` field. Returning a borrow preserves the source value without a
/// clone (and therefore without a possible allocation).
fn returns_borrowed_projection(expr: &Expr, ret: &Type, table: &TypeTable) -> bool {
    let Expr::Let(name, value, body) = expr else {
        return false;
    };
    if !matches!(body.as_ref(), Expr::Var(result) if result == name) {
        return false;
    }
    let Expr::Proj(owner, field, _) = value.as_ref() else {
        return false;
    };
    table
        .get(owner.as_str())
        .and_then(|declaration| {
            declaration
                .ctors
                .iter()
                .flat_map(|constructor| constructor.fields.iter())
                .find_map(|(name, ty)| (name == field).then_some(ty))
        })
        .is_some_and(|field_type| {
            field_type == ret && !copy_type(field_type, table, &mut BTreeSet::new())
        })
}

/// Rust spelling of a type in an ordinary (owned, by-value) position.
fn type_to_rust(ty: &Type) -> Result<String, Error> {
    Ok(match ty {
        Type::Nat => String::from("u64"),
        Type::Int => return Err(Error::UnboundedInt),
        Type::Int8 => String::from("i8"),
        Type::Int16 => String::from("i16"),
        Type::Int32 => String::from("i32"),
        Type::Int64 => String::from("i64"),
        Type::UInt8 => String::from("u8"),
        Type::UInt16 => String::from("u16"),
        Type::UInt32 => String::from("u32"),
        Type::UInt64 => String::from("u64"),
        Type::String => String::from("alloc::string::String"),
        Type::Bytes => String::from("alloc::vec::Vec<u8>"),
        Type::Ordering => String::from("core::cmp::Ordering"),
        Type::Bool => String::from("bool"),
        Type::Named(n) => format!("crate::{}", rust_ident(last_component(n))),
        Type::Option(inner) => format!("Option<{}>", type_to_rust(inner)?),
        Type::Result { ok, error } => {
            format!("Result<{}, {}>", type_to_rust(ok)?, type_to_rust(error)?)
        }
        Type::Tuple(items) => {
            let mut rendered = Vec::with_capacity(items.len());
            for item in items {
                rendered.push(type_to_rust(item)?);
            }
            format!("({})", rendered.join(", "))
        }
        Type::Opaque(s) => return Err(Error::OpaqueType(s.clone())),
        // A top-level list parameter/return still uses the allocation-free
        // slice/buffer ABI. Nested list values are explicit owned data and
        // therefore use `Vec` in generated Cargo packages.
        Type::List(inner) => format!("alloc::vec::Vec<{}>", type_to_rust(inner)?),
        Type::Vec(inner) => {
            return Err(Error::HeapType(format!(
                "(Vec {})",
                type_to_rust(inner).unwrap_or_else(|_| String::from("_"))
            )))
        }
    })
}

/// Rust spelling of a parameter type: a top-level list borrows as a slice.
///
/// Checks named types against the module's type table first: parameter and
/// return types are not fields, so [`check_field_type`] never sees them, and
/// without this check an undeclared `(named ...)` in a signature would
/// silently render as `crate::Whatever` instead of being rejected.
fn param_type_to_rust(
    ty: &Type,
    table: &TypeTable,
    returns_boolean: bool,
) -> Result<String, Error> {
    check_named_type(ty, table)?;
    if borrowed_parameter(ty, table, returns_boolean) {
        match ty {
            Type::String => Ok(String::from("&str")),
            Type::Bytes => Ok(String::from("&[u8]")),
            Type::List(inner) => Ok(format!("&[{}]", type_to_rust(inner)?)),
            _ => Ok(format!("&{}", type_to_rust(ty)?)),
        }
    } else {
        type_to_rust(ty)
    }
}

fn borrowed_parameter(ty: &Type, table: &TypeTable, returns_boolean: bool) -> bool {
    matches!(ty, Type::List(_))
        || matches!(ty, Type::Named(_)) && !copy_type(ty, table, &mut BTreeSet::new())
        || returns_boolean && matches!(ty, Type::String | Type::Bytes)
}

/// A `(named ...)` type occurring in a definition's signature must be
/// declared in the module's type table, at any depth (inside `Option`,
/// `List`, `Vec`, or `Tuple`); otherwise it has no known Rust rendering.
fn check_named_type(ty: &Type, table: &TypeTable) -> Result<(), Error> {
    match ty {
        Type::Named(n) => {
            if table.contains_key(n.as_str()) {
                Ok(())
            } else {
                Err(Error::OpaqueType(n.clone()))
            }
        }
        Type::Option(inner) | Type::Vec(inner) | Type::List(inner) => {
            check_named_type(inner, table)
        }
        Type::Result { ok, error } => {
            check_named_type(ok, table)?;
            check_named_type(error, table)
        }
        Type::Tuple(items) => {
            for item in items {
                check_named_type(item, table)?;
            }
            Ok(())
        }
        _ => Ok(()),
    }
}

/// The element type of a list return type.
fn list_element(ty: &Type) -> Result<&Type, Error> {
    match ty {
        Type::List(inner) => Ok(inner),
        _ => Err(Error::UnsupportedList(
            "expected a list return type".to_string(),
        )),
    }
}

/// Join-point analysis for one definition body (two-pass jp/jmp lowering).
struct JpContext<'a> {
    /// name → (params, body) of each `jp` declaration in the body
    decls: BTreeMap<&'a str, (&'a [String], &'a Expr)>,
    /// name → total number of `jmp` sites in the body
    jmp_counts: BTreeMap<&'a str, usize>,
}

impl<'a> JpContext<'a> {
    fn collect(body: &'a Expr) -> Self {
        let mut ctx = JpContext {
            decls: BTreeMap::new(),
            jmp_counts: BTreeMap::new(),
        };
        ctx.walk(body);
        ctx
    }

    fn walk(&mut self, expr: &'a Expr) {
        // Record decls and counts, then recurse into every subexpression.
        match expr {
            Expr::Jp { name, params, body } => {
                self.decls.insert(name.as_str(), (params, body));
            }
            Expr::Jmp(name, _) => {
                *self.jmp_counts.entry(name.as_str()).or_insert(0) += 1;
            }
            _ => {}
        }
        for child in expr.children() {
            self.walk(child);
        }
    }

    fn jmp_count(&self, name: &str) -> usize {
        self.jmp_counts.get(name).copied().unwrap_or(0)
    }

    /// A join point is cyclic if a jump to it occurs inside its own body.
    fn is_cyclic(&self, name: &str) -> bool {
        match self.decls.get(name) {
            Some((_, body)) => count_jmps(body, name) > 0,
            None => false,
        }
    }

    /// Inlineable: at least one caller, and not self-referential.
    ///
    /// LCNF uses multi-caller join points as shared continuations for ordinary
    /// matches. Duplicating an acyclic pure continuation at each jump is
    /// allocation-free and preserves the expression result.
    fn is_inlineable(&self, name: &str) -> bool {
        self.jmp_count(name) > 0 && !self.is_cyclic(name)
    }
}

/// Number of `jmp <name>` sites within `expr`.
fn count_jmps(expr: &Expr, name: &str) -> usize {
    let self_count = match expr {
        Expr::Jmp(n, _) if n == name => 1,
        _ => 0,
    };
    self_count + expr.children().map(|c| count_jmps(c, name)).sum::<usize>()
}

/// Where the expression being rendered will land.
///
/// The two modes share one traversal: control flow (`if`, `let`, `cases`)
/// is rendered identically and simply propagates the mode into its branches,
/// while the leaves differ.
enum Mode<'x, 'm> {
    /// Ordinary value position. The rendered text has the expression's own
    /// Rust type, with `?` embedded wherever an operation can fail.
    Value,
    /// List builder position. The rendered text has type
    /// `Result<usize, crate::ComputeError>` and fills `out`.
    Builder {
        /// The `&mut [T]` expression this list is written into.
        out: &'x str,
        /// `let`-bound list values in scope, innermost last. LCNF emits lists
        /// in A-normal form, so cons cells arrive as chains of `let`s rather
        /// than as one nested expression.
        env: &'x [(&'m str, &'m Expr)],
        /// Nesting depth, used to keep generated temporaries unique.
        depth: usize,
    },
}

struct Renderer<'s, 'm> {
    shapes: &'s Signatures<'m>,
    definitions: &'m [Definition],
    params: &'m [(String, Type)],
    ctx: JpContext<'m>,
    types: &'s TypeTable<'m>,
    /// Non-`Copy` LCNF `let` bindings referenced more than once.
    ///
    /// Lean values are immutable and may be shared freely. Rust record
    /// construction consumes owned fields, so an LCNF common subexpression
    /// such as one `String` used by two fields must be cloned at each use.
    /// Restricting this to repeated, known non-`Copy` locals keeps the
    /// allocation-free scalar/slice profile unchanged.
    clone_locals: BTreeSet<String>,
    /// Closed polymorphic empty constructors cannot share one inferred Rust
    /// local across differently monomorphized uses.
    inline_values: BTreeMap<String, &'m Expr>,
}

impl<'m> Renderer<'_, 'm> {
    fn value(&self, expr: &'m Expr) -> Result<String, Error> {
        self.render(expr, &Mode::Value)
    }

    fn resolved_inline(&self, expr: &'m Expr) -> &'m Expr {
        match expr {
            Expr::Var(name) => self
                .inline_values
                .get(name)
                .map_or(expr, |value| self.resolved_inline(value)),
            _ => expr,
        }
    }

    fn is_empty_list(&self, expr: &Expr) -> bool {
        match expr {
            Expr::Ctor(name, arguments) => name == "List.nil" && arguments.is_empty(),
            Expr::Var(name) => self
                .inline_values
                .get(name)
                .is_some_and(|value| self.is_empty_list(value)),
            _ => false,
        }
    }

    fn list_head_is_copy(&self, scrutinee: &Expr) -> bool {
        let Expr::Var(name) = scrutinee else {
            return true;
        };
        self.params
            .iter()
            .find_map(|(parameter, ty)| {
                (parameter == name).then_some(ty).and_then(|ty| match ty {
                    Type::List(element) => {
                        Some(copy_type(element, self.types, &mut BTreeSet::new()))
                    }
                    _ => None,
                })
            })
            .unwrap_or(true)
    }

    /// The declaration of a constructor, by its full Lean name.
    fn ctor_decl(&self, name: &str) -> Option<(&'m TypeDecl, &'m CtorDecl)> {
        self.types.values().find_map(|decl| {
            decl.ctors
                .iter()
                .find(|c| c.name == name)
                .map(|c| (*decl, c))
        })
    }

    fn shape_of(&self, name: &str) -> Option<Shape> {
        self.shapes.get(name).copied()
    }

    /// Return the declared type of a projected structure field.
    ///
    /// LCNF lowers a structure accessor returning `List T` to a projection in
    /// a `let`, rather than to a cons chain.  The list still has an existing
    /// owner (the structure argument), so it can be copied into the caller's
    /// output buffer without allocating.
    fn projection_field_type(&self, ty: &str, field: &str) -> Option<&'m Type> {
        self.types.get(ty).and_then(|declaration| {
            declaration
                .ctors
                .iter()
                .flat_map(|constructor| constructor.fields.iter())
                .find_map(|(name, ty)| (name == field).then_some(ty))
        })
    }

    fn render_call_args(&self, name: &str, args: &'m [Expr]) -> Result<Vec<String>, Error> {
        let definition = self
            .definitions
            .iter()
            .find(|definition| definition.name == name);
        args.iter()
            .enumerate()
            .map(|(index, argument)| {
                let argument = self.resolved_inline(argument);
                match definition.and_then(|definition| {
                    definition.params.get(index).map(|(_, ty)| {
                        (
                            ty,
                            borrowed_parameter(ty, self.types, definition.ret == Type::Bool),
                        )
                    })
                }) {
                    Some((Type::String, true)) if matches!(argument, Expr::String(_)) => {
                        let Expr::String(value) = argument else {
                            unreachable!()
                        };
                        Ok(format!("{value:?}"))
                    }
                    Some((Type::String | Type::Bytes, true)) => {
                        let rendered = self.value(argument)?;
                        Ok(format!("({rendered}).as_ref()"))
                    }
                    Some((_, true)) => {
                        let rendered = self.value(argument)?;
                        Ok(format!("&({rendered})"))
                    }
                    _ => self.value(argument),
                }
            })
            .collect()
    }

    /// Is this expression a list value (and therefore only renderable in
    /// builder position or as a `let` binding resolved through `env`)?
    fn is_list_valued(&self, expr: &Expr, env: &[(&'m str, &'m Expr)]) -> bool {
        match expr {
            Expr::Ctor(name, _) => name == "List.nil" || name == "List.cons",
            Expr::Call(name, _) => matches!(
                self.shape_of(name),
                Some(Shape::Buffer) | Some(Shape::StaticList)
            ),
            Expr::Var(name) => {
                lookup(env, name).is_some()
                    || self
                        .params
                        .iter()
                        .any(|(parameter, ty)| parameter == name && matches!(ty, Type::List(_)))
            }
            Expr::Proj(ty, field, _) => {
                matches!(self.projection_field_type(ty, field), Some(Type::List(_)))
            }
            _ => false,
        }
    }

    fn render(&self, expr: &'m Expr, mode: &Mode<'_, 'm>) -> Result<String, Error> {
        match expr {
            // ---- control flow: identical in both modes ----
            Expr::If(cond, t, f) => Ok(format!(
                "if {} {{ {} }} else {{ {} }}",
                self.value(cond)?,
                self.render(t, mode)?,
                self.render(f, mode)?
            )),
            Expr::Let(name, _, body) if self.inline_values.contains_key(name) => {
                self.render(body, mode)
            }
            Expr::Let(name, value, body)
                if count_var_uses(body, name) == 0
                    && !matches!(value.as_ref(), Expr::Jp { .. }) =>
            {
                self.render(body, mode)
            }
            Expr::Let(name, val, body) => match mode {
                Mode::Builder { out, env, depth } if self.is_list_valued(val, env) => {
                    // A list binding has no runtime representation to emit;
                    // record it and resolve uses through the environment.
                    let mut extended = env.to_vec();
                    extended.push((name.as_str(), val));
                    self.render(
                        body,
                        &Mode::Builder {
                            out,
                            env: &extended,
                            depth: *depth,
                        },
                    )
                }
                _ => Ok(format!(
                    "{{ let {} = {}; {} }}",
                    rust_local_ident(name),
                    self.value(val)?,
                    self.render(body, mode)?
                )),
            },
            Expr::Match {
                scrut,
                alts,
                default,
            } => self.render_match(scrut, alts, default.as_deref(), mode),

            // ---- list-shaped leaves ----
            Expr::Ctor(name, args) if name == "List.nil" && args.is_empty() => match mode {
                // Turbofished: an empty list is the one builder leaf that
                // constrains neither type parameter on its own, and it can
                // appear under a `?` (as the tail of a cons).
                Mode::Builder { .. } => Ok(String::from("Ok::<usize, crate::ComputeError>(0)")),
                Mode::Value => Ok(String::from("alloc::vec::Vec::new()")),
            },
            Expr::Ctor(name, args) if name == "List.cons" && args.len() == 2 => match mode {
                Mode::Builder { out, env, depth } => {
                    self.render_cons(&args[0], &args[1], out, env, *depth)
                }
                Mode::Value if self.is_empty_list(&args[1]) => {
                    Ok(format!("alloc::vec![{}]", self.value(&args[0])?))
                }
                Mode::Value => Ok(format!(
                    "{{ let mut __list = alloc::vec![{}]; __list.extend({}); __list }}",
                    self.value(&args[0])?,
                    self.value(&args[1])?
                )),
            },

            // ---- everything else ----
            Expr::Var(name) if self.inline_values.contains_key(name) => {
                self.render(self.inline_values[name], mode)
            }
            Expr::Var(name) => match mode {
                Mode::Builder { out, env, .. } => match lookup(env, name) {
                    Some(bound) => self.render(bound, mode),
                    None if self.params.iter().any(|(parameter, ty)| {
                        parameter == name && matches!(ty, Type::List(_))
                    }) =>
                    {
                        let source = rust_local_ident(name);
                        Ok(format!(
                            "if {source}.len() > ({out}).len() {{ Err(crate::ComputeError::OutputTooSmall) }} else {{ let __len = {source}.len(); ({out})[..__len].copy_from_slice({source}); Ok(__len) }}"
                        ))
                    }
                    None => Err(Error::UnsupportedList(format!(
                        "`{}` is not a list built in this definition",
                        name
                    ))),
                },
                Mode::Value if self.clone_locals.contains(name) => {
                    Ok(format!("{}.clone()", rust_local_ident(name)))
                }
                Mode::Value => Ok(rust_local_ident(name)),
            },
            Expr::Call(name, args) => {
                let rendered = self.render_call_args(name, args)?;
                match (mode, self.shape_of(name)) {
                    (Mode::Builder { out, .. }, Some(Shape::Buffer)) => {
                        // The callee writes straight into our remaining buffer
                        // and reports how much of it it used.
                        let mut all = rendered;
                        all.push((*out).to_string());
                        Ok(format!("{}({})", name, all.join(", ")))
                    }
                    (Mode::Builder { .. }, _) => Err(Error::UnsupportedList(format!(
                        "`{}` does not build its list into a caller buffer",
                        name
                    ))),
                    (Mode::Value, Some(Shape::Buffer)) => Err(Error::UnsupportedList(format!(
                        "`{}` returns a list; its result cannot be used as an intermediate value",
                        name
                    ))),
                    (Mode::Value, Some(Shape::Fallible)) => {
                        Ok(format!("{}({})?", name, rendered.join(", ")))
                    }
                    (Mode::Value, _) => Ok(format!("{}({})", name, rendered.join(", "))),
                }
            }

            // A list field already has owned storage in its enclosing value.
            // Copy its elements into the caller-provided buffer, just as a
            // top-level borrowed list parameter is copied.  `clone_from_slice`
            // preserves the generic generated-type contract without requiring
            // list elements to be `Copy`, and performs no allocation.
            Expr::Proj(ty, field, _) if matches!(mode, Mode::Builder { .. }) => {
                if !matches!(self.projection_field_type(ty, field), Some(Type::List(_))) {
                    return Err(Error::UnsupportedList(format!(
                        "`{}.{}` is not a list field",
                        ty, field
                    )));
                }
                let Mode::Builder { out, .. } = mode else {
                    unreachable!()
                };
                let source = self.value(expr)?;
                Ok(format!(
                    "{{ let __source = &({source}); if __source.len() > ({out}).len() {{ Err(crate::ComputeError::OutputTooSmall) }} else {{ let __len = __source.len(); ({out})[..__len].clone_from_slice(__source); Ok(__len) }} }}"
                ))
            }

            // An unresolved callee: refuse it outright rather than rendering
            // a call to a function nobody generated, in either mode.
            Expr::Extern(name, _) => Err(Error::UnresolvedCall(name.clone())),

            // Remaining nodes are value-typed; reaching them in builder mode
            // means the IR put a non-list where a list was declared.
            _ => match mode {
                Mode::Builder { .. } => Err(Error::UnsupportedList(
                    "expression does not build a list".to_string(),
                )),
                Mode::Value => self.render_value_leaf(expr),
            },
        }
    }

    fn render_value_leaf(&self, expr: &'m Expr) -> Result<String, Error> {
        match expr {
            Expr::Nat(n) => Ok(format!("{}", n)),
            Expr::Int(n) => Ok(format!("{}", n)),
            Expr::String(value) => Ok(format!(
                "alloc::string::String::from({value:?})"
            )),
            Expr::Bool(b) => Ok(format!("{}", b)),
            Expr::Param(index) => self
                .params
                .get(*index)
                .map(|(name, _)| rust_local_ident(name))
                .ok_or(Error::ParamOutOfBounds(*index)),
            Expr::Add(a, b) => self.checked_binop(a, b, "checked_add", "AddOverflow"),
            Expr::Mul(a, b) => self.checked_binop(a, b, "checked_mul", "MulOverflow"),
            Expr::CheckedAdd(a, b) => Ok(format!(
                "({}).checked_add({})",
                self.value(a)?,
                self.value(b)?
            )),
            Expr::CheckedSub(a, b) => Ok(format!(
                "({}).checked_sub({})",
                self.value(a)?,
                self.value(b)?
            )),
            Expr::CheckedMul(a, b) => Ok(format!(
                "({}).checked_mul({})",
                self.value(a)?,
                self.value(b)?
            )),
            Expr::CheckedNeg(value) => Ok(format!("({}).checked_neg()", self.value(value)?)),
            Expr::CheckedDiv(a, b) => Ok(format!(
                "({}).checked_div({})",
                self.value(a)?,
                self.value(b)?
            )),
            Expr::BitAnd(a, b) => self.binop(a, b, "&"),
            Expr::BitOr(a, b) => self.binop(a, b, "|"),
            Expr::BitXor(a, b) => self.binop(a, b, "^"),
            Expr::BitNot(value) => Ok(format!("!({})", self.value(value)?)),
            Expr::CheckedShl(a, b) => Ok(format!(
                "({}).checked_shl({})",
                self.value(a)?,
                self.value(b)?
            )),
            Expr::CheckedShr(a, b) => Ok(format!(
                "({}).checked_shr({})",
                self.value(a)?,
                self.value(b)?
            )),
            Expr::CheckedConvert(value) => Ok(format!(
                "core::convert::TryFrom::try_from({}).ok()",
                self.value(value)?
            )),
            Expr::Append(left, right) => Ok(format!(
                "{{ let mut __value = {}; __value.extend_from_slice(&{}); __value }}",
                self.value(left)?,
                self.value(right)?
            )),
            Expr::Length(value) => Ok(format!("({}).len() as u64", self.value(value)?)),
            Expr::Index(value, offset) => Ok(format!(
                "usize::try_from({}).ok().and_then(|__index| ({}).get(__index).cloned())",
                self.value(offset)?,
                self.value(value)?
            )),
            Expr::Slice(value, start, count) => Ok(format!(
                "{{ let __start = usize::try_from({}).ok(); let __count = usize::try_from({}).ok(); match (__start, __count) {{ (Some(__start), Some(__count)) => __start.checked_add(__count).and_then(|__end| ({}).get(__start..__end).map(|__slice| __slice.to_vec())), _ => None }} }}",
                self.value(start)?,
                self.value(count)?,
                self.value(value)?
            )),
            Expr::Utf8Encode(value) => Ok(format!("({}).into_bytes()", self.value(value)?)),
            Expr::Utf8Decode(value) => Ok(format!(
                "alloc::string::String::from_utf8({}).ok()",
                self.value(value)?
            )),
            Expr::CompareBytes(left, right) => Ok(format!(
                "({}).cmp(&{})",
                self.value(left)?,
                self.value(right)?
            )),
            Expr::SplitExact(value, delimiter, maximum) => Ok(format!(
                "{{ let __value = {}; let __delimiter = {}; let __maximum = usize::try_from({}).ok(); if __delimiter.is_empty() {{ None }} else {{ let __fields: alloc::vec::Vec<alloc::string::String> = __value.split(&__delimiter).map(alloc::string::String::from).collect(); __maximum.filter(|__maximum| __fields.len() <= *__maximum).map(|_| __fields) }} }}",
                self.value(value)?,
                self.value(delimiter)?,
                self.value(maximum)?
            )),
            Expr::Join(values, delimiter) => Ok(format!(
                "({}).join(&{})",
                self.value(values)?,
                self.value(delimiter)?
            )),
            Expr::ParseDecimal(value) => Ok(format!(
                "{{ let __text = {}; __text.parse().ok().filter(|__value| alloc::string::ToString::to_string(__value) == __text) }}",
                self.value(value)?
            )),
            Expr::FormatDecimal(value) => {
                Ok(format!("alloc::format!(\"{{}}\", {})", self.value(value)?))
            }
            Expr::Quotient(left, right, zero) => Ok(format!(
                "if {} == 0 {{ {} }} else {{ {} / {} }}",
                self.value(right)?,
                self.value(zero)?,
                self.value(left)?,
                self.value(right)?
            )),
            Expr::Remainder(left, right, zero) => Ok(format!(
                "if {} == 0 {{ {} }} else {{ {} % {} }}",
                self.value(right)?,
                self.value(zero)?,
                self.value(left)?,
                self.value(right)?
            )),
            Expr::Negate(value) => Ok(format!("-({})", self.value(value)?)),
            Expr::Sub(a, b) => {
                // Lean Nat subtraction truncates at zero, so it is total.
                // See `checked_binop` for the `as u64` receiver pin.
                Ok(format!(
                    "(({}) as u64).saturating_sub({})",
                    self.value(a)?,
                    self.value(b)?
                ))
            }
            Expr::Div(a, b) => self.total_binop(a, b, "/"),
            Expr::Mod(a, b) => self.total_binop(a, b, "%"),
            Expr::Shl(a, b) => self.checked_exponent_op(
                a,
                b,
                "checked_shl",
                "ShiftExponentTooLarge",
                "ShiftOverflow",
            ),
            // Unlike `Shl`, `Nat.shiftRight` is total and infallible: Lean's
            // `Nat` is unbounded, so `a >>> b = 0` for any `b >= 64` once `a`
            // fits `u64`. `checked_shr` already returns `None` exactly there
            // (and for `b >= 2^32`, via the `try_from` fallback to
            // `u32::MAX`), so `unwrap_or(0)` is the exact answer, not a
            // fallback for a real error — there is no `ComputeError` variant
            // for this because none is needed.
            Expr::Shr(a, b) => Ok(format!(
                "(({}) as u64).checked_shr(u32::try_from({}).unwrap_or(u32::MAX)).unwrap_or(0)",
                self.value(a)?,
                self.value(b)?
            )),
            Expr::Pow(a, b) => {
                self.checked_exponent_op(a, b, "checked_pow", "PowExponentTooLarge", "PowOverflow")
            }
            Expr::Eq(a, b) => match (
                self.resolved_inline(a.as_ref()),
                self.resolved_inline(b.as_ref()),
            ) {
                (other, Expr::String(value)) | (Expr::String(value), other) => {
                    Ok(format!("{} == {value:?}", self.value(other)?))
                }
                _ => self.binop(a, b, "=="),
            },
            Expr::Lt(a, b) => self.binop(a, b, "<"),
            Expr::Le(a, b) => self.binop(a, b, "<="),
            Expr::Gt(a, b) => self.binop(a, b, ">"),
            Expr::Ctor(name, args) => {
                let args = self.render_args(args)?;
                if name == "Prod.mk" {
                    Ok(format!("({})", args.join(", ")))
                } else if name == "Bool.true" && args.is_empty() {
                    Ok(String::from("true"))
                } else if name == "Bool.false" && args.is_empty() {
                    Ok(String::from("false"))
                } else if name == "Option.none" && args.is_empty() {
                    Ok(String::from("None"))
                } else if name == "Option.some" && args.len() == 1 {
                    Ok(format!("Some({})", args[0]))
                } else if name == "Except.ok" && args.len() == 1 {
                    Ok(format!("Ok({})", args[0]))
                } else if name == "Except.error" && args.len() == 1 {
                    Ok(format!("Err({})", args[0]))
                } else if let Some((decl, cdecl)) = self.ctor_decl(name) {
                    if args.len() != cdecl.fields.len() {
                        return Err(Error::UnsupportedFieldType(format!(
                            "`{}` takes {} field(s) but got {} argument(s)",
                            name,
                            cdecl.fields.len(),
                            args.len()
                        )));
                    }
                    let path = if decl.ctors.len() == 1 {
                        format!("crate::{}", rust_ident(last_component(&decl.name)))
                    } else {
                        format!(
                            "crate::{}::{}",
                            rust_ident(last_component(&decl.name)),
                            rust_ident(last_component(&cdecl.name))
                        )
                    };
                    if cdecl.fields.is_empty() {
                        Ok(path)
                    } else {
                        let mut bound = Vec::with_capacity(args.len());
                        for ((field, _), arg) in cdecl.fields.iter().zip(args.iter()) {
                            bound.push(format!("{}: {}", rust_ident(field), arg));
                        }
                        Ok(format!("{} {{ {} }}", path, bound.join(", ")))
                    }
                } else if name.contains('.') {
                    // No declaration for this constructor, and its Lean name
                    // is dotted. The tuple-style fallthrough below would emit
                    // the dots verbatim — `Conformance.NoProp.mk(n, n)` — and
                    // that is not a Rust path in expression position; it
                    // parses as field access on a value named `Conformance`,
                    // so even `syn::parse_str` waves it through and the
                    // failure surfaces as a rustc error about the generated
                    // file. Refuse it here, naming the constructor. The
                    // bare-name form below stays: a dot-free ctor is at least
                    // a syntactically valid path to a type the host may
                    // supply by hand.
                    Err(Error::UnresolvedCall(name.clone()))
                } else if args.is_empty() {
                    Ok(name.clone())
                } else {
                    Ok(format!("{}({})", name, args.join(", ")))
                }
            }
            Expr::Proj(ty, field, e) => {
                let field_type = self.projection_field_type(ty, field);
                if self.types.contains_key(ty.as_str()) && field_type.is_none() {
                    return Err(Error::UnknownField(ty.clone(), field.clone()));
                }
                let projection = format!("({}).{}", self.value(e)?, rust_ident(field));
                if field_type.is_some_and(|field_type| {
                    !copy_type(field_type, self.types, &mut BTreeSet::new())
                }) {
                    Ok(format!("&{projection}"))
                } else {
                    Ok(projection)
                }
            }
            Expr::Jp { name, body, .. } => {
                if self.ctx.jmp_count(name) == 0 {
                    // No jump sites: the declaration is just a block.
                    Ok(format!(
                        "{{ /* jp \"{}\": no jump sites */ {} }}",
                        name,
                        self.value(body)?
                    ))
                } else if self.ctx.is_inlineable(name) {
                    // Inlined at its single jump site; nothing to emit here.
                    Ok(format!("/* jp \"{}\" inlined at its jump site */ ()", name))
                } else {
                    // Cyclic. This used to emit a `loop {}`
                    // skeleton with a "manual port required" comment, which is
                    // not Rust that compiles: the join point's parameters are
                    // never bound, and each jump site has type `()` where the
                    // arm needs a value. Emitting it at exit 0 is exactly the
                    // silently-broken-output failure this crate rejects
                    // everywhere else, so it is a rejection now.
                    Err(Error::UnsupportedJoinPoint(name.clone()))
                }
            }
            Expr::Jmp(name, args) => match self.ctx.decls.get(name.as_str()) {
                Some((jp_params, body)) if self.ctx.is_inlineable(name) => {
                    let mut out = String::from("{ ");
                    for (p, a) in jp_params.iter().zip(args.iter()) {
                        out.push_str(&format!(
                            "let {} = {}; ",
                            rust_local_ident(p),
                            self.value(a)?
                        ));
                    }
                    out.push_str(&self.value(body)?);
                    out.push_str(" }");
                    Ok(out)
                }
                // The declaration site rejects this too; rejecting here as
                // well means the error names the jump the reader can see,
                // whichever of the two codegen reaches first.
                Some(_) => Err(Error::UnsupportedJoinPoint(name.clone())),
                None => Ok(format!(
                    "/* jmp \"{}\": no matching jp declaration */ ()",
                    name
                )),
            },
            Expr::Unreachable => Ok(String::from("unreachable!()")),
            Expr::Opaque(s) => Err(Error::OpaqueExpr(s.clone())),
            // Handled by `render` before it delegates here.
            Expr::If(..)
            | Expr::Let(..)
            | Expr::Match { .. }
            | Expr::Var(_)
            | Expr::Call(..)
            | Expr::Extern(..) => {
                unreachable!("control-flow nodes are rendered by `render`")
            }
        }
    }

    /// `List.cons head tail` in builder position: take one element off the
    /// front of the buffer, write the head, and recurse the tail into what is
    /// left. `split_first_mut` makes exhaustion an `Err` rather than an index
    /// panic, so the generated code has no bounds-check panic path at all.
    fn render_cons(
        &self,
        head: &'m Expr,
        tail: &'m Expr,
        out: &str,
        env: &[(&'m str, &'m Expr)],
        depth: usize,
    ) -> Result<String, Error> {
        let head = self.value(head)?;
        let (slot, rest_buf) = (format!("__head{}", depth), format!("__rest{}", depth));
        let rest = self.render(
            tail,
            &Mode::Builder {
                out: &rest_buf,
                env,
                depth: depth + 1,
            },
        )?;
        Ok(format!(
            "match ({}).split_first_mut() {{ None => Err(crate::ComputeError::OutputTooSmall), Some(({}, {})) => {{ *{} = {}; let __len{} = {}?; Ok(__len{} + 1) }} }}",
            out, slot, rest_buf, slot, head, depth, rest, depth
        ))
    }

    fn render_match(
        &self,
        scrut: &'m Expr,
        alts: &'m [Alt],
        default: Option<&'m Expr>,
        mode: &Mode<'_, 'm>,
    ) -> Result<String, Error> {
        let head_is_copy = self.list_head_is_copy(scrut);
        let scrut = self.value(scrut)?;
        let mut out = format!("match {} {{\n", scrut);
        for alt in alts {
            let body = self.render(&alt.body, mode)?;
            let arm = match (alt.ctor.as_str(), alt.binders.len()) {
                // LCNF structural recursion on Nat cases: `Nat.zero` is the
                // literal `0`; `Nat.succ k` binds the predecessor. Since the
                // zero arm matches first, the succ arm's scrutinee is ≥ 1 and
                // `saturating_sub(1)` is the exact predecessor (and stays
                // within the crate's bounded-Nat policy).
                ("Nat.zero", 0) => format!("        0 => {},\n", body),
                ("Nat.succ", 1) => format!(
                    "        _ => {{ let {} = ({}).saturating_sub(1); {} }},\n",
                    rust_local_ident(&alt.binders[0]),
                    scrut,
                    body
                ),
                // Lists are slices: the empty and non-empty slice patterns are
                // exhaustive, and the tail binds as a sub-slice at no cost.
                // Match ergonomics bind the head by reference; rebind it by
                // value so arithmetic on it needs no dereference syntax.
                ("List.nil", 0) => format!("        [] => {},\n", body),
                ("List.cons", 2) if head_is_copy => format!(
                    "        [{}, {} @ ..] => {{ let {} = {}.clone(); {} }},\n",
                    rust_local_ident(&alt.binders[0]),
                    rust_local_ident(&alt.binders[1]),
                    rust_local_ident(&alt.binders[0]),
                    rust_local_ident(&alt.binders[0]),
                    body
                ),
                ("List.cons", 2) => format!(
                    "        [{}, {} @ ..] => {},\n",
                    rust_local_ident(&alt.binders[0]),
                    rust_local_ident(&alt.binders[1]),
                    body
                ),
                ("Bool.true", 0) => format!("        true => {},\n", body),
                ("Bool.false", 0) => format!("        false => {},\n", body),
                ("Option.none", 0) => format!("        None => {},\n", body),
                ("Option.some", 1) => format!(
                    "        Some({}) => {},\n",
                    rust_local_ident(&alt.binders[0]),
                    body
                ),
                ("Except.ok", 1) => format!(
                    "        Ok({}) => {},\n",
                    rust_local_ident(&alt.binders[0]),
                    body
                ),
                ("Except.error", 1) => format!(
                    "        Err({}) => {},\n",
                    rust_local_ident(&alt.binders[0]),
                    body
                ),
                _ => match self.ctor_decl(&alt.ctor) {
                    Some((decl, cdecl)) if alt.binders.len() == cdecl.fields.len() => {
                        let path = if decl.ctors.len() == 1 {
                            format!("crate::{}", rust_ident(last_component(&decl.name)))
                        } else {
                            format!(
                                "crate::{}::{}",
                                rust_ident(last_component(&decl.name)),
                                rust_ident(last_component(&cdecl.name))
                            )
                        };
                        if cdecl.fields.is_empty() {
                            format!("        {} => {},\n", path, body)
                        } else {
                            let mut bound = Vec::with_capacity(alt.binders.len());
                            for ((field, _), binder) in cdecl.fields.iter().zip(alt.binders.iter())
                            {
                                bound.push(format!(
                                    "{}: {}",
                                    rust_ident(field),
                                    rust_local_ident(binder)
                                ));
                            }
                            format!("        {} {{ {} }} => {},\n", path, bound.join(", "), body)
                        }
                    }
                    // Declared, but the alt's binder count does not match the
                    // constructor's field count: this must be rejected, not
                    // rendered. Falling through to the positional arms below
                    // would emit a dotted name used as a Rust path with
                    // positional fields — e.g. `M.Shape.circle(r, extra)` —
                    // which does not compile. Symmetric with the arity check
                    // on the construction side.
                    Some((_, cdecl)) => {
                        return Err(Error::UnsupportedFieldType(format!(
                            "`{}` takes {} field(s) but got {} binder(s)",
                            alt.ctor,
                            cdecl.fields.len(),
                            alt.binders.len()
                        )));
                    }
                    None if alt.binders.is_empty() => {
                        format!("        {} => {},\n", alt.ctor, body)
                    }
                    None => format!(
                        "        {}({}) => {},\n",
                        alt.ctor,
                        alt.binders
                            .iter()
                            .map(|binder| rust_local_ident(binder))
                            .collect::<Vec<_>>()
                            .join(", "),
                        body
                    ),
                },
            };
            out.push_str(&arm);
        }
        if let Some(d) = default {
            out.push_str(&format!("        _ => {},\n", self.render(d, mode)?));
        }
        out.push_str("    }");
        Ok(out)
    }

    /// Flatten a constant `List.cons`/`List.nil` chain into array elements for
    /// a promoted `&'static [T]`. Only `let`-bound list values are followed;
    /// anything computed belongs in builder mode instead.
    fn static_list(
        &self,
        expr: &'m Expr,
        env: &[(&'m str, &'m Expr)],
        items: &mut Vec<String>,
    ) -> Result<(), Error> {
        match expr {
            Expr::Var(name) => match lookup(env, name) {
                Some(bound) => self.static_list(bound, env, items),
                None => Err(Error::UnsupportedList(format!(
                    "`{}` is not a constant list",
                    name
                ))),
            },
            Expr::Let(name, val, body) if self.is_list_valued(val, env) => {
                let mut extended = env.to_vec();
                extended.push((name.as_str(), val));
                self.static_list(body, &extended, items)
            }
            Expr::Ctor(name, args) if name == "List.nil" && args.is_empty() => Ok(()),
            Expr::Ctor(name, args) if name == "List.cons" && args.len() == 2 => {
                items.push(self.value(&args[0])?);
                self.static_list(&args[1], env, items)
            }
            _ => Err(Error::UnsupportedList(
                "zero-argument list definitions must be constant cons chains".to_string(),
            )),
        }
    }

    fn render_args(&self, args: &'m [Expr]) -> Result<Vec<String>, Error> {
        args.iter().map(|a| self.value(a)).collect()
    }

    fn binop(&self, a: &'m Expr, b: &'m Expr, op: &str) -> Result<String, Error> {
        Ok(format!("({} {} {})", self.value(a)?, op, self.value(b)?))
    }

    /// `checked_add`/`checked_mul`: report overflow instead of panicking.
    ///
    /// `as u64` pins the receiver: method calls on an inferred `{integer}`
    /// (a let-bound literal, e.g. LCNF's `let _x := 1`) fail method resolution
    /// (E0689) — a no-op when the receiver is already `u64`.
    fn checked_binop(
        &self,
        a: &'m Expr,
        b: &'m Expr,
        method: &str,
        error: &str,
    ) -> Result<String, Error> {
        Ok(format!(
            "(({}) as u64).{}({}).ok_or(crate::ComputeError::{})?",
            self.value(a)?,
            method,
            self.value(b)?,
            error
        ))
    }

    /// `checked_shl`/`checked_pow`: the exponent must also narrow to `u32`,
    /// which is a second, distinct failure mode.
    fn checked_exponent_op(
        &self,
        a: &'m Expr,
        b: &'m Expr,
        method: &str,
        exponent_error: &str,
        overflow_error: &str,
    ) -> Result<String, Error> {
        Ok(format!(
            "(({}) as u64).{}(u32::try_from({}).map_err(|_| crate::ComputeError::{})?).ok_or(crate::ComputeError::{})?",
            self.value(a)?,
            method,
            self.value(b)?,
            exponent_error,
            overflow_error
        ))
    }

    /// Lean Nat division and modulo are total: `x / 0 = x % 0 = 0`.
    fn total_binop(&self, a: &'m Expr, b: &'m Expr, op: &str) -> Result<String, Error> {
        let (a, b) = (self.value(a)?, self.value(b)?);
        Ok(format!(
            "if ({}) == 0 {{ 0 }} else {{ ({}) {} ({}) }}",
            b, a, op, b
        ))
    }
}

/// Innermost-first lookup in a builder-mode list environment.
fn lookup<'m>(env: &[(&'m str, &'m Expr)], name: &str) -> Option<&'m Expr> {
    env.iter()
        .rev()
        .find(|(bound, _)| *bound == name)
        .map(|(_, value)| *value)
}

#[cfg(test)]
mod tests;
