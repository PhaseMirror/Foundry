# External oracle corpus provenance

The Kubernetes cases are byte-for-byte copies from the locked
`kubernetes/kubernetes` revision `bb826b1d48562f110659e64e8ec444327433db95`:

- `valid-service.yaml`: `hack/testdata/kubernetes-service.yaml`
- `invalid-pod.yaml`: `hack/testdata/invalid-pod.yaml`

They are redistributed under the upstream Apache-2.0 license recorded by
`KUBERNETES-1-36-4` in `standards.lock`.

The locked `devcontainers/spec` source archive contains its official schemas
but no complete positive/negative `devcontainer.json` fixture pair. The two
Dev Container cases are therefore explicitly PrismPM-planted schema corpus
inputs. They exercise the exact upstream base-schema asset without claiming to
be upstream conformance fixtures. The schema is redistributed under the MIT
license recorded by `DEVCONTAINER-C95FFEED` in `standards.lock`.

These are schema-oracle cases only. They do not establish runtime startup,
admission, defaulting, editor, or container-engine behavior.

The Cosign pair is the exact `cosign_checksums.txt` and corresponding Sigstore
bundle published as release assets for the locked Cosign 3.1.3 release. Their
SHA-256 values are respectively
`aec2a6f68d307b09ae196e388dc691a146fa8bdba7fcce9ca4ca41b918adfa63`
and `976bcb216e45ed0274e464e2e16d81e84cc85a69b3ed6e3488c1e7cda116379a`.
The certificate identity is
`keyless@projectsigstore.iam.gserviceaccount.com` and its OIDC issuer is
`https://accounts.google.com`. The sandbox verifies the pair offline against
the separately content-bound Cosign/TUF-derived trusted-root snapshot; a
one-byte subject mutation is the negative case.

The SLSA pair is a byte-for-byte copy of the zero-byte artifact and v0.1
Sigstore bundle at
`cli/slsa-verifier/testdata/gha_container-based/v1.7.0/` in the locked
SLSA verifier 2.7.1 source. Their SHA-256 values are respectively
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
and `1c6e77e49058e35519a875964231581defb7ee1eb461d5c043051601f5b688a3`.
The offline wrapper uses Cosign 3.1.3 to verify the bundle against the pinned
root, then enforces the SLSA v1 subject, source, and builder fields. This is an
intentional scoped replacement for the upstream 2.7.1 CLI path, which always
refreshes TUF and therefore cannot satisfy the no-network oracle contract.

The `github-signed-tags` records are canonicalized copies of GitHub's exact
annotated-tag payload and detached signature for every authority row that
claims a signed tag. GitHub's provider-verification result is retained only as
acquisition metadata. Verification independently replays each signature in the
network-denied SDK sandbox against the exact public key named by that authority
row. The OpenPGP keys are records `2155637` (`sudo-bmitch`) and `5228653`
(`AkihiroSuda`) from the respective GitHub `gpg_keys` endpoints. The SSH keys
are records `682831` (`Hayden-IO`) and `276780` (`songy23`) from the respective
`ssh_signing_keys` endpoints. Each modeled trust-root binding records the
packaged-byte SHA-256 and full signing fingerprint.

Those public keys are upstream account material intentionally published for
signature verification, not Prism-created trust authorities. PrismPM packages
only the selected public key bytes and records the legal classification as
`public-key-material-published-for-verification` with redistribution limited to
verification use. Tests replay all five official signatures and plant a wrong
key, changed payload, changed signature, and stale target revision.
