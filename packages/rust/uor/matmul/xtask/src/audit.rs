//! The grep-shaped gates.
//!
//! These are crude on purpose. A gate that needs interpretation is a gate that
//! gets argued with; these ones read the source, find a token, and fail. Each
//! carries the rule it enforces in its failure message, because the point of a
//! red gate is to name the promise that was broken.

use std::path::{Path, PathBuf};

use uor_matmul_model::Model;

use crate::Fail;

/// The crates that ship. The rules below apply to these and not to the
/// dev-and-CI-only crates, which may use `std`, `alloc`, and floats freely.
const SHIPPED: &[&str] = &[
    "uor-matmul",
    "uor-matmul-core",
    "uor-matmul-codec",
    "uor-matmul-kernels",
    "uor-matmul-gemm",
];

/// Files where a numeral may appear without deriving from the model:
/// the generated output itself, and the model-facing gates.
const NUMERAL_ALLOWLIST: &[&str] = &["generated.rs"];

struct Source {
    path: PathBuf,
    rel: String,
    text: String,
}

fn shipped_sources(root: &Path) -> Result<Vec<Source>, Fail> {
    let mut out = Vec::new();
    for name in SHIPPED {
        let dir = root.join("crates").join(name).join("src");
        if !dir.exists() {
            continue;
        }
        collect(&dir, root, &mut out)?;
    }
    Ok(out)
}

fn collect(dir: &Path, root: &Path, out: &mut Vec<Source>) -> Result<(), Fail> {
    for entry in std::fs::read_dir(dir)? {
        let path = entry?.path();
        if path.is_dir() {
            collect(&path, root, out)?;
        } else if path.extension().is_some_and(|e| e == "rs") {
            let text = std::fs::read_to_string(&path)?;
            let rel = path
                .strip_prefix(root)
                .unwrap_or(&path)
                .display()
                .to_string();
            out.push(Source { path, rel, text });
        }
    }
    Ok(())
}

/// Lines of `text` outside comments and outside `#[cfg(test)]` modules.
///
/// A rule about what the library *does* must not be tripped by a doc comment
/// explaining what it does not do, nor by a test that deliberately constructs
/// the forbidden thing to prove it is caught.
fn effective_lines(text: &str) -> Vec<(usize, &str)> {
    let mut out = Vec::new();
    let mut in_test = false;
    let mut test_depth = 0i32;
    let mut depth = 0i32;
    for (i, raw) in text.lines().enumerate() {
        let line = raw.trim();
        if line.starts_with("//") || line.starts_with("#!") {
            // A `#![deny(...)]` or a comment states policy; it never is the
            // behaviour the gate is looking for.
            continue;
        }
        let opens = raw.matches('{').count() as i32;
        let closes = raw.matches('}').count() as i32;
        if line.starts_with("#[cfg(test)]") {
            in_test = true;
            test_depth = depth;
        }
        if !in_test {
            let code = line.split("//").next().unwrap_or("");
            if !code.trim().is_empty() {
                out.push((i + 1, code));
            }
        }
        depth += opens - closes;
        if in_test && depth <= test_depth && closes > 0 {
            in_test = false;
        }
    }
    out
}

/// R1: no magic numeral. Every constant derives by `const fn` from the declared
/// tuple, and `133144` appears only inside a `const _: () = assert!(...)` pin.
pub fn check_constants(root: &Path) -> Result<(), Fail> {
    let model = Model::load(&root.join("model"))?;
    let sources = shipped_sources(root)?;

    // Every narrow threshold's numeral, and every instantiation bound, may
    // appear only in the generated file or inside a const-assert pin.
    let mut pinned: Vec<String> = Vec::new();
    for t in &model.constants.narrow.threshold {
        pinned.push(t.k_max.to_string());
        pinned.push(t.per_step.to_string());
    }

    let mut violations = Vec::new();
    for src in &sources {
        if NUMERAL_ALLOWLIST.iter().any(|a| src.path.ends_with(a)) {
            continue;
        }
        for (line_no, line) in effective_lines(&src.text) {
            if line.contains("const _: () = assert!") {
                continue;
            }
            for numeral in &pinned {
                // Numerals below four digits are ubiquitous and carry no claim
                // (`2`, `64`, `128` are widths, not model constants).
                if numeral.len() < 4 {
                    continue;
                }
                if contains_numeral(line, numeral) {
                    violations.push(format!(
                        "{}:{line_no}: the numeral {numeral} is a model constant\n    {}",
                        src.rel,
                        line.trim()
                    ));
                }
            }
        }
    }

    if !violations.is_empty() {
        return Err(format!(
            "R1: no magic numeral. Every constant derives by const fn from the declared \
             tuple, and a model numeral appears only in the generated file or inside a \
             `const _: () = assert!(...)` pin.\n\n{}",
            violations.join("\n")
        )
        .into());
    }
    println!("check-constants: no model numeral is restated in the shipped crates (R1)");
    Ok(())
}

/// Does `line` contain `numeral` as a whole number rather than as a digit run
/// inside a longer one?
fn contains_numeral(line: &str, numeral: &str) -> bool {
    let bytes = line.as_bytes();
    let mut from = 0;
    while let Some(pos) = line[from..].find(numeral) {
        let start = from + pos;
        let end = start + numeral.len();
        let before_ok = start == 0 || !bytes[start - 1].is_ascii_digit();
        let after_ok = end >= bytes.len() || !bytes[end].is_ascii_digit();
        if before_ok && after_ok {
            return true;
        }
        from = start + 1;
    }
    false
}

/// R8: no arbitrary limitation. Every bound is a property of the caller's
/// chosen instantiation, never of the library.
///
/// Concretely: no shipped crate may return an error the model does not
/// sanction. §2's "there is no `CN-*` class" is checked here --- the absence of
/// negative testing is only honest if there is nothing to test negatively.
pub fn audit_limits(root: &Path) -> Result<(), Fail> {
    let sources = shipped_sources(root)?;
    // The only error type the library may name, plus the declaration check at
    // the alphabet boundary, which is not the operation failing (§5.2).
    let sanctioned = ["NotAProduct", "ObservedBound", "KappaError"];

    let mut violations = Vec::new();
    for src in &sources {
        for (line_no, line) in effective_lines(&src.text) {
            let Some(pos) = line.find("Result<") else {
                continue;
            };
            let tail = &line[pos..];
            if sanctioned.iter().any(|s| tail.contains(s)) {
                continue;
            }
            violations.push(format!("{}:{line_no}:{}", src.rel, line.trim()));
        }
    }
    if !violations.is_empty() {
        return Err(format!(
            "R8: every bound in the library is derived from declared parameters and is a \
             property of the caller's chosen instantiation. C6: the only reportable \
             condition is that the requested object does not exist, reported at view \
             construction. A `Result` over anything else is a limitation the model does \
             not sanction.\n\n{}",
            violations.join("\n")
        )
        .into());
    }
    println!("audit-limits: no shipped crate returns an unsanctioned error (R8, C6)");
    Ok(())
}

/// R13, `CU-01`, `CU-03`: one method. No float addition, no saturating or
/// rounding instruction in an accumulation, no lesser method held in reserve.
pub fn audit_purity(root: &Path) -> Result<(), Fail> {
    let sources = shipped_sources(root)?;

    // R2: no float *arithmetic* anywhere. `f32` and `f64` are permitted as
    // element types being decoded and as the target of the encode step; what is
    // forbidden is adding, subtracting, multiplying, or fusing two floats.
    //
    // This is the static half of the rule and it is deliberately crude. The
    // definitive gate is `CU-01`, which disassembles every shipped kernel and
    // looks for the opcodes themselves --- a source grep cannot see what the
    // optimizer emitted, and a rule this important should not rest on one.
    let mut violations = Vec::new();
    for src in &sources {
        for (line_no, line) in effective_lines(&src.text) {
            for tok in FLOAT_ARITHMETIC {
                if line.contains(tok) {
                    violations.push(format!(
                        "R2: {}:{line_no}: `{tok}` is float arithmetic\n    {}",
                        src.rel,
                        line.trim()
                    ));
                }
            }
            if let Some(op) = float_literal_arithmetic(line) {
                violations.push(format!(
                    "R2: {}:{line_no}: `{op}` applied to a float literal\n    {}",
                    src.rel,
                    line.trim()
                ));
            }
            // R3: no saturating or rounding instruction in an accumulation.
            // The single encode step is the only place information is
            // discarded. A saturating operation anywhere else must carry an
            // `R3-ok:` note saying why it is not an accumulation --- cursor
            // arithmetic on an index cannot change an output value, but a grep
            // cannot tell an index from an accumulator, so the author says so.
            for tok in ["saturating_add", "saturating_mul", "saturating_sub"] {
                if !line.contains(tok) {
                    continue;
                }
                // The note is a trailing comment, which `effective_lines` strips,
                // so the raw line is what carries it.
                let raw = src
                    .text
                    .lines()
                    .nth(line_no.saturating_sub(1))
                    .unwrap_or("");
                let in_encode_step = src.rel.contains("gemm") || raw.contains("R3-ok:");
                if !in_encode_step {
                    violations.push(format!(
                        "R3: {}:{line_no}: `{tok}` with no `R3-ok:` note\n    {}",
                        src.rel,
                        line.trim()
                    ));
                }
            }
            // R13: the vocabulary of a second method.
            for tok in ["fallback", "fast_path", "approximate", "good_enough"] {
                if contains_word(line, tok) {
                    violations.push(format!(
                        "R13: {}:{line_no}: `{tok}` names a second method\n    {}",
                        src.rel,
                        line.trim()
                    ));
                }
            }
        }
    }

    if !violations.is_empty() {
        return Err(format!(
            "R13: one method, no fallback. Every path in the library is \
             decode-then-accumulate-exactly; backends are factorizations of one identity, \
             not a quality hierarchy.\n\n{}",
            violations.join("\n")
        )
        .into());
    }
    println!("audit-purity: one method; no float arithmetic, no second-best (R2, R3, R13)");
    Ok(())
}

/// Method names that can only be float arithmetic.
const FLOAT_ARITHMETIC: &[&str] = &[
    "mul_add",
    "powi",
    "powf",
    ".sqrt()",
    "f32::EPSILON",
    "f64::EPSILON",
    "to_degrees",
    "to_radians",
];

/// An arithmetic operator adjacent to a float literal.
///
/// Catches `x + 1.0` and `2.0 * y` without needing to know any types. A float
/// literal in the shipped crates is only ever a constant --- `0.0` for a zero
/// element --- so an operator next to one is arithmetic on a float.
fn float_literal_arithmetic(line: &str) -> Option<&'static str> {
    let bytes = line.as_bytes();
    for (i, w) in bytes.windows(2).enumerate() {
        // A float literal is a digit, a dot, then a digit.
        if w[0] != b'.' || !w[1].is_ascii_digit() {
            continue;
        }
        if i == 0 || !bytes[i - 1].is_ascii_digit() {
            continue;
        }
        // Scan outwards for an arithmetic operator on either side.
        // Skip back over the literal's integer part, or `before` ends with a
        // digit and no operator is ever seen.
        let mut b = i;
        while b > 0 && (bytes[b - 1].is_ascii_digit() || bytes[b - 1] == b'_') {
            b -= 1;
        }
        let before = line[..b].trim_end();
        let after = {
            let mut j = i + 1;
            while j < bytes.len() && (bytes[j].is_ascii_digit() || bytes[j] == b'_') {
                j += 1;
            }
            line[j.min(line.len())..].trim_start()
        };
        for (op, name) in [('+', "+"), ('-', "-"), ('*', "*"), ('/', "/")] {
            if before.ends_with(op) || after.starts_with(op) {
                return Some(name);
            }
        }
    }
    None
}

fn contains_word(line: &str, word: &str) -> bool {
    let bytes = line.as_bytes();
    let mut from = 0;
    while let Some(pos) = line[from..].find(word) {
        let start = from + pos;
        let end = start + word.len();
        let ident = |b: u8| b.is_ascii_alphanumeric() || b == b'_';
        let before_ok = start == 0 || !ident(bytes[start - 1]);
        let after_ok = end >= bytes.len() || !ident(bytes[end]);
        if before_ok && after_ok {
            return true;
        }
        from = start + 1;
    }
    false
}

/// R15: nothing is deferred. No `TODO`, no stub, no placeholder document
/// section, no capability behind a flag that turns it off, no "later version".
pub fn audit_deferral(root: &Path) -> Result<(), Fail> {
    let markers = [
        "TODO",
        "FIXME",
        "XXX",
        "unimplemented!",
        "todo!",
        "for now",
        "later version",
    ];
    let mut violations = Vec::new();

    let mut files: Vec<PathBuf> = Vec::new();
    for name in SHIPPED {
        let dir = root.join("crates").join(name);
        if dir.exists() {
            gather_all(&dir, &mut files)?;
        }
    }
    for doc in [
        "README.md",
        "ARCHITECTURE.md",
        "CONFORMANCE.md",
        "VERIFICATION.md",
    ] {
        let p = root.join(doc);
        if p.exists() {
            files.push(p);
        }
    }

    for path in files {
        let Ok(text) = std::fs::read_to_string(&path) else {
            continue;
        };
        let rel = path
            .strip_prefix(root)
            .unwrap_or(&path)
            .display()
            .to_string();
        for (i, line) in text.lines().enumerate() {
            for marker in markers {
                if !line.contains(marker) {
                    continue;
                }
                // A backticked marker is a *mention*, not a use: the
                // documentation has to be able to name what the gate catches
                // without tripping it. Anything outside code spans is real.
                if outside_code_spans(line, marker) {
                    violations.push(format!("{rel}:{}: {}", i + 1, line.trim()));
                }
            }
        }
    }

    if !violations.is_empty() {
        return Err(format!(
            "R15: nothing is deferred. No TODO, no stub, no placeholder section, no \
             capability behind a flag that turns it off, no 'later version'. Every \
             capability ships in the one release.\n\n{}",
            violations.join("\n")
        )
        .into());
    }
    println!("audit-deferral: nothing is deferred (R15)");
    Ok(())
}

/// Does `marker` occur in `line` outside every backtick-delimited span?
fn outside_code_spans(line: &str, marker: &str) -> bool {
    let mut rest = line;
    let mut at = 0usize;
    while let Some(pos) = rest.find(marker) {
        let absolute = at + pos;
        // An odd number of backticks before this occurrence means it is inside
        // a span.
        if line[..absolute].matches('`').count().is_multiple_of(2) {
            return true;
        }
        at = absolute + marker.len();
        rest = &line[at..];
    }
    false
}

fn gather_all(dir: &Path, out: &mut Vec<PathBuf>) -> Result<(), Fail> {
    for entry in std::fs::read_dir(dir)? {
        let path = entry?.path();
        if path.is_dir() {
            if path.file_name().is_some_and(|n| n == "target") {
                continue;
            }
            gather_all(&path, out)?;
        } else if path
            .extension()
            .is_some_and(|e| e == "rs" || e == "md" || e == "toml")
        {
            out.push(path);
        }
    }
    Ok(())
}

/// `CU-01`, R2: no float add, subtract, multiply, or FMA opcode appears in any
/// shipped kernel's disassembly.
///
/// The definitive form of R2. The source grep in [`audit_purity`] cannot see
/// what the optimizer emitted; this reads the assembly the compiler actually
/// produced and looks for the instructions themselves.
///
/// A kernel that computed a float sum would fail here even if it did so through
/// a helper the grep never saw, and that is the point: the rule is about the
/// machine code, so the check should be too.
///
/// What it deliberately does *not* catch is a float add the optimizer removed,
/// because such an add is not in the shipped kernel. That is the gate reporting
/// the binary rather than the source, which is the only thing worth reporting.
pub fn audit_disassembly(root: &Path) -> Result<(), Fail> {
    let out_dir = root.join("target").join("cu01-asm");
    std::fs::create_dir_all(&out_dir)?;

    let mut checked = 0usize;
    let mut violations = Vec::new();

    for krate in ["uor-matmul-kernels", "uor-matmul-core", "uor-matmul-gemm"] {
        let status = std::process::Command::new(env!("CARGO"))
            .current_dir(root)
            .args(["rustc", "--release", "-p", krate, "--lib", "--target-dir"])
            .arg(&out_dir)
            .args(["--", "--emit", "asm", "-C", "debuginfo=0"])
            .status()?;
        if !status.success() {
            return Err(format!("could not build {krate} for disassembly").into());
        }

        for path in asm_files(&out_dir)? {
            let Ok(text) = std::fs::read_to_string(&path) else {
                continue;
            };
            let name = path
                .file_name()
                .unwrap_or_default()
                .to_string_lossy()
                .to_string();
            if !name.starts_with(&krate.replace('-', "_")) {
                continue;
            }
            checked += 1;
            for (i, line) in text.lines().enumerate() {
                if let Some(op) = float_opcode(line.trim()) {
                    violations.push(format!("{name}:{}: `{op}`\n    {}", i + 1, line.trim()));
                }
            }
        }
    }

    if checked == 0 {
        return Err("CU-01 disassembled nothing; the gate would pass vacuously".into());
    }
    if !violations.is_empty() {
        return Err(format!(
            "R2, CU-01: the library never adds two floats. A float arithmetic opcode in a \
             shipped kernel means an accumulation is not exact, which breaks every claim in \
             §3.\n\n{}",
            violations.join("\n")
        )
        .into());
    }
    println!(
        "audit-disassembly: no float arithmetic opcode in {checked} shipped object(s) (CU-01)"
    );
    Ok(())
}

/// Float arithmetic opcodes, across the ISAs this workspace targets.
///
/// Conversions (`cvtsi2ss`, `scvtf`) and moves (`movss`, `fmov`) are *not*
/// here: decoding a float and encoding one back are exactly what the library
/// does, and forbidding them would forbid the operation rather than the defect.
/// What is forbidden is arithmetic *between* two floats.
const FLOAT_OPCODES: &[&str] = &[
    // x86
    "addss", "addsd", "addps", "addpd", "subss", "subsd", "subps", "subpd", "mulss", "mulsd",
    "mulps", "mulpd", "divss", "divsd", "divps", "divpd", "vaddss", "vaddsd", "vaddps", "vaddpd",
    "vsubss", "vsubsd", "vsubps", "vsubpd", "vmulss", "vmulsd", "vmulps", "vmulpd", "vfmadd",
    "vfmsub", "vfnmadd", "haddps", "haddpd", // aarch64
    "fadd", "fsub", "fmul", "fdiv", "fmadd", "fmsub", "fnmadd", "fmla", "fmls",
    // wasm
    "f32.add", "f32.sub", "f32.mul", "f64.add", "f64.sub", "f64.mul",
];

/// The float opcode on this assembly line, if any.
fn float_opcode(line: &str) -> Option<&'static str> {
    // Labels, directives, and comments are not instructions.
    if line.is_empty()
        || line.starts_with('.')
        || line.starts_with('#')
        || line.starts_with("//")
        || line.ends_with(':')
    {
        return None;
    }
    let mnemonic = line.split_whitespace().next()?;
    FLOAT_OPCODES
        .iter()
        .copied()
        .find(|op| mnemonic == *op || mnemonic.starts_with(op))
}

fn asm_files(dir: &Path) -> Result<Vec<PathBuf>, Fail> {
    let mut out = Vec::new();
    let mut stack = std::vec![dir.to_path_buf()];
    while let Some(d) = stack.pop() {
        let Ok(entries) = std::fs::read_dir(&d) else {
            continue;
        };
        for entry in entries {
            let path = entry?.path();
            if path.is_dir() {
                stack.push(path);
            } else if path.extension().is_some_and(|e| e == "s") {
                out.push(path);
            }
        }
    }
    Ok(out)
}
