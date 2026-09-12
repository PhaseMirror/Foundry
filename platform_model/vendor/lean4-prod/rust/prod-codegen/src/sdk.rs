//! Language bindings over the generated scalar C ABI.
//!
//! These artifacts are adapters around the compiled Rust library. They do
//! not reimplement Lean functions in each language; all execution remains in
//! the generated Rust/C ABI library, with each SDK handling its language's
//! calling convention and scalar conversions.

use super::c_abi::{generate_c_bindings, is_bool, rust_abi_type, FunctionSpec};
use super::{last_component, rust_ident, CAbiError, CBindings, Shape};
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use prod_ir::Module;

/// The generated files for one exported IR module.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SdkBindings {
    pub c_header: String,
    pub c_wrapper: String,
    pub rust: String,
    pub python: String,
    pub typescript: String,
    pub kotlin: String,
    /// Generated wasm-bindgen Rust source. The CLI packages this source into
    /// `.wasm`, `.js`, and `.d.ts` artifacts with `wasm-pack`.
    pub wasm: String,
}

fn result_name(spec: &FunctionSpec) -> String {
    format!("ProdFfi_{}_Result", spec.c_name)
}

fn rust_return(spec: &FunctionSpec) -> String {
    if spec.shape == Shape::Fallible {
        // The native declarations live in a nested module while the result
        // structs are public items at the SDK root.
        format!("super::{}", result_name(spec))
    } else {
        String::from(rust_abi_type(spec.ret))
    }
}

fn rust_public_type(spec: &FunctionSpec) -> &'static str {
    if is_bool(spec.ret) {
        "bool"
    } else {
        rust_abi_type(spec.ret)
    }
}

fn rust_params(spec: &FunctionSpec) -> String {
    spec.params
        .iter()
        .map(|(name, scalar)| {
            format!(
                "{}: {}",
                name,
                if is_bool(*scalar) {
                    "bool"
                } else {
                    rust_abi_type(*scalar)
                }
            )
        })
        .collect::<Vec<_>>()
        .join(", ")
}

fn rust_native_params(spec: &FunctionSpec) -> String {
    spec.params
        .iter()
        .map(|(name, scalar)| format!("{}: {}", name, rust_abi_type(*scalar)))
        .collect::<Vec<_>>()
        .join(", ")
}

fn rust_call_args(spec: &FunctionSpec) -> String {
    spec.params
        .iter()
        .map(|(name, scalar)| {
            if is_bool(*scalar) {
                format!("if {} {{ 1 }} else {{ 0 }}", name)
            } else {
                name.clone()
            }
        })
        .collect::<Vec<_>>()
        .join(", ")
}

fn rust_value(spec: &FunctionSpec, value: &str) -> String {
    if is_bool(spec.ret) {
        format!("({}) != 0", value)
    } else {
        String::from(value)
    }
}

fn python_type(scalar: super::c_abi::Scalar) -> &'static str {
    match scalar {
        super::c_abi::Scalar::Nat => "ctypes.c_uint64",
        super::c_abi::Scalar::Int => "ctypes.c_int64",
        super::c_abi::Scalar::Bool => "ctypes.c_uint8",
    }
}

fn typescript_type(scalar: super::c_abi::Scalar) -> &'static str {
    if is_bool(scalar) {
        "boolean"
    } else {
        // BigInt is required: JavaScript Number cannot represent all u64/i64
        // values without losing precision.
        "bigint"
    }
}

fn kotlin_type(scalar: super::c_abi::Scalar) -> &'static str {
    match scalar {
        super::c_abi::Scalar::Nat | super::c_abi::Scalar::Int => "Long",
        super::c_abi::Scalar::Bool => "Byte",
    }
}

fn generate_rust(specs: &[FunctionSpec], library: &str) -> String {
    let mut out =
        String::from("//! Generated Rust SDK for a Lean 4 library.\n#![allow(unsafe_code)]\n\n");
    for spec in specs {
        if spec.shape == Shape::Fallible {
            out.push_str(&format!(
                "#[repr(C)]\n#[derive(Debug, Clone, Copy)]\npub struct {} {{\n    pub status: i32,\n    pub value: {},\n}}\n\n",
                result_name(spec),
                rust_abi_type(spec.ret)
            ));
        }
    }
    out.push_str(&format!(
        "mod native {{\n    #[link(name = \"{}\")]\n    extern \"C\" {{\n",
        library
    ));
    for spec in specs {
        out.push_str(&format!(
            "        pub fn {}({}) -> {};\n",
            spec.c_name,
            rust_native_params(spec),
            rust_return(spec)
        ));
    }
    out.push_str("    }\n}\n\n");
    for spec in specs {
        let params = rust_params(spec);
        let call_args = rust_call_args(spec);
        let call = format!("unsafe {{ {}::{}({}) }}", "self", spec.c_name, call_args);
        // The generated module is deliberately named `native`, so the
        // wrapper never collides with the public function names.
        let call = call.replace("self::", "native::");
        if spec.shape == Shape::Fallible {
            out.push_str(&format!(
                "pub fn {}({}) -> Result<{}, i32> {{\n    let raw = {};\n    if raw.status == 0 {{ Ok({}) }} else {{ Err(raw.status) }}\n}}\n\n",
                spec.c_name,
                params,
                rust_public_type(spec),
                call,
                rust_value(spec, "raw.value")
            ));
        } else {
            out.push_str(&format!(
                "pub fn {}({}) -> {} {{\n    {}\n}}\n\n",
                spec.c_name,
                params,
                rust_public_type(spec),
                rust_value(spec, &call)
            ));
        }
    }
    out
}

fn generate_python(specs: &[FunctionSpec]) -> String {
    let mut out = String::from(
        "\"\"\"Generated ctypes SDK for a Lean 4 scalar library.\"\"\"\nimport ctypes\n\nPROD_STATUS_OK = 0\n\n",
    );
    for spec in specs {
        if spec.shape == Shape::Fallible {
            out.push_str(&format!(
                "class {}(ctypes.Structure):\n    _fields_ = [(\"status\", ctypes.c_int32), (\"value\", {})]\n\n",
                result_name(spec),
                python_type(spec.ret)
            ));
        }
    }
    out.push_str("def load_library(path):\n    return ctypes.CDLL(path)\n\n");
    for spec in specs {
        let args = spec
            .params
            .iter()
            .map(|(_, scalar)| python_type(*scalar))
            .collect::<Vec<_>>()
            .join(", ");
        let call_args = spec
            .params
            .iter()
            .map(|(name, scalar)| {
                if is_bool(*scalar) {
                    format!("1 if {} else 0", name)
                } else {
                    name.clone()
                }
            })
            .collect::<Vec<_>>()
            .join(", ");
        let signature = spec
            .params
            .iter()
            .map(|(n, _)| n.as_str())
            .collect::<Vec<_>>()
            .join(", ");
        let signature = if signature.is_empty() {
            String::from("lib")
        } else {
            format!("lib, {}", signature)
        };
        out.push_str(&format!("def {}({}):\n", spec.c_name, signature));
        out.push_str(&format!(
            "    fn = lib.{}\n    fn.argtypes = [{}]\n    fn.restype = {}\n    raw = fn({})\n",
            spec.c_name,
            args,
            if spec.shape == Shape::Fallible {
                result_name(spec)
            } else {
                python_type(spec.ret).to_string()
            },
            call_args
        ));
        if spec.shape == Shape::Fallible {
            out.push_str(&format!("    if raw.status != PROD_STATUS_OK:\n        raise RuntimeError(\"{} failed with status {{}}\".format(raw.status))\n    return {}\n\n", spec.definition, if is_bool(spec.ret) { "bool(raw.value)" } else { "raw.value" }));
        } else {
            out.push_str(&format!(
                "    return {}\n\n",
                if is_bool(spec.ret) {
                    "bool(raw)"
                } else {
                    "raw"
                }
            ));
        }
    }
    out
}

fn generate_typescript(specs: &[FunctionSpec]) -> String {
    let mut out = String::from(
        "// Generated TypeScript binding. Supply functions from a native loader\n// such as koffi or ffi-napi through `bind`.\nexport type NativeScalar = bigint | number;\nexport type NativeArgument = NativeScalar;\nexport type NativeResult = { status: number; value: NativeScalar };\nexport type NativeLibrary = Record<string, (...args: NativeArgument[]) => NativeScalar | NativeResult>;\n\nexport const PROD_STATUS_OK = 0;\n\n",
    );
    for spec in specs {
        if spec.shape == Shape::Fallible {
            out.push_str(&format!(
                "export type {} = {{ status: number; value: NativeScalar }};\n",
                result_name(spec)
            ));
        }
    }
    out.push_str("\nexport interface Lean4ProdApi {\n");
    for spec in specs {
        out.push_str(&format!(
            "  {}({}): {};\n",
            spec.c_name,
            spec.params
                .iter()
                .map(|(n, s)| format!("{}: {}", n, typescript_type(*s)))
                .collect::<Vec<_>>()
                .join(", "),
            typescript_type(spec.ret)
        ));
    }
    out.push_str("}\n\nexport function bind(native: NativeLibrary): Lean4ProdApi {\n  return {\n");
    for spec in specs {
        let args = spec
            .params
            .iter()
            .map(|(n, _)| n.clone())
            .collect::<Vec<_>>()
            .join(", ");
        let native_args = spec
            .params
            .iter()
            .map(|(n, s)| {
                if is_bool(*s) {
                    format!("{} ? 1 : 0", n)
                } else {
                    n.clone()
                }
            })
            .collect::<Vec<_>>()
            .join(", ");
        out.push_str(&format!(
            "    {}: ({}) => {{\n      const raw = native[\"{}\"]({}) as any;\n",
            spec.c_name, args, spec.c_name, native_args
        ));
        if spec.shape == Shape::Fallible {
            out.push_str(&format!("      if (raw.status !== PROD_STATUS_OK) throw new Error(\"{} failed with status \" + raw.status);\n      return {};\n    }},\n", spec.definition, if is_bool(spec.ret) { "Number(raw.value) !== 0" } else { "BigInt(raw.value)" }));
        } else {
            out.push_str(&format!(
                "      return {};\n    }},\n",
                if is_bool(spec.ret) {
                    "Number(raw) !== 0"
                } else {
                    "BigInt(raw)"
                }
            ));
        }
    }
    out.push_str("  };\n}\n");
    out
}

fn kotlin_class_name(spec: &FunctionSpec) -> String {
    format!(
        "{}Result",
        spec.c_name
            .replace('_', " ")
            .split_whitespace()
            .map(|word| {
                let mut chars = word.chars();
                match chars.next() {
                    Some(first) => first.to_ascii_uppercase().to_string() + chars.as_str(),
                    None => String::new(),
                }
            })
            .collect::<String>()
    )
}

fn generate_kotlin(specs: &[FunctionSpec], library: &str) -> String {
    let mut out = String::from("// Generated Kotlin/JNA binding for a Lean 4 scalar library.\nimport com.sun.jna.Library\nimport com.sun.jna.Native\nimport com.sun.jna.Structure\n\n");
    for spec in specs {
        if spec.shape == Shape::Fallible {
            out.push_str(&format!("class {} : Structure(), Structure.ByValue {{\n    @JvmField var status: Int = 0\n    @JvmField var value: {} = {}\n    override fun getFieldOrder(): List<String> = listOf(\"status\", \"value\")\n}}\n\n", kotlin_class_name(spec), kotlin_type(spec.ret), if is_bool(spec.ret) { "0" } else { "0L" }));
        }
    }
    out.push_str("interface Lean4ProdNative : Library {\n");
    for spec in specs {
        out.push_str(&format!(
            "    fun {}({}): {}\n",
            spec.c_name,
            spec.params
                .iter()
                .map(|(n, s)| format!("{}: {}", n, kotlin_type(*s)))
                .collect::<Vec<_>>()
                .join(", "),
            if spec.shape == Shape::Fallible {
                kotlin_class_name(spec)
            } else {
                kotlin_type(spec.ret).to_string()
            }
        ));
    }
    out.push_str(&format!("}}\n\nobject Lean4Prod {{\n    @JvmStatic fun load(path: String): Lean4ProdNative = Native.load(path, Lean4ProdNative::class.java)\n    const val DEFAULT_LIBRARY = \"{}\"\n}}\n\n", library));
    for spec in specs {
        let ret = if spec.shape == Shape::Fallible {
            format!(
                "Result<{}>",
                if is_bool(spec.ret) { "Boolean" } else { "Long" }
            )
        } else {
            if is_bool(spec.ret) {
                "Boolean".to_string()
            } else {
                "Long".to_string()
            }
        };
        let params = spec
            .params
            .iter()
            .map(|(n, s)| format!("{}: {}", n, if is_bool(*s) { "Boolean" } else { "Long" }))
            .collect::<Vec<_>>()
            .join(", ");
        let args = spec
            .params
            .iter()
            .map(|(n, s)| {
                if is_bool(*s) {
                    format!("if ({}) 1 else 0", n)
                } else {
                    n.clone()
                }
            })
            .collect::<Vec<_>>()
            .join(", ");
        out.push_str(&format!(
            "fun Lean4ProdNative.safe_{}({}): {} {{\n    val raw = {}({})\n",
            spec.c_name, params, ret, spec.c_name, args
        ));
        if spec.shape == Shape::Fallible {
            out.push_str(&format!("    return if (raw.status == 0) Result.success({}) else Result.failure(IllegalStateException(\"{} failed with status ${{raw.status}}\"))\n}}\n\n", if is_bool(spec.ret) { "raw.value.toInt() != 0" } else { "raw.value" }, spec.definition));
        } else {
            out.push_str(&format!(
                "    return {}\n}}\n\n",
                if is_bool(spec.ret) {
                    "raw.toInt() != 0"
                } else {
                    "raw"
                }
            ));
        }
    }
    out
}

fn wasm_error_helper() -> &'static str {
    r#"fn __prod_compute_error(error: crate::ComputeError) -> JsValue {
    JsValue::from_str(match error {
        crate::ComputeError::AddOverflow => "addition overflow",
        crate::ComputeError::MulOverflow => "multiplication overflow",
        crate::ComputeError::ShiftOverflow => "shift overflow",
        crate::ComputeError::PowOverflow => "power overflow",
        crate::ComputeError::ShiftExponentTooLarge => "shift exponent too large",
        crate::ComputeError::PowExponentTooLarge => "power exponent too large",
        crate::ComputeError::OutputTooSmall => "output buffer too small",
    })
}

"#
}

fn generate_wasm(module: &Module, specs: &[FunctionSpec]) -> Result<String, CAbiError> {
    let body =
        super::generate_module(module).map_err(|error| CAbiError::UnsupportedDefinition {
            definition: module.name.clone(),
            reason: format!("wasm codegen: {error}"),
        })?;
    let mut out = String::from(
        "// Generated wasm-bindgen SDK for a Lean 4 library.\n#![allow(unsafe_code)]\n\nuse wasm_bindgen::prelude::*;\n\n#[derive(Debug, Clone, Copy, PartialEq, Eq)]\npub enum ComputeError {\n    AddOverflow,\n    MulOverflow,\n    ShiftOverflow,\n    PowOverflow,\n    ShiftExponentTooLarge,\n    PowExponentTooLarge,\n    OutputTooSmall,\n}\n\n",
    );
    out.push_str(wasm_error_helper());
    out.push_str(&body);
    for spec in specs {
        let rust_name = rust_ident(last_component(&spec.definition));
        let wrapper_name = format!("__wasm_{}", spec.c_name);
        let params = spec
            .params
            .iter()
            .map(|(name, scalar)| {
                format!(
                    "{}: {}",
                    name,
                    if is_bool(*scalar) {
                        "bool"
                    } else {
                        rust_abi_type(*scalar)
                    }
                )
            })
            .collect::<Vec<_>>()
            .join(", ");
        let args = spec
            .params
            .iter()
            .map(|(name, _)| name.as_str())
            .collect::<Vec<_>>()
            .join(", ");
        let return_type = rust_public_type(spec);
        if spec.shape == Shape::Fallible {
            out.push_str(&format!(
                "#[wasm_bindgen(js_name = \"{}\")]\npub fn {}({}) -> Result<{}, JsValue> {{\n    {}({}).map_err(__prod_compute_error)\n}}\n\n",
                spec.c_name, wrapper_name, params, return_type, rust_name, args
            ));
        } else {
            out.push_str(&format!(
                "#[wasm_bindgen(js_name = \"{}\")]\npub fn {}({}) -> {} {{\n    {}({})\n}}\n\n",
                spec.c_name, wrapper_name, params, return_type, rust_name, args
            ));
        }
    }
    Ok(out)
}

/// Generate all supported language SDK artifacts over the common C ABI.
pub fn generate_sdks(module: &Module, library: &str) -> Result<SdkBindings, CAbiError> {
    let c: CBindings = generate_c_bindings(module)?;
    let wasm = generate_wasm(module, &c.functions)?;
    Ok(SdkBindings {
        c_header: c.header,
        c_wrapper: c.rust,
        rust: generate_rust(&c.functions, library),
        python: generate_python(&c.functions),
        typescript: generate_typescript(&c.functions),
        kotlin: generate_kotlin(&c.functions, library),
        wasm,
    })
}
