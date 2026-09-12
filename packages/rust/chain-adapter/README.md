# chain-adapter

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/rust-1.70%2B-orange.svg)](https://www.rust-lang.org)

A **Rust library** that abstracts interaction with an Ethereum‑compatible blockchain for the Phase Mirror `chain‑adapter` protocol. It provides a concrete implementation of the `IChainAdapter` trait (`EVMAdapter`) that can:

- **Submit zk‑SNARK proofs** to the on‑chain core contract.
- **Query the current chain state** (current state hash, prime gates, etc.).
- **Verify proofs on‑chain** via a verifier contract.
- **Query network information** such as the chain ID.
- **Manage contract addresses** in a type‑safe way.
- **Placeholder utilities** for nullifier handling (future work).

The crate is part of the **Phase Mirror** ecosystem (see the `CONTRIBUTING.md` for the governance model).

---

## 📦 Crate Layout

```
chain-adapter/
├─ Cargo.toml                 # Crate metadata and dependencies
├─ src/
│   ├─ lib.rs                # Re‑exports the public API
│   ├─ adapter.rs            # `EVMAdapter` implementation
│   ├─ events.rs             # Event definitions (currently empty)
│   └─ models.rs             # Core data structures (ChainState, Proof, …)
├─ LICENSE
├─ CONTRIBUTING.md
├─ CODE_OF_CONDUCT.md
└─ …                        # Additional governance docs
```

### Key Types (in `models.rs`)
- `ChainState` – Holds the on‑chain state hash, prime gates and bookkeeping info.
- `ContractAddresses` – Addresses of the core contract and verifier contracts.
- `Proof`, `ProofSubmission` – Structured representation of zk‑SNARK proof data.
- `TransactionResult` – Minimal receipt information returned after a transaction.

---

## 🛠️ Getting Started

Add the crate to your workspace or binary:

```toml
[dependencies]
chain-adapter = { path = "../chain-adapter" }
```

If you are using the top‑level workspace (the repository contains a workspace definition), the `version.workspace = true` entry in `Cargo.toml` means the version is managed centrally.

### Minimum Rust version
The crate requires **Rust 1.70** or newer.

### Feature Flags
No optional features are currently defined – the crate pulls in the following runtime dependencies:
- `alloy` – Ethereum client utilities (HTTP provider, solidity bindings, etc.)
- `tokio` – Async runtime
- `serde` / `serde_json` – (de)serialization of proof payloads
- `anyhow` – Error handling
- `url` – URL parsing for RPC endpoints

---

## 🚀 Example Usage

```rust
use chain_adapter::{EVMAdapter, IChainAdapter, models::{ProofSubmission, ContractAddresses}};
use url::Url;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialise the adapter with an RPC endpoint and optional private key.
    let rpc = "https://mainnet.infura.io/v3/YOUR_PROJECT_ID";
    let private_key = Some("0xabc123..."ul);
    let addresses = ContractAddresses {
        core: "0xCoreContract".parse()?,
        root_verifier: "0xVerifier".parse()?,
        miller_rabin_verifier: "0xMRVerifier".parse()?,
        recovery_verifier: "0xRecovery".parse()?,
        receipt_registry: None,
        finality_tracker: None,
    };

    let adapter = EVMAdapter::new(rpc, private_key, Some(addresses)).await?;

    // Example: fetch the current chain state.
    let state = adapter.get_current_state().await?;
    println!("Current state hash: 0x{:x}", state.current_state);

    // Example: submit a proof (you would build a proper ProofSubmission struct).
    // let submission = ProofSubmission { ... };
    // let receipt = adapter.submit_proof(submission).await?;
    // println!("Tx hash: {}", receipt.hash);

    Ok(())
}
```

> **Note** – The library only provides the low‑level adapter. Higher‑level protocol orchestration lives in the `phase-mirror` crates.

---

## 📚 Documentation
The public API is re‑exported from `src/lib.rs`. Run `cargo doc --open` to generate and view the documentation locally.

---

## 🤝 Contributing
Please see our extensive guidelines:
- **Code of Conduct** – `CODE_OF_CONDUCT.md`
- **How to Contribute** – `CONTRIBUTING.md`
- **Governance & MIP process** – `Ξ-Constitution.md` and related docs.

All contributions must be licensed under the Apache‑2.0 with Managed Service Restriction (see `LICENSE`).

---

## 📜 License
`chain-adapter` is released under the **Apache License 2.0** with a Managed Service Restriction as described in `LICENSE`.

---

## 📞 Contact
For questions or community discussion, join the Phase Mirror GitHub Discussions or email `support@citizengardens.org`.
