# VERIFICATION

Which axis of `just vv` discharges which class of claim.

| `just` recipe | Enforces | ID classes |
| --- | --- | --- |
| `just fmt-check` | the diff is reviewable | --- |
| `just model` | R1, R8, R10, R11, R13, R15 | `CM-01`, and the absence of `CN-*` |
| `just lint` | clippy at `-D warnings`, including the unsafe-documentation lints | --- |
| `just test` | the whole suite | `CS-*`, `CT-*`, `CD-*`, `CB-*`, `CK-*`, `CX-*`, `CA-01`, `CP-01`, `CU-02` .. `CU-05`, `CG-*` |
| `just purity` | R2, R3, R13 by grep, and `CU-01` by disassembly | `CU-01` |
| `just no-alloc` | R7, C1 | `CA-03` |
| `just bdd` | R9 and R4's behavioural half | `CM-02`, `CM-03` |
| `just checked` | every accumulator operation checked, no overflow | `CT-02` |
| `just cross` | the corpus digest off the host | `CA-02` |
| `just scaling` | fitted exponents, reported never asserted | `CG-01` .. `CG-07` |
| `just fuzz` | totality over unstructured input | `CT-01`, `CT-03`, `CK-06` |

## Every gate is falsifiable

A gate nobody has seen fail is indistinguishable from a gate that cannot. Each
of these has been checked by planting the defect it exists to catch:

| Gate | Planted defect | Reported |
| --- | --- | --- |
| `check-constants` (R1) | a model numeral restated in a shipped crate | yes |
| `audit-limits` (R8) | a `Result` over an unsanctioned error | yes |
| `audit-purity` (R2) | `x + 1.0` in a shipped crate | yes |
| `audit-disassembly` (`CU-01`) | a float accumulation the optimizer keeps | yes |
| `audit-deferral` (R15) | a `TODO` in a shipped crate | yes |
| the honesty meta-gate (R4) | an ID with no test | yes |
| the differential comparator | a one-element difference | yes |
| the ulp metric | `+0.0` against `-0.0`, and a known one-ulp pair | yes |
| the scaling fit | a known exponent, and too few points | yes |
| the NumPy digest check | a published SHA-256 vector | yes |

`audit-disassembly` deliberately does *not* catch a float add the optimizer
removed, because such an add is not in the shipped kernel. The gate reports the
binary rather than the source, which is the only thing worth reporting.

## What the suite does not establish

The upstream formalization's theorems. `CL-MM01` .. `CL-MM04` are cited, never
re-derived, and a `CX-*` result is evidence that the kernels realize the
identity --- not a proof of it. `model/authorities.toml` records what is cited
and from where; the meta-gate fails the build if any document blurs the two
registers.
