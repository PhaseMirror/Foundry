<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# The Phase Mirror Oracle Pro is now at a point where its internal machinery is

unified. To move toward an external ecosystem, we must define the "contract"
between the Oracle and its clients.

Here is a concrete sketch for a minimal external verifier API. This would live
in a standalone crate (e.g., phase-mirror-client) that avoids the heavy
dependencies of the Pro-tier prover.

External Verifier API Sketch (Rust)

    1 /// The Phase Mirror Client API
    2 /// This module provides the minimal structures for verifying Oracle
      outputs.
    3 pub mod verifier {
    4     use serde::{Deserialize, Serialize};
    5
    6     /// 1. Configuration Seal: The mathematical "anchors" of the domain.
    7     /// Certificates from mismatched seals are rejected immediately.
    8     #[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
    9     pub struct ConfigurationSeal {
    10         pub domain_tag: String,     // e.g., "AZ-TFTC-1D-MAINNET"
11         pub prime_index: u32,       // The prime basis used (e.g., 64)
12         pub n0_scale: u32,          // The base scale for N0
13         pub air_version: String,    // e.g., "v0.3.0-temporal"
14     }
15
16     /// 2. Multiplicity Certificate: The high-level claim about spectral
health.
17     \#[derive(Serialize, Deserialize, Clone, Debug)]
18     pub struct MultiplicityCertificate {
19         pub seal: ConfigurationSeal,
20         pub timestamp_ms: u64,
21         pub spectral_gap: u64,        // The delta_pz value
22         pub resonance_root: [u8; 32], // Merkle root of resonance words
23         pub status: OracleStatus,     // e.g., STABLE, RECOVERED, VETOED
24         pub signature: Vec<u8>,       // Oracle's Ed25519/Secp256k1
signature
25     }
26
27     \#[derive(Serialize, Deserialize, Clone, Debug)]
28     pub enum OracleStatus {
29         Stable,
30         Recovered { ks_statistic: f64 },
31         Vetoed { reason: String },
32     }
33
34     /// 3. Resonance Proof: The STARK proof artifact.
35     \#[derive(Serialize, Deserialize, Clone, Debug)]
36     pub struct ResonanceProof {
37         pub proof_bytes: Vec<u8>,    // Plonky3 serialized proof
38         pub public_inputs: Vec<u64>, // [initial_mask, delta_pz,
delta_pz_floor, ...]
39     }
40
41     /// 4. Verification Outcome
42     \#[derive(Debug, PartialEq)]
43     pub enum VerificationResult {
44         Success,
45         MismatchedSeal(String),
46         InvalidSignature,
47         ProofFailure(String),
48         VetoedByOracle(String),
49     }
50
51     /// The Core Verifier logic
52     pub struct PhaseMirrorVerifier {
53         pub oracle_public_key: Vec<u8>,
54     }
55
56     impl PhaseMirrorVerifier {
57         /// End-to-end verification of an Oracle event.
58         pub fn verify_event(
59             \&self,
60             expected_domain: \&str,
61             cert: \&MultiplicityCertificate,
62             proof: \&ResonanceProof,
63         ) -> VerificationResult {
64             // A. Check Compatibility
65             if cert.seal.domain_tag != expected_domain {
66                 return
VerificationResult::MismatchedSeal(cert.seal.domain_tag.clone());
67             }
68
69             // B. Verify Signature (fast path)
70             if !self.verify_cert_signature(cert) {
71                 return VerificationResult::InvalidSignature;
72             }
73
74             // C. Check Veto Status
75             if let OracleStatus::Vetoed { reason } = \&cert.status {
76                 return VerificationResult::VetoedByOracle(reason.clone());
77             }
78
79             // D. Verify ZK Proof (Plonky3 STARK)
80             // This ensures the resonance data matches the claims in the
cert.
81             match self.verify_stark(cert, proof) {
82                 Ok(_) => VerificationResult::Success,
83                 Err(e) => VerificationResult::ProofFailure(e),
84             }
85         }
86
87         fn verify_cert_signature(\&self, cert: \&MultiplicityCertificate) ->
bool {
88             // Implementation uses standard crypto libs (e.g.,
ed25519-dalek)
89             true
90         }
91
92         fn verify_stark(\&self, cert: \&MultiplicityCertificate, proof:
\&ResonanceProof) -> Result<(), String> {
93             // Implementation invokes Plonky3 verifier for 'air-prime-res'
94             Ok(())
95         }
96     }
97 }

Implementation Strategy

1. Crate Extraction: I will create agi_os/crates/phase-mirror-client
containing this API.
2. Plonky3 Verifier Integration: This crate will depend on p3-uni-stark but
not the full prover or the heavy simulation machinery.
3. CLI Tooling: A new CLI tool pm-verify will be added to agi_os/bin/ to
demonstrate usage:

1     pm-verify --domain "AZ-TFTC-1D" --cert cert.json --proof proof.bin

Does this API capture the "contracts" you had in mind, or should we add more
granular fields to the ConfigurationSeal (e.g., the specific Hamiltonian
parameters or the spectral veto threshold)?

Yes — this is very close to the right contract, but I would add a few more **seal-critical** fields and slightly tighten the separation between the signed certificate layer and the proof-verification layer. In particular, verifier contracts for ZK systems generally need an explicit binding to a verification key or its hash, and signed payloads should be canonicalized rather than relying on ad hoc serde output.[^1][^2][^3]

## Main recommendation

Keep your four objects, but strengthen them this way:

- `ConfigurationSeal`: include the parameters that define **mathematical compatibility**, not just branding/versioning.
- `MultiplicityCertificate`: keep it as the signed high-level claim.
- `ResonanceProof`: bind it to the exact verifier configuration and public-input schema.
- `PhaseMirrorVerifier`: verify in this order:

1. seal compatibility,
2. canonical signed payload,
3. proof/public-input consistency,
4. policy outcome (`Stable` / `Recovered` / `Vetoed`).[^4][^2][^5]

That means: yes, add more granular fields to the seal, but only the ones that affect **proof meaning** or **certificate comparability**.

## What to add to `ConfigurationSeal`

I would add these fields:

- `hamiltonian_family: String`
- `spectral_threshold_profile: String` or a hash thereof
- `proof_system: String` such as `"plonky3-uni-stark"`
- `verification_key_hash: [u8; 32]`
- `public_input_schema_hash: [u8; 32]`

Why these matter:

- If two domains use different Hamiltonian parameterizations, then the same spectral output may not mean the same thing, so the seal should capture at least the Hamiltonian **family** or a hash of the full config.[^2]
- The verifier must know which proof configuration it is checking; Plonky3 discussion explicitly highlights that verification-key material or a hash of it needs to be part of the verification contract.[^2]
- Public inputs must be schema-bound, because ZK verifiers are sensitive not just to values but to their exact ordering and interpretation.[^5][^4]

I would **not** put every raw Hamiltonian coefficient directly in the seal unless clients truly need them. Better pattern: include a `model_hash` or `spectral_threshold_profile_hash` derived from the authoritative config document.

## What to change in `MultiplicityCertificate`

I would split the signed payload from the signature container:

```rust
pub struct SignedMultiplicityCertificate {
    pub payload: MultiplicityCertificatePayload,
    pub signature: [u8; 64],
    pub signature_scheme: SignatureScheme,
}

pub struct MultiplicityCertificatePayload {
    pub seal: ConfigurationSeal,
    pub timestamp_ms: u64,
    pub spectral_gap: u64,
    pub resonance_root: [u8; 32],
    pub proof_commitment: [u8; 32],
    pub status: OracleStatus,
}
```

This is better because:

- the signature is over a **canonical payload**, not over a Rust struct with incidental serialization behavior,
- the payload can explicitly bind to the proof through `proof_commitment`,
- Ed25519 verification libraries in Rust are designed around signing bytes/messages, not arbitrary serde objects.[^6][^3][^1]

Also, I would strongly prefer:

- `signature: [u8; 64]` over `Vec<u8>`,
- `oracle_public_key: [u8; 32]` or an enum-wrapped fixed-size key,
because fixed-width crypto material is less error-prone than variable-length blobs.[^7][^3]


## What to change in `ResonanceProof`

Your current `public_inputs: Vec<u64>` is too loose for a stable external contract. I would make it explicit:

```rust
pub struct ResonancePublicInputs {
    pub initial_mask: u64,
    pub delta_pz: u64,
    pub delta_pz_floor: u64,
    pub resonance_root: [u8; 32],
}

pub struct ResonanceProof {
    pub proof_system: String,
    pub verification_key_hash: [u8; 32],
    pub public_inputs: ResonancePublicInputs,
    pub proof_bytes: Vec<u8>,
}
```

Why:

- vectors are fragile; field order bugs become silent compatibility bugs,
- typed public inputs make the contract self-describing,
- verifier-side proof validation should reject proofs whose `verification_key_hash` doesn’t match the expected seal.[^4][^2]


## Verification order

I would adjust `verify_event()` to:

1. Check `cert.payload.seal.domain_tag == expected_domain`.
2. Check full seal compatibility, not just domain tag:
    - `prime_index`
    - `n0_scale`
    - `air_version`
    - `verification_key_hash`
    - `public_input_schema_hash`
3. Verify certificate signature on canonical bytes.
4. If `status == Vetoed`, return `VetoedByOracle` **after** signature verification but **before** expensive proof verification.
5. Cross-check that certificate payload and proof public inputs agree:
    - `spectral_gap == delta_pz`
    - `resonance_root` matches
    - proof config matches seal
6. Verify STARK proof.[^3][^1][^2]

That gives you a fast-fail path while still preserving cryptographic meaning.

## Suggested `VerificationResult`

I’d make it a bit more granular:

```rust
pub enum VerificationResult {
    Success,
    MismatchedSeal { expected: ConfigurationSeal, actual: ConfigurationSeal },
    InvalidSignature,
    ProofInputMismatch(String),
    ProofFailure(String),
    VetoedByOracle(String),
}
```

That helps downstream clients distinguish:

- “wrong domain/config,”
- “forged certificate,”
- “real certificate but inconsistent proof,”
- “validly vetoed event.”


## CLI contract

Your CLI shape is good:

```bash
pm-verify --domain "AZ-TFTC-1D" --cert cert.json --proof proof.bin
```

I would extend it slightly to support explicit verifier pinning:

```bash
pm-verify \
  --domain "AZ-TFTC-1D" \
  --expected-seal seal.json \
  --cert cert.json \
  --proof proof.bin
```

or

```bash
pm-verify --domain "AZ-TFTC-1D" --vk-hash <hex> --cert cert.json --proof proof.bin
```

That avoids hidden trust in whatever seal the certificate claims for itself.[^2]

## Direct answer

So: **yes, add more granular seal fields**, but add them as **hashes or stable identifiers of mathematical/proof semantics**, not as a dump of every runtime parameter. The most important additions are:

- `verification_key_hash`
- `public_input_schema_hash`
- `hamiltonian_family` or `model_hash`
- `spectral_threshold_profile` or its hash

With those additions, your API becomes a real external contract rather than just a convenient serialization of internal state.[^5][^4][^2]

If you want, I can draft the **revised Rust API** for `phase-mirror-client` with these changes baked in.
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18][^19][^20][^21][^22][^23][^24][^25][^26][^27][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://github.com/RustCrypto/signatures/blob/master/ed25519/src/lib.rs

[^2]: https://github.com/Plonky3/Plonky3/issues/511

[^3]: https://doc.dalek.rs/ed25519_dalek/index.html

[^4]: https://github.com/succinctlabs/sp1-contracts/blob/main/contracts/src/v3.0.0-rc1/PlonkVerifier.sol

[^5]: https://www.openzeppelin.com/news/linea-prover-audit

[^6]: https://docs.rs/ed25519

[^7]: https://github.com/rust-bitcoin/rust-secp256k1/issues/295

[^8]: https://github.com/RustCrypto/signatures/issues/818

[^9]: https://github.com/jedisct1/rust-ed25519-compact

[^10]: https://gist.github.com/VladChernenko/1e864fb2978e0d565e0e981927aaff8f

[^11]: https://gist.github.com/CalebCurry/81333903de4e1bac043da20d3b90cf89

[^12]: https://github.com/godaddy/ans-registry/

[^13]: https://github.com/saifaustcse/api-best-practices

[^14]: https://github.com/RustCrypto/signatures/actions/workflows/ed25519.yml

[^15]: https://github.com/Consensys/plonk-solidity-audit

[^16]: https://github.com/Breus/json-masker/blob/master/adr/0002-masking-configuration-API.md

[^17]: https://github.com/RustCrypto/signatures/blob/master/ed25519/Cargo.toml

[^18]: https://github.com/guanzhi/zkrypt/blob/main/Plonk-Verifier.sol

[^19]: https://fnordig.de/2016/09/28/signify-ed25519-signatures-for-your-files/

[^20]: https://tidelabs.github.io/tidext/ed25519/index.html

[^21]: https://sapient-bundle.readthedocs.io/en/latest/configuration.html

[^22]: https://users.rust-lang.org/t/serde-use-within-a-library-best-practices/111059

[^23]: https://www.certik.com/blog/breaking-down-proof-construction-in-plonky3-the-fibonacci-example-unveiled

[^24]: https://docs.digicert.com/en/content-trust-manager/sign-documents/client-tools/sealsign-2-0/configure-sealsign-2-0/configure-sealsign-2-0-on-linux.html

[^25]: https://ssojet.com/keypair-generation/generate-keypair-using-ed25519-in-rust

[^26]: https://seal-docs.wal.app/Design

[^27]: https://github.com/dalek-cryptography/ed25519-dalek/issues/80

