//! Negative standards-register contract tests.

use repo_model::Standards;

fn row(extra: &str) -> String {
    format!(
        r#"spec = "prismpm/standards/1"
[[standard]]
id = "ISO-TEST-2026"
name = "ISO test catalog row"
edition = "2026"
reference = "https://www.iso.org/standard/1.html"
basis = "public-catalog"
scope = "Public catalog scope"
provenance = "ISO public catalog"
interpretation = "A repository-authored interpretation."
facet_package = "prism.arch"
facet_entries = ["arch-component"]
coverage_state = "implemented"
release_scope = true
{extra}
"#
    )
}

#[test]
fn missing_edition_and_unsupported_certification_are_rejected() {
    let mut standards: Standards = toml::from_str(&row("")).expect("row");
    standards.standard[0].edition.clear();
    assert!(standards.check().is_err());

    let mut standards: Standards = toml::from_str(&row("")).expect("row");
    standards.standard[0].interpretation = "PrismPM is ISO certified".to_owned();
    assert!(standards.check().is_err());
}

#[test]
fn body_and_long_quotation_fields_are_not_in_the_schema() {
    assert!(toml::from_str::<Standards>(&row("body = \"forbidden\"")).is_err());
    assert!(toml::from_str::<Standards>(&row("long_quotation = \"forbidden\"")).is_err());
}
