# AGENTS

The standing brief for anyone --- human or otherwise --- changing this
repository.

## Read first

`README.md` for the thesis and the non-goals, then `ARCHITECTURE.md` §"The one
sentence". Everything else follows from those two.

## The rules, in the order they are most often broken

1. **The model is the single source (R10).** Every constant lives in
   `model/*.toml`. `crates/uor-matmul-core/src/generated.rs` and
   `CONFORMANCE.md` are *generated*; editing either is a mistake the gate
   catches. Run `just model-write` after changing the model.

2. **Nothing is deferred (R15).** No `TODO`, no stub, no placeholder section, no
   capability behind a flag that turns it off. If a change cannot be finished,
   it should not be started --- and `cargo xtask audit-deferral` will say so.

3. **One method (R13).** There is no fast path and no careful path. If a change
   introduces a second way of computing the same thing, it is wrong even if both
   ways agree, because agreement today is not agreement tomorrow. Backends and
   traversals are *factorizations*: they must be differentially tested against
   the portable reference, and the reference is never optimized (R6).

4. **The operation is total (R14, C6).** `gemm` returns `()`. If a change wants
   to return a `Result`, the question to ask is "what object does not exist?" ---
   and if the answer is anything about the data's size, depth, or magnitude, the
   change is wrong.

5. **Levels are load-bearing (R4).** A claim is `some-true` (reproduced from an
   authority), `build` (constructed here and validated), or `open` (measured and
   reported). Writing "proves" about an `open` claim fails the meta-gate, and it
   should.

## Adding a capability

In this order, because the order is the discipline:

1. A row in `model/ids.toml`, with its level.
2. A scenario in `features/suites/`, tagged with the ID.
3. A failing test whose name **ends in the ID**, lowercased with underscores.
4. The parametric implementation.
5. `just vv`.

Steps 1--3 before step 4 is R9. The meta-gate enforces all of it: an ID with no
scenario, a scenario with no ID, or an ID with no test all fail `just bdd`.

## Adding a backend

Add a module under `crates/uor-matmul-kernels/src/isa/` exporting a
`KernelSpec`, and add it to `available()`. Touch no driver code --- if you need
to, the abstraction is wrong and that is the thing to fix. The differential test
picks it up automatically.

## Adding an element type

An `impl Element`, plus `IntegerElement` or `FloatElement`. If you find yourself
adding a branch anywhere else, the type is not being added parametrically.

## Writing a gate

A gate that cannot fail is worse than no gate, because it reads as evidence.
Before adding one, plant the defect it exists to catch and confirm it fires;
then record that in `VERIFICATION.md`'s falsifiability table. Two gates in this
repository were found to be vacuous exactly this way.

## Comments

Explain *why*, not *what*. The code says what it does. A comment earns its place
by recording the reason a decision went one way when it could plausibly have
gone another --- a bound that is derived rather than chosen, an ordering that is
normative rather than conventional, a saturation that is inside the encode step
rather than in an accumulation.
