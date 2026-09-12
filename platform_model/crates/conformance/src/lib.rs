//! Conformance testing harness and validation runners.

#![deny(missing_docs)]
#![forbid(unsafe_code)]
// Conformance deliberately exercises the complete public PrismError value;
// boxing it here would test a different API from downstream callers.
#![allow(clippy::result_large_err)]

pub mod cases;
pub mod fixtures;
pub mod meta;
pub mod runner;

pub use meta::check_honesty;

use std::collections::BTreeSet;
use std::path::Path;

/// Scan workspace test names.
#[must_use]
pub fn workspace_test_names(root: &Path) -> BTreeSet<String> {
    let (names, _flagged) = workspace_test_names_with_flags(root);
    names
}

/// Scan test names and check flags independently from test source files.
#[must_use]
pub fn workspace_test_names_with_flags(root: &Path) -> (BTreeSet<String>, BTreeSet<String>) {
    let mut names = BTreeSet::new();
    let mut flagged = BTreeSet::new();

    let tests_file = root.join("crates/conformance/tests/conformance.rs");
    if let Ok(content) = std::fs::read_to_string(&tests_file) {
        for line in content.lines() {
            let line = line.trim();
            if let Some(rest) = line.strip_prefix("test_case!(") {
                if let Some(ident) = rest.split(',').next() {
                    let ident = ident.trim();
                    if !ident.is_empty() {
                        names.insert(ident.to_owned());
                    }
                }
            } else if let Some(rest) = line.strip_prefix("fn ") {
                if let Some(ident) = rest.split('(').next() {
                    let ident = ident.trim();
                    if ident.starts_with("conformance_") {
                        names.insert(ident.to_owned());
                    }
                }
            }
        }

        let compact: String = content
            .chars()
            .filter(|character| !character.is_whitespace())
            .collect();
        let unconditional_macro = "($id:ident,$str:expr)=>{#[test]fn$id(){cases::run($str);}};";
        if !compact.contains(unconditional_macro) {
            flagged.insert("test_case! macro does not emit an unconditional #[test]".to_owned());
        }
        for attribute in ["#[ignore", "#[cfg(", "#[cfg_attr(", "#[should_panic"] {
            if compact.contains(attribute) {
                flagged.insert(format!(
                    "conformance test source contains disabling attribute {attribute}"
                ));
            }
        }
    }

    (names, flagged)
}

#[cfg(test)]
mod tests {
    use super::workspace_test_names_with_flags;

    fn repository_with_tests(source: &str) -> tempfile::TempDir {
        let root = tempfile::tempdir().expect("temporary repository");
        let directory = root.path().join("crates/conformance/tests");
        std::fs::create_dir_all(&directory).expect("test directory");
        std::fs::write(directory.join("conformance.rs"), source).expect("test source");
        root
    }

    #[test]
    fn conformance_discovery_rejects_hidden_or_non_test_macros() {
        let valid = r#"
            macro_rules! test_case {
                ($id:ident, $str:expr) => { #[test] fn $id() { cases::run($str); } };
            }
            test_case!(conformance_rp_01, "RP-01");
        "#;
        let root = repository_with_tests(valid);
        let (names, flagged) = workspace_test_names_with_flags(root.path());
        assert_eq!(names.into_iter().collect::<Vec<_>>(), ["conformance_rp_01"]);
        assert!(flagged.is_empty());

        let hidden = valid.replace("#[test]", "#[ignore]\n#[test]");
        let root = repository_with_tests(&hidden);
        assert!(!workspace_test_names_with_flags(root.path()).1.is_empty());

        let not_a_test = valid.replace("#[test]", "");
        let root = repository_with_tests(&not_a_test);
        assert!(!workspace_test_names_with_flags(root.path()).1.is_empty());
    }
}
