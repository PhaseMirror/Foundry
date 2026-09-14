//! Byte-exact renderer for `basis_factors.json` in Python's
//! `json.dump(data, f, indent=2)` format.
//!
//! Python emits keys in insertion order (`primes`, `max_exp`, `basis`), lists
//! one element per line indented two spaces per nesting level, and finishes
//! without a trailing newline. This renderer reproduces that layout exactly;
//! `tests/fidelity.rs` asserts byte equality against the committed JSON.

use crate::model::BasisData;

/// Render `BasisData` exactly as `export_basis.py` writes it.
pub fn render_basis_data(data: &BasisData) -> String {
    let mut out = String::from("{\n");
    out.push_str(&format!(
        "  \"primes\": {},\n",
        indent_array(&data.primes, 4, 2)
    ));
    out.push_str(&format!("  \"max_exp\": {},\n", data.max_exp));
    out.push_str("  \"basis\": [\n");
    let total = data.basis.len();
    for (i, entry) in data.basis.iter().enumerate() {
        out.push_str("    {\n");
        out.push_str(&format!("      \"n\": {},\n", entry.n));
        out.push_str(&format!(
            "      \"exponents\": {}\n",
            indent_array(&entry.exponents, 8, 6)
        ));
        out.push_str(if i + 1 == total { "    }" } else { "    }," });
        out.push('\n');
    }
    out.push_str("  ]\n");
    out.push('}');
    out
}

fn indent_array(items: &[u64], element_pad: usize, close_pad: usize) -> String {
    if items.is_empty() {
        return "[]".to_string();
    }
    let pad = " ".repeat(element_pad);
    let body = items
        .iter()
        .map(|v| format!("{pad}{v}"))
        .collect::<Vec<_>>()
        .join(",\n");
    format!("[\n{body}\n{}]", " ".repeat(close_pad))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::BasisEntry;

    #[test]
    fn tiny_document_layout() {
        let data = BasisData {
            primes: vec![2, 3],
            max_exp: 1,
            basis: vec![BasisEntry { n: 1, exponents: vec![0, 0] }],
        };
        assert_eq!(
            render_basis_data(&data),
            "{\n  \"primes\": [\n    2,\n    3\n  ],\n  \"max_exp\": 1,\n  \"basis\": [\n    {\n      \"n\": 1,\n      \"exponents\": [\n        0,\n        0\n      ]\n    }\n  ]\n}"
        );
    }
}