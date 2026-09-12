//! C ABI artifacts for the scalar subset of generated Rust.
//!
//! This is intentionally separate from the Rust printer. The Rust printer
//! remains the source of truth for the implementation, while this module
//! emits the C declaration and a matching `extern "C"` adapter. Unsupported
//! shapes are omitted from the artifact with an explanatory header comment.

use super::{last_component, rust_ident, signatures, Shape};
use alloc::collections::BTreeSet;
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use core::fmt;
use prod_ir::{Definition, Module, Type};

/// The generated C header and the Rust source that implements its functions.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CBindings {
    pub header: String,
    pub rust: String,
    pub(crate) functions: Vec<FunctionSpec>,
}

/// One scalar function in the generated C ABI. Other SDK printers consume
/// this metadata so their names and status/result shapes cannot drift from
/// the C header.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct FunctionSpec {
    pub(crate) definition: String,
    pub(crate) params: Vec<(String, Scalar)>,
    pub(crate) ret: Scalar,
    pub(crate) shape: Shape,
    pub(crate) c_name: String,
}

pub(crate) fn rust_abi_type(scalar: Scalar) -> &'static str {
    scalar.rust_abi_type()
}

pub(crate) fn is_bool(scalar: Scalar) -> bool {
    scalar == Scalar::Bool
}

/// A C ABI request that cannot be represented safely by the scalar adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CAbiError {
    UnsupportedType { definition: String, ty: String },
    UnsupportedDefinition { definition: String, reason: String },
    NameCollision { name: String },
}

impl fmt::Display for CAbiError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::UnsupportedType { definition, ty } => write!(
                f,
                "C ABI only supports scalar Nat, Int64, and Bool values: `{}` in `{}`",
                ty, definition
            ),
            Self::UnsupportedDefinition { definition, reason } => {
                write!(f, "cannot generate C ABI for `{}`: {}", definition, reason)
            }
            Self::NameCollision { name } => {
                write!(f, "C ABI name collision after sanitizing `{}`", name)
            }
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Scalar {
    Nat,
    Int,
    Bool,
}

impl Scalar {
    fn c_type(self) -> &'static str {
        match self {
            Self::Nat => "uint64_t",
            Self::Int => "int64_t",
            // C callers pass 0 or 1. This avoids depending on the size of
            // Rust's `bool` in the public ABI.
            Self::Bool => "uint8_t",
        }
    }

    fn rust_abi_type(self) -> &'static str {
        match self {
            Self::Nat => "u64",
            Self::Int => "i64",
            Self::Bool => "u8",
        }
    }

    fn zero(self) -> &'static str {
        "0"
    }
}

fn scalar(definition: &Definition, ty: &Type) -> Result<Scalar, CAbiError> {
    match ty {
        Type::Nat => Ok(Scalar::Nat),
        Type::Int64 => Ok(Scalar::Int),
        Type::Bool => Ok(Scalar::Bool),
        other => Err(CAbiError::UnsupportedType {
            definition: definition.name.clone(),
            ty: format!("{:?}", other),
        }),
    }
}

/// Convert a Lean name into a stable, valid C identifier. Full names are
/// retained so namespaces do not silently collide.
fn c_name(name: &str) -> String {
    let mut out = String::from("prod_");
    let mut previous_separator = false;
    for ch in name.chars() {
        if ch.is_ascii_alphanumeric() {
            out.push(ch.to_ascii_lowercase());
            previous_separator = false;
        } else if !previous_separator {
            out.push('_');
            previous_separator = true;
        }
    }
    while out.ends_with('_') {
        out.pop();
    }
    out
}

fn rust_arg(scalar: Scalar, name: &str) -> String {
    match scalar {
        Scalar::Bool => format!("{} != 0", name),
        Scalar::Nat | Scalar::Int => String::from(name),
    }
}

fn c_value(scalar: Scalar, value: &str) -> String {
    match scalar {
        Scalar::Bool => format!("if {} {{ 1 }} else {{ 0 }}", value),
        Scalar::Nat | Scalar::Int => String::from(value),
    }
}

fn status_match() -> &'static str {
    "match error {
        crate::ComputeError::AddOverflow => 1,
        crate::ComputeError::MulOverflow => 2,
        crate::ComputeError::ShiftOverflow => 3,
        crate::ComputeError::PowOverflow => 4,
        crate::ComputeError::ShiftExponentTooLarge => 5,
        crate::ComputeError::PowExponentTooLarge => 6,
        crate::ComputeError::OutputTooSmall => 7,
    }"
}

fn header_guard(module: &str) -> String {
    let mut guard = String::from("LEAN4_PROD_");
    for ch in module.chars() {
        if ch.is_ascii_alphanumeric() {
            guard.push(ch.to_ascii_uppercase());
        } else {
            guard.push('_');
        }
    }
    guard.push_str("_H");
    guard
}

/// Generate a C header and matching Rust `extern "C"` wrappers.
///
/// The first ABI is deliberately scalar-only: `Nat`/`Int`/`Bool` parameters
/// and returns. A fallible definition returns a C-compatible result record
/// whose `status` is zero on success and whose `value` is meaningful only on
/// success. Lists need a buffer/length ownership contract, and generated
/// structs/enums need an explicit layout policy; those are separate ABI
/// designs rather than implicit extensions of this one.
pub fn generate_c_bindings(module: &Module) -> Result<CBindings, CAbiError> {
    let shapes = signatures(&module.definitions);
    let mut names = BTreeSet::new();
    let mut entries = Vec::new();
    let mut skipped = Vec::new();

    for def in &module.definitions {
        let shape = shapes
            .get(def.name.as_str())
            .copied()
            .unwrap_or(Shape::Value);
        if !matches!(shape, Shape::Value | Shape::Fallible) {
            skipped.push(format!(
                "{} (list functions require an explicit caller-owned buffer ABI)",
                def.name
            ));
            continue;
        }

        let params: Vec<Scalar> = match def
            .params
            .iter()
            .map(|(_, ty)| scalar(def, ty))
            .collect::<Result<_, _>>()
        {
            Ok(params) => params,
            Err(error) => {
                skipped.push(error.to_string());
                continue;
            }
        };
        let ret = match scalar(def, &def.ret) {
            Ok(ret) => ret,
            Err(error) => {
                skipped.push(error.to_string());
                continue;
            }
        };
        let qualified_name = format!("{}.{}", module.name, def.name);
        let name = c_name(&qualified_name);
        if !names.insert(name.clone()) {
            return Err(CAbiError::NameCollision { name });
        }
        entries.push((def, shape, params, ret, name));
    }

    if entries.is_empty() {
        let reason = skipped
            .first()
            .cloned()
            .unwrap_or_else(|| String::from("module contains no definitions"));
        return Err(CAbiError::UnsupportedDefinition {
            definition: module.name.clone(),
            reason,
        });
    }

    let functions: Vec<FunctionSpec> = entries
        .iter()
        .map(|(def, shape, params, ret, name)| FunctionSpec {
            definition: def.name.clone(),
            params: def
                .params
                .iter()
                .zip(params.iter())
                .map(|((name, _), scalar)| (name.clone(), *scalar))
                .collect(),
            ret: *ret,
            shape: *shape,
            c_name: name.clone(),
        })
        .collect();

    let guard = header_guard(&module.name);
    let mut header = format!(
        "/* Generated from Lean 4 module: {}. Do not edit. */\n#ifndef {}\n#define {}\n\n#include <stdint.h>\n\n",
        module.name, guard, guard
    );
    header.push_str(
        "/* Boolean arguments and results use uint8_t: 0 is false, nonzero is true. */\n",
    );
    if !skipped.is_empty() {
        header.push_str("/* Definitions omitted from this scalar ABI: */\n");
        for definition in &skipped {
            header.push_str("/* - ");
            header.push_str(definition);
            header.push_str(" */\n");
        }
    }
    header.push_str("typedef int32_t prod_status_t;\n");
    header.push_str(
        "enum {\n  PROD_STATUS_OK = 0,\n  PROD_STATUS_ADD_OVERFLOW = 1,\n  PROD_STATUS_MUL_OVERFLOW = 2,\n  PROD_STATUS_SHIFT_OVERFLOW = 3,\n  PROD_STATUS_POW_OVERFLOW = 4,\n  PROD_STATUS_SHIFT_EXPONENT_TOO_LARGE = 5,\n  PROD_STATUS_POW_EXPONENT_TOO_LARGE = 6,\n  PROD_STATUS_OUTPUT_TOO_SMALL = 7\n};\n\n",
    );

    let mut rust =
        String::from("// Generated C ABI wrappers for Lean 4 definitions. Do not edit.\n\n");
    for (def, shape, params, ret, name) in entries {
        let rust_fn = rust_ident(last_component(&def.name));
        let args: Vec<String> = def
            .params
            .iter()
            .zip(params.iter())
            .map(|((param, _), scalar)| format!("{}: {}", param, scalar.rust_abi_type()))
            .collect();
        let c_args: Vec<String> = def
            .params
            .iter()
            .zip(params.iter())
            .map(|((param, _), scalar)| format!("{} {}", scalar.c_type(), param))
            .collect();
        let call_args: Vec<String> = def
            .params
            .iter()
            .zip(params.iter())
            .map(|((param, _), scalar)| rust_arg(*scalar, param))
            .collect();
        let c_signature = if c_args.is_empty() {
            String::from("void")
        } else {
            c_args.join(", ")
        };
        let call = if call_args.is_empty() {
            format!("{}()", rust_fn)
        } else {
            format!("{}({})", rust_fn, call_args.join(", "))
        };

        match shape {
            Shape::Value => {
                header.push_str(&format!("{} {}({});\n", ret.c_type(), name, c_signature));
                rust.push_str(&format!(
                    "#[no_mangle]\npub extern \"C\" fn {}({}) -> {} {{\n    {}\n}}\n\n",
                    name,
                    args.join(", "),
                    ret.rust_abi_type(),
                    c_value(ret, &call)
                ));
            }
            Shape::Fallible => {
                let result_name = format!("ProdFfi_{}_Result", name);
                let result_c_name = format!("{}_result_t", name);
                header.push_str(&format!(
                    "typedef struct {} {{ prod_status_t status; {} value; }} {};\n",
                    name,
                    ret.c_type(),
                    result_c_name
                ));
                header.push_str(&format!("{} {}({});\n", result_c_name, name, c_signature));
                rust.push_str(&format!(
                    "#[repr(C)]\n#[derive(Debug, Clone, Copy)]\npub struct {} {{\n    pub status: i32,\n    pub value: {},\n}}\n\n#[no_mangle]\npub extern \"C\" fn {}({}) -> {} {{\n    match {} {{\n        Ok(value) => {} {{ status: 0, value: {} }},\n        Err(error) => {} {{ status: {}, value: {} }},\n    }}\n}}\n\n",
                    result_name,
                    ret.rust_abi_type(),
                    name,
                    args.join(", "),
                    result_name,
                    call,
                    result_name,
                    c_value(ret, "value"),
                    result_name,
                    status_match(),
                    ret.zero()
                ));
            }
            Shape::Buffer | Shape::StaticList => unreachable!(),
        }
    }
    header.push_str("\n#endif /* ");
    header.push_str(&guard);
    header.push_str(" */\n");

    Ok(CBindings {
        header,
        rust,
        functions,
    })
}
