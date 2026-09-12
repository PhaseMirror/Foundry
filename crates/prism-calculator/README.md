# prism-calculator

A sealed PrismPM calculator model: `Operation`, `Request`, `Result Int64`,
`CalculatorError`, and byte-level `AcceptanceVector`s.

This crate is the **Twin-side victim** for the Phase Mirror Adversarial
Twin lift harness (`tests/adversarial_twin_integration.rs`). It is
deliberately small: its semantics are sealed, its arithmetic is checked,
and its acceptance vectors are byte-stable so the Twin can lift the model
into a prime-indexed dynamical system and attempt to break it.

See `docs/adr/accepted/0002-Prism-Pirtm-Integration.md` for the full
architectural contract.