# PrismPM 0.3.0

PrismPM 0.3.0 is the first production-system SDK release. It retains the
Holo/1 application profile and adds locked product-release construction, OCI
distribution, Compose and Kubernetes 1.36.4 targets, lifecycle and recovery
operations, supply-chain policy, immutable standards/oracle imports, and the
UOR template/action SDK entrypoint.

The exact adopted editions, acquired source hashes, executable oracle hashes,
and covered/uncovered requirements are recorded in `standards.lock`; that lock
is normative and is included in the SDK image. A passing imported schema or
finite upstream corpus is reported only at that scope. This release makes no
standards-certification, universal-correctness, untested-provider, or
unsupported SLSA-level claim.

Supported deployment targets are the pinned Compose implementation and
Kubernetes 1.36.4/Kind profile. GitHub Pages remains the portable Calculator
application publication target, not the stateful production-service target.
Provider-specific managed-cloud adapters are not included.

The release publishes six separately signed multi-platform OCI identities:
the complete SDK, the generated-browser runtime, Compose/Kubernetes/GitHub
Pages adapter packages, and the redistributable oracle-runner package. Release
assets record each manifest-list and per-platform digest; consumer locks pin
the manifest-list digests rather than the `0.3.0` discovery tags.

Holo/1 is unchanged. `prism-stdlib` 0.2 adds production-system model APIs while
preserving the accepted 0.1 application APIs. Product releases are immutable:
promotion, deployment, rollback, and recovery select the exact OCI digest.
The separately authorized contract-migration phase can raise the compatible
data floor; PrismPM then refuses a release below that floor.

Security reports: use the private vulnerability-reporting facility in the
GitHub Security tab for `UOR-Foundation/PrismPM`.

Verification begins with immutable identities published in this release:

```sh
sha256sum --check SHA256SUMS
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/UOR-Foundation/PrismPM/.github/workflows/release.yml@refs/tags/v0\.3\.0$' \
  ghcr.io/uor-foundation/prismpm-sdk@sha256:DIGEST
docker run --rm ghcr.io/uor-foundation/prismpm-sdk@sha256:DIGEST prismpm --version
```

Replace `DIGEST` only with the manifest-list digest in the signed release
assets; tags are discovery names and are not verification or deployment
identities.
